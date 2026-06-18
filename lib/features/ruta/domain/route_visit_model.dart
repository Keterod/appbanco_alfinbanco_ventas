/// Prioridad de visita en la ruta.
enum RoutePriority {
  alta('Alta'),
  media('Media'),
  normal('Normal');

  const RoutePriority(this.label);
  final String label;

  int get sortOrder => switch (this) {
        RoutePriority.alta => 0,
        RoutePriority.media => 1,
        RoutePriority.normal => 2,
      };
}

/// Estado de la visita en ruta.
enum RouteVisitStatus {
  pendiente('Pendiente'),
  visitado('Visitado');

  const RouteVisitStatus(this.label);
  final String label;
}

/// Tipo de gestión en la visita.
enum RouteManagementType {
  renovacion('Renovación'),
  nuevaSolicitud('Nueva solicitud'),
  cobranza('Cobranza'),
  seguimiento('Seguimiento'),
  ampliacion('Ampliación');

  const RouteManagementType(this.label);
  final String label;
}

/// Visita planificada en la ruta diaria (HU-V09).
class RouteVisitModel {
  const RouteVisitModel({
    required this.id,
    required this.clientId,
    required this.clienteNombre,
    this.documento,
    required this.direccion,
    required this.tipoGestion,
    required this.prioridad,
    required this.estadoVisita,
    required this.lat,
    required this.lng,
    required this.distanciaKm,
    required this.tiempoEstimadoMin,
    required this.ordenSugerido,
  });

  final String id;
  final String clientId;
  final String clienteNombre;
  final String? documento;
  final String direccion;
  final RouteManagementType tipoGestion;
  final RoutePriority prioridad;
  final RouteVisitStatus estadoVisita;
  final double lat;
  final double lng;
  final double distanciaKm;
  final int tiempoEstimadoMin;
  final int ordenSugerido;

  bool get isPendiente => estadoVisita == RouteVisitStatus.pendiente;
  bool get isVisitado => estadoVisita == RouteVisitStatus.visitado;

  RouteVisitModel copyWith({
    RouteVisitStatus? estadoVisita,
    int? ordenSugerido,
    double? distanciaKm,
    int? tiempoEstimadoMin,
  }) {
    return RouteVisitModel(
      id: id,
      clientId: clientId,
      clienteNombre: clienteNombre,
      documento: documento,
      direccion: direccion,
      tipoGestion: tipoGestion,
      prioridad: prioridad,
      estadoVisita: estadoVisita ?? this.estadoVisita,
      lat: lat,
      lng: lng,
      distanciaKm: distanciaKm ?? this.distanciaKm,
      tiempoEstimadoMin: tiempoEstimadoMin ?? this.tiempoEstimadoMin,
      ordenSugerido: ordenSugerido ?? this.ordenSugerido,
    );
  }
}
