class Expense {
  final int? id;
  final int? userId;
  final int categoryId;
  final int amountSantim;
  final DateTime expenseDate;
  final String? description;
  final String? notes;
  final bool isSynced;
  final String syncStatus;
  final DateTime clientUpdatedAt;
  final DateTime? deletedAt;
  final DateTime createdAt;

  // NEW: Fields to hold joined data from the categories table
  final String? categoryName;
  final String? categoryIcon;

  const Expense({
    this.id,
    this.userId,
    required this.categoryId,
    required this.amountSantim,
    required this.expenseDate,
    this.description,
    this.notes,
    this.isSynced = false,
    this.syncStatus = 'pending',
    required this.clientUpdatedAt,
    this.deletedAt,
    required this.createdAt,
    this.categoryName,
    this.categoryIcon,
  });
}
