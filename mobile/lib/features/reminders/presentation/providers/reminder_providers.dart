import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:birrmetrics/features/reminders/data/repositories/reminder_repository.dart';
import 'package:birrmetrics/features/reminders/domain/entities/reminder.dart';

final reminderRepositoryProvider = Provider((ref) => ReminderRepository());

class RemindersNotifier extends StateNotifier<AsyncValue<List<Reminder>>> {
  final ReminderRepository _repo;

  RemindersNotifier(this._repo) : super(const AsyncLoading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.getActiveReminders());
  }

  Future<void> addReminder(Reminder reminder) async {
    await _repo.addReminder(reminder);
    await load();
  }

  // NEW: Update reminder
  Future<void> updateReminder(Reminder reminder) async {
    await _repo.updateReminder(reminder);
    await load();
  }

  Future<void> deleteReminder(int id) async {
    await _repo.deleteReminder(id);
    await load();
  }
}

final remindersProvider =
StateNotifierProvider<RemindersNotifier, AsyncValue<List<Reminder>>>((ref) {
  return RemindersNotifier(ref.watch(reminderRepositoryProvider));
});
