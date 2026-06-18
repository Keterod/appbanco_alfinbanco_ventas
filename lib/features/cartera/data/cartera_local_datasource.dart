import 'package:sqflite/sqflite.dart';

import '../../../core/storage/local_db.dart';
import '../domain/client_portfolio_model.dart';

/// DataSource SQLite para cartera diaria offline.
/// Operaciones CRUD sobre la tabla `cartera_cache`.
class CarteraLocalDataSource {
  CarteraLocalDataSource._();
  static final CarteraLocalDataSource instance = CarteraLocalDataSource._();

  Future<void> saveCartera(
    List<ClientPortfolioModel> clients,
    String asesorId,
    String fecha,
  ) async {
    final db = await LocalDb.database;
    final batch = db.batch();

    // Limpiar cache previo del mismo asesor + fecha
    batch.delete('cartera_cache',
        where: 'asesor_id = ? AND fecha_asignacion = ?',
        whereArgs: [asesorId, fecha]);

    for (var i = 0; i < clients.length; i++) {
      final c = clients[i];
      batch.insert(
        'cartera_cache',
        {
          'id': '${asesorId}_${c.id}_$i',
          'asesor_id': asesorId,
          ...c.toMap(),
          'fecha_asignacion': fecha,
          'orden_manual': i,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<List<ClientPortfolioModel>> loadCartera(
    String asesorId,
    String fecha,
  ) async {
    final db = await LocalDb.database;
    final rows = await db.query(
      'cartera_cache',
      where: 'asesor_id = ? AND fecha_asignacion = ?',
      whereArgs: [asesorId, fecha],
      orderBy: 'orden_manual ASC',
    );
    return rows.map((r) => ClientPortfolioModel.fromMap(r)).toList();
  }

  Future<void> clearCartera(String asesorId, String fecha) async {
    final db = await LocalDb.database;
    await db.delete(
      'cartera_cache',
      where: 'asesor_id = ? AND fecha_asignacion = ?',
      whereArgs: [asesorId, fecha],
    );
  }

  Future<bool> hasCartera(String asesorId, String fecha) async {
    final db = await LocalDb.database;
    final count = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM cartera_cache WHERE asesor_id = ? AND fecha_asignacion = ?',
      [asesorId, fecha],
    ));
    return (count ?? 0) > 0;
  }

  Future<void> updateEstadoVisita(
    String asesorId,
    String clienteId,
    String nuevoEstado,
  ) async {
    final db = await LocalDb.database;
    await db.update(
      'cartera_cache',
      {'estado_visita': nuevoEstado},
      where: 'asesor_id = ? AND cliente_id = ?',
      whereArgs: [asesorId, clienteId],
    );
  }
}
