import 'package:birrmetrics/core/storage/app_database.dart';
import 'package:birrmetrics/features/budget/domain/entities/budget.dart';
import 'package:sqflite/sqflite.dart';

class BudgetRepository {
  Future<Database> get _db async => await AppDatabase.instance;

  /// Fetches the budget for the current month.
  /// Returns null if none is set.
  Future<Budget?> getCurrentBudget() async {
    final db = await _db;
    final period = Budget.currentPeriod();
    final maps = await db.query(
      'budgets',
      where: 'user_id = ? AND period = ?',
      whereArgs: [1, period],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return _fromMap(maps.first);
  }

  /// Inserts or updates the budget for the current month.
  Future<void> setCurrentBudget(int amountSantim) async {
    final db = await _db;
    final period = Budget.currentPeriod();
    final now = DateTime.now().toIso8601String();

    // Check if one already exists
    final existing = await db.query(
      'budgets',
      where: 'user_id = ? AND period = ?',
      whereArgs: [1, period],
      limit: 1,
    );

    if (existing.isEmpty) {
      await db.insert('budgets', {
        'user_id': 1,
        'period': period,
        'amount_santim': amountSantim,
        'created_at': now,
        'updated_at': now,
      });
    } else {
      await db.update(
        'budgets',
        {
          'amount_santim': amountSantim,
          'updated_at': now,
        },
        where: 'user_id = ? AND period = ?',
        whereArgs: [1, period],
      );
    }
  }

  /// Clears the budget for the current month.
  Future<void> clearCurrentBudget() async {
    final db = await _db;
    final period = Budget.currentPeriod();
    await db.delete(
      'budgets',
      where: 'user_id = ? AND period = ?',
      whereArgs: [1, period],
    );
  }

  Budget _fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      period: map['period'] as String,
      amountSantim: map['amount_santim'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
