import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:birrmetrics/features/sync/data/sync_service.dart';
import 'package:birrmetrics/features/expenses/presentation/providers/expense_providers.dart';
import 'package:birrmetrics/features/debts/presentation/providers/debt_providers.dart';

final syncServiceProvider = Provider((ref) => SyncService());

final syncStateProvider = StateNotifierProvider<SyncNotifier, AsyncValue<String?>>((ref) {
  return SyncNotifier(ref.watch(syncServiceProvider), ref);
});

class SyncNotifier extends StateNotifier<AsyncValue<String?>> {
  final SyncService _service;
  final Ref _ref;

  SyncNotifier(this._service, this._ref) : super(const AsyncData(null));

  Future<void> syncNow() async {
    state = const AsyncLoading();
    try {
      final result = await _service.fullSync();
      
      // FIXED: Calling the exact method names from your providers
      _ref.read(expensesProvider.notifier).loadAll();
      _ref.read(debtsProvider.notifier).loadDebts();
      
      state = AsyncData(result);
    } catch (e) {
      state = AsyncError(e.toString().replaceAll('Exception: ', ''), StackTrace.current);
    }
  }
}