import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:birrmetrics/core/theme/app_colors.dart';
import 'package:birrmetrics/core/theme/app_spacing.dart';
import 'package:birrmetrics/core/utils/money_formatter.dart';
import 'package:birrmetrics/features/budget/presentation/providers/budget_provider.dart';
import 'package:birrmetrics/features/budget/presentation/screens/set_budget_sheet.dart';
import 'package:birrmetrics/features/expenses/presentation/providers/expense_providers.dart';

class BudgetProgressCard extends ConsumerWidget {
  const BudgetProgressCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetAsync = ref.watch(budgetProvider);
    final expensesState = ref.watch(expensesProvider);

    return budgetAsync.when(
      loading: () => const _BudgetCardLoading(),
      error: (_, __) => const SizedBox.shrink(),
      data: (budget) {
        // Use expensesState.total (not totalSpentProvider)
        final spent = expensesState.total.maybeWhen(
          data: (s) => s,
          orElse: () => 0,
        );

        if (budget == null || budget.amountSantim == 0) {
          return _NoBudgetCard(onTap: () => _openSetBudgetSheet(context, null));
        }

        final total = budget.amountSantim;
        final remaining = (total - spent).clamp(0, total).toInt();
        final percentUsed = (spent / total).clamp(0.0, 1.5);
        final isOver = spent > total;

        return _BudgetProgress(
          total: total,
          spent: spent,
          remaining: remaining,
          percentUsed: percentUsed,
          isOver: isOver,
          onEdit: () => _openSetBudgetSheet(context, total),
        );
      },
    );
  }

  void _openSetBudgetSheet(BuildContext context, int? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => SetBudgetSheet(existingAmountSantim: existing),
    );
  }
}

class _NoBudgetCard extends StatelessWidget {
  final VoidCallback onTap;

  const _NoBudgetCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.savings_outlined,
                    color: AppColors.accent, size: 24),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Set a monthly budget',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      'Track your spending against a goal',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  size: 16, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _BudgetProgress extends StatelessWidget {
  final int total;
  final int spent;
  final int remaining;
  final double percentUsed;
  final bool isOver;
  final VoidCallback onEdit;

  const _BudgetProgress({
    required this.total,
    required this.spent,
    required this.remaining,
    required this.percentUsed,
    required this.isOver,
    required this.onEdit,
  });

  Color get _progressColor {
    if (isOver) return AppColors.danger;
    if (percentUsed >= 0.8) return AppColors.warning;
    return AppColors.accent;
  }

  String get _statusText {
    if (isOver) return 'Over budget';
    if (percentUsed >= 0.8) return 'Close to limit';
    return 'On track';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.savings_outlined,
                          size: 18, color: _progressColor),
                      const SizedBox(width: 6),
                      Text('Monthly Budget',
                          style: Theme.of(context).textTheme.bodyLarge),
                    ],
                  ),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _progressColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _statusText,
                      style: TextStyle(
                        color: _progressColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: MoneyFormatter.formatSantim(
                          isOver ? spent - total : remaining),
                      style:
                      Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _progressColor,
                      ),
                    ),
                    TextSpan(
                      text: isOver ? '  over' : '  left',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${MoneyFormatter.formatSantim(spent)} of ${MoneyFormatter.formatSantim(total)} spent',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: AppSpacing.md),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentUsed.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(_progressColor),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(percentUsed * 100).toStringAsFixed(0)}% used',
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: AppColors.textMuted),
                  ),
                  Text(
                    'Tap to edit',
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BudgetCardLoading extends StatelessWidget {
  const _BudgetCardLoading();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}
