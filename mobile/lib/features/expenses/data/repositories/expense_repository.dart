import 'package:birrmetrics/core/storage/app_database.dart';
import 'package:birrmetrics/features/expenses/data/models/expense_model.dart';
import 'package:birrmetrics/features/expenses/domain/entities/expense.dart';
import 'package:sqflite/sqflite.dart';

class ExpenseRepository {
  Future<Database> get _db async => await AppDatabase.instance;

  Future<int> addExpense(Expense expense) async {
    final db = await _db;
    final model = ExpenseModel(
      userId: expense.userId,
      categoryId: expense.categoryId,
      amountSantim: expense.amountSantim,
      expenseDate: expense.expenseDate,
      description: expense.description,
      notes: expense.notes,
      isSynced: expense.isSynced,
      syncStatus: expense.syncStatus,
      clientUpdatedAt: expense.clientUpdatedAt,
      createdAt: expense.createdAt,
    );
    return await db.insert('expenses', model.toMap());
  }

  Future<List<Expense>> getAllExpenses() async {
    final db = await _db;

    // NEW: JOIN query to get category name and icon
    final maps = await db.rawQuery('''
      SELECT e.*, c.name as category_name, c.icon as category_icon
      FROM expenses e
      JOIN categories c ON e.category_id = c.id
      WHERE e.deleted_at IS NULL
      ORDER BY e.expense_date DESC
    ''');

    return maps.map((map) {
      return Expense(
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
        categoryName: map['category_name'] as String?,
        categoryIcon: map['category_icon'] as String?,
      );
    }).toList();
  }

  Future<int> getTotalSpentThisMonth() async {
    final db = await _db;
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1).toIso8601String();

    final result = await db.rawQuery(
      'SELECT SUM(amount_santim) as total FROM expenses WHERE expense_date >= ? AND deleted_at IS NULL',
      [startOfMonth],
    );
    return (result.first['total'] as int?) ?? 0;
  }
}
