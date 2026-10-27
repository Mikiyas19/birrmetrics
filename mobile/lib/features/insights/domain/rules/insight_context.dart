import 'package:birrmetrics/features/expenses/domain/entities/expense.dart';
import 'package:birrmetrics/features/debts/domain/entities/debt.dart';

class InsightContext {
  final DateTime now;
  final List<Expense> monthExpenses;
  final List<Expense> last7DaysExpenses;
  final List<Expense> lastMonthExpenses;
  final List<Debt> activeDebts;
  final int monthlyBudgetSantim;
  final Map<int, int> spendByCategory;
  final Map<int, String> categoryNames;
  final int totalSpentThisMonth;
  final int daysElapsed;
  final int daysInMonth;

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

  double get budgetUsedPercent {
    if (monthlyBudgetSantim <= 0) return 0;
    return (totalSpentThisMonth / monthlyBudgetSantim) * 100;
  }

  /// The number of days from the first expense of this month until today.
  int get activeDaysInMonth {
    if (monthExpenses.isEmpty) return 0;

    final firstExpenseDate = monthExpenses
        .map((e) => e.expenseDate)
        .reduce((a, b) => a.isBefore(b) ? a : b);

    final diff = now.difference(firstExpenseDate).inDays + 1;
    return diff > 0 ? diff : 1;
  }

  bool hasEnoughData({int minDays = 3, int minSpentSantim = 0}) {
    return activeDaysInMonth >= minDays && totalSpentThisMonth >= minSpentSantim;
  }

  /// Average spent per active day
  double get dailyAvgSpent {
    if (activeDaysInMonth == 0) return 0;
    return totalSpentThisMonth / activeDaysInMonth;
  }

  /// Predicts month-end spend based on active average
  int get projectedMonthlySpend {
    if (activeDaysInMonth == 0) return 0;
    return (dailyAvgSpent * daysInMonth).round();
  }

  bool get hasBudget => monthlyBudgetSantim > 0;
  bool get hasExpenses => monthExpenses.isNotEmpty;
  bool get hasDebts => activeDebts.isNotEmpty;
}
