/// Calificación SBS en consulta de buró.
enum CalificacionSbsBuro {
  normal('Normal'),
  cpp('CPP'),
  deficiente('Deficiente'),
  dudoso('Dudoso'),
  perdida('Pérdida');

  const CalificacionSbsBuro(this.label);
  final String label;
}

/// Resultado interpretativo de la consulta.
enum BuroStatus {
  apto('APTO'),
  revisar('REVISAR'),
  bloqueado('BLOQUEADO');

  const BuroStatus(this.label);
  final String label;
}

/// Resultado de consulta de buró y listas (HU-V08).
class BuroResultModel {
  const BuroResultModel({
    this.clientId,
    required this.nombres,
    required this.documento,
    required this.calificacionSbs,
    required this.entidadesConDeuda,
    required this.deudaTotalPen,
    required this.mayorDeuda,
    required this.diasMayorMora,
    required this.enListaNegra,
    this.motivoBloqueo,
    required this.recomendacion,
    required this.fechaConsulta,
    required this.firmaConsentimientoRegistrada,
    required this.resultadoDisponible,
    required this.status,
  });

  final String? clientId;
  final String nombres;
  final String documento;
  final CalificacionSbsBuro calificacionSbs;
  final int entidadesConDeuda;
  final double deudaTotalPen;
  final double mayorDeuda;
  final int diasMayorMora;
  final bool enListaNegra;
  final String? motivoBloqueo;
  final String recomendacion;
  final DateTime fechaConsulta;
  final bool firmaConsentimientoRegistrada;
  final bool resultadoDisponible;
  final BuroStatus status;

  bool get puedeContinuarSolicitud =>
      status == BuroStatus.apto || status == BuroStatus.revisar;
}
