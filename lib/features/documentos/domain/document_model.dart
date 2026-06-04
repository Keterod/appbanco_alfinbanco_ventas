/// Tipo de documento de la solicitud.
enum TipoDocumento {
  dniAnverso('DNI — Anverso'),
  dniReverso('DNI — Reverso'),
  fotoNegocio('Foto del negocio'),
  fotoAsesorCliente('Foto asesor con cliente'),
  ruc('RUC / Constancia SUNAT'),
  reciboServicios('Recibo de servicios'),
  contratoArrendamiento('Contrato de arrendamiento');

  const TipoDocumento(this.nombreVisible);
  final String nombreVisible;

  bool get esObligatorio => switch (this) {
        TipoDocumento.dniAnverso ||
        TipoDocumento.dniReverso ||
        TipoDocumento.fotoNegocio ||
        TipoDocumento.fotoAsesorCliente =>
          true,
        _ => false,
      };
}

/// Estado del documento en el checklist.
enum EstadoDocumento {
  pendiente('Pendiente'),
  listo('Listo'),
  rechazado('Rechazado');

  const EstadoDocumento(this.label);
  final String label;
}

/// Modelo de documento capturado o pendiente (HU-V05).
class DocumentModel {
  const DocumentModel({
    required this.id,
    required this.solicitudId,
    required this.tipoDocumento,
    required this.nombreVisible,
    required this.obligatorio,
    required this.estado,
    this.imagePathSimulado,
    this.tamanioKb,
    this.nitidezScore,
    this.fechaCaptura,
  });

  final String id;
  final String solicitudId;
  final TipoDocumento tipoDocumento;
  final String nombreVisible;
  final bool obligatorio;
  final EstadoDocumento estado;
  final String? imagePathSimulado;
  final int? tamanioKb;
  final double? nitidezScore;
  final DateTime? fechaCaptura;

  bool get isListo => estado == EstadoDocumento.listo;
  bool get isPendiente => estado == EstadoDocumento.pendiente;

  DocumentModel copyWith({
    EstadoDocumento? estado,
    String? imagePathSimulado,
    int? tamanioKb,
    double? nitidezScore,
    DateTime? fechaCaptura,
    bool clearCapture = false,
  }) {
    if (clearCapture) {
      return DocumentModel(
        id: id,
        solicitudId: solicitudId,
        tipoDocumento: tipoDocumento,
        nombreVisible: nombreVisible,
        obligatorio: obligatorio,
        estado: estado ?? EstadoDocumento.pendiente,
        imagePathSimulado: null,
        tamanioKb: null,
        nitidezScore: null,
        fechaCaptura: null,
      );
    }
    return DocumentModel(
      id: id,
      solicitudId: solicitudId,
      tipoDocumento: tipoDocumento,
      nombreVisible: nombreVisible,
      obligatorio: obligatorio,
      estado: estado ?? this.estado,
      imagePathSimulado: imagePathSimulado ?? this.imagePathSimulado,
      tamanioKb: tamanioKb ?? this.tamanioKb,
      nitidezScore: nitidezScore ?? this.nitidezScore,
      fechaCaptura: fechaCaptura ?? this.fechaCaptura,
    );
  }
}
