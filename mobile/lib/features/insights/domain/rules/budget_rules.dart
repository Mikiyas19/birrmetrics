import 'package:birrmetrics/core/utils/money_formatter.dart';
import 'package:birrmetrics/features/insights/domain/entities/insight.dart';
import 'package:birrmetrics/features/insights/domain/rules/insight_context.dart';
import 'package:birrmetrics/features/insights/domain/rules/insight_rule.dart';

class BudgetNotSetRule extends InsightRule {
  @override
  String get key => 'BUDGET_NOT_SET';

  @override
  String get dedupeWindow => 'once_per_week';

  @override
  String getDataSignature(InsightContext context) => '';

  @override
  List<Insight> evaluate(InsightContext context) {
    if (context.hasBudget || !context.hasExpenses) return [];
    return [
      Insight(
        ruleKey: key,
        severity: InsightSeverity.info,
        title: 'Set a monthly budget',
        message: 'You\'ve spent ${MoneyFormatter.formatSantim(context.totalSpentThisMonth)} this month '
            'but haven\'t set a budget. Setting one helps you stay on track.',
        triggeredAt: DateTime.now(),
      ),
    ];
  }
}

class Budget50PctRule extends InsightRule {
  @override
  String get key => 'BUDGET_50_PCT';

  @override
  String get dedupeWindow => 'once_per_month';

  @override
  String getDataSignature(InsightContext context) => '';

  @override
  List<Insight> evaluate(InsightContext context) {
    if (!context.hasBudget) return [];
    final pct = context.budgetUsedPercent;
    if (pct < 50 || pct >= 80) return [];
    return [
      Insight(
        ruleKey: key,
        severity: InsightSeverity.info,
        title: 'Halfway through your budget',
        message: 'You\'ve used ${pct.toStringAsFixed(0)}% of your monthly budget. '
            'You have ${MoneyFormatter.formatSantim(context.monthlyBudgetSantim - context.totalSpentThisMonth)} left.',
        triggeredAt: DateTime.now(),
      ),
    ];
  }
}

class Budget80PctRule extends InsightRule {
  @override
  String get key => 'BUDGET_80_PCT';

  @override
  String get dedupeWindow => 'once_per_day';

  @override
  String getDataSignature(InsightContext context) => '';

  @override
  List<Insight> evaluate(InsightContext context) {
    if (!context.hasBudget) return [];
    final pct = context.budgetUsedPercent;
    if (pct < 80 || pct >= 100) return [];
    return [
      Insight(
        ruleKey: key,
        severity: InsightSeverity.warning,
        title: 'Careful — 80% of budget used',
        message: 'You\'ve used ${pct.toStringAsFixed(0)}% of your monthly budget. '
            'Only ${MoneyFormatter.formatSantim(context.monthlyBudgetSantim - context.totalSpentThisMonth)} left for ${context.daysInMonth - context.daysElapsed} days.',
        triggeredAt: DateTime.now(),
      ),
    ];
  }
}

class BudgetExceededRule extends InsightRule {
  @override
  String get key => 'BUDGET_100_PCT';

  @override
  String get dedupeWindow => 'once_per_day';

  @override
  String getDataSignature(InsightContext context) => '';

  @override
  List<Insight> evaluate(InsightContext context) {
    if (!context.hasBudget) return [];
    final pct = context.budgetUsedPercent;
    if (pct < 100) return [];
    final overBy = context.totalSpentThisMonth - context.monthlyBudgetSantim;
    return [
      Insight(
        ruleKey: key,
        severity: InsightSeverity.critical,
        title: 'Budget exceeded',
        message: 'You\'ve gone ${MoneyFormatter.formatSantim(overBy)} over your monthly budget. '
            'Consider pausing non-essential spending.',
        triggeredAt: DateTime.now(),
      ),
    ];
  }
}

class BudgetProjectionRule extends InsightRule {
  @override
  String get key => 'BUDGET_PROJECTED_OVERRUN';

  @override
  String get dedupeWindow => 'once_per_week';

  @override
  String getDataSignature(InsightContext context) {
    return '${context.projectedMonthlySpend}';
  }

  @override
  List<Insight> evaluate(InsightContext context) {
    // Do not predict if there are not enough active days
    if (!context.hasBudget || context.activeDaysInMonth < 5) return [];

    final projected = context.projectedMonthlySpend;
    if (projected <= context.monthlyBudgetSantim) return [];

    final overBy = projected - context.monthlyBudgetSantim;
    return [
      Insight(
        ruleKey: key,
        severity: InsightSeverity.warning,
        title: 'On track to overspend',
        message: 'At your current pace, you\'ll spend ${MoneyFormatter.formatSantim(projected)} '
            'this month — ${MoneyFormatter.formatSantim(overBy)} over budget.',
        triggeredAt: DateTime.now(),
      ),
    ];
  }
}

class BudgetOnTrackRule extends InsightRule {
  @override
  String get key => 'BUDGET_ON_TRACK';

  @override
  String get dedupeWindow => 'once_per_week';

  @override
  String getDataSignature(InsightContext context) => '';

  @override
  List<Insight> evaluate(InsightContext context) {
    // Require at least 5 active days to judge if the user is on track
    if (!context.hasBudget || context.activeDaysInMonth < 5) return [];
    final projected = context.projectedMonthlySpend;
    if (projected >= context.monthlyBudgetSantim) return [];
    final saving = context.monthlyBudgetSantim - projected;
    return [
      Insight(
        ruleKey: key,
        severity: InsightSeverity.info,
        title: 'On track 🎉',
        message: 'You\'re projected to end the month with ${MoneyFormatter.formatSantim(saving)} under budget. Keep it up!',
        triggeredAt: DateTime.now(),
      ),
    ];
  }
}
