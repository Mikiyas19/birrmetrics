import 'package:birrmetrics/core/utils/money_formatter.dart';
import 'package:birrmetrics/features/insights/domain/entities/insight.dart';
import 'package:birrmetrics/features/insights/domain/rules/insight_context.dart';
import 'package:birrmetrics/features/insights/domain/rules/insight_rule.dart';

/// Fires when user has expenses but no budget set.
class BudgetNotSetRule extends InsightRule {
  @override
  String get key => 'BUDGET_NOT_SET';

  @override
  String get dedupeWindow => 'once_per_week';

  @override
  List<Insight> evaluate(InsightContext ctx) {
    if (ctx.hasBudget || !ctx.hasExpenses) return [];
    return [
      Insight(
        ruleKey: key,
        severity: InsightSeverity.info,
        title: 'Set a monthly budget',
        message: 'You\'ve spent ${MoneyFormatter.formatSantim(ctx.totalSpentThisMonth)} this month '
            'but haven\'t set a budget. Setting one helps you stay on track.',
        triggeredAt: DateTime.now(),
      ),
    ];
  }
}

/// Fires once when budget crosses 50%.
class Budget50PctRule extends InsightRule {
  @override
  String get key => 'BUDGET_50_PCT';

  @override
  String get dedupeWindow => 'once_per_month';

  @override
  List<Insight> evaluate(InsightContext ctx) {
    if (!ctx.hasBudget) return [];
    final pct = ctx.budgetUsedPercent;
    if (pct < 50 || pct >= 80) return [];
    return [
      Insight(
        ruleKey: key,
        severity: InsightSeverity.info,
        title: 'Halfway through your budget',
        message: 'You\'ve used ${pct.toStringAsFixed(0)}% of your monthly budget. '
            'You have ${MoneyFormatter.formatSantim(ctx.monthlyBudgetSantim - ctx.totalSpentThisMonth)} left.',
        triggeredAt: DateTime.now(),
      ),
    ];
  }
}

/// Fires once when budget crosses 80%.
class Budget80PctRule extends InsightRule {
  @override
  String get key => 'BUDGET_80_PCT';

  @override
  String get dedupeWindow => 'once_per_day';

  @override
  List<Insight> evaluate(InsightContext ctx) {
    if (!ctx.hasBudget) return [];
    final pct = ctx.budgetUsedPercent;
    if (pct < 80 || pct >= 100) return [];
    return [
      Insight(
        ruleKey: key,
        severity: InsightSeverity.warning,
        title: 'Careful — 80% of budget used',
        message: 'You\'ve used ${pct.toStringAsFixed(0)}% of your monthly budget. '
            'Only ${MoneyFormatter.formatSantim(ctx.monthlyBudgetSantim - ctx.totalSpentThisMonth)} left for ${ctx.daysInMonth - ctx.daysElapsed} days.',
        triggeredAt: DateTime.now(),
      ),
    ];
  }
}

/// Fires when budget is exceeded.
class BudgetExceededRule extends InsightRule {
  @override
  String get key => 'BUDGET_100_PCT';

  @override
  String get dedupeWindow => 'once_per_day';

  @override
  List<Insight> evaluate(InsightContext ctx) {
    if (!ctx.hasBudget) return [];
    final pct = ctx.budgetUsedPercent;
    if (pct < 100) return [];
    final overBy = ctx.totalSpentThisMonth - ctx.monthlyBudgetSantim;
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

/// Predicts end-of-month spending pace.
class BudgetProjectionRule extends InsightRule {
  @override
  String get key => 'BUDGET_PROJECTED_OVERRUN';

  @override
  String get dedupeWindow => 'once_per_week';

  @override
  List<Insight> evaluate(InsightContext ctx) {
    if (!ctx.hasBudget || ctx.daysElapsed < 5) return [];
    final projected = ctx.projectedMonthlySpend;
    if (projected <= ctx.monthlyBudgetSantim) return [];
    final overBy = projected - ctx.monthlyBudgetSantim;
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

/// Positive reinforcement when on track.
class BudgetOnTrackRule extends InsightRule {
  @override
  String get key => 'BUDGET_ON_TRACK';

  @override
  String get dedupeWindow => 'once_per_week';

  @override
  List<Insight> evaluate(InsightContext ctx) {
    if (!ctx.hasBudget || ctx.daysElapsed < 10 || ctx.hasExpenses == false) return [];
    final projected = ctx.projectedMonthlySpend;
    if (projected >= ctx.monthlyBudgetSantim) return [];
    final saving = ctx.monthlyBudgetSantim - projected;
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
