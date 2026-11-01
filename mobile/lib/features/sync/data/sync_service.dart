import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:birrmetrics/core/storage/secure_storage.dart';
import 'package:birrmetrics/features/expenses/data/repositories/expense_repository.dart';
import 'package:birrmetrics/features/debts/data/repositories/debt_repository.dart';

class SyncService {
  final _dio = Dio(BaseOptions(
    baseUrl: dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8080/api/v1',
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));

  final _expenseRepo = ExpenseRepository();
  final _debtRepo = DebtRepository();

  Future<String> fullSync() async {
    final token = await SecureStorage.getToken();
    if (token == null) throw Exception('Not authenticated');

    // 1. PUSH local changes
    final unsyncedExpenses = await _expenseRepo.getUnsyncedExpenses();
    final unsyncedDebts = await _debtRepo.getUnsyncedDebts();

    final pushCount = unsyncedExpenses.length + unsyncedDebts.length;

    if (pushCount > 0) {
      // Ensure is_lent is sent as a boolean
      final formattedDebts = unsyncedDebts.map((d) {
        return {
          ...d,
          'is_lent': (d['is_lent'] as int) == 1,
        };
      }).toList();

      final payload = {
        'expenses': unsyncedExpenses,
        'debts': formattedDebts,
      };

      try {
        await _dio.post(
          '/sync/batch',
          data: payload,
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
      } on DioException catch (e) {
        throw Exception('Push failed: ${e.response?.data ?? e.message}');
      }

      final expenseIds = unsyncedExpenses.map((e) => e['id'] as int).toList();
      final debtIds = unsyncedDebts.map((d) => d['id'] as int).toList();

      await _expenseRepo.markExpensesAsSynced(expenseIds);
      await _debtRepo.markDebtsAsSynced(debtIds);
    }

    // 2. PULL remote changes
    int pullCount = 0;
    try {
      final res = await _dio.get(
        '/sync/pull',
        queryParameters: {'since': ''},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final expenses = res.data['expenses'] as List<dynamic>? ?? [];
      final debts = res.data['debts'] as List<dynamic>? ?? [];

      for (final e in expenses) {
        final isNew = await _expenseRepo.insertPulledExpense(Map<String, dynamic>.from(e));
        if (isNew) pullCount++;
      }

      for (final d in debts) {
        final isNew = await _debtRepo.insertPulledDebt(Map<String, dynamic>.from(d));
        if (isNew) pullCount++;
      }
    } on DioException catch (e) {
      throw Exception('Pull failed: ${e.response?.data ?? e.message}');
    }

    return 'Pushed $pushCount, Pulled $pullCount';
  }
}