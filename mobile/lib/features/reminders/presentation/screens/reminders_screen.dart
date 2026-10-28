import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:birrmetrics/core/theme/app_colors.dart';
import 'package:birrmetrics/core/theme/app_spacing.dart';
import 'package:birrmetrics/features/reminders/domain/entities/reminder.dart';
import 'package:birrmetrics/features/reminders/presentation/providers/reminder_providers.dart';
import 'package:birrmetrics/features/reminders/presentation/screens/add_reminder_sheet.dart';

class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  void _openEditSheet(BuildContext context, Reminder reminder) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddReminderSheet(existing: reminder),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remindersAsync = ref.watch(remindersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => const AddReminderSheet(),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: remindersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (reminders) {
          if (reminders.isEmpty) {
            return const Center(child: Text('No reminders set.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: reminders.length,
            itemBuilder: (context, index) {
              final r = reminders[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.notifications, color: AppColors.accent),
                  title: Text(r.title),
                  subtitle: Text(
                    '${DateFormat.yMMMd().add_jm().format(r.nextTriggerAt)} • ${r.recurrence}',
                  ),
                  // NEW: Tap to edit
                  onTap: () => _openEditSheet(context, r),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: AppColors.danger),
                    onPressed: () => ref.read(remindersProvider.notifier).deleteReminder(r.id!),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
