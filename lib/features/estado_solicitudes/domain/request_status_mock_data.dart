import 'request_status_model.dart';

/// Datos mock del tablero de solicitudes.
abstract final class RequestStatusMockData {
  static List<RequestStatusModel> all() => List.unmodifiable(_requests);

  static RequestStatusModel? findById(String id) {
    try {
      return _requests.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  static RequestStatusModel? findByExpediente(String expediente) {
    try {
      return _requests.firstWhere((r) => r.numeroExpediente == expediente);
    } catch (_) {
      return null;
    }
  }

  static RequestStatusModel? findByReference(String? reference) {
    if (reference == null || reference.isEmpty) return null;
    try {
      return _requests.firstWhere((r) => r.matchesReference(reference));
    } catch (_) {
      return null;
    }
  }

  static List<RequestTimelineItem> _baseTimeline({
    required RequestStatus current,
    required DateTime base,
    bool includeDesembolso = false,
    bool rejected = false,
    bool conditioned = false,
  }) {
    final items = <RequestTimelineItem>[
      RequestTimelineItem(
        id: 'tl-1',
        titulo: 'Solicitud enviada',
        descripcion: 'Registro en canal oficial de ventas.',
        responsable: 'Oficial de crédito',
        fechaHora: base,
        completado: true,
        estado: RequestStatus.enviada,
      ),
      RequestTimelineItem(
        id: 'tl-2',
        titulo: 'Recibida por comité',
        descripcion: 'Asignación al comité de evaluación.',
        responsable: 'Mesa de entrada',
        fechaHora: base.add(const Duration(hours: 4)),
        completado: current.index >= RequestStatus.enComite.index,
        estado: RequestStatus.enComite,
      ),
      RequestTimelineItem(
        id: 'tl-3',
        titulo: 'En evaluación',
        descripcion: 'Análisis de riesgo y capacidad de pago.',
        responsable: 'Analista crediticio',
        fechaHora: base.add(const Duration(days: 1)),
        completado: current.index >= RequestStatus.enEvaluacion.index,
        estado: RequestStatus.enEvaluacion,
      ),
    ];

    if (rejected) {
      items.add(
        RequestTimelineItem(
          id: 'tl-4',
          titulo: 'Rechazada',
          descripcion: 'Solicitud no cumple política vigente.',
          responsable: 'Comité de crédito',
          fechaHora: base.add(const Duration(days: 2)),
          completado: true,
          estado: RequestStatus.rechazada,
        ),
      );
      return items;
    }

    if (conditioned) {
      items.add(
        RequestTimelineItem(
          id: 'tl-4',
          titulo: 'Condicionada',
          descripcion: 'Aprobación sujeta a cumplimiento de condiciones.',
          responsable: 'Comité de crédito',
          fechaHora: base.add(const Duration(days: 2)),
          completado: true,
          estado: RequestStatus.condicionada,
        ),
      );
    } else if (current.index >= RequestStatus.aprobada.index) {
      items.add(
        RequestTimelineItem(
          id: 'tl-4',
          titulo: 'Aprobada',
          descripcion: 'Resolución favorable del comité.',
          responsable: 'Comité de crédito',
          fechaHora: base.add(const Duration(days: 2)),
          completado: true,
          estado: RequestStatus.aprobada,
        ),
      );
    } else {
      items.add(
        RequestTimelineItem(
          id: 'tl-4',
          titulo: 'Resolución del comité',
          descripcion: 'Pendiente de dictamen final.',
          responsable: 'Comité de crédito',
          fechaHora: base.add(const Duration(days: 2)),
          completado: false,
          estado: RequestStatus.aprobada,
        ),
      );
    }

    items.add(
      RequestTimelineItem(
        id: 'tl-5',
        titulo: 'Desembolsada',
        descripcion: 'Abono de fondos al cliente.',
        responsable: 'Operaciones',
        fechaHora: base.add(const Duration(days: 4)),
        completado: includeDesembolso,
        estado: RequestStatus.desembolsada,
      ),
    );

    return items;
  }

  static final List<RequestStatusModel> _requests = [
    RequestStatusModel(
      id: 'req-001',
      numeroExpediente: 'EXP-ALF-2026-0001',
      solicitudLocalId: 'ALF-LOCAL-0001',
      clienteNombre: 'Rosa Quispe',
      documento: '45678912',
      montoSolicitado: 12000,
      fechaEnvio: DateTime(2026, 6, 1, 10, 30),
      diasDesdeEnvio: 3,
      analistaAsignado: 'Lic. Patricia Mora',
      estado: RequestStatus.enEvaluacion,
      timeline: _baseTimeline(
        current: RequestStatus.enEvaluacion,
        base: DateTime(2026, 6, 1, 10, 30),
      ),
    ),
    RequestStatusModel(
      id: 'req-002',
      numeroExpediente: 'EXP-ALF-2026-0002',
      clienteNombre: 'Miguel Huamán',
      documento: '72345618',
      montoSolicitado: 18000,
      fechaEnvio: DateTime(2026, 5, 28, 9, 0),
      diasDesdeEnvio: 7,
      analistaAsignado: 'Lic. Jorge Salinas',
      estado: RequestStatus.enviada,
      timeline: _baseTimeline(
        current: RequestStatus.enviada,
        base: DateTime(2026, 5, 28, 9, 0),
      ),
    ),
    RequestStatusModel(
      id: 'req-003',
      numeroExpediente: 'EXP-ALF-2026-0003',
      clienteNombre: 'Carmen Flores',
      documento: '40123456',
      montoSolicitado: 3500,
      fechaEnvio: DateTime(2026, 5, 25, 14, 15),
      diasDesdeEnvio: 10,
      analistaAsignado: 'Lic. Patricia Mora',
      estado: RequestStatus.enComite,
      timeline: _baseTimeline(
        current: RequestStatus.enComite,
        base: DateTime(2026, 5, 25, 14, 15),
      ),
    ),
    RequestStatusModel(
      id: 'req-004',
      numeroExpediente: 'EXP-ALF-2026-0004',
      clienteNombre: 'José Ramos',
      documento: '10876543',
      montoSolicitado: 8000,
      montoAprobado: 7500,
      fechaEnvio: DateTime(2026, 5, 20, 11, 0),
      diasDesdeEnvio: 15,
      analistaAsignado: 'Lic. Andrea Vela',
      estado: RequestStatus.aprobada,
      timeline: _baseTimeline(
        current: RequestStatus.aprobada,
        base: DateTime(2026, 5, 20, 11, 0),
      ),
    ),
    RequestStatusModel(
      id: 'req-005',
      numeroExpediente: 'EXP-ALF-2026-0005',
      clienteNombre: 'Ana Torres',
      documento: '71234567',
      montoSolicitado: 25000,
      montoAprobado: 22000,
      fechaEnvio: DateTime(2026, 5, 18, 16, 45),
      diasDesdeEnvio: 17,
      analistaAsignado: 'Lic. Jorge Salinas',
      estado: RequestStatus.condicionada,
      condicionAdicional:
          'Presentar garantía prendaria actualizada en 5 días hábiles.',
      timeline: _baseTimeline(
        current: RequestStatus.condicionada,
        base: DateTime(2026, 5, 18, 16, 45),
        conditioned: true,
      ),
    ),
    RequestStatusModel(
      id: 'req-006',
      numeroExpediente: 'EXP-ALF-2026-0006',
      clienteNombre: 'Luis Mendoza',
      documento: '44556677',
      montoSolicitado: 6000,
      fechaEnvio: DateTime(2026, 5, 15, 8, 20),
      diasDesdeEnvio: 20,
      analistaAsignado: 'Lic. Andrea Vela',
      estado: RequestStatus.rechazada,
      motivoRechazo:
          'Capacidad de pago insuficiente según flujo de caja declarado.',
      timeline: _baseTimeline(
        current: RequestStatus.rechazada,
        base: DateTime(2026, 5, 15, 8, 20),
        rejected: true,
      ),
    ),
    RequestStatusModel(
      id: 'req-007',
      numeroExpediente: 'EXP-ALF-2026-0007',
      clienteNombre: 'Elena Rojas',
      documento: '33445566',
      montoSolicitado: 15000,
      montoAprobado: 15000,
      fechaEnvio: DateTime(2026, 5, 10, 13, 0),
      diasDesdeEnvio: 25,
      analistaAsignado: 'Lic. Patricia Mora',
      estado: RequestStatus.desembolsada,
      timeline: _baseTimeline(
        current: RequestStatus.desembolsada,
        base: DateTime(2026, 5, 10, 13, 0),
        includeDesembolso: true,
      ),
    ),
    RequestStatusModel(
      id: 'req-008',
      numeroExpediente: 'EXP-ALF-2026-0008',
      clienteNombre: 'Carlos Vega',
      documento: '22334455',
      montoSolicitado: 9500,
      montoAprobado: 9000,
      fechaEnvio: DateTime(2026, 5, 8, 10, 0),
      diasDesdeEnvio: 27,
      analistaAsignado: 'Lic. Jorge Salinas',
      estado: RequestStatus.desembolsada,
      timeline: _baseTimeline(
        current: RequestStatus.desembolsada,
        base: DateTime(2026, 5, 8, 10, 0),
        includeDesembolso: true,
      ),
    ),
  ];
}
