/// Estado de un paso de transmisión.
enum TransmissionStepStatus {
  pendiente('Pendiente'),
  enProceso('En proceso'),
  completado('Completado'),
  error('Error');

  const TransmissionStepStatus(this.label);
  final String label;
}

/// Estado general de la transmisión.
enum TransmissionStatus {
  pendiente('Pendiente'),
  transmitiendo('Transmitiendo'),
  completado('Completado'),
  error('Error');

  const TransmissionStatus(this.label);
  final String label;
}

/// Paso individual del proceso de transmisión.
class TransmissionStepModel {
  const TransmissionStepModel({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.estado,
    this.progreso = 0,
  });

  final String id;
  final String titulo;
  final String descripcion;
  final TransmissionStepStatus estado;
  final double progreso;

  TransmissionStepModel copyWith({
    TransmissionStepStatus? estado,
    double? progreso,
  }) {
    return TransmissionStepModel(
      id: id,
      titulo: titulo,
      descripcion: descripcion,
      estado: estado ?? this.estado,
      progreso: progreso ?? this.progreso,
    );
  }
}

/// Modelo agregado de transmisión electrónica (HU-V06).
class TransmissionModel {
  const TransmissionModel({
    required this.solicitudId,
    required this.estadoGeneral,
    required this.pasos,
    this.numeroExpedienteOficial,
    this.tiempoEstimadoRespuesta,
    this.fechaEnvio,
    this.mensajeFinal,
  });

  final String solicitudId;
  final TransmissionStatus estadoGeneral;
  final List<TransmissionStepModel> pasos;
  final String? numeroExpedienteOficial;
  final String? tiempoEstimadoRespuesta;
  final DateTime? fechaEnvio;
  final String? mensajeFinal;
}
