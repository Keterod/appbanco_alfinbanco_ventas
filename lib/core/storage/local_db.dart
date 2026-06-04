import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Singleton de la base de datos SQLite local.
/// Gestiona inicialización y migraciones.
class LocalDb {
  static Database? _db;

  static Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'alfinbanco.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    // Cola offline: visitas pendientes de sincronizar
    await db.execute('''
      CREATE TABLE visitas_pendientes (
        id TEXT PRIMARY KEY,
        cartera_id TEXT NOT NULL,
        resultado TEXT NOT NULL,
        observacion TEXT,
        timestamp_visita TEXT NOT NULL,
        lat REAL,
        lng REAL,
        pendiente_sync INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Borradores de solicitudes de crédito
    await db.execute('''
      CREATE TABLE solicitudes_borrador (
        id TEXT PRIMARY KEY,
        cliente_id TEXT,
        cliente_nombre TEXT,
        paso_actual INTEGER NOT NULL DEFAULT 1,
        datos_json TEXT NOT NULL,
        monto_solicitado REAL,
        asesor_id TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Cache de cartera diaria para modo offline
    await db.execute('''
      CREATE TABLE cartera_cache (
        id TEXT PRIMARY KEY,
        asesor_id TEXT NOT NULL,
        cliente_id TEXT NOT NULL,
        cliente_nombre TEXT NOT NULL,
        numero_documento TEXT,
        tipo_gestion TEXT NOT NULL,
        prioridad TEXT NOT NULL,
        score_prioridad INTEGER NOT NULL DEFAULT 0,
        estado_visita TEXT NOT NULL DEFAULT "pendiente",
        monto_credito REAL,
        direccion TEXT,
        fecha_asignacion TEXT NOT NULL,
        orden_manual INTEGER,
        lat REAL,
        lng REAL
      )
    ''');

    // Orden manual de visitas del asesor
    await db.execute('''
      CREATE TABLE cartera_orden_local (
        id TEXT PRIMARY KEY,
        cartera_id TEXT NOT NULL,
        orden INTEGER NOT NULL,
        fecha TEXT NOT NULL
      )
    ''');
  }
}
