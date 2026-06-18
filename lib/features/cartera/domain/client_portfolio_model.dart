/// Modelo de cliente en cartera diaria (HU-V02).
class ClientPortfolioModel {
  const ClientPortfolioModel({
    required this.id,
    required this.clientName,
    required this.managementType,
    required this.status,
    this.address,
    this.amount,
    this.numeroDocumento,
    this.prioridad = 'normal',
    this.scorePrioridad = 0,
    this.lat,
    this.lng,
  });

  final String id;
  final String clientName;
  final String managementType;
  final String status;
  final String? address;
  final double? amount;
  final String? numeroDocumento;
  final String prioridad;
  final int scorePrioridad;
  final double? lat;
  final double? lng;

  bool get isPending => status.toLowerCase() == 'pendiente';
  bool get isVisited => status.toLowerCase() == 'visitado';

  Map<String, dynamic> toMap() => {
        'cliente_id': id,
        'cliente_nombre': clientName,
        'numero_documento': numeroDocumento,
        'tipo_gestion': managementType,
        'prioridad': prioridad,
        'score_prioridad': scorePrioridad,
        'estado_visita': status,
        'monto_credito': amount,
        'direccion': address,
        'lat': lat,
        'lng': lng,
      };

  factory ClientPortfolioModel.fromMap(Map<String, dynamic> map) =>
      ClientPortfolioModel(
        id: (map['cliente_id'] ?? map['id'] ?? '').toString(),
        clientName: (map['cliente_nombre'] ?? map['client_name'] ?? '').toString(),
        numeroDocumento: (map['numero_documento'] ?? map['numeroDocumento'])?.toString(),
        managementType: (map['tipo_gestion'] ?? map['management_type'] ?? '').toString(),
        prioridad: (map['prioridad'] ?? 'normal').toString(),
        scorePrioridad: _toInt(map['score_prioridad'] ?? map['scorePrioridad'] ?? 0),
        status: (map['estado_visita'] ?? map['status'] ?? '').toString(),
        address: (map['direccion'] ?? map['address'])?.toString(),
        amount: _toDouble(map['monto_credito'] ?? map['amount']),
        lat: _toDouble(map['lat']),
        lng: _toDouble(map['lng']),
      );

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }
}
