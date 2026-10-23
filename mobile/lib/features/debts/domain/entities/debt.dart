class Debt {
  final int? id;
  final int? userId;
  final String counterparty;
  final String? counterpartyPhone;
  final int amountSantim;
  final int remainingSantim;
  final bool isLent; // true = I lent (they owe me), false = I borrowed (I owe them)
  final DateTime? dueDate;
  final String status; // 'pending', 'partial', 'settled'
  final String? notes;
  final bool isSynced;
  final String syncStatus;
  final DateTime clientUpdatedAt;
  final DateTime? deletedAt;
  final DateTime createdAt;

  const Debt({
    this.id,
    this.userId,
    required this.counterparty,
    this.counterpartyPhone,
    required this.amountSantim,
    required this.remainingSantim,
    required this.isLent,
    this.dueDate,
    this.status = 'pending',
    this.notes,
    this.isSynced = false,
    this.syncStatus = 'pending',
    required this.clientUpdatedAt,
    this.deletedAt,
    required this.createdAt,
  });
}
