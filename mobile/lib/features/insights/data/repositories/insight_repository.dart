import 'dart:convert';
import 'package:birrmetrics/core/storage/app_database.dart';
import 'package:birrmetrics/features/insights/domain/entities/insight.dart';
import 'package:sqflite/sqflite.dart';

class InsightRepository {
  Future<Database> get _db async => await AppDatabase.instance;

  Future<int> insertInsight(Insight insight) async {
    final db = await _db;
    return await db.insert('insights', {
      'user_id': 1,
      'rule_key': insight.ruleKey,
      'severity': insight.severity.name,
      'title': insight.title,
      'message': insight.message,
      'payload_json': insight.payload != null ? jsonEncode(insight.payload) : null,
      'is_read': insight.isRead ? 1 : 0,
      'triggered_at': insight.triggeredAt.toIso8601String(),
      'expires_at': insight.expiresAt?.toIso8601String(),
    });
  }

  Future<List<Insight>> getRecentInsights({int limit = 50}) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();

    final maps = await db.query(
      'insights',
      where: 'user_id = ? AND (expires_at IS NULL OR expires_at > ?)',
      whereArgs: [1, now],
      orderBy: 'triggered_at DESC',
      limit: limit,
    );

    return maps.map((map) => Insight(
      id: map['id'] as int?,
      ruleKey: map['rule_key'] as String,
      severity: InsightSeverity.values.firstWhere(
            (s) => s.name == map['severity'],
        orElse: () => InsightSeverity.info,
      ),
      title: map['title'] as String,
      message: map['message'] as String,
      payload: map['payload_json'] != null
          ? jsonDecode(map['payload_json'] as String) as Map<String, dynamic>
          : null,
      isRead: (map['is_read'] as int) == 1,
      triggeredAt: DateTime.parse(map['triggered_at'] as String),
      expiresAt: map['expires_at'] != null
          ? DateTime.parse(map['expires_at'] as String)
          : null,
    )).toList();
  }

  Future<void> markAsRead(int insightId) async {
    final db = await _db;
    await db.update(
      'insights',
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [insightId],
    );
  }

  Future<void> pruneExpired() async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    await db.delete(
      'insights',
      where: 'expires_at IS NOT NULL AND expires_at <= ?',
      whereArgs: [now],
    );
  }

  Future<void> deleteInsight(int insightId) async {
    final db = await _db;
    await db.delete(
      'insights',
      where: 'id = ?',
      whereArgs: [insightId],
    );
  }

  Future<void> clearAll() async {
    final db = await _db;
    await db.delete('insights', where: 'user_id = ?', whereArgs: [1]);
  }
}
