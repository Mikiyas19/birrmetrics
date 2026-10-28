import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:birrmetrics/core/theme/app_spacing.dart';
import 'package:birrmetrics/features/reminders/domain/entities/reminder.dart';
import 'package:birrmetrics/features/reminders/presentation/providers/reminder_providers.dart';

class AddReminderSheet extends ConsumerStatefulWidget {
  final Reminder? existing;

  const AddReminderSheet({super.key, this.existing});

  @override
  ConsumerState<AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends ConsumerState<AddReminderSheet> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _recurrence = 'none';

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final r = widget.existing!;
      _titleController.text = r.title;
      _bodyController.text = r.body ?? '';
      _selectedDate = r.nextTriggerAt;
      _recurrence = r.recurrence;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (date != null) {
      if (!mounted) return;
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );
      if (time != null) {
        setState(() => _selectedDate = DateTime(
          date.year, date.month, date.day, time.hour, time.minute,
        ));
      }
    }
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) return;

    final reminder = Reminder(
      id: widget.existing?.id,
      title: _titleController.text.trim(),
      body: _bodyController.text.trim().isEmpty ? null : _bodyController.text.trim(),
      nextTriggerAt: _selectedDate,
      recurrence: _recurrence,
    );

    if (widget.existing == null) {
      await ref.read(remindersProvider.notifier).addReminder(reminder);
    } else {
      await ref.read(remindersProvider.notifier).updateReminder(reminder);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;

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
          Text(isEditing ? 'Edit Reminder' : 'New Reminder',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.lg),

          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title (e.g., Pay Rent)',
              prefixIcon: Icon(Icons.title),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          TextField(
            controller: _bodyController,
            decoration: const InputDecoration(
              labelText: 'Notes (Optional)',
              prefixIcon: Icon(Icons.notes),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          InkWell(
            onTap: _pickDate,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Date & Time',
                prefixIcon: Icon(Icons.alarm),
              ),
              child: Text(DateFormat.yMMMd().add_jm().format(_selectedDate)),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          DropdownButtonFormField<String>(
            initialValue: _recurrence,
            decoration: const InputDecoration(
              labelText: 'Repeat',
              prefixIcon: Icon(Icons.repeat),
            ),
            items: const [
              DropdownMenuItem(value: 'none', child: Text('Once')),
              DropdownMenuItem(value: 'daily', child: Text('Daily')),
              DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
              DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
            ],
            onChanged: (val) => setState(() => _recurrence = val ?? 'none'),
          ),
          const SizedBox(height: AppSpacing.xl),

          FilledButton(
            onPressed: _submit,
            child: Text(isEditing ? 'Save Changes' : 'Save Reminder'),
          ),
        ],
      ),
    );
  }
}
