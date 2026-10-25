import 'package:birrmetrics/core/utils/money_formatter.dart';
import 'package:birrmetrics/features/insights/domain/entities/insight.dart';
import 'package:birrmetrics/features/insights/domain/rules/insight_context.dart';
import 'package:birrmetrics/features/insights/domain/rules/insight_rule.dart';

/// Fires when a single category dominates spending (>40%).
class TopCategoryRule extends InsightRule {
  @override
  String get key => 'TOP_CATEGORY_OVER_40';

  @override
  List<Insight> evaluate(InsightContext ctx) {
    if (ctx.totalSpentThisMonth == 0) return [];
    final top = ctx.spendByCategory.entries.reduce(
          (a, b) => a.value > b.value ? a : b,
    );
    final pct = (top.value / ctx.totalSpentThisMonth) * 100;
    if (pct < 40) return [];
    final catName = ctx.categoryNames[top.key] ?? 'Unknown';
    return [
      Insight(
        ruleKey: key,
        severity: InsightSeverity.warning,
        title: '$catName is your biggest expense',
        message: '$catName takes up ${pct.toStringAsFixed(0)}% of your spending '
            '(${MoneyFormatter.formatSantim(top.value)}). Consider reducing it.',
        triggeredAt: DateTime.now(),
      ),
    ];
  }
}

/// Fires when a category has a spike this week vs. 4-week average.
class CategorySpikeRule extends InsightRule {
  @override
  String get key => 'CATEGORY_SPIKE';

  @override
  String get dedupeWindow => 'once_per_week';

  @override
  List<Insight> evaluate(InsightContext ctx) {
    if (ctx.lastMonthExpenses.isEmpty) return [];
    // Compute last week's spend per category
    final lastWeekByCat = <int, int>{};
    for (final e in ctx.last7DaysExpenses) {
      lastWeekByCat[e.categoryId] = (lastWeekByCat[e.categoryId] ?? 0) + e.amountSantim;
    }
    // Compute 4-week average per category from last month
    final lastMonthByCat = <int, int>{};
    for (final e in ctx.lastMonthExpenses) {
      lastMonthByCat[e.categoryId] = (lastMonthByCat[e.categoryId] ?? 0) + e.amountSantim;
    }

    for (final entry in lastWeekByCat.entries) {
      final monthAvg = (lastMonthByCat[entry.key] ?? 0) / 4;
      if (monthAvg > 0 && entry.value > monthAvg * 2) {
        final catName = ctx.categoryNames[entry.key] ?? 'Unknown';
        return [
          Insight(
            ruleKey: key,
            severity: InsightSeverity.warning,
            title: 'Unusual $catName spending',
            message: 'You spent ${MoneyFormatter.formatSantim(entry.value)} on $catName this week — '
                'more than double your usual ${MoneyFormatter.formatSantim(monthAvg.round())}.',
            triggeredAt: DateTime.now(),
          ),
        ];
      }
    }
    return [];
  }
}

/// Fires when user has never logged a category they just used.
class NewCategoryRule extends InsightRule {
  @override
  String get key => 'NEW_CATEGORY_USED';

  @override
  String get dedupeWindow => 'once_per_day';

  @override
  List<Insight> evaluate(InsightContext ctx) {
    // Only fire if this month has exactly ONE expense (first-ever in a new category)
    if (ctx.monthExpenses.length != 1) return [];
    final catName = ctx.categoryNames[ctx.monthExpenses.first.categoryId] ?? 'Unknown';
    return [
      Insight(
        ruleKey: key,
        severity: InsightSeverity.info,
        title: 'First $catName expense',
        message: 'You just logged your first $catName expense. Categories help you see where money goes.',
        triggeredAt: DateTime.now(),
      ),
    ];
  }
}

/// Fires when "Other" category is heavy (>25% of spend).
class HeavyUncategorizedRule extends InsightRule {
  @override
  String get key => 'UNCATEGORIZED_HEAVY';

  @override
  String get dedupeWindow => 'once_per_week';

  @override
  List<Insight> evaluate(InsightContext ctx) {
    if (ctx.totalSpentThisMonth == 0) return [];
    // Find "Other" category id
    int? otherId;
    for (final entry in ctx.categoryNames.entries) {
      if (entry.value.toLowerCase() == 'other') {
        otherId = entry.key;
        break;
      }
    }
    if (otherId == null) return [];
    final otherSpend = ctx.spendByCategory[otherId] ?? 0;
    final pct = (otherSpend / ctx.totalSpentThisMonth) * 100;
    if (pct < 25) return [];
    return [
      Insight(
        ruleKey: key,
        severity: InsightSeverity.info,
        title: 'Lots of "Other" expenses',
        message: '${pct.toStringAsFixed(0)}% of your spending is in "Other" '
            '(${MoneyFormatter.formatSantim(otherSpend)}). Try creating more specific categories for better insights.',
        triggeredAt: DateTime.now(),
      ),
    ];
  }
}
