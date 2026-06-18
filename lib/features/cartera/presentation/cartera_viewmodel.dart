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
  String _dataSource = 'demo';
  late List<ClientPortfolioModel> _clients;

  bool get isLoading => _isLoading;
  bool get usingMock => _usingMock;
  bool get isOffline => _dataSource == 'offline';
  String get dataSource => _dataSource;
  String get dataSourceLabel {
    switch (_dataSource) {
      case 'live':
        return 'Sincronizado con Supabase';
      case 'offline':
        return 'Modo offline · datos guardados';
      case 'demo':
        return 'Modo demo';
      default:
        return _dataSource;
    }
  }

  String get officerName =>
      AsesorRepository.instance.current?.nombreCompleto ?? 'Diego';

  List<ClientPortfolioModel> get clients => List.unmodifiable(_clients);

  int get totalVisits => _clients.length;

  int get pendingVisits => _clients.where((c) => c.isPending).length;

  List<ClientPortfolioModel> get visitedClients =>
      _clients.where((c) => c.isVisited).toList(growable: false);

  Future<void> loadCartera() async {
    _isLoading = true;
    _usingMock = true;
    notifyListeners();

    debugPrint('[CARTERA-VM] loadCartera iniciado hasSession=${SupabaseHelper.hasSession}');

    if (SupabaseHelper.hasSession) {
      try {
        debugPrint('[CARTERA-VM] llamando _repo.loadCarteraDiaria()');
        final remote = await _repo.loadCarteraDiaria();
        _dataSource = _repo.lastSource;
        debugPrint('[CARTERA-VM] _repo.lastSource=$_dataSource remote.length=${remote.length}');
        if (remote.isNotEmpty) {
          _clients = remote;
          _usingMock = false;
          _isLoading = false;
          debugPrint('[CARTERA-VM] datos remotos asignados, source=$_dataSource');
          notifyListeners();
          return;
        }
        debugPrint('[CARTERA-VM] datos vacíos desde repo, source=$_dataSource');
      } catch (error, stackTrace) {
        _dataSource = _repo.lastSource;
        debugPrint('[CARTERA-VM] excepción: $error');
        debugPrint('[CARTERA-VM] _repo.lastSource después de error=$_dataSource');
        SupabaseHelper.log('cartera falló, usando fallback mock');
        SupabaseHelper.logError(error, stackTrace);
      }
    } else {
      debugPrint('[CARTERA-VM] sin sesión → demo');
    }

    _clients = List.from(_seedClients);
    _dataSource = 'demo';
    _isLoading = false;
    debugPrint('[CARTERA-VM] fallback a seed demo, source=$_dataSource');
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
