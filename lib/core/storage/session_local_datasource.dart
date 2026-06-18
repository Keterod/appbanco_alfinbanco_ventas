import 'package:sqflite/sqflite.dart';

import 'local_db.dart';

/// Cache local de datos mínimos del asesor autenticado.
/// Usa la tabla `asesor_cache` (key/value) en SQLite.
/// No guarda contraseñas ni datos sensibles.
class SessionLocalDataSource {
  SessionLocalDataSource._();
  static final SessionLocalDataSource instance = SessionLocalDataSource._();

  Future<void> saveAsesorSession(Map<String, String> data) async {
    final db = await LocalDb.database;
    final batch = db.batch();
    for (final entry in data.entries) {
      batch.insert(
        'asesor_cache',
        {'key': 'asesor_${entry.key}', 'value': entry.value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    batch.insert(
      'asesor_cache',
      {'key': 'asesor_cache_version', 'value': '1'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await batch.commit(noResult: true);
  }

  Future<Map<String, String>> loadAsesorSession() async {
    final db = await LocalDb.database;
    final rows = await db.query(
      'asesor_cache',
      where: "key LIKE 'asesor_%'",
    );
    final result = <String, String>{};
    for (final row in rows) {
      final key = (row['key'] as String?)?.replaceFirst('asesor_', '') ?? '';
      final value = (row['value'] as String?) ?? '';
      if (key.isNotEmpty) {
        result[key] = value;
      }
    }
    return result;
  }

  Future<bool> hasCachedSession() async {
    final db = await LocalDb.database;
    final rows = await db.rawQuery(
      "SELECT COUNT(*) AS cnt FROM asesor_cache WHERE key = 'asesor_cache_version'",
    );
    final count = (rows.isNotEmpty ? rows.first['cnt'] : 0) as int? ?? 0;
    return count > 0;
  }

  Future<void> clearAsesorSession() async {
    final db = await LocalDb.database;
    await db.delete('asesor_cache', where: "key LIKE 'asesor_%'");
  }
}