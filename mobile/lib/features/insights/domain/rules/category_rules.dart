import 'package:birrmetrics/core/utils/money_formatter.dart';
import 'package:birrmetrics/features/insights/domain/entities/insight.dart';
import 'package:birrmetrics/features/insights/domain/rules/insight_context.dart';
import 'package:birrmetrics/features/insights/domain/rules/insight_rule.dart';

class TopCategoryRule extends InsightRule {
  @override
  String get key => 'TOP_CATEGORY_OVER_40';

  @override
  String get dedupeWindow => 'once_per_week';

  @override
  String getDataSignature(InsightContext context) {
    return '${context.totalSpentThisMonth}-${context.spendByCategory.values.fold(0, (a, b) => a + b)}';
  }

  @override
  List<Insight> evaluate(InsightContext context) {
    // NEW: Require at least 3 active days
    if (!context.hasEnoughData(minDays: 3)) return [];
    if (context.totalSpentThisMonth == 0) return [];

    final top = context.spendByCategory.entries.reduce(
          (a, b) => a.value > b.value ? a : b,
    );
    final pct = (top.value / context.totalSpentThisMonth) * 100;
    if (pct < 40) return [];
    final catName = context.categoryNames[top.key] ?? 'Unknown';
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

class CategorySpikeRule extends InsightRule {
  @override
  String get key => 'CATEGORY_SPIKE';

  @override
  String get dedupeWindow => 'once_per_week';

  @override
  String getDataSignature(InsightContext context) => '';

  @override
  List<Insight> evaluate(InsightContext context) {
    // Requires actual last month data
    if (context.lastMonthExpenses.isEmpty) return [];
    final lastWeekByCat = <int, int>{};
    for (final e in context.last7DaysExpenses) {
      lastWeekByCat[e.categoryId] = (lastWeekByCat[e.categoryId] ?? 0) + e.amountSantim;
    }
    final lastMonthByCat = <int, int>{};
    for (final e in context.lastMonthExpenses) {
      lastMonthByCat[e.categoryId] = (lastMonthByCat[e.categoryId] ?? 0) + e.amountSantim;
    }

    for (final entry in lastWeekByCat.entries) {
      final monthAvg = (lastMonthByCat[entry.key] ?? 0) / 4;
      if (monthAvg > 0 && entry.value > monthAvg * 2) {
        final catName = context.categoryNames[entry.key] ?? 'Unknown';
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

class NewCategoryRule extends InsightRule {
  @override
  String get key => 'NEW_CATEGORY_USED';

  @override
  String get dedupeWindow => 'once_per_day';

  @override
  String getDataSignature(InsightContext context) => '';

  @override
  List<Insight> evaluate(InsightContext context) {
    if (context.monthExpenses.length != 1) return [];
    final catName = context.categoryNames[context.monthExpenses.first.categoryId] ?? 'Unknown';
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

class HeavyUncategorizedRule extends InsightRule {
  @override
  String get key => 'UNCATEGORIZED_HEAVY';

  @override
  String get dedupeWindow => 'once_per_week';

  @override
  String getDataSignature(InsightContext context) => '';

  @override
  List<Insight> evaluate(InsightContext context) {
    if (context.totalSpentThisMonth == 0) return [];
    int? otherId;
    for (final entry in context.categoryNames.entries) {
      if (entry.value.toLowerCase() == 'other') {
        otherId = entry.key;
        break;
      }
    }
    if (otherId == null) return [];
    final otherSpend = context.spendByCategory[otherId] ?? 0;
    final pct = (otherSpend / context.totalSpentThisMonth) * 100;
    if (pct < 25) return [];
    return [
      Insight(
        ruleKey: key,
        severity: InsightSeverity.info,
        title: 'Lots of "Other" expenses',
        message: '${pct.toStringAsFixed(0)}% of your spending is in "Other" '
            '(${MoneyFormatter.formatSantim(otherSpend)}). Try creating more specific categories.',
        triggeredAt: DateTime.now(),
      ),
    ];
  }
}
