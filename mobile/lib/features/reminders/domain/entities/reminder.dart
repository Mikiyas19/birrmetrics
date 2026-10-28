class Reminder {
  final int? id;
  final int userId;
  final String title;
  final String? body;
  final DateTime nextTriggerAt;
  final String recurrence; // 'none', 'daily', 'weekly', 'monthly'
  final bool isActive;
  final DateTime? lastTriggeredAt;

  const Reminder({
    this.id,
    this.userId = 1,
    required this.title,
    this.body,
    required this.nextTriggerAt,
    this.recurrence = 'none',
    this.isActive = true,
    this.lastTriggeredAt,
  });
}
