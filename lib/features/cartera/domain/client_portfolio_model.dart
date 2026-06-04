/// Modelo de cliente en cartera diaria (HU-V02).
class ClientPortfolioModel {
  const ClientPortfolioModel({
    required this.id,
    required this.clientName,
    required this.managementType,
    required this.status,
    this.address,
    this.amount,
  });

  final String id;
  final String clientName;
  final String managementType;
  final String status;
  final String? address;
  final double? amount;

  bool get isPending => status.toLowerCase() == 'pendiente';
  bool get isVisited => status.toLowerCase() == 'visitado';
}
