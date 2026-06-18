import '../../../core/supabase/supabase_client.dart';
import '../../../core/supabase/supabase_helper.dart';
import '../../auth/data/asesor_repository.dart';
import '../domain/request_status_model.dart';
import '../domain/request_status_mock_data.dart';

class EstadoSolicitudesRepository {
  EstadoSolicitudesRepository._();
  static final EstadoSolicitudesRepository instance =
      EstadoSolicitudesRepository._();

  Future<List<RequestStatusModel>> loadSolicitudes() async {
    SupabaseHelper.log('estado_solicitudes load iniciado');

    if (!SupabaseHelper.hasSession) {
      SupabaseHelper.log('estado_solicitudes sin sesión');
      return RequestStatusMockData.all();
    }

    try {
      final asesor = await AsesorRepository.instance.requireCurrentAsesor();
      SupabaseHelper.log('estado_solicitudes asesor_id=${asesor.id}');

      final rows = await SupabaseHelper.withTimeout(
        supabase
            .from('solicitudes_credito')
            .select('*, clientes!left(nombres, apellidos, numero_documento)')
            .eq('asesor_id', asesor.id)
            .order('created_at', ascending: false),
        operation: 'solicitudes_credito lista',
      );

      if (rows.isEmpty) {
        SupabaseHelper.log('estado_solicitudes vacío, fallback mock');
        return RequestStatusMockData.all();
      }

      return rows.map((row) => _mapRow(row)).toList();
    } catch (error, stackTrace) {
      SupabaseHelper.log('estado_solicitudes falló, fallback mock');
      SupabaseHelper.logError(error, stackTrace);
      return RequestStatusMockData.all();
    }
  }

  Future<RequestStatusModel?> loadSolicitudById(String id) async {
    SupabaseHelper.log('estado_solicitud detalle id=$id');

    if (!SupabaseHelper.hasSession) {
      return null;
    }

    try {
      final asesor = await AsesorRepository.instance.requireCurrentAsesor();

      final row = await SupabaseHelper.withTimeout(
        supabase
            .from('solicitudes_credito')
            .select('*, clientes!left(nombres, apellidos, numero_documento)')
            .eq('id', id)
            .eq('asesor_id', asesor.id)
            .maybeSingle(),
        operation: 'solicitudes_credito detalle',
      );

      if (row == null) return null;

      return _mapRow(row);
    } catch (error, stackTrace) {
      SupabaseHelper.logError(error, stackTrace);
      return null;
    }
  }

  Future<RequestStatusModel?> loadSolicitudByExpediente(
      String expediente) async {
    if (!SupabaseHelper.hasSession) return null;

    try {
      final row = await SupabaseHelper.withTimeout(
        supabase
            .from('solicitudes_credito')
            .select('*, clientes!left(nombres, apellidos, numero_documento)')
            .eq('numero_expediente', expediente)
            .maybeSingle(),
        operation: 'solicitudes_credito por expediente',
      );

      if (row == null) return null;

      return _mapRow(row);
    } catch (error, stackTrace) {
      SupabaseHelper.logError(error, stackTrace);
      return null;
    }
  }

  RequestStatusModel _mapRow(Map<String, dynamic> row) {
    final clientes = row['clientes'] as Map<String, dynamic>?;
    final nombres = clientes?['nombres']?.toString() ?? '';
    final apellidos = clientes?['apellidos']?.toString() ?? '';
    final clienteNombre = '$nombres $apellidos'.trim();
    final documento = clientes?['numero_documento']?.toString() ?? '';
    final montoSolicitado = _toDouble(row['monto_solicitado']) ?? 0;
    final montoAprobado = _toDouble(row['monto_aprobado']);
    final createdAt = _parseDateTime(row['created_at']);
    final estadoStr = row['estado']?.toString() ?? 'enviada';

    final estado = _parseEstado(estadoStr);

    final timeline = _buildTimeline(
      estado: estado,
      createdAt: createdAt,
      row: row,
    );

    final diasDesdeEnvio = createdAt != null
        ? DateTime.now().difference(createdAt).inDays
        : 0;

    return RequestStatusModel(
      id: row['id']?.toString() ?? '',
      numeroExpediente:
          row['numero_expediente']?.toString() ?? 'SIN-EXP',
      clienteNombre: clienteNombre.isNotEmpty ? clienteNombre : 'Cliente',
      documento: documento,
      montoSolicitado: montoSolicitado,
      montoAprobado: montoAprobado,
      fechaEnvio: createdAt ?? DateTime.now(),
      diasDesdeEnvio: diasDesdeEnvio,
      analistaAsignado: row['analista_asignado']?.toString() ?? '—',
      estado: estado,
      motivoRechazo: row['motivo_rechazo']?.toString(),
      condicionAdicional: row['condicion_adicional']?.toString(),
      timeline: timeline,
      solicitudLocalId: row['solicitud_local_id']?.toString(),
    );
  }

