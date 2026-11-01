import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:birrmetrics/core/theme/app_colors.dart';
import 'package:birrmetrics/core/theme/app_spacing.dart';
import 'package:birrmetrics/core/utils/money_formatter.dart';
import 'package:birrmetrics/features/categories/presentation/providers/category_providers.dart';
import 'package:birrmetrics/features/expenses/domain/entities/expense.dart';
import 'package:birrmetrics/features/expenses/presentation/providers/expense_providers.dart';

class AddExpenseSheet extends ConsumerStatefulWidget {
  final Expense? existingExpense;

  const AddExpenseSheet({super.key, this.existingExpense});

  @override
  ConsumerState<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends ConsumerState<AddExpenseSheet> {
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  int? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.existingExpense != null) {
      final e = widget.existingExpense!;
      _amountController.text = (e.amountSantim / 100).toStringAsFixed(2);
      _descController.text = e.description ?? '';
      _selectedCategoryId = e.categoryId;
      _selectedDate = e.expenseDate;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _openAddCategoryDialog() {
    final controller = TextEditingController();
    final emojiController = TextEditingController(text: '🍔');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(labelText: 'Category Name'),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: emojiController,
                decoration: const InputDecoration(labelText: 'Emoji (optional)'),
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
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  await ref.read(categoriesProvider.notifier).addCategory(
                    name,
                    emojiController.text.trim().isEmpty ? '🏷️' : emojiController.text.trim(),
                  );
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0 || _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount and category')),
      );
      return;
    }

    final expense = Expense(
      id: widget.existingExpense?.id,
      categoryId: _selectedCategoryId!,
      amountSantim: MoneyFormatter.toSantim(amount),
      expenseDate: _selectedDate,
      description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      clientUpdatedAt: DateTime.now(),
      createdAt: widget.existingExpense?.createdAt ?? DateTime.now(),
    );

    if (widget.existingExpense == null) {
      await ref.read(expensesProvider.notifier).addExpense(expense);
    } else {
      await ref.read(expensesProvider.notifier).updateExpense(expense);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoriesAsync = ref.watch(categoriesProvider);
    final isEditing = widget.existingExpense != null;

    return categoriesAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (categories) {
        if (_selectedCategoryId == null && categories.isNotEmpty) {
          _selectedCategoryId = categories.first.id;
        }

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
                isEditing ? 'Edit Expense' : 'Add Expense',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
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
              const SizedBox(height: AppSpacing.md),

              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'When did this happen?',
                    prefixIcon: Icon(Icons.event),
                    suffixIcon: Icon(Icons.arrow_drop_down),
                  ),
                  child: Text(
                    DateFormat.yMMMd().format(_selectedDate),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Category', style: Theme.of(context).textTheme.labelLarge),
                  TextButton.icon(
                    onPressed: _openAddCategoryDialog,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('New'),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: categories.map((cat) {
                  final isSelected = _selectedCategoryId == cat.id;
                  return ChoiceChip(
                    label: Text('${cat.icon}  ${cat.name}'),
                    selected: isSelected,
                    onSelected: (val) => setState(() => _selectedCategoryId = cat.id),
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
                child: Text(isEditing ? 'Save Changes' : 'Save Expense'),
              ),
            ],
          ),
        );
      },
    );
  }
}
