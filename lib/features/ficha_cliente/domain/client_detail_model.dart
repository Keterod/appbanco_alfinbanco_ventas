/// Calificación SBS del cliente.
enum CalificacionSbs {
  normal('Normal'),
  cpp('CPP'),
  deficiente('Deficiente'),
  dudoso('Dudoso'),
  perdida('Pérdida');

  const CalificacionSbs(this.label);
  final String label;
}

/// Crédito histórico del cliente.
class CreditHistoryItem {
  const CreditHistoryItem({
    required this.producto,
    required this.monto,
    required this.plazoMeses,
    required this.tasa,
    required this.estado,
    required this.porcentajePagosPuntuales,
  });

  final String producto;
  final double monto;
  final int plazoMeses;
  final double tasa;
  final String estado;
  final double porcentajePagosPuntuales;
}

/// Modelo detallado de cliente para ficha (HU-V03).
class ClientDetailModel {
  const ClientDetailModel({
    required this.id,
    required this.nombres,
    required this.apellidos,
    required this.documento,
    required this.telefono,
    required this.direccion,
    required this.tipoNegocio,
    required this.nombreNegocio,
    required this.antiguedadNegocio,
    required this.deudaTotal,
    required this.cuotasAlDia,
    required this.cuotasEnMora,
    required this.ultimoPago,
    required this.calificacionSbs,
    this.montoPreaprobado,
    this.plazoSugerido,
    this.teaReferencial,
    this.fechaVencimientoOferta,
    this.historialCreditos = const [],
  });

  final String id;
  final String nombres;
  final String apellidos;
  final String documento;
  final String telefono;
  final String direccion;
  final String tipoNegocio;
  final String nombreNegocio;
  final String antiguedadNegocio;
  final double deudaTotal;
  final int cuotasAlDia;
  final int cuotasEnMora;
  final DateTime ultimoPago;
  final CalificacionSbs calificacionSbs;
  final double? montoPreaprobado;
  final int? plazoSugerido;
  final double? teaReferencial;
  final DateTime? fechaVencimientoOferta;
  final List<CreditHistoryItem> historialCreditos;

  String get nombreCompleto => '$nombres $apellidos';

  String get iniciales {
    final n = nombres.isNotEmpty ? nombres[0] : '';
    final a = apellidos.isNotEmpty ? apellidos[0] : '';
    return '$n$a'.toUpperCase();
  }

  /// DNI censurado: muestra solo los últimos 4 dígitos.
  String get documentoCensurado {
    final digits = documento.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 4) return '****';
    return '***${digits.substring(digits.length - 4)}';
  }

  bool get tieneOfertaVigente =>
      montoPreaprobado != null &&
      plazoSugerido != null &&
      teaReferencial != null &&
      fechaVencimientoOferta != null;
}
