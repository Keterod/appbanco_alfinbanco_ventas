import 'package:sqflite/sqflite.dart';

import '../storage/local_db.dart';
import 'sync_models.dart';

/// DataSource SQLite para la cola de sincronización.
/// Operaciones sobre `sync_outbox` y `sync_log`.
class SyncLocalDataSource {
  SyncLocalDataSource._();
  static final SyncLocalDataSource instance = SyncLocalDataSource._();

  // ─── outbox ───────────────────────────────────────────────────────

  Future<void> enqueue(SyncOutboxEntry entry) async {
    final db = await LocalDb.database;
    await db.insert(
      'sync_outbox',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<SyncOutboxEntry>> getPending({int limit = 20}) async {
    final db = await LocalDb.database;
    final rows = await db.query(
      'sync_outbox',
      where: 'status = ? OR (status = ? AND retry_count < 3)',
      whereArgs: [SyncStatus.pending, SyncStatus.failed],
      orderBy: 'created_at ASC',
      limit: limit,
    );
    return rows.map((r) => SyncOutboxEntry.fromMap(r)).toList();
  }

  Future<int> getPendingCount() async {
    final db = await LocalDb.database;
    final count = Sqflite.firstIntValue(await db.rawQuery(
      "SELECT COUNT(*) FROM sync_outbox WHERE status = 'pending' OR (status = 'failed' AND retry_count < 3)",
    ));
    return count ?? 0;
  }

  Future<void> markProcessing(String id) async {
    final db = await LocalDb.database;
    await db.update(
      'sync_outbox',
      {
        'status': SyncStatus.processing,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markSynced(String id) async {
    final db = await LocalDb.database;
    await db.update(
      'sync_outbox',
      {
        'status': SyncStatus.synced,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markFailed(String id, String error) async {
    final db = await LocalDb.database;
    final entry = await _getById(id);
    final retryCount = (entry?.retryCount ?? 0) + 1;
    final newStatus =
        retryCount >= 3 ? SyncStatus.failed : SyncStatus.pending;
    await db.update(
      'sync_outbox',
      {
        'status': newStatus,
        'retry_count': retryCount,
        'last_error': error,
        'updated_at': DateTime.now().toIso8601String(),
        'next_retry_at': retryCount < 3
            ? DateTime.now()
                .add(const Duration(minutes: 5))
                .toIso8601String()
            : null,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteSyncedOlderThan(Duration age) async {
    final db = await LocalDb.database;
    final cutoff = DateTime.now().subtract(age).toIso8601String();
    await db.delete(
      'sync_outbox',
      where: "status = ? AND updated_at < ?",
      whereArgs: [SyncStatus.synced, cutoff],
    );
  }

  Future<SyncOutboxEntry?> _getById(String id) async {
    final db = await LocalDb.database;
    final rows = await db.query(
      'sync_outbox',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return SyncOutboxEntry.fromMap(rows.first);
  }

  // ─── log ──────────────────────────────────────────────────────────

  Future<void> writeLog(SyncLogEntry log) async {
    final db = await LocalDb.database;
    await db.insert(
      'sync_log',
      log.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<SyncLogEntry>> getLogsForOutbox(String outboxId) async {
    final db = await LocalDb.database;
    final rows = await db.query(
      'sync_log',
      where: 'outbox_id = ?',
      whereArgs: [outboxId],
      orderBy: 'created_at ASC',
    );
    return rows.map((r) => SyncLogEntry.fromMap(r)).toList();
  }

  Future<void> deleteLogsOlderThan(Duration age) async {
    final db = await LocalDb.database;
    final cutoff = DateTime.now().subtract(age).toIso8601String();
    await db.delete(
      'sync_log',
      where: 'created_at < ?',
      whereArgs: [cutoff],
    );
  }
}
