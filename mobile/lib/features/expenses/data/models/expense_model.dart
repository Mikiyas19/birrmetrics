import 'package:birrmetrics/features/expenses/domain/entities/expense.dart';

class ExpenseModel extends Expense {
  const ExpenseModel({
    super.id,
    super.userId,
    required super.categoryId,
    required super.amountSantim,
    required super.expenseDate,
    super.description,
    super.notes,
    super.isSynced,
    super.syncStatus,
    required super.clientUpdatedAt,
    super.deletedAt,
    required super.createdAt,
  });

  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int?,
      categoryId: map['category_id'] as int,
      amountSantim: map['amount_santim'] as int,
      expenseDate: DateTime.parse(map['expense_date'] as String),
      description: map['description'] as String?,
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
      'user_id': userId ?? 1, // Default to 1 for now until Auth is built
      'category_id': categoryId,
      'amount_santim': amountSantim,
      'expense_date': expenseDate.toIso8601String(),
      'description': description,
      'notes': notes,
      'is_synced': isSynced ? 1 : 0,
      'sync_status': syncStatus,
      'client_updated_at': clientUpdatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
