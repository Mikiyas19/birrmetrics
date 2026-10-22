import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:birrmetrics/core/utils/money_formatter.dart';
import 'package:birrmetrics/features/expenses/domain/entities/expense.dart';

class RecentExpensesList extends StatelessWidget {
  final List<Expense> expenses;

  const RecentExpensesList({super.key, required this.expenses});

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) {
      return const Center(child: Text('No expenses yet. Tap + to add one.'));
    }

    return ListView.separated(
      itemCount: expenses.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final exp = expenses[index];
        final dateStr = DateFormat('MMM d').format(exp.expenseDate);
        final icon = exp.categoryIcon ?? '🏷️';
        final catName = exp.categoryName ?? 'Other';

        // FIX: Only show the description if it exists. Otherwise, show the Category Name.
        final titleText = (exp.description != null && exp.description!.isNotEmpty)
            ? exp.description!
            : catName;

        // FIX: Only show "Date • Category" if there is a description.
        // If no description, just show "Date".
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
      },
    );
  }
}
