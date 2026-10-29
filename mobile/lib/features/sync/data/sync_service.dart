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

  /// Pushes unsynced local records to the server.
  /// Returns a summary string (e.g. "5 items synced").
  Future<String> pushChanges() async {
    final token = await SecureStorage.getToken();
    if (token == null) throw Exception('Not authenticated');

    // 1. Fetch unsynced records
    final unsyncedExpenses = await _expenseRepo.getUnsyncedExpenses();
    final unsyncedDebts = await _debtRepo.getUnsyncedDebts();

    final totalCount = unsyncedExpenses.length + unsyncedDebts.length;
    if (totalCount == 0) return 'Nothing to sync';

    // 2. Build the payload
    final payload = {
      'expenses': unsyncedExpenses,
      'debts': unsyncedDebts,
    };

    // 3. Send to backend
    try {
      await _dio.post(
        '/sync/batch',
        data: payload,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      throw Exception('Sync failed: ${e.response?.data ?? e.message}');
    }

    // 4. Mark records as synced locally
    final expenseIds = unsyncedExpenses.map((e) => e['id'] as int).toList();
    final debtIds = unsyncedDebts.map((d) => d['id'] as int).toList();

    await _expenseRepo.markExpensesAsSynced(expenseIds);
    await _debtRepo.markDebtsAsSynced(debtIds);

    return '$totalCount item${totalCount == 1 ? '' : 's'} synced';
  }

  /// Pulls remote changes created after a given timestamp.
  Future<int> pullChanges({DateTime? since}) async {
    final token = await SecureStorage.getToken();
    if (token == null) throw Exception('Not authenticated');

    final sinceParam = since?.toUtc().toIso8601String() ?? '';

    try {
      final res = await _dio.get(
        '/sync/pull',
        queryParameters: {'since': sinceParam},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final expenses = res.data['expenses'] as List<dynamic>? ?? [];
      final debts = res.data['debts'] as List<dynamic>? ?? [];

      return expenses.length + debts.length;
    } on DioException catch (e) {
      throw Exception('Pull failed: ${e.response?.data ?? e.message}');
    }
  }
}