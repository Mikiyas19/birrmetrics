import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:birrmetrics/features/budget/data/repositories/budget_repository.dart';
import 'package:birrmetrics/features/budget/domain/entities/budget.dart';

final budgetRepositoryProvider = Provider((ref) => BudgetRepository());

/// Manages the current month's budget state.
class BudgetNotifier extends StateNotifier<AsyncValue<Budget?>> {
  final BudgetRepository _repo;

  BudgetNotifier(this._repo) : super(const AsyncLoading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.getCurrentBudget());
  }

  Future<void> setBudget(int amountSantim) async {
    await _repo.setCurrentBudget(amountSantim);
    await load();
  }

  Future<void> clearBudget() async {
    await _repo.clearCurrentBudget();
    await load();
  }
}

final budgetProvider =
StateNotifierProvider<BudgetNotifier, AsyncValue<Budget?>>((ref) {
  return BudgetNotifier(ref.watch(budgetRepositoryProvider));
});

/// Convenience provider: just the amount in santim (0 if no budget).
/// Used by the insight engine and dashboard.
final monthlyBudgetProvider = Provider<int>((ref) {
  final budgetAsync = ref.watch(budgetProvider);
  return budgetAsync.maybeWhen(
    data: (budget) => budget?.amountSantim ?? 0,
    orElse: () => 0,
  );
});
