import 'package:sqflite/sqflite.dart';

abstract final class SeedData {
  static Future<void> insertDefaultData(Database db) async {
    // 1. Create a default local user (ID 1) so Foreign Keys don't fail
    await db.insert('users', {
      'id': 1,
      'email': 'local@birrmetrics.app',
      'password_hash': 'local_hash',
      'full_name': 'Local User',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    // 2. Insert default categories
    final List<Map<String, dynamic>> categories = [
      {'id': 1, 'name': 'Food', 'icon': '🍔', 'color': '#F2A65A', 'is_system': 1, 'is_deletable': 0},
      {'id': 2, 'name': 'Transport', 'icon': '🚌', 'color': '#3B82F6', 'is_system': 1, 'is_deletable': 0},
      {'id': 3, 'name': 'Education', 'icon': '📚', 'color': '#8B5CF6', 'is_system': 1, 'is_deletable': 0},
      {'id': 4, 'name': 'Fun', 'icon': '🎬', 'color': '#EC4899', 'is_system': 1, 'is_deletable': 0},
      {'id': 5, 'name': 'Health', 'icon': '💊', 'color': '#E04F5F', 'is_system': 1, 'is_deletable': 0},
      {'id': 6, 'name': 'Bills', 'icon': '🧾', 'color': '#F59E0B', 'is_system': 1, 'is_deletable': 0},
      {'id': 7, 'name': 'Other', 'icon': '🏷️', 'color': '#8B97A5', 'is_system': 1, 'is_deletable': 0},
    ];

    for (final category in categories) {
      await db.insert('categories', category, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }
}
