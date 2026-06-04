/// Tipo de gestión de cobranza.
enum CollectionManagementType {
  visita('Visita en campo'),
  llamada('Llamada telefónica'),
  mensaje('Mensaje / WhatsApp');

  const CollectionManagementType(this.label);
  final String label;
}

/// Resultado de la gestión de cobranza.
enum CollectionResult {
  compromisoPago('Compromiso de pago'),
  pagoParcial('Pago parcial'),
  sinContacto('Sin contacto'),
  seNiega('Cliente se niega');

  const CollectionResult(this.label);
  final String label;
}

/// Estado de gestión del cliente en mora.
enum CollectionStatus {
  pendiente('Pendiente'),
  gestionado('Gestionado'),
  compromisoVigente('Compromiso vigente');

  const CollectionStatus(this.label);
  final String label;
}

/// Prioridad según días de mora.
enum OverduePriority {
  preventiva('Preventiva'),
  prioritaria('Prioritaria'),
  urgente('Urgente');

  const OverduePriority(this.label);
  final String label;

  static OverduePriority fromDiasMora(int dias) {
    if (dias <= 30) return OverduePriority.preventiva;
    if (dias <= 60) return OverduePriority.prioritaria;
    return OverduePriority.urgente;
  }
}

/// Acción de cobranza registrada en campo.
class CollectionActionModel {
  const CollectionActionModel({
    required this.id,
    required this.clientId,
    required this.creditoId,
    required this.tipoGestion,
    required this.resultado,
    this.montoPagado,
    this.fechaCompromiso,
    this.montoCompromiso,
    required this.observaciones,
    required this.lat,
    required this.lng,
    required this.timestampGestion,
  });

  final String id;
  final String clientId;
  final String creditoId;
  final CollectionManagementType tipoGestion;
  final CollectionResult resultado;
  final double? montoPagado;
  final DateTime? fechaCompromiso;
  final double? montoCompromiso;
  final String observaciones;
  final double lat;
  final double lng;
  final DateTime timestampGestion;
}

/// Cliente con mora para recuperación de cartera (HU-V10).
class OverdueClientModel {
  const OverdueClientModel({
    required this.id,
    required this.clientId,
    required this.clienteNombre,
    required this.documento,
    required this.telefono,
    required this.direccion,
    required this.creditoId,
    required this.montoVencido,
    required this.diasMora,
    required this.fechaUltimoContacto,
    required this.fechaVencimientoCuota,
    required this.estadoGestion,
    required this.prioridad,
    this.acciones = const [],
  });

  final String id;
  final String clientId;
  final String clienteNombre;
  final String documento;
  final String telefono;
  final String direccion;
  final String creditoId;
  final double montoVencido;
  final int diasMora;
  final DateTime fechaUltimoContacto;
  final DateTime fechaVencimientoCuota;
  final CollectionStatus estadoGestion;
  final OverduePriority prioridad;
  final List<CollectionActionModel> acciones;

  String get documentoCensurado {
    final digits = documento.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 4) return '****';
    return '***${digits.substring(digits.length - 4)}';
  }

  OverdueClientModel copyWith({
    CollectionStatus? estadoGestion,
    DateTime? fechaUltimoContacto,
    List<CollectionActionModel>? acciones,
  }) {
    return OverdueClientModel(
      id: id,
      clientId: clientId,
      clienteNombre: clienteNombre,
      documento: documento,
      telefono: telefono,
      direccion: direccion,
      creditoId: creditoId,
      montoVencido: montoVencido,
      diasMora: diasMora,
      fechaUltimoContacto: fechaUltimoContacto ?? this.fechaUltimoContacto,
      fechaVencimientoCuota: fechaVencimientoCuota,
      estadoGestion: estadoGestion ?? this.estadoGestion,
      prioridad: prioridad,
      acciones: acciones ?? this.acciones,
    );
  }
}
