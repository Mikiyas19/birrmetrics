enum InsightSeverity { info, warning, critical }

class Insight {
  final int? id;
  final String ruleKey;
  final InsightSeverity severity;
  final String title;
  final String message;
  final Map<String, dynamic>? payload;
  final bool isRead;
  final DateTime triggeredAt;
  final DateTime? expiresAt; // NEW

  const Insight({
    this.id,
    required this.ruleKey,
    required this.severity,
    required this.title,
    required this.message,
    this.payload,
    this.isRead = false,
    required this.triggeredAt,
    this.expiresAt,
  });

  Insight copyWith({bool? isRead}) {
    return Insight(
      id: id,
      ruleKey: ruleKey,
      severity: severity,
      title: title,
      message: message,
      payload: payload,
      isRead: isRead ?? this.isRead,
      triggeredAt: triggeredAt,
      expiresAt: expiresAt,
    );
  }
}
