import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:birrmetrics/core/utils/money_formatter.dart';
import 'package:birrmetrics/features/expenses/domain/entities/expense.dart';

class RecentExpensesList extends StatelessWidget {
  final List<Expense> expenses;
  final bool shrinkWrap;

  const RecentExpensesList({
    super.key,
    required this.expenses,
    this.shrinkWrap = false,
  });

  // FIXED: Converted to a method declaration
  Widget _buildItem(BuildContext context, int index) {
    final exp = expenses[index];
    final dateStr = DateFormat('MMM d').format(exp.expenseDate);
    final icon = exp.categoryIcon ?? '🏷️';
    final catName = exp.categoryName ?? 'Other';

    final titleText = (exp.description != null && exp.description!.isNotEmpty)
        ? exp.description!
        : catName;

    final subtitleText = (exp.description != null && exp.description!.isNotEmpty)
        ? '$dateStr • $catName'
        : dateStr;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Text(icon, style: const TextStyle(fontSize: 20)),
      ),
      title: Text(
        titleText,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(subtitleText),
      trailing: Text(
        MoneyFormatter.formatSantim(exp.amountSantim),
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: Text('No expenses yet. Tap + to add one.')),
      );
    }

    if (shrinkWrap) {
      return Column(
        children: List.generate(expenses.length, (index) => _buildItem(context, index)),
      );
    }

    return ListView.separated(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      itemCount: expenses.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: _buildItem,
    );
  }
}
