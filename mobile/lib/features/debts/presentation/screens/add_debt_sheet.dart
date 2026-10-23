import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:birrmetrics/core/theme/app_spacing.dart';
import 'package:birrmetrics/core/utils/money_formatter.dart';
import 'package:birrmetrics/features/debts/domain/entities/debt.dart';

class AddDebtSheet extends ConsumerStatefulWidget {
  final Debt? existingDebt;

  const AddDebtSheet({super.key, this.existingDebt});

  @override
  ConsumerState<AddDebtSheet> createState() => _AddDebtSheetState();
}

class _AddDebtSheetState extends ConsumerState<AddDebtSheet> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();

  bool _isLent = true;
  DateTime? _dueDate;
  DateTime _debtDate = DateTime.now(); // NEW: track debt creation date separately

  @override
  void initState() {
    super.initState();
    if (widget.existingDebt != null) {
      final d = widget.existingDebt!;
      _nameController.text = d.counterparty;
      _amountController.text = (d.amountSantim / 100).toStringAsFixed(2);
      _descController.text = d.notes ?? '';
      _isLent = d.isLent;
      _dueDate = d.dueDate;
      _debtDate = d.createdAt;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDebtDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _debtDate,
      // Allow recording debts from up to 2 years ago
      firstDate: DateTime(DateTime.now().year - 2),
      // Cannot create debt in the future
      lastDate: DateTime.now(),
      helpText: 'When did this debt happen?',
    );
    if (picked != null) {
      setState(() {
        _debtDate = picked;
        // Reset due date if it's before the new debt date
        if (_dueDate != null && _dueDate!.isBefore(_debtDate)) {
          _dueDate = null;
        }
      });
    }
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? _debtDate.add(const Duration(days: 7)),
      // Due date must be on or after the debt date
      firstDate: _debtDate,
      lastDate: DateTime(2030),
      helpText: 'When should this be repaid?',
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  int get _totalRepaid {
    if (widget.existingDebt == null) return 0;
    return widget.existingDebt!.amountSantim - widget.existingDebt!.remainingSantim;
  }

  void _submit() {
    final double? amount = double.tryParse(_amountController.text);
    final name = _nameController.text.trim();

    if (name.isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name and a valid amount')),
      );
      return;
    }

    final newAmountSantim = MoneyFormatter.toSantim(amount);

    // Validation for edits: cannot lower the amount below what has already been repaid
    if (widget.existingDebt != null) {
      final paid = _totalRepaid;
      if (newAmountSantim < paid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(
            'Cannot lower amount below ${MoneyFormatter.formatSantim(paid)} — that amount has already been repaid.',
          )),
        );
        return;
      }
    }

    // Compute new remaining and status
    int newRemainingSantim;
    String newStatus;
    if (widget.existingDebt != null) {
      final paid = _totalRepaid;
      newRemainingSantim = newAmountSantim - paid;
      if (newRemainingSantim == 0) {
        newStatus = 'settled';
      } else if (paid > 0) {
        newStatus = 'partial';
      } else {
        newStatus = 'pending';
      }
    } else {
      newRemainingSantim = newAmountSantim;
      newStatus = 'pending';
    }

    final debt = Debt(
      id: widget.existingDebt?.id,
      counterparty: name,
      amountSantim: newAmountSantim,
      remainingSantim: newRemainingSantim,
      isLent: _isLent,
      dueDate: _dueDate,
      status: newStatus,
      notes: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      clientUpdatedAt: DateTime.now(),
      // Use the picked debt date, not "now"
      createdAt: widget.existingDebt?.createdAt ?? _debtDate,
    );

    Navigator.pop(context, debt);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingDebt != null;
    final totalRepaid = _totalRepaid;

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
            isEditing ? 'Edit Debt' : 'Record a Debt',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),

          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Owed to Me'), icon: Icon(Icons.arrow_downward)),
              ButtonSegment(value: false, label: Text('I Owe'), icon: Icon(Icons.arrow_upward)),
            ],
            selected: {_isLent},
            onSelectionChanged: (Set<bool> newSelection) {
              setState(() => _isLent = newSelection.first);
            },
          ),
          const SizedBox(height: AppSpacing.lg),

          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Person\'s Name',
              prefixIcon: Icon(Icons.person),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: Theme.of(context).textTheme.titleLarge,
            decoration: InputDecoration(
              labelText: 'Amount',
              prefixText: 'ETB ',
              prefixIcon: const Icon(Icons.attach_money),
              helperText: isEditing && totalRepaid > 0
                  ? 'Minimum: ${MoneyFormatter.formatSantim(totalRepaid)} (already repaid)'
                  : null,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // NEW: Debt Date picker (when did this actually happen?)
          InkWell(
            onTap: isEditing ? null : _pickDebtDate, // Lock after creation
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'When did this happen?',
                prefixIcon: const Icon(Icons.event),
                suffixIcon: isEditing ? null : const Icon(Icons.arrow_drop_down),
                helperText: isEditing
                    ? 'Debt date cannot be changed after creation'
                    : 'For backdated entries, pick a past date',
              ),
              child: Text(
                DateFormat.yMMMd().format(_debtDate),
                style: TextStyle(
                  color: isEditing ? Colors.grey : null,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          InkWell(
            onTap: _pickDueDate,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Due Date (Optional)',
                prefixIcon: Icon(Icons.calendar_today),
                suffixIcon: Icon(Icons.arrow_drop_down),
              ),
              child: Text(
                _dueDate == null ? 'No due date set' : DateFormat.yMMMd().format(_dueDate!),
                style: TextStyle(color: _dueDate == null ? Colors.grey : null),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          TextField(
            controller: _descController,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Notes (Optional)',
              prefixIcon: Icon(Icons.notes),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          FilledButton(
            onPressed: _submit,
            child: Text(isEditing ? 'Save Changes' : 'Save Debt'),
          ),
        ],
      ),
    );
  }
}
