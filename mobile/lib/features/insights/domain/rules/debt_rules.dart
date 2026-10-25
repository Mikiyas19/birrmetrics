import 'package:birrmetrics/core/utils/money_formatter.dart';
import 'package:birrmetrics/features/insights/domain/entities/insight.dart';
import 'package:birrmetrics/features/insights/domain/rules/insight_context.dart';
import 'package:birrmetrics/features/insights/domain/rules/insight_rule.dart';

/// Fires when any active debt is overdue.
class DebtOverdueRule extends InsightRule {
  @override
  String get key => 'DEBT_OVERDUE';

  @override
  String get dedupeWindow => 'once_per_day';

  @override
  List<Insight> evaluate(InsightContext ctx) {
    final overdue = ctx.activeDebts
        .where((d) => d.dueDate != null && d.dueDate!.isBefore(ctx.now))
        .toList();
    if (overdue.isEmpty) return [];
    final total = overdue.fold<int>(0, (s, d) => s + d.remainingSantim);
    return [
      Insight(
        ruleKey: key,
        severity: InsightSeverity.critical,
        title: '${overdue.length} overdue debt${overdue.length > 1 ? 's' : ''}',
        message: 'You have ${MoneyFormatter.formatSantim(total)} in overdue debts. '
            'Consider following up with ${overdue.first.counterparty}.',
        triggeredAt: DateTime.now(),
      ),
    ];
  }
}

/// Fires when a debt is due within 3 days.
class DebtDueSoonRule extends InsightRule {
  @override
  String get key => 'DEBT_DUE_SOON';

  @override
  String get dedupeWindow => 'once_per_day';

  @override
  List<Insight> evaluate(InsightContext ctx) {
    final threeDaysFromNow = ctx.now.add(const Duration(days: 3));
    final dueSoon = ctx.activeDebts
        .where((d) =>
    d.dueDate != null &&
        d.dueDate!.isAfter(ctx.now) &&
        d.dueDate!.isBefore(threeDaysFromNow))
        .toList();
    if (dueSoon.isEmpty) return [];
    return [
      Insight(
        ruleKey: key,
        severity: InsightSeverity.warning,
        title: 'Debt due soon',
        message: '${dueSoon.first.counterparty} is due on '
            '${_formatDate(dueSoon.first.dueDate!)}. Amount: ${MoneyFormatter.formatSantim(dueSoon.first.remainingSantim)}.',
        triggeredAt: DateTime.now(),
      ),
    ];
  }
}

/// Fires when net debt balance is significantly negative.
class NetDebtHighRule extends InsightRule {
  @override
  String get key => 'DEBT_BALANCE_HIGH';

  @override
  String get dedupeWindow => 'once_per_week';

  @override
  List<Insight> evaluate(InsightContext ctx) {
    int owedToMe = 0;
    int iOwe = 0;
    for (final d in ctx.activeDebts) {
      if (d.isLent) {
        owedToMe += d.remainingSantim;
      } else {
        iOwe += d.remainingSantim;
      }
    }
    if (iOwe <= owedToMe) return [];
    final net = iOwe - owedToMe;
    return [
      Insight(
        ruleKey: key,
        severity: InsightSeverity.warning,
        title: 'You owe more than you\'re owed',
        message: 'Your net debt is ${MoneyFormatter.formatSantim(net)} — you owe more than you\'re owed. '
            'Prioritize settling outstanding balances.',
        triggeredAt: DateTime.now(),
      ),
    ];
  }
}

/// Fires when there are many pending debts (> 5).
class ManyPendingDebtsRule extends InsightRule {
  @override
  String get key => 'MANY_PENDING_DEBTS';

  @override
  String get dedupeWindow => 'once_per_week';

  @override
  List<Insight> evaluate(InsightContext ctx) {
    if (ctx.activeDebts.length <= 5) return [];
    return [
      Insight(
        ruleKey: key,
        severity: InsightSeverity.info,
        title: 'Lots of open debts',
        message: 'You have ${ctx.activeDebts.length} open debts. Consider settling some to simplify your finances.',
        triggeredAt: DateTime.now(),
      ),
    ];
  }
}

/// Fires when a large debt has no due date.
class DebtNoDueDateRule extends InsightRule {
  @override
  String get key => 'DEBT_NO_DUE_DATE';

  @override
  String get dedupeWindow => 'once_per_week';

  @override
  List<Insight> evaluate(InsightContext ctx) {
    final large = ctx.activeDebts
        .where((d) => d.dueDate == null && d.remainingSantim >= 10000)
        .toList(); // 100 ETB+
    if (large.isEmpty) return [];
    return [
      Insight(
        ruleKey: key,
        severity: InsightSeverity.info,
        title: 'Add a due date',
        message: 'The debt with ${large.first.counterparty} has no due date. '
            'Adding one helps you stay on top of repayments.',
        triggeredAt: DateTime.now(),
      ),
    ];
  }
}

String _formatDate(DateTime d) {
  final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  return '${months[d.month - 1]} ${d.day}, ${d.year}';
}
