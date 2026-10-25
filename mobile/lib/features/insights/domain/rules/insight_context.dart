import 'package:birrmetrics/features/expenses/domain/entities/expense.dart';
import 'package:birrmetrics/features/debts/domain/entities/debt.dart';

class InsightContext {
  final DateTime now;
  final List<Expense> monthExpenses;      // Current month's expenses
  final List<Expense> last7DaysExpenses;  // For spike detection
  final List<Expense> lastMonthExpenses;  // For trend detection
  final List<Debt> activeDebts;           // Not settled
  final int monthlyBudgetSantim;          // 0 if not set
  final Map<int, int> spendByCategory;    // categoryId → total santim
  final Map<int, String> categoryNames;   // categoryId → name
  final int totalSpentThisMonth;          // Sum of all expenses this month
  final int daysElapsed;                  // Days elapsed in current month
  final int daysInMonth;                  // Total days in current month

  const InsightContext({
    required this.now,
    required this.monthExpenses,
    required this.last7DaysExpenses,
    required this.lastMonthExpenses,
    required this.activeDebts,
    required this.monthlyBudgetSantim,
    required this.spendByCategory,
    required this.categoryNames,
    required this.totalSpentThisMonth,
    required this.daysElapsed,
    required this.daysInMonth,
  });

  // Helper methods for rules
  double get budgetUsedPercent {
    if (monthlyBudgetSantim <= 0) return 0;
    return (totalSpentThisMonth / monthlyBudgetSantim) * 100;
  }

  /// Average spent per ACTIVE day (days where the user actually spent money).
  /// Falls back to 0 if no expenses.
  double get dailyAvgSpent {
    if (monthExpenses.isEmpty) return 0;
    // Count unique days with expenses
    final activeDays = monthExpenses
        .map((e) => DateTime(e.expenseDate.year, e.expenseDate.month, e.expenseDate.day))
        .toSet()
        .length;
    if (activeDays == 0) return 0;
    return totalSpentThisMonth / activeDays;
  }

  int get projectedMonthlySpend {
    if (daysElapsed == 0) return 0;
    return (dailyAvgSpent * daysInMonth).round();
  }

  bool get hasBudget => monthlyBudgetSantim > 0;
  bool get hasExpenses => monthExpenses.isNotEmpty;
  bool get hasDebts => activeDebts.isNotEmpty;
}