  List<RequestTimelineItem> _buildTimeline({
    required RequestStatus estado,
    required DateTime? createdAt,
    required Map<String, dynamic> row,
  }) {
    final base = createdAt ?? DateTime.now();
    final items = <RequestTimelineItem>[
      RequestTimelineItem(
        id: 'tl-1',
        titulo: 'Solicitud registrada',
        descripcion: 'Registro en canal oficial de ventas.',
        responsable: row['asesor_id']?.toString() ?? 'Oficial de crédito',
        fechaHora: base,
        completado: true,
        estado: RequestStatus.enviada,
      ),
    ];

    final updatedAt = _parseDateTime(row['updated_at']);
    final estadoActual = estado;

    if (estadoActual.index >= RequestStatus.enComite.index) {
      items.add(RequestTimelineItem(
        id: 'tl-2',
        titulo: 'Enviada a comité',
        descripcion: 'Asignación al comité de evaluación.',
        responsable: 'Mesa de entrada',
        fechaHora: updatedAt ?? base.add(const Duration(hours: 4)),
        completado: true,
        estado: RequestStatus.enComite,
      ));
    }

    if (estadoActual.index >= RequestStatus.enEvaluacion.index) {
      items.add(RequestTimelineItem(
        id: 'tl-3',
        titulo: 'En evaluación',
        descripcion: 'Análisis de riesgo y capacidad de pago.',
        responsable: 'Analista crediticio',
        fechaHora: updatedAt ?? base.add(const Duration(days: 1)),
        completado: true,
        estado: RequestStatus.enEvaluacion,
      ));
    }

    if (estadoActual == RequestStatus.rechazada) {
      items.add(RequestTimelineItem(
        id: 'tl-4',
        titulo: 'Rechazada',
        descripcion: row['motivo_rechazo']?.toString() ??
            'No cumple política vigente.',
        responsable: 'Comité de crédito',
        fechaHora: updatedAt ?? base.add(const Duration(days: 2)),
        completado: true,
        estado: RequestStatus.rechazada,
      ));
    } else if (estadoActual == RequestStatus.condicionada) {
      items.add(RequestTimelineItem(
        id: 'tl-4',
        titulo: 'Condicionada',
        descripcion: 'Aprobación sujeta a condiciones.',
        responsable: 'Comité de crédito',
        fechaHora: updatedAt ?? base.add(const Duration(days: 2)),
        completado: true,
        estado: RequestStatus.condicionada,
      ));
    } else if (estadoActual.index >= RequestStatus.aprobada.index) {
      items.add(RequestTimelineItem(
        id: 'tl-4',
        titulo: 'Aprobada',
        descripcion: 'Resolución favorable del comité.',
        responsable: 'Comité de crédito',
        fechaHora: updatedAt ?? base.add(const Duration(days: 2)),
        completado: true,
        estado: RequestStatus.aprobada,
      ));
    }

    if (estadoActual == RequestStatus.desembolsada) {
      items.add(RequestTimelineItem(
        id: 'tl-5',
        titulo: 'Desembolsada',
        descripcion: 'Abono de fondos al cliente.',
        responsable: 'Operaciones',
        fechaHora: updatedAt ?? base.add(const Duration(days: 4)),
        completado: true,
        estado: RequestStatus.desembolsada,
      ));
    }

    return items;
  }

  RequestStatus _parseEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'enviada':
        return RequestStatus.enviada;
      case 'en_comite':
      case 'en comité':
      case 'en comite':
        return RequestStatus.enComite;
      case 'en_evaluacion':
      case 'en evaluación':
      case 'en evaluacion':
        return RequestStatus.enEvaluacion;
      case 'aprobada':
        return RequestStatus.aprobada;
      case 'condicionada':
        return RequestStatus.condicionada;
      case 'rechazada':
        return RequestStatus.rechazada;
      case 'desembolsada':
        return RequestStatus.desembolsada;
      default:
        return RequestStatus.enviada;
    }
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
