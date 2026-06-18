import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'local_db.dart';

/// DataSource SQLite para borradores de solicitud.
/// Tabla `solicitudes_borrador`.
class BorradorLocalDataSource {
  BorradorLocalDataSource._();
  static final BorradorLocalDataSource instance = BorradorLocalDataSource._();

  /// Serializa el estado actual del formulario a la tabla de borradores.
  Future<void> saveBorrador({
    required String asesorId,
    String? clienteId,
    String? clienteNombre,
    required int pasoActual,
    required Map<String, dynamic> formData,
    double? montoSolicitado,
  }) async {
    final db = await LocalDb.database;
    final id = clienteId ?? 'default';
    await db.insert(
      'solicitudes_borrador',
      {
        'id': id,
        'cliente_id': clienteId,
        'cliente_nombre': clienteNombre,
        'paso_actual': pasoActual,
        'datos_json': jsonEncode(formData),
        'monto_solicitado': montoSolicitado,
        'asesor_id': asesorId,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Carga un borrador previo.
  Future<Map<String, dynamic>?> loadBorrador({
    String? clienteId,
  }) async {
    final db = await LocalDb.database;
    final id = clienteId ?? 'default';
    final rows = await db.query(
      'solicitudes_borrador',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final row = rows.first;
    return {
      'id': row['id'],
      'cliente_id': row['cliente_id'],
      'cliente_nombre': row['cliente_nombre'],
      'paso_actual': row['paso_actual'],
      'datos_json': jsonDecode(row['datos_json'] as String) as Map<String, dynamic>,
      'monto_solicitado': row['monto_solicitado'],
      'asesor_id': row['asesor_id'],
      'updated_at': row['updated_at'],
    };
  }

  /// Elimina el borrador tras enviar la solicitud.
  Future<void> deleteBorrador({String? clienteId}) async {
    final db = await LocalDb.database;
    final id = clienteId ?? 'default';
    await db.delete(
      'solicitudes_borrador',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
