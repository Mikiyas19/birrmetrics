import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:birrmetrics/core/theme/app_colors.dart';
import 'package:birrmetrics/core/theme/app_spacing.dart';
import 'package:birrmetrics/core/utils/money_formatter.dart';
import 'package:birrmetrics/features/expenses/domain/entities/expense.dart';
import 'package:birrmetrics/features/expenses/presentation/providers/expense_providers.dart';
import 'package:intl/intl.dart';

class AddExpenseSheet extends ConsumerStatefulWidget {
  const AddExpenseSheet({super.key});

  @override
  ConsumerState<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends ConsumerState<AddExpenseSheet> {
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  int _selectedCategoryId = 1;
  DateTime _selectedDate = DateTime.now(); // NEW: State for the date

  final List<Map<String, dynamic>> _categories = [
    {'id': 1, 'name': 'Food', 'icon': '🍔'},
    {'id': 2, 'name': 'Transport', 'icon': '🚌'},
    {'id': 3, 'name': 'Education', 'icon': '📚'},
    {'id': 4, 'name': 'Fun', 'icon': '🎬'},
    {'id': 5, 'name': 'Health', 'icon': '💊'},
    {'id': 6, 'name': 'Bills', 'icon': '🧾'},
    {'id': 7, 'name': 'Other', 'icon': '🏷️'},
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // NEW: Function to show the native calendar
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(), // Prevent selecting future expenses
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    final double? amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid amount')));
      return;
    }

    final expense = Expense(
      categoryId: _selectedCategoryId,
      amountSantim: MoneyFormatter.toSantim(amount),
      expenseDate: _selectedDate, // Use the selected date
      description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      clientUpdatedAt: DateTime.now(),
      createdAt: DateTime.now(),
    );

    await ref.read(expensesProvider.notifier).addExpense(expense);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          Text('Add Expense', style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.lg),

          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(color: AppColors.accent),
            decoration: const InputDecoration(
              hintText: '0.00',
              prefixText: 'ETB ',
              prefixStyle: TextStyle(color: AppColors.textMuted, fontSize: 24),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // NEW: Date Picker Row
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      DateFormat.yMMMd().format(_selectedDate),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          Text('Category', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: _categories.map((cat) {
              final isSelected = _selectedCategoryId == cat['id'];
              return ChoiceChip(
                label: Text('${cat['icon']}  ${cat['name']}'),
                selected: isSelected,
                onSelected: (val) => setState(() => _selectedCategoryId = cat['id']),
                selectedColor: AppColors.accent.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.accent : (isDark ? AppColors.darkText : AppColors.textPrimary),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.lg),

          TextField(
            controller: _descController,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'What was this for? (Optional)',
              prefixIcon: Icon(Icons.notes),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          FilledButton(
            onPressed: _submit,
            child: const Text('Save Expense'),
          ),
        ],
      ),
    );
  }
}
