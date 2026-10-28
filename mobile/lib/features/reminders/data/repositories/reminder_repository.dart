import 'package:birrmetrics/core/notifications/notification_service.dart';
import 'package:birrmetrics/core/storage/app_database.dart';
import 'package:birrmetrics/features/reminders/domain/entities/reminder.dart';
import 'package:sqflite/sqflite.dart';

class ReminderRepository {
  Future<Database> get _db async => await AppDatabase.instance;
  final _notif = NotificationService();

  Future<int> addReminder(Reminder reminder) async {
    final db = await _db;
    final id = await db.insert('reminders', {
      'user_id': reminder.userId,
      'title': reminder.title,
      'body': reminder.body,
      'next_trigger_at': reminder.nextTriggerAt.toIso8601String(),
      'recurrence': reminder.recurrence,
      'is_active': reminder.isActive ? 1 : 0,
    });

    await _notif.scheduleReminder(
      id: id,
      title: reminder.title,
      body: reminder.body,
      scheduledAt: reminder.nextTriggerAt,
      recurrence: reminder.recurrence,
    );

    return id;
  }

  // NEW: Update an existing reminder
  Future<void> updateReminder(Reminder reminder) async {
    final db = await _db;

    // 1. Update the database
    await db.update(
      'reminders',
      {
        'title': reminder.title,
        'body': reminder.body,
        'next_trigger_at': reminder.nextTriggerAt.toIso8601String(),
        'recurrence': reminder.recurrence,
        'is_active': reminder.isActive ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [reminder.id],
    );

    // 2. Cancel the old scheduled notification
    await _notif.cancel(reminder.id!);

    // 3. Reschedule with the new data
    await _notif.scheduleReminder(
      id: reminder.id!,
      title: reminder.title,
      body: reminder.body,
      scheduledAt: reminder.nextTriggerAt,
      recurrence: reminder.recurrence,
    );
  }

  Future<List<Reminder>> getActiveReminders() async {
    final db = await _db;
    final maps = await db.query(
      'reminders',
      where: 'user_id = ? AND is_active = 1',
      whereArgs: [1],
      orderBy: 'next_trigger_at ASC',
    );
    return maps.map((map) => Reminder(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      title: map['title'] as String,
      body: map['body'] as String?,
      nextTriggerAt: DateTime.parse(map['next_trigger_at'] as String),
      recurrence: map['recurrence'] as String,
      isActive: (map['is_active'] as int) == 1,
      lastTriggeredAt: map['last_triggered_at'] != null
          ? DateTime.parse(map['last_triggered_at'] as String)
          : null,
    )).toList();
  }

  Future<void> deleteReminder(int id) async {
    final db = await _db;
    await db.delete('reminders', where: 'id = ?', whereArgs: [id]);
    await _notif.cancel(id);
  }
}
