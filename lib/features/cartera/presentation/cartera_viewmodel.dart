import 'package:flutter/foundation.dart';

import '../../../core/supabase/supabase_helper.dart';
import '../../auth/data/asesor_repository.dart';
import '../data/cartera_repository.dart';
import '../domain/client_portfolio_model.dart';

/// ViewModel de cartera diaria (HU-V02).
class CarteraViewModel extends ChangeNotifier {
  CarteraViewModel() {
    _clients = List.from(_seedClients);
  }

  final CarteraRepository _repo = CarteraRepository.instance;

  bool _isLoading = false;
  bool _usingMock = true;
  late List<ClientPortfolioModel> _clients;

  bool get isLoading => _isLoading;
  bool get usingMock => _usingMock;

  String get officerName =>
      AsesorRepository.instance.current?.nombreCompleto ?? 'Diego';

  List<ClientPortfolioModel> get clients => List.unmodifiable(_clients);

  int get totalVisits => _clients.length;

  int get pendingVisits => _clients.where((c) => c.isPending).length;

  List<ClientPortfolioModel> get visitedClients =>
      _clients.where((c) => c.isVisited).toList(growable: false);

  Future<void> loadCartera() async {
    _isLoading = true;
    notifyListeners();

    if (SupabaseHelper.hasSession) {
      try {
        SupabaseHelper.log('CarteraViewModel loadCartera Supabase');
        final remote = await _repo.loadCarteraDiaria();
        if (remote.isNotEmpty) {
          _clients = remote;
          _usingMock = false;
          _isLoading = false;
          notifyListeners();
          return;
        }
        SupabaseHelper.log('cartera vacía, usando fallback mock');
      } catch (error, stackTrace) {
        SupabaseHelper.log('cartera falló, usando fallback mock');
        SupabaseHelper.logError(error, stackTrace);
      }
    }

    _clients = List.from(_seedClients);
    _usingMock = true;
    _isLoading = false;
    notifyListeners();
  }

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
