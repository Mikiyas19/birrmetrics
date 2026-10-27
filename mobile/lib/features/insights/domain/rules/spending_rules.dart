import 'package:birrmetrics/core/utils/money_formatter.dart';
import 'package:birrmetrics/features/insights/domain/entities/insight.dart';
import 'package:birrmetrics/features/insights/domain/rules/insight_context.dart';
import 'package:birrmetrics/features/insights/domain/rules/insight_rule.dart';

class DailySpikeRule extends InsightRule {
  @override
  String get key => 'DAILY_SPIKE';

  @override
  String get dedupeWindow => 'once_per_day';

  @override
  Duration? get expiresIn => const Duration(hours: 12);

  @override
  String getDataSignature(InsightContext context) {
    final today = DateTime(context.now.year, context.now.month, context.now.day);
    final todaySpend = context.monthExpenses
        .where((e) => DateTime(e.expenseDate.year, e.expenseDate.month, e.expenseDate.day) == today)
        .fold<int>(0, (s, e) => s + e.amountSantim);
    return '$todaySpend-${context.activeDaysInMonth}';
  }

  @override
  List<Insight> evaluate(InsightContext context) {
    // Require at least 3 active days of history
    if (context.activeDaysInMonth < 3) return [];

    final today = DateTime(context.now.year, context.now.month, context.now.day);
    final todaySpend = context.monthExpenses
        .where((e) => DateTime(e.expenseDate.year, e.expenseDate.month, e.expenseDate.day) == today)
        .fold<int>(0, (s, e) => s + e.amountSantim);
    if (todaySpend == 0) return [];

    // Get expenses before today to compute the historical average
    final previousExpenses = context.monthExpenses
        .where((e) => DateTime(e.expenseDate.year, e.expenseDate.month, e.expenseDate.day) != today)
        .toList();
    if (previousExpenses.isEmpty) return [];

    // Calculate active days before today
    final firstPreviousExpense = previousExpenses
        .map((e) => e.expenseDate)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final prevActiveDays = today.difference(firstPreviousExpense).inDays + 1;

    if (prevActiveDays < 2) return [];

    final prevTotal = previousExpenses.fold<int>(0, (s, e) => s + e.amountSantim);
    final avgBefore = prevTotal / prevActiveDays;

    if (avgBefore == 0 || todaySpend < avgBefore * 2) return [];

    return [
      Insight(
        ruleKey: key,
        severity: InsightSeverity.warning,
        title: 'Spending spike today',
        message: 'You\'ve spent ${MoneyFormatter.formatSantim(todaySpend)} today — '
            'more than double your recent average of ${MoneyFormatter.formatSantim(avgBefore.round())}/day.',
        triggeredAt: DateTime.now(),
      ),
    ];
  }
}

class LargestTransactionRule extends InsightRule {
  @override
  String get key => 'LARGEST_TRANSACTION';

  @override
  String get dedupeWindow => 'once_per_week';

  @override
  Duration? get expiresIn => const Duration(days: 7);

  @override
  String getDataSignature(InsightContext context) => '';

  @override
  List<Insight> evaluate(InsightContext context) {
    if (context.last7DaysExpenses.isEmpty) return [];
    final largest = context.last7DaysExpenses.reduce(
          (a, b) => a.amountSantim > b.amountSantim ? a : b,
    );
    final avg = context.last7DaysExpenses.fold<int>(0, (s, e) => s + e.amountSantim) /
        context.last7DaysExpenses.length;
    if (largest.amountSantim < avg * 3) return [];
    final desc = largest.description ?? 'transaction';
    return [
      Insight(
        ruleKey: key,
        severity: InsightSeverity.info,
        title: 'Largest expense this week',
        message: 'Your biggest expense was ${MoneyFormatter.formatSantim(largest.amountSantim)} on $desc. '
            'Review if it was expected.',
        triggeredAt: DateTime.now(),
      ),
    ];
  }
}

class MonthStartRule extends InsightRule {
  @override
  String get key => 'MONTH_START';

  @override
  String get dedupeWindow => 'once_per_month';

  @override
  Duration? get expiresIn => const Duration(days: 3);

  @override
  String getDataSignature(InsightContext context) => '';

  @override
  List<Insight> evaluate(InsightContext context) {
    if (context.daysElapsed > 1) return [];
    if (context.monthExpenses.isEmpty) return [];
    return [
      Insight(
        ruleKey: key,
        severity: InsightSeverity.info,
        title: 'New month started',
        message: 'A fresh month — a fresh start. Set a budget if you haven\'t yet, and stay mindful of your spending.',
        triggeredAt: DateTime.now(),
      ),
    ];
  }
}

class NoSpendRule extends InsightRule {
  @override
  String get key => 'NO_SPEND_DAY';

  @override
  String get dedupeWindow => 'once_per_day';

  @override
  Duration? get expiresIn => const Duration(hours: 24);

  @override
  String getDataSignature(InsightContext context) => '';

  @override
  List<Insight> evaluate(InsightContext context) {
    if (context.daysElapsed < 3) return [];
    final today = DateTime(context.now.year, context.now.month, context.now.day);
    final todaySpend = context.monthExpenses
        .where((e) => DateTime(e.expenseDate.year, e.expenseDate.month, e.expenseDate.day) == today)
        .fold<int>(0, (s, e) => s + e.amountSantim);
    if (todaySpend > 0) return [];
    return [
      Insight(
        ruleKey: key,
        severity: InsightSeverity.info,
        title: 'No spending today 🎉',
        message: 'You haven\'t logged any expenses today. Great discipline!',
        triggeredAt: DateTime.now(),
      ),
    ];
  }
}

class WeekendSpikeRule extends InsightRule {
  @override
  String get key => 'WEEKEND_SPIKE';

  @override
  String get dedupeWindow => 'once_per_week';

  @override
  Duration? get expiresIn => const Duration(days: 7);

  @override
  String getDataSignature(InsightContext context) => '';

  @override
  List<Insight> evaluate(InsightContext context) {
    if (context.last7DaysExpenses.length < 5) return [];

    int weekendSpend = 0;
    int weekdaySpend = 0;
    int weekendDays = 0;
    int weekdayDays = 0;

    for (final e in context.last7DaysExpenses) {
      final isWeekend = e.expenseDate.weekday == DateTime.saturday ||
          e.expenseDate.weekday == DateTime.sunday;
      if (isWeekend) {
        weekendSpend += e.amountSantim;
      } else {
        weekdaySpend += e.amountSantim;
      }
    }

    for (int i = 0; i < 7; i++) {
      final d = context.now.subtract(Duration(days: i));
      if (d.weekday == DateTime.saturday || d.weekday == DateTime.sunday) {
        weekendDays++;
      } else {
        weekdayDays++;
      }
    }

    if (weekendDays == 0 || weekdayDays == 0) return [];
    final weekendAvg = weekendSpend / weekendDays;
    final weekdayAvg = weekdaySpend / weekdayDays;

    if (weekdayAvg == 0 || weekendAvg < weekdayAvg * 1.5) return [];

    return [
      Insight(
        ruleKey: key,
        severity: InsightSeverity.info,
        title: 'Weekend spending is higher',
        message: 'You spend ${(weekendAvg / weekdayAvg).toStringAsFixed(1)}x more on weekends '
            '(${MoneyFormatter.formatSantim(weekendAvg.round())}/day vs ${MoneyFormatter.formatSantim(weekdayAvg.round())}/day).',
        triggeredAt: DateTime.now(),
      ),
    ];
  }
}
