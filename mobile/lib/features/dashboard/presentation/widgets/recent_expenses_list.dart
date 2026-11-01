import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:birrmetrics/core/theme/app_colors.dart';
import 'package:birrmetrics/core/utils/money_formatter.dart';
import 'package:birrmetrics/features/expenses/domain/entities/expense.dart';
import 'package:birrmetrics/features/expenses/presentation/providers/expense_providers.dart';
import 'package:birrmetrics/features/expenses/presentation/screens/add_expense_sheet.dart';

class RecentExpensesList extends ConsumerWidget {
  final List<Expense> expenses;
  final bool shrinkWrap;

  const RecentExpensesList({
    super.key,
    required this.expenses,
    this.shrinkWrap = false,
  });

  void _showActionSheet(BuildContext context, WidgetRef ref, Expense expense) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Expense'),
              onTap: () {
                Navigator.pop(sheetContext);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => AddExpenseSheet(existingExpense: expense),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.danger),
              title: const Text('Delete Expense', style: TextStyle(color: AppColors.danger)),
              onTap: () {
                Navigator.pop(sheetContext);
                _confirmDelete(context, ref, expense);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Expense expense) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Expense?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(expensesProvider.notifier).deleteExpense(expense.id!);
              Navigator.pop(dialogContext);
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, WidgetRef ref, int index) {
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
      onLongPress: () => _showActionSheet(context, ref, exp),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (expenses.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: Text('No expenses yet. Tap + to add one.')),
      );
    }

    if (shrinkWrap) {
      return Column(
        children: List.generate(
          expenses.length,
              (index) => _buildItem(context, ref, index),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      itemCount: expenses.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) => _buildItem(context, ref, index),
    );
  }
}
