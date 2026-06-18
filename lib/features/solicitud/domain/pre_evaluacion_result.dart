import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Resultado de la pre-evaluación crediticia simple.
enum Elegibilidad {
  apto,
  observado,
  noApto;

  String get label {
    switch (this) {
      case Elegibilidad.apto:
        return 'APTO';
      case Elegibilidad.observado:
        return 'OBSERVADO';
      case Elegibilidad.noApto:
        return 'NO APTO';
    }
  }

  Color get color {
    switch (this) {
      case Elegibilidad.apto:
        return AppColors.semaforoNormal;
      case Elegibilidad.observado:
        return AppColors.semaforoCpp;
      case Elegibilidad.noApto:
        return AppColors.gestionRecuperacionMora;
    }
  }

  IconData get icon {
    switch (this) {
      case Elegibilidad.apto:
        return Icons.check_circle_outline;
      case Elegibilidad.observado:
        return Icons.warning_amber_outlined;
      case Elegibilidad.noApto:
        return Icons.cancel_outlined;
    }
  }
}

/// Nivel de riesgo asignado.
enum RiesgoCrediticio {
  bajo,
  medio,
  alto;

  String get label {
    switch (this) {
      case RiesgoCrediticio.bajo:
        return 'Bajo';
      case RiesgoCrediticio.medio:
        return 'Medio';
      case RiesgoCrediticio.alto:
        return 'Alto';
    }
  }

  Color get color {
    switch (this) {
      case RiesgoCrediticio.bajo:
        return AppColors.semaforoNormal;
      case RiesgoCrediticio.medio:
        return AppColors.semaforoCpp;
      case RiesgoCrediticio.alto:
        return AppColors.gestionRecuperacionMora;
    }
  }
}

/// Resultado de pre-evaluación crediticia simple (no vinculante).
class PreEvaluacionResult {
  const PreEvaluacionResult({
    required this.score,
    required this.elegibilidad,
    required this.ratioCapacidadPago,
    required this.capacidadDisponible,
    required this.riesgo,
    required this.mensaje,
    required this.motivos,
  });

  final int score;
  final Elegibilidad elegibilidad;
  final double ratioCapacidadPago;
  final double capacidadDisponible;
  final RiesgoCrediticio riesgo;
  final String mensaje;
  final List<String> motivos;

  bool get esApto => elegibilidad == Elegibilidad.apto;
  bool get esObservado => elegibilidad == Elegibilidad.observado;
  bool get esNoApto => elegibilidad == Elegibilidad.noApto;

  Map<String, dynamic> toMap() => {
        'score': score,
        'elegibilidad': elegibilidad.name,
        'ratio_capacidad_pago': (ratioCapacidadPago * 100).roundToDouble() / 100,
        'capacidad_disponible':
            (capacidadDisponible * 100).roundToDouble() / 100,
        'riesgo': riesgo.name,
        'mensaje': mensaje,
        'motivos': motivos,
      };

  Map<String, dynamic> toJson() => toMap();
}