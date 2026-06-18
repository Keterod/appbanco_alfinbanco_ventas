import 'package:sqflite/sqflite.dart';

import '../../../core/storage/local_db.dart';

/// DataSource SQLite para persistir estado visitado de ruta.
/// Tabla `visitas_pendientes`.
class VisitasLocalDataSource {
  VisitasLocalDataSource._();
  static final VisitasLocalDataSource instance = VisitasLocalDataSource._();

  /// Guarda o actualiza el estado de una visita.
  Future<void> saveVisitaEstado({
    required String visitaId,
    required String carteraId,
    required String resultado,
    String? observacion,
    double? lat,
    double? lng,
  }) async {
    final db = await LocalDb.database;
    await db.insert(
      'visitas_pendientes',
      {
        'id': visitaId,
        'cartera_id': carteraId,
        'resultado': resultado,
        'observacion': observacion,
        'timestamp_visita': DateTime.now().toIso8601String(),
        'lat': lat,
        'lng': lng,
        'pendiente_sync': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Carga todos los estados guardados de visitas.
  Future<Map<String, String>> loadAllEstados() async {
    final db = await LocalDb.database;
    final rows = await db.query('visitas_pendientes');
    return {
      for (final row in rows)
        (row['cartera_id'] ?? '').toString(): (row['resultado'] ?? 'pendiente').toString(),
    };
  }

  /// Elimina el registro de una visita específica.
  Future<void> deleteVisita(String visitaId) async {
    final db = await LocalDb.database;
    await db.delete(
      'visitas_pendientes',
      where: 'id = ?',
      whereArgs: [visitaId],
    );
  }

  /// Limpia todos los registros de visitas.
  Future<void> clearAll() async {
    final db = await LocalDb.database;
    await db.delete('visitas_pendientes');
  }
}
