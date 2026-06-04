import 'package:flutter/foundation.dart';

import '../data/cobranza_local_repository.dart';
import '../domain/collection_model.dart';

/// ViewModel del listado de cartera vencida (HU-V10).
class CobranzaViewModel extends ChangeNotifier {
  final CobranzaLocalRepository _repo = CobranzaLocalRepository.instance;

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  OverduePriority? _selectedPriorityFilter;
  List<OverdueClientModel> _clients = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  OverduePriority? get selectedPriorityFilter => _selectedPriorityFilter;
  List<OverdueClientModel> get overdueClients => List.unmodifiable(_clients);

  Future<void> loadOverdueClients() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 400));

    _repo.ensureInitialized();
    _clients = List.from(_repo.clients);
    _isLoading = false;
    notifyListeners();
  }

  void setPriorityFilter(OverduePriority? priority) {
    _selectedPriorityFilter = priority;
    notifyListeners();
  }

  List<OverdueClientModel> getFilteredClients() {
    if (_selectedPriorityFilter == null) return _clients;
    return _clients
        .where((c) => c.prioridad == _selectedPriorityFilter)
        .toList(growable: false);
  }

  double getTotalOverdueAmount() =>
      _clients.fold(0, (sum, c) => sum + c.montoVencido);

  int getCountByPriority(OverduePriority priority) =>
      _clients.where((c) => c.prioridad == priority).length;

  OverdueClientModel? getClientById(String id) => _repo.getById(id);

  void registerAction(String overdueClientId, CollectionActionModel action) {
    _repo.registerAction(overdueClientId, action);
    _clients = List.from(_repo.clients);
    _successMessage = 'Gestión registrada correctamente.';
    notifyListeners();
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}
