/// Tipo de actividad registrada en el reporte del oficial.
enum ReportActivityType {
  visita,
  solicitud,
  cobranza,
  desembolso,
  alerta;

  String get label => switch (this) {
        ReportActivityType.visita => 'Visita',
        ReportActivityType.solicitud => 'Solicitud',
        ReportActivityType.cobranza => 'Cobranza',
        ReportActivityType.desembolso => 'Desembolso',
        ReportActivityType.alerta => 'Alerta',
      };
}

/// Resumen operativo del oficial para un periodo determinado.
class OfficerReportModel {
  const OfficerReportModel({
    required this.asesorNombre,
    required this.periodo,
    required this.visitasAsignadas,
    required this.visitasRealizadas,
    required this.visitasPendientes,
    required this.solicitudesEnviadas,
    required this.solicitudesAprobadas,
    required this.solicitudesDesembolsadas,
    required this.montoSolicitado,
    required this.montoAprobado,
    required this.clientesEnMora,
    required this.montoVencido,
    required this.gestionesCobranza,
    required this.tasaAprobacion,
    required this.coberturaVisitas,
  });

  final String asesorNombre;
  final String periodo;
  final int visitasAsignadas;
  final int visitasRealizadas;
  final int visitasPendientes;
  final int solicitudesEnviadas;
  final int solicitudesAprobadas;
  final int solicitudesDesembolsadas;
  final double montoSolicitado;
  final double montoAprobado;
  final int clientesEnMora;
  final double montoVencido;
  final int gestionesCobranza;
  final double tasaAprobacion;
  final double coberturaVisitas;
}

/// Evento individual en la línea de tiempo del reporte.
class ReportActivityItem {
  const ReportActivityItem({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.fecha,
    required this.tipo,
  });

  final String id;
  final String titulo;
  final String descripcion;
  final DateTime fecha;
  final ReportActivityType tipo;
}
