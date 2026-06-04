/// Estado de una solicitud en el tablero.
enum RequestStatus {
  enviada('Enviada'),
  enComite('En comité'),
  enEvaluacion('En evaluación'),
  aprobada('Aprobada'),
  condicionada('Condicionada'),
  rechazada('Rechazada'),
  desembolsada('Desembolsada');

  const RequestStatus(this.label);
  final String label;
}

/// Evento de la línea de tiempo.
class RequestTimelineItem {
  const RequestTimelineItem({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.responsable,
    required this.fechaHora,
    required this.completado,
    required this.estado,
  });

  final String id;
  final String titulo;
  final String descripcion;
  final String responsable;
  final DateTime fechaHora;
  final bool completado;
  final RequestStatus estado;
}

/// Solicitud con estado y seguimiento (HU-V07).
class RequestStatusModel {
  const RequestStatusModel({
    required this.id,
    required this.numeroExpediente,
    required this.clienteNombre,
    required this.documento,
    required this.montoSolicitado,
    this.montoAprobado,
    required this.fechaEnvio,
    required this.diasDesdeEnvio,
    required this.analistaAsignado,
    required this.estado,
    this.motivoRechazo,
    this.condicionAdicional,
    required this.timeline,
    this.solicitudLocalId,
  });

  final String id;
  final String numeroExpediente;
  final String clienteNombre;
  final String documento;
  final double montoSolicitado;
  final double? montoAprobado;
  final DateTime fechaEnvio;
  final int diasDesdeEnvio;
  final String analistaAsignado;
  final RequestStatus estado;
  final String? motivoRechazo;
  final String? condicionAdicional;
  final List<RequestTimelineItem> timeline;

  /// Referencia local del flujo (ej. ALF-LOCAL-0001).
  final String? solicitudLocalId;

  bool matchesReference(String? reference) {
    if (reference == null || reference.isEmpty) return false;
    return id == reference ||
        numeroExpediente == reference ||
        solicitudLocalId == reference;
  }
}
