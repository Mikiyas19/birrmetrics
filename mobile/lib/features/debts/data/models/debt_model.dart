import 'package:birrmetrics/features/debts/domain/entities/debt.dart';

class DebtModel extends Debt {
  const DebtModel({
    super.id,
    super.userId,
    required super.counterparty,
    super.counterpartyPhone,
    required super.amountSantim,
    required super.remainingSantim,
    required super.isLent,
    super.dueDate,
    super.status,
    super.notes,
    super.isSynced,
    super.syncStatus,
    required super.clientUpdatedAt,
    super.deletedAt,
    required super.createdAt,
  });

  factory DebtModel.fromMap(Map<String, dynamic> map) {
    return DebtModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int?,
      counterparty: map['counterparty'] as String,
      counterpartyPhone: map['counterparty_phone'] as String?,
      amountSantim: map['amount_santim'] as int,
      remainingSantim: map['remaining_santim'] as int,
      isLent: (map['is_lent'] as int) == 1,
      dueDate: map['due_date'] != null ? DateTime.parse(map['due_date'] as String) : null,
      status: map['status'] as String,
      notes: map['notes'] as String?,
      isSynced: (map['is_synced'] as int) == 1,
      syncStatus: map['sync_status'] as String,
      clientUpdatedAt: DateTime.parse(map['client_updated_at'] as String),
      deletedAt: map['deleted_at'] != null ? DateTime.parse(map['deleted_at'] as String) : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId ?? 1,
      'counterparty': counterparty,
      'counterparty_phone': counterpartyPhone,
      'amount_santim': amountSantim,
      'remaining_santim': remainingSantim,
      'is_lent': isLent ? 1 : 0,
      'due_date': dueDate?.toIso8601String(),
      'status': status,
      'notes': notes,
      'is_synced': isSynced ? 1 : 0,
      'sync_status': syncStatus,
      'client_updated_at': clientUpdatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
