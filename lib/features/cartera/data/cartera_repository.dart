import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../../../core/supabase/supabase_client.dart';
import '../../../core/supabase/supabase_helper.dart';
import '../../auth/data/asesor_repository.dart';
import '../domain/client_portfolio_model.dart';
import 'cartera_local_datasource.dart';

/// Repositorio de cartera diaria desde Supabase con fallback SQLite.
class CarteraRepository {
  CarteraRepository._();
  static final CarteraRepository instance = CarteraRepository._();

  /// Fuente de la última carga: 'live', 'offline', 'demo'
  String lastSource = 'live';

  Future<List<ClientPortfolioModel>> loadCarteraDiaria() async {
    debugPrint('[CARTERA] ===== loadCarteraDiaria iniciado =====');

    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    debugPrint('[CARTERA] fecha buscada=$todayStr');

    if (!SupabaseHelper.hasSession) {
      debugPrint('[CARTERA] sin sesión activa → SQLite');
      return _loadFromSqlite(todayStr);
    }

    // Verificar conectividad antes de llamar a Supabase
    final connectivityResult = await Connectivity().checkConnectivity();
    debugPrint('[CARTERA] connectivityResult=$connectivityResult');
    // BUGFIX: empty list (común en desktop/emuladores) debe tratarse como online
    final hasConnectivity = connectivityResult.isEmpty ||
        connectivityResult.any((r) => r != ConnectivityResult.none);
    if (!hasConnectivity) {
      debugPrint('[CARTERA] sin conexión de red confirmada → SQLite');
      return _loadFromSqlite(todayStr);
    }

    try {
      final asesor = await AsesorRepository.instance.requireCurrentAsesor();
      debugPrint('[CARTERA] source=supabase asesorId=${asesor.id} fecha=$todayStr');

      final response = await SupabaseHelper.withTimeout(
        supabase
            .from('cartera_diaria')
            .select()
            .eq('asesor_id', asesor.id)
            .eq('fecha_asignacion', todayStr)
            .order('orden_manual', ascending: true),
        operation: 'cartera_diaria hoy',
      );

      debugPrint('[CARTERA] supabase response rows=${response.length}');
      if (response.isNotEmpty) {
        debugPrint('[CARTERA] primera fila sample=${response.first}');
      }

      List<Map<String, dynamic>> carteraRows = response;

      if (carteraRows.isEmpty) {
        debugPrint('[CARTERA] hoy vacío, consultando histórico del asesor');
        final historico = await SupabaseHelper.withTimeout(
          supabase
              .from('cartera_diaria')
              .select()
              .eq('asesor_id', asesor.id)
              .order('orden_manual', ascending: true),
          operation: 'cartera_diaria all',
        );
        debugPrint('[CARTERA] histórico rows=${historico.length}');
        carteraRows = historico;
      }

      List<ClientPortfolioModel> result = [];
      if (carteraRows.isNotEmpty) {
        final clienteIds = carteraRows
            .map((r) => r['cliente_id']?.toString())
            .whereType<String>()
            .where((id) => id.isNotEmpty)
            .toSet()
            .toList();
        debugPrint('[CARTERA] clienteIds a buscar=${clienteIds.length}');

        final clientesById = await _loadClientesMap(clienteIds);
        debugPrint('[CARTERA] clientes encontrados=${clientesById.length}');

        result = carteraRows
            .map((row) => _mapRow(row, clientesById))
            .whereType<ClientPortfolioModel>()
            .toList();
        debugPrint('[CARTERA] modelos mapeados=${result.length}');
      }

      // Cachear en SQLite si hay datos (no fatal si falla)
      if (result.isNotEmpty) {
        try {
          await CarteraLocalDataSource.instance
              .saveCartera(result, asesor.id, todayStr);
          debugPrint('[CARTERA] cache SQLite guardado (${result.length} registros)');
        } catch (e) {
          debugPrint('[CARTERA] warning: cache SQLite falló pero Supabase OK: $e');
        }
      } else {
        debugPrint('[CARTERA] resultado vacío, NO se cachea en SQLite');
      }

      lastSource = 'live';
      debugPrint('[CARTERA] lastSource=live → devolviendo ${result.length} registros');
      return result;
    } catch (error, stackTrace) {
      debugPrint('[CARTERA] supabase error=$error');
      debugPrint('[CARTERA] supabase stackTrace=$stackTrace');
      SupabaseHelper.log('cartera load falló, intentando offline');
      SupabaseHelper.logError(error, stackTrace);
      return _loadFromSqlite(todayStr);
    }
  }

  Future<List<ClientPortfolioModel>> _loadFromSqlite(String fecha) async {
    final asesor = AsesorRepository.instance.current;
    if (asesor == null) {
      lastSource = 'demo';
      debugPrint('[CARTERA] sqlite fallback: sin asesor → demo');
      throw StateError('Sin sesión activa.');
    }
    final hasData =
        await CarteraLocalDataSource.instance.hasCartera(asesor.id, fecha);
    if (!hasData) {
      lastSource = 'demo';
      debugPrint('[CARTERA] sqlite fallback: sin datos en cache → demo');
      throw StateError('Sin datos offline');
    }
    final cached = await CarteraLocalDataSource.instance.loadCartera(asesor.id, fecha);
    debugPrint('[CARTERA] sqlite rows=${cached.length}');
    lastSource = 'offline';
    debugPrint('[CARTERA] lastSource=offline → devolviendo ${cached.length} registros');
    return cached;
  }

  Future<Map<String, Map<String, dynamic>>> _loadClientesMap(
    List<String> ids,
  ) async {
    if (ids.isEmpty) return {};

    try {
      final rows = await SupabaseHelper.withTimeout(
        supabase.from('clientes').select().inFilter('id', ids),
        operation: 'clientes',
      );
      debugPrint('[CARTERA] _loadClientesMap rows=${rows.length}');

      return {
        for (final row in rows)
          if (row['id'] != null) row['id'].toString(): row,
      };
    } catch (e) {
      debugPrint('[CARTERA] _loadClientesMap error=$e');
      return {};
    }
  }

  ClientPortfolioModel? _mapRow(
    Map<String, dynamic> row,
    Map<String, Map<String, dynamic>> clientesById,
  ) {
    final clienteId = row['cliente_id']?.toString();
    if (clienteId == null || clienteId.isEmpty) {
      debugPrint('[CARTERA] _mapRow: clienteId nulo o vacío → skip');
      return null;
    }

    final cliente = clientesById[clienteId];
    final nombres = cliente?['nombres']?.toString() ?? '';
    final apellidos = cliente?['apellidos']?.toString() ?? '';
    final nombre = '$nombres $apellidos'.trim();

    return ClientPortfolioModel(
      id: clienteId,
      clientName: nombre.isNotEmpty ? nombre : 'Cliente',
      numeroDocumento: cliente?['numero_documento']?.toString(),
      managementType: row['tipo_gestion']?.toString() ?? 'Gestión',
      prioridad: row['prioridad']?.toString() ?? 'normal',
      scorePrioridad: _toInt(row['score_prioridad']),
      status: row['estado_visita']?.toString() ?? 'Pendiente',
      address: cliente?['direccion']?.toString(),
      amount: _toDouble(cliente?['ingresos_estimados']),
      lat: _toDouble(cliente?['lat'] ?? row['lat']),
      lng: _toDouble(cliente?['lng'] ?? row['lng']),
    );
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
