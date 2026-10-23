import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:birrmetrics/core/theme/app_colors.dart';
import 'package:birrmetrics/core/theme/app_spacing.dart';
import 'package:birrmetrics/core/utils/money_formatter.dart';
import 'package:birrmetrics/features/debts/domain/entities/debt.dart';
import 'package:birrmetrics/features/debts/presentation/providers/debt_providers.dart';
import 'package:birrmetrics/features/debts/presentation/screens/add_debt_sheet.dart';

class DebtsScreen extends ConsumerStatefulWidget {
  const DebtsScreen({super.key});

  @override
  ConsumerState<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends ConsumerState<DebtsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openAddDebtSheet() async {
    final Debt? newDebt = await showModalBottomSheet<Debt>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AddDebtSheet(),
    );

    if (newDebt != null) {
      await ref.read(debtsProvider.notifier).addDebt(newDebt);
    }
  }

  Future<void> _openEditDebtSheet(Debt debt) async {
    final Debt? updated = await showModalBottomSheet<Debt>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddDebtSheet(existingDebt: debt),
    );

    if (updated != null) {
      await ref.read(debtsProvider.notifier).updateDebt(updated);
    }
  }

  void _confirmDelete(BuildContext context, Debt debt) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Debt?'),
          content: Text('Are you sure you want to delete the debt with ${debt.counterparty}? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                await ref.read(debtsProvider.notifier).deleteDebt(debt.id!);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(debtsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debts'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Owed to Me'),
            Tab(text: 'I Owe'),
            Tab(text: 'Settled'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddDebtSheet,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        child: const Icon(Icons.add),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDebtList(state.lentDebts, isLent: true),
          _buildDebtList(state.borrowedDebts, isLent: false),
          _buildDebtList(state.settledDebts, isLent: true),
        ],
      ),
    );
  }

  Widget _buildDebtList(AsyncValue<List<Debt>> asyncDebts, {required bool isLent}) {
    return asyncDebts.when(
      data: (debts) {
        if (debts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isLent ? Icons.arrow_downward : Icons.arrow_upward,
                  size: 64,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  isLent ? 'Nobody owes you money yet.' : 'You don\'t owe anyone.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: debts.length,
          itemBuilder: (context, index) {
            final debt = debts[index];
            return _DebtCard(
              debt: debt,
              onEdit: () => _openEditDebtSheet(debt),
              onDelete: () => _confirmDelete(context, debt),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }
}

class _DebtCard extends ConsumerWidget {
  final Debt debt;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DebtCard({
    required this.debt,
    required this.onEdit,
    required this.onDelete,
  });

  void _showActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Debt'),
                onTap: () {
                  Navigator.pop(context);
                  onEdit();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: AppColors.danger),
                title: const Text('Delete Debt', style: TextStyle(color: AppColors.danger)),
                onTap: () {
                  Navigator.pop(context);
                  onDelete();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmSettle(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Settle Debt?'),
          content: Text(
            'This will mark the full remaining balance of '
                '${MoneyFormatter.formatSantim(debt.remainingSantim)} as paid today. '
                'The full amount will appear in the history.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                await ref.read(debtsProvider.notifier).settleDebt(debt.id!);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: const Text('Settle Now'),
            ),
          ],
        );
      },
    );
  }

  void _showRepayDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();

    // FIX: Normalize both dates to midnight to avoid time-component comparison bugs
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final createdDate = DateTime(debt.createdAt.year, debt.createdAt.month, debt.createdAt.day);

    // earliestDate cannot be after today (defensive)
    final earliestDate = createdDate.isAfter(todayDate) ? todayDate : createdDate;
    final latestDate = todayDate;

    DateTime selectedDate = todayDate.isBefore(earliestDate) ? earliestDate : todayDate;
    final maxRepayable = debt.remainingSantim;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
            builder: (context, setState) {
              final bool onlyOneDay = earliestDate.isAtSameMomentAs(latestDate);
              final String dateHint = onlyOneDay
                  ? 'Only ${DateFormat.yMMMd().format(earliestDate)} available'
                  : 'Between ${DateFormat.yMMMd().format(earliestDate)} and ${DateFormat.yMMMd().format(latestDate)}';

              return AlertDialog(
                title: Text('Repay to ${debt.counterparty}'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Remaining balance: ${MoneyFormatter.formatSantim(debt.remainingSantim)}'),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: controller,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Amount to repay',
                        prefixText: 'ETB ',
                        helperText: 'Max: ${MoneyFormatter.formatSantim(maxRepayable)}',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: earliestDate,
                          lastDate: latestDate,
                          helpText: 'Select repayment date',
                          fieldLabelText: 'Repayment Date',
                          fieldHintText: 'MM/DD/YYYY',
                          errorFormatText: 'Invalid date format',
                          errorInvalidText: 'Date must be between '
                              '${DateFormat.yMMMd().format(earliestDate)} and '
                              '${DateFormat.yMMMd().format(latestDate)}',
                        );
                        if (picked != null) {
                          setState(() => selectedDate = picked);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Date',
                          prefixIcon: const Icon(Icons.calendar_today),
                          helperText: dateHint,
                          suffixIcon: const Icon(Icons.arrow_drop_down),
                        ),
                        child: Text(
                          DateFormat.yMMMd().format(selectedDate),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () async {
                      final amount = double.tryParse(controller.text);
                      if (amount == null || amount <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a valid amount')),
                        );
                        return;
                      }
                      final amountSantim = MoneyFormatter.toSantim(amount);
                      if (amountSantim > maxRepayable) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(
                              'You can only repay up to ${MoneyFormatter.formatSantim(maxRepayable)}')),
                        );
                        return;
                      }
                      await ref.read(debtsProvider.notifier).partialRepay(
                        debt.id!,
                        amountSantim,
                        selectedDate,
                      );
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text('Repay'),
                  ),
                ],
              );
            }
        );
      },
    );
  }

  void _showHistoryDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('History with ${debt.counterparty}'),
          content: Consumer(
            builder: (consumerContext, consumerRef, child) {
              final historyAsync = consumerRef.watch(repaymentHistoryProvider(debt.id!));

              return SizedBox(
                width: double.maxFinite,
                height: 340,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryTile(
                            label: 'Total Debt',
                            value: MoneyFormatter.formatSantim(debt.amountSantim),
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Expanded(
                          child: _SummaryTile(
                            label: 'Remaining',
                            value: MoneyFormatter.formatSantim(debt.remainingSantim),
                            color: debt.remainingSantim == 0
                                ? AppColors.success
                                : AppColors.warning,
                            align: CrossAxisAlignment.center,
                          ),
                        ),
                        Expanded(
                          child: _SummaryTile(
                            label: 'Status',
                            value: debt.status.toUpperCase(),
                            color: debt.status == 'settled' ? AppColors.success : AppColors.warning,
                            align: CrossAxisAlignment.end,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Divider(),
                    const SizedBox(height: AppSpacing.sm),
                    Expanded(
                      child: historyAsync.when(
                        data: (repayments) {
                          if (repayments.isEmpty) {
                            return const Center(child: Text('No repayments recorded yet.'));
                          }
                          return ListView.builder(
                            itemCount: repayments.length,
                            itemBuilder: (context, index) {
                              final repayment = repayments[index];
                              return ListTile(
                                leading: const Icon(Icons.check_circle, color: AppColors.success),
                                title: Text(MoneyFormatter.formatSantim(repayment.amountSantim)),
                                subtitle: Text(DateFormat.yMMMd().format(repayment.repaymentDate)),
                              );
                            },
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (err, _) => Center(child: Text('Error: $err')),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                ref.invalidate(repaymentHistoryProvider(debt.id!));
              },
              child: const Text('Refresh'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPartial = debt.status == 'partial';
    final isSettled = debt.status == 'settled';
    final isOverdue = debt.dueDate != null && debt.dueDate!.isBefore(DateTime.now());
    final showActions = !isSettled;

    final displayAmount = isSettled ? debt.amountSantim : debt.remainingSantim;
    final displayColor = isSettled ? AppColors.textMuted : (debt.isLent ? AppColors.accent : AppColors.danger);

    final settledIcon = debt.isLent ? Icons.check_circle : Icons.check_circle_outline;
    final settledColor = debt.isLent ? AppColors.success : AppColors.info;
    final settledLabel = debt.isLent ? 'You were paid' : 'You paid';

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: () => _showHistoryDialog(context, ref),
        onLongPress: () => _showActionSheet(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: isSettled
                              ? settledColor.withValues(alpha: 0.2)
                              : (debt.isLent ? AppColors.accent.withValues(alpha: 0.2) : AppColors.danger.withValues(alpha: 0.2)),
                          child: Icon(
                            isSettled ? settledIcon : (debt.isLent ? Icons.arrow_downward : Icons.arrow_upward),
                            color: isSettled ? settledColor : (debt.isLent ? AppColors.accent : AppColors.danger),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                debt.counterparty,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  decoration: isSettled ? TextDecoration.lineThrough : null,
                                  color: isSettled ? AppColors.textMuted : null,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (debt.notes != null && debt.notes!.isNotEmpty)
                                Text(
                                  debt.notes!,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        MoneyFormatter.formatSantim(displayAmount),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: displayColor,
                          decoration: isSettled ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (isSettled)
                        Text(
                          settledLabel,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: settledColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  if (debt.dueDate != null && !isSettled) ...[
                    Icon(Icons.calendar_today, size: 14, color: isOverdue ? AppColors.danger : AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      'Due: ${DateFormat.yMMMd().format(debt.dueDate!)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isOverdue ? AppColors.danger : AppColors.textMuted,
                        fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const Spacer(),
                  ] else
                    const Spacer(),
                  if (isPartial)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Partial', style: TextStyle(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  if (isSettled)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: settledColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Settled', style: TextStyle(color: settledColor, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (showActions)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _showRepayDialog(context, ref),
                      icon: const Icon(Icons.payments_outlined, size: 18),
                      label: const Text('Repay'),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    SizedBox(
                      width: 100,
                      child: FilledButton.tonal(
                        onPressed: () => _confirmSettle(context, ref),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accent.withValues(alpha: 0.15),
                          foregroundColor: AppColors.accent,
                          minimumSize: const Size(0, 40),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        child: const Text('Settle'),
                      ),
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

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final CrossAxisAlignment align;

  const _SummaryTile({
    required this.label,
    required this.value,
    required this.color,
    this.align = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
