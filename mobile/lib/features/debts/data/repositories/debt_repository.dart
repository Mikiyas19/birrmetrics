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

    // DATA SAFETY 1: Clamp date to be >= debt creation date
    final safeRepaymentDate = repaymentDate.isBefore(debt.createdAt)
        ? debt.createdAt
        : repaymentDate;

    // DATA SAFETY 2: Clamp amount to remaining balance
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

    // Settle uses today's date
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
        'sync_status': 'pending',
        'client_updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [debtId],
    );
  }
}
