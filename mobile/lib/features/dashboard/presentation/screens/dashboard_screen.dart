import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:birrmetrics/core/theme/app_spacing.dart';
import 'package:birrmetrics/core/theme/app_typography.dart';
import 'package:birrmetrics/core/utils/money_formatter.dart';
import 'package:birrmetrics/features/expenses/presentation/providers/expense_providers.dart';
import 'package:birrmetrics/features/expenses/presentation/screens/add_expense_sheet.dart';
import 'package:birrmetrics/features/dashboard/presentation/widgets/recent_expenses_list.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(expensesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => const AddExpenseSheet(),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Spent This Month', style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: AppSpacing.xs),
                    state.total.when(
                      data: (santim) => Text(MoneyFormatter.formatSantim(santim), style: AppTypography.money(context)),
                      loading: () => const SizedBox(height: 40, child: Center(child: CircularProgressIndicator())),
                      error: (err, _) => Text('Error: $err'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            Text('Recent Transactions', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),

            // FIX: Using the extracted widget here
            Expanded(
              child: state.list.when(
                data: (expenses) => RecentExpensesList(expenses: expenses),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Text('Error: $err'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
