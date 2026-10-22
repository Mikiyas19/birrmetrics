import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:birrmetrics/core/storage/seed_data.dart';

class AppDatabase {
  static Database? _database;

  static Future<Database> get instance async {
    if (_database != null) return _database!;
    _database = await _initDB('birrmetrics.db');
    return _database!;
  }

  static Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2, // Bumped to 2 to force the upgrade
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  static Future<void> _createDB(Database db, int version) async {
    debugPrint('Creating database tables...');

    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        full_name TEXT,
        currency TEXT NOT NULL DEFAULT 'ETB',
        monthly_budget INTEGER NOT NULL DEFAULT 0,
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        last_sync_at DATETIME
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
        name TEXT NOT NULL,
        icon TEXT,
        color TEXT,
        is_system INTEGER NOT NULL DEFAULT 0,
        is_deletable INTEGER NOT NULL DEFAULT 1,
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(user_id, name)
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        category_id INTEGER NOT NULL REFERENCES categories(id),
        amount_santim INTEGER NOT NULL CHECK (amount_santim > 0),
        expense_date DATE NOT NULL,
        description TEXT,
        notes TEXT,
        is_synced INTEGER NOT NULL DEFAULT 0,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        client_updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        deleted_at DATETIME,
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    await db.execute('CREATE INDEX idx_exp_user_date ON expenses(user_id, expense_date DESC)');
    await db.execute('CREATE INDEX idx_exp_user_cat ON expenses(user_id, category_id)');

    await db.execute('''
      CREATE TABLE debts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        counterparty TEXT NOT NULL,
        counterparty_phone TEXT,
        amount_santim INTEGER NOT NULL CHECK (amount_santim > 0),
        remaining_santim INTEGER NOT NULL CHECK (remaining_santim >= 0),
        is_lent INTEGER NOT NULL,
        due_date DATE,
        status TEXT NOT NULL DEFAULT 'pending',
        notes TEXT,
        is_synced INTEGER NOT NULL DEFAULT 0,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        client_updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        deleted_at DATETIME,
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    await db.execute('CREATE INDEX idx_debt_user_status ON debts(user_id, status)');

    await db.execute('''
      CREATE TABLE reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        expense_id INTEGER REFERENCES expenses(id) ON DELETE SET NULL,
        debt_id INTEGER REFERENCES debts(id) ON DELETE SET NULL,
        title TEXT NOT NULL,
        body TEXT,
        next_trigger_at DATETIME NOT NULL,
        recurrence TEXT NOT NULL DEFAULT 'none',
        is_active INTEGER NOT NULL DEFAULT 1,
        last_triggered_at DATETIME,
        is_synced INTEGER NOT NULL DEFAULT 0,
        client_updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CHECK (expense_id IS NULL OR debt_id IS NULL)
      )
    ''');
    await db.execute('CREATE INDEX idx_rem_next ON reminders(next_trigger_at)');

    await db.execute('''
      CREATE TABLE budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        period TEXT NOT NULL,
        amount_santim INTEGER NOT NULL CHECK (amount_santim >= 0),
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(user_id, period)
      )
    ''');

    await db.execute('''
      CREATE TABLE insights (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        rule_key TEXT NOT NULL,
        severity TEXT NOT NULL,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        payload_json TEXT,
        is_read INTEGER NOT NULL DEFAULT 0,
        triggered_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        expires_at DATETIME
      )
    ''');
    await db.execute('CREATE INDEX idx_insights_user ON insights(user_id, triggered_at DESC)');

    await db.execute('''
      CREATE TABLE sync_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        started_at DATETIME NOT NULL,
        finished_at DATETIME,
        uploaded INTEGER NOT NULL DEFAULT 0,
        downloaded INTEGER NOT NULL DEFAULT 0,
        conflicts INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL,
        error_msg TEXT
      )
    ''');

    await SeedData.insertDefaultData(db);
    debugPrint('Database created and seeded successfully.');
  }

  static Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    debugPrint('Upgrading database from $oldVersion to $newVersion');
    if (oldVersion < 2) {
      // Insert the default user and categories for older versions
      await SeedData.insertDefaultData(db);
    }
  }
}
