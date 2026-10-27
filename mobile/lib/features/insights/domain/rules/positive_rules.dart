import 'package:birrmetrics/core/utils/money_formatter.dart';
import 'package:birrmetrics/features/insights/domain/entities/insight.dart';
import 'package:birrmetrics/features/insights/domain/rules/insight_context.dart';
import 'package:birrmetrics/features/insights/domain/rules/insight_rule.dart';

class FirstExpenseRule extends InsightRule {
  @override
  String get key => 'FIRST_EXPENSE';

  @override
  String get dedupeWindow => 'always';

  @override
  Duration? get expiresIn => const Duration(days: 1);

  @override
  String getDataSignature(InsightContext context) => '';

  @override
  List<Insight> evaluate(InsightContext context) {
    if (context.monthExpenses.length != 1) return [];
    return [
      Insight(
        ruleKey: key,
        severity: InsightSeverity.info,
        title: 'Welcome to BirrMetrics! 👋',
        message: 'You just logged your first expense. Track consistently and insights will appear here.',
        triggeredAt: DateTime.now(),
      ),
    ];
  }
}

class SpendStreakRule extends InsightRule {
  @override
  String get key => 'SPEND_STREAK';

  @override
  String get dedupeWindow => 'once_per_week';

  @override
  String getDataSignature(InsightContext context) => '';

  @override
  List<Insight> evaluate(InsightContext context) {
    if (context.monthExpenses.isEmpty) return [];
    final daysWithSpend = <DateTime>{};
    for (final e in context.monthExpenses) {
      daysWithSpend.add(DateTime(e.expenseDate.year, e.expenseDate.month, e.expenseDate.day));
    }
    int streak = 0;
    for (int i = 0; i < 30; i++) {
      final d = DateTime(context.now.year, context.now.month, context.now.day)
          .subtract(Duration(days: i));
      if (daysWithSpend.contains(d)) break;
      streak++;
    }
    if (streak < 3) return [];
    return [
      Insight(
        ruleKey: key,
        severity: InsightSeverity.info,
        title: '$streak-day no-spend streak 🔥',
        message: 'You haven\'t logged any expenses for $streak days. Keep the streak going!',
        triggeredAt: DateTime.now(),
      ),
    ];
  }
}

class SavingsOpportunityRule extends InsightRule {
  @override
  String get key => 'SAVINGS_OPPORTUNITY';

  @override
  String get dedupeWindow => 'once_per_month';

  @override
  Duration? get expiresIn => const Duration(days: 7);

  // Signature includes total spent so it re-fires when spending grows
  @override
  String getDataSignature(InsightContext context) {
    return '${context.totalSpentThisMonth}';
  }

  @override
  List<Insight> evaluate(InsightContext context) {
    // NEW: Require at least 7 active days AND at least 500 ETB spent
    if (!context.hasEnoughData(minDays: 7, minSpentSantim: 50000)) return [];
    if (context.spendByCategory.isEmpty) return [];

    final top = context.spendByCategory.entries.reduce(
          (a, b) => a.value > b.value ? a : b,
    );
    final savings = (top.value * 0.2).round();
    if (savings < 5000) return []; // at least 50 ETB savings
    final catName = context.categoryNames[top.key] ?? 'Unknown';
    return [
      Insight(
        ruleKey: key,
        severity: InsightSeverity.info,
        title: 'Savings opportunity',
        message: 'If you cut $catName spending by 20%, you\'d save ${MoneyFormatter.formatSantim(savings)} this month.',
        triggeredAt: DateTime.now(),
      ),
    ];
  }
}
