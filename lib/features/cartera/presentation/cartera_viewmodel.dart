import 'package:flutter/foundation.dart';

import '../domain/client_portfolio_model.dart';

/// ViewModel de cartera diaria (HU-V02).
class CarteraViewModel extends ChangeNotifier {
  CarteraViewModel() {
    _clients = _seedClients;
  }

  final String officerName = 'Diego';

  late final List<ClientPortfolioModel> _clients;

  List<ClientPortfolioModel> get clients => List.unmodifiable(_clients);

  int get totalVisits => _clients.length;

  int get pendingVisits => _clients.where((c) => c.isPending).length;

  List<ClientPortfolioModel> get visitedClients =>
      _clients.where((c) => c.isVisited).toList(growable: false);

  static const List<ClientPortfolioModel> _seedClients = [
    ClientPortfolioModel(
      id: 'cli-001',
      clientName: 'Rosa Quispe',
      managementType: 'Renovación',
      status: 'Pendiente',
      address: 'Av. Los Olivos 234, Lima',
      amount: 8500,
    ),
    ClientPortfolioModel(
      id: 'cli-002',
      clientName: 'Miguel Huamán',
      managementType: 'Nuevo',
      status: 'Pendiente',
      address: 'Jr. Huascar 120',
    ),
    ClientPortfolioModel(
      id: 'cli-003',
      clientName: 'Carmen Flores',
      managementType: 'Cobranza',
      status: 'Visitado',
      amount: 1200.50,
    ),
    ClientPortfolioModel(
      id: 'cli-004',
      clientName: 'José Ramos',
      managementType: 'Renovación',
      status: 'Pendiente',
    ),
    ClientPortfolioModel(
      id: 'cli-005',
      clientName: 'Ana Torres',
      managementType: 'Nuevo',
      status: 'Visitado',
      address: 'Calle Las Flores 45, San Juan de Lurigancho',
      amount: 15000,
    ),
  ];
}
