import 'package:birrmetrics/core/storage/app_database.dart';
import 'package:birrmetrics/features/debts/data/models/debt_model.dart';
import 'package:birrmetrics/features/debts/domain/entities/debt.dart';
import 'package:birrmetrics/features/debts/domain/entities/repayment.dart';
import 'package:sqflite/sqflite.dart';

class DebtRepository {
  Future<Database> get _db async => await AppDatabase.instance;

  Future<int> addDebt(Debt debt) async {
    final db = await _db;
    final model = DebtModel(
      userId: debt.userId,
      counterparty: debt.counterparty,
      counterpartyPhone: debt.counterpartyPhone,
      amountSantim: debt.amountSantim,
      remainingSantim: debt.remainingSantim,
      isLent: debt.isLent,
      dueDate: debt.dueDate,
      status: debt.status,
      notes: debt.notes,
      clientUpdatedAt: debt.clientUpdatedAt,
      createdAt: debt.createdAt,
    );
    return await db.insert('debts', model.toMap());
  }

  Future<List<DebtModel>> getAllDebts() async {
    final db = await _db;
    final maps = await db.query('debts', where: 'deleted_at IS NULL', orderBy: 'created_at DESC');
    return maps.map((map) => DebtModel.fromMap(map)).toList();
  }

  Future<void> partialRepay(int debtId, int repayAmountSantim, DateTime repaymentDate) async {
    final db = await _db;

    final maps = await db.query('debts', where: 'id = ?', whereArgs: [debtId]);
    if (maps.isEmpty) return;
    final debt = DebtModel.fromMap(maps.first);

    final safeRepaymentDate = repaymentDate.isBefore(debt.createdAt)
        ? debt.createdAt
        : repaymentDate;

    final clampedRepayAmountSantim = repayAmountSantim > debt.remainingSantim
        ? debt.remainingSantim
        : repayAmountSantim;

    int newRemaining = debt.remainingSantim - clampedRepayAmountSantim;
    if (newRemaining < 0) newRemaining = 0;

    String newStatus = 'pending';
    if (newRemaining == 0) {
      newStatus = 'settled';
    } else if (newRemaining < debt.amountSantim) {
      newStatus = 'partial';
    }

    await db.update(
      'debts',
      {
        'remaining_santim': newRemaining,
        'status': newStatus,
        'client_updated_at': DateTime.now().toIso8601String(),
        'is_synced': 0, // FIX: Mark as unsynced
        'sync_status': 'pending',
      },
      where: 'id = ?',
      whereArgs: [debtId],
    );

    await db.insert('repayments', {
      'debt_id': debtId,
      'amount_santim': clampedRepayAmountSantim,
      'repayment_date': safeRepaymentDate.toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> settleDebt(int debtId) async {
    final db = await _db;

    final maps = await db.query('debts', where: 'id = ?', whereArgs: [debtId]);
    if (maps.isNotEmpty) {
      final debt = DebtModel.fromMap(maps.first);
      if (debt.remainingSantim > 0) {
        await db.insert('repayments', {
          'debt_id': debtId,
          'amount_santim': debt.remainingSantim,
          'repayment_date': DateTime.now().toIso8601String(),
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    }

    await db.update(
      'debts',
      {
        'remaining_santim': 0,
        'status': 'settled',
        'client_updated_at': DateTime.now().toIso8601String(),
        'is_synced': 0, // FIX: Mark as unsynced
        'sync_status': 'pending',
      },
      where: 'id = ?',
      whereArgs: [debtId],
    );
  }

  Future<List<Repayment>> getRepaymentsForDebt(int debtId) async {
    final db = await _db;
    final maps = await db.query(
      'repayments',
      where: 'debt_id = ?',
      whereArgs: [debtId],
      orderBy: 'repayment_date DESC',
    );
    return maps.map((map) => Repayment(
      id: map['id'] as int?,
      debtId: map['debt_id'] as int,
      amountSantim: map['amount_santim'] as int,
      repaymentDate: DateTime.parse(map['repayment_date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    )).toList();
  }

  Future<void> updateDebt(Debt debt) async {
    final db = await _db;
    final model = DebtModel(
      id: debt.id,
      userId: debt.userId,
      counterparty: debt.counterparty,
      counterpartyPhone: debt.counterpartyPhone,
      amountSantim: debt.amountSantim,
      remainingSantim: debt.remainingSantim,
      isLent: debt.isLent,
      dueDate: debt.dueDate,
      status: debt.status,
      notes: debt.notes,
      isSynced: false,
      syncStatus: 'pending',
      clientUpdatedAt: DateTime.now(),
      createdAt: debt.createdAt,
    );

    await db.update(
      'debts',
      model.toMap(),
      where: 'id = ?',
      whereArgs: [debt.id],
    );
  }

  Future<void> deleteDebt(int debtId) async {
    final db = await _db;
    await db.update(
      'debts',
      {
        'deleted_at': DateTime.now().toIso8601String(),
        'is_synced': 0, // FIX: Mark as unsynced
        'sync_status': 'pending',
        'client_updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [debtId],
    );
  }

  Future<List<Map<String, dynamic>>> getUnsyncedDebts() async {
    final db = await _db;
    return await db.query(
      'debts',
      where: 'is_synced = 0',
      orderBy: 'created_at ASC',
    );
  }

  Future<void> markDebtsAsSynced(List<int> ids) async {
    if (ids.isEmpty) return;
    final db = await _db;
    final placeholders = List.filled(ids.length, '?').join(',');
    await db.rawUpdate(
      'UPDATE debts SET is_synced = 1, sync_status = ? WHERE id IN ($placeholders)',
      ['synced', ...ids],
    );
  }

  Future<bool> insertPulledDebt(Map<String, dynamic> data) async {
    final db = await _db;

    final existing = await db.query('debts', where: 'id = ?', whereArgs: [data['id']]);
    if (existing.isNotEmpty) return false;

    await db.insert('debts', {
      'id': data['id'],
      'user_id': 1,
      'counterparty': data['counterparty'],
      'amount_santim': data['amount_santim'],
      'remaining_santim': data['remaining_santim'],
      'is_lent': data['is_lent'] == true ? 1 : 0,
      'due_date': data['due_date'],
      'status': data['status'],
      'is_synced': 1,
      'sync_status': 'synced',
      'client_updated_at': data['client_updated_at'] ?? DateTime.now().toIso8601String(),
      'created_at': data['created_at'] ?? DateTime.now().toIso8601String(),
      'deleted_at': data['deleted_at'],
    });
    return true;
  }
}
