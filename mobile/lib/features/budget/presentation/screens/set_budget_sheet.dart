import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:birrmetrics/core/theme/app_colors.dart';
import 'package:birrmetrics/core/theme/app_spacing.dart';
import 'package:birrmetrics/core/utils/money_formatter.dart';
import 'package:birrmetrics/features/budget/presentation/providers/budget_provider.dart';

class SetBudgetSheet extends ConsumerStatefulWidget {
  final int? existingAmountSantim;

  const SetBudgetSheet({super.key, this.existingAmountSantim});

  @override
  ConsumerState<SetBudgetSheet> createState() => _SetBudgetSheetState();
}

class _SetBudgetSheetState extends ConsumerState<SetBudgetSheet> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.existingAmountSantim != null && widget.existingAmountSantim! > 0) {
      _controller.text = (widget.existingAmountSantim! / 100).toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() async {
    final amount = double.tryParse(_controller.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    await ref.read(budgetProvider.notifier).setBudget(MoneyFormatter.toSantim(amount));
    if (mounted) Navigator.pop(context);
  }

  void _clear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove Budget?'),
        content: const Text('This will remove your budget for the current month.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(budgetProvider.notifier).clearBudget();
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasExisting = widget.existingAmountSantim != null && widget.existingAmountSantim! > 0;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            hasExisting ? 'Update Budget' : 'Set Monthly Budget',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'How much do you want to spend this month?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),

          TextField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              color: AppColors.accent,
            ),
            decoration: const InputDecoration(
              hintText: '0.00',
              prefixText: 'ETB ',
              prefixStyle: TextStyle(color: AppColors.textMuted, fontSize: 24),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          FilledButton(
            onPressed: _submit,
            child: Text(hasExisting ? 'Update Budget' : 'Set Budget'),
          ),

          if (hasExisting) ...[
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: _clear,
              child: const Text(
                'Remove Budget',
                style: TextStyle(color: AppColors.danger),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
