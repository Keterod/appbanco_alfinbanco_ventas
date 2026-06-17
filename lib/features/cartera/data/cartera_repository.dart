import '../../../core/supabase/supabase_client.dart';
import '../../../core/supabase/supabase_helper.dart';
import '../../auth/data/asesor_repository.dart';
import '../domain/client_portfolio_model.dart';

/// Repositorio de cartera diaria desde Supabase.
class CarteraRepository {
  CarteraRepository._();
  static final CarteraRepository instance = CarteraRepository._();

  Future<List<ClientPortfolioModel>> loadCarteraDiaria() async {
    SupabaseHelper.log('cartera load iniciado');

    if (!SupabaseHelper.hasSession) {
      SupabaseHelper.log('cartera sin sesión');
      throw StateError('Sin sesión activa.');
    }

    try {
      final asesor = await AsesorRepository.instance.requireCurrentAsesor();
      SupabaseHelper.log('cartera asesor_id=${asesor.id}');

      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      var query = supabase
          .from('cartera_diaria')
          .select()
          .eq('asesor_id', asesor.id)
          .eq('fecha_asignacion', todayStr)
          .order('orden_manual', ascending: true);

      var carteraRows = await SupabaseHelper.withTimeout(
        query,
        operation: 'cartera_diaria hoy',
      );

      if (carteraRows.isEmpty) {
        SupabaseHelper.log('cartera hoy vacía, cargando histórico del asesor');
        carteraRows = await SupabaseHelper.withTimeout(
          supabase
              .from('cartera_diaria')
              .select()
              .eq('asesor_id', asesor.id)
              .order('orden_manual', ascending: true),
          operation: 'cartera_diaria all',
        );
      }

      SupabaseHelper.log('cartera rows=${carteraRows.length}');

      if (carteraRows.isEmpty) return [];

      final clienteIds = carteraRows
          .map((r) => r['cliente_id']?.toString())
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      final clientesById = await _loadClientesMap(clienteIds);

      return carteraRows
          .map((row) => _mapRow(row, clientesById))
          .whereType<ClientPortfolioModel>()
          .toList();
    } catch (error, stackTrace) {
      SupabaseHelper.log('cartera load falló');
      SupabaseHelper.logError(error, stackTrace);
      rethrow;
    }
  }

  Future<Map<String, Map<String, dynamic>>> _loadClientesMap(
    List<String> ids,
  ) async {
    if (ids.isEmpty) return {};

    final rows = await SupabaseHelper.withTimeout(
      supabase.from('clientes').select().inFilter('id', ids),
      operation: 'clientes',
    );

    return {
      for (final row in rows)
        if (row['id'] != null) row['id'].toString(): row,
    };
  }

  ClientPortfolioModel? _mapRow(
    Map<String, dynamic> row,
    Map<String, Map<String, dynamic>> clientesById,
  ) {
    final clienteId = row['cliente_id']?.toString();
    if (clienteId == null || clienteId.isEmpty) return null;

    final cliente = clientesById[clienteId];
    final nombres = cliente?['nombres']?.toString() ?? '';
    final apellidos = cliente?['apellidos']?.toString() ?? '';
    final nombre = '$nombres $apellidos'.trim();

    return ClientPortfolioModel(
      id: clienteId,
      clientName: nombre.isNotEmpty ? nombre : 'Cliente',
      managementType: row['tipo_gestion']?.toString() ?? 'Gestión',
      status: row['estado_visita']?.toString() ?? 'Pendiente',
      address: cliente?['direccion']?.toString(),
      amount: _toDouble(cliente?['ingresos_estimados']),
    );
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
