import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:birrmetrics/features/expenses/data/repositories/expense_repository.dart';
import 'package:birrmetrics/features/expenses/domain/entities/expense.dart';

final expenseRepositoryProvider = Provider((ref) => ExpenseRepository());

class ExpensesState {
  final AsyncValue<List<Expense>> list;
  final AsyncValue<int> total;

  ExpensesState({required this.list, required this.total});
}

class ExpensesNotifier extends StateNotifier<ExpensesState> {
  final ExpenseRepository _repo;

  ExpensesNotifier(this._repo) : super(ExpensesState(list: const AsyncLoading(), total: const AsyncLoading())) {
    loadAll();
  }

  Future<void> loadAll() async {
    state = ExpensesState(list: const AsyncLoading(), total: state.total);
    final expenses = await _repo.getAllExpenses();
    final total = await _repo.getTotalSpentThisMonth();
    state = ExpensesState(list: AsyncData(expenses), total: AsyncData(total));
  }

  Future<void> addExpense(Expense expense) async {
    await _repo.addExpense(expense);
    await loadAll(); // Reload automatically after saving!
  }
}

final expensesProvider = StateNotifierProvider<ExpensesNotifier, ExpensesState>((ref) {
  return ExpensesNotifier(ref.watch(expenseRepositoryProvider));
});
