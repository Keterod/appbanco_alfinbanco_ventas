/// Fila individual del cronograma de pagos (sistema francés, cuota fija).
class CronogramaRow {
  const CronogramaRow({
    required this.numeroCuota,
    required this.fechaPago,
    required this.capital,
    required this.interes,
    required this.cuota,
    required this.saldo,
  });

  final int numeroCuota;
  final DateTime fechaPago;
  final double capital;
  final double interes;
  final double cuota;
  final double saldo;

  CronogramaRow copyWith({double? saldo}) => CronogramaRow(
        numeroCuota: numeroCuota,
        fechaPago: fechaPago,
        capital: capital,
        interes: interes,
        cuota: cuota,
        saldo: saldo ?? this.saldo,
      );

  Map<String, dynamic> toMap() => {
        'numero_cuota': numeroCuota,
        'fecha_pago': fechaPago.toIso8601String(),
        'capital': _r2(capital),
        'interes': _r2(interes),
        'cuota': _r2(cuota),
        'saldo': _r2(saldo),
      };

  factory CronogramaRow.fromMap(Map<String, dynamic> map) => CronogramaRow(
        numeroCuota: (map['numero_cuota'] as num?)?.toInt() ?? 0,
        fechaPago: DateTime.tryParse(map['fecha_pago']?.toString() ?? '') ??
            DateTime.now(),
        capital: (map['capital'] as num?)?.toDouble() ?? 0,
        interes: (map['interes'] as num?)?.toDouble() ?? 0,
        cuota: (map['cuota'] as num?)?.toDouble() ?? 0,
        saldo: (map['saldo'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toJson() => toMap();

  static double _r2(double v) => (v * 100).roundToDouble() / 100;
}