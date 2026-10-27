import 'package:birrmetrics/core/storage/app_database.dart';
import 'package:birrmetrics/features/categories/domain/entities/category.dart';
import 'package:sqflite/sqflite.dart';

class CategoryRepository {
  Future<Database> get _db async => await AppDatabase.instance;

  Future<List<ExpenseCategory>> getAllCategories() async {
    final db = await _db;
    // Fetch system categories (user_id IS NULL) and user categories (user_id = 1)
    final maps = await db.query(
      'categories',
      where: 'user_id IS NULL OR user_id = ?',
      whereArgs: [1],
      orderBy: 'is_system DESC, id ASC',
    );

    return maps.map((map) => ExpenseCategory(
      id: map['id'] as int?,
      name: map['name'] as String,
      icon: map['icon'] as String? ?? '🏷️',
      isSystem: map['is_system'] as int,
      isDeletable: map['is_deletable'] as int,
    )).toList();
  }

  Future<int> addCategory(String name, String icon) async {
    final db = await _db;
    return await db.insert('categories', {
      'user_id': 1,
      'name': name,
      'icon': icon,
      'is_system': 0,
      'is_deletable': 1,
    });
  }

  Future<void> deleteCategory(int id) async {
    final db = await _db;
    // For safety, check if there are expenses using this category
    final expenses = await db.query('expenses', where: 'category_id = ?', whereArgs: [id], limit: 1);
    if (expenses.isNotEmpty) {
      throw Exception('Cannot delete category: it is currently used by expenses.');
    }
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }
}
