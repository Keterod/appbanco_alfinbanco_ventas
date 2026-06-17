import 'package:flutter/foundation.dart';

import '../data/estado_solicitudes_repository.dart';
import '../domain/request_status_mock_data.dart';
import '../domain/request_status_model.dart';

/// ViewModel del tablero de estado de solicitudes (HU-V07).
class EstadoSolicitudesViewModel extends ChangeNotifier {
  final EstadoSolicitudesRepository _repo =
      EstadoSolicitudesRepository.instance;

  bool _isLoading = false;
  String? _errorMessage;
  RequestStatus _selectedStatus = RequestStatus.enviada;
  List<RequestStatusModel> _requests = [];
  String? _highlightReference;
  bool _usandoDatosReales = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  RequestStatus get selectedStatus => _selectedStatus;
  String? get highlightReference => _highlightReference;
  bool get usandoDatosReales => _usandoDatosReales;

  int get totalSolicitudes => _requests.length;

  int get totalAprobadas => getCountByStatus(RequestStatus.aprobada) +
      getCountByStatus(RequestStatus.condicionada) +
      getCountByStatus(RequestStatus.desembolsada);

  int get totalDesembolsadas => getCountByStatus(RequestStatus.desembolsada);

  double get montoTotalAprobado => _requests
      .where((r) =>
          r.estado == RequestStatus.aprobada ||
          r.estado == RequestStatus.condicionada ||
          r.estado == RequestStatus.desembolsada)
      .fold(0, (sum, r) => sum + (r.montoAprobado ?? r.montoSolicitado));

  Future<void> loadRequests({String? highlightedSolicitudId}) async {
    _isLoading = true;
    _errorMessage = null;
    _highlightReference = highlightedSolicitudId;
    notifyListeners();

    try {
      final real = await _repo.loadSolicitudes();
      final anyReal =
          real.any((r) => r.id.startsWith('req-') == false);
      if (real.isNotEmpty && anyReal) {
        _requests = real;
        _usandoDatosReales = true;
      } else {
        _requests = RequestStatusMockData.all();
        _usandoDatosReales = false;
      }
    } catch (_) {
      _requests = RequestStatusMockData.all();
      _usandoDatosReales = false;
    }

    if (_highlightReference != null) {
      final match = _usandoDatosReales
          ? _requests.cast<RequestStatusModel?>().firstWhere(
                (r) => r!.matchesReference(_highlightReference),
                orElse: () => null,
              )
          : RequestStatusMockData.findByReference(_highlightReference);
      if (match != null) {
        _selectedStatus = match.estado;
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  void selectStatus(RequestStatus status) {
    _selectedStatus = status;
    notifyListeners();
  }

  void filterByStatus(RequestStatus status) => selectStatus(status);

  int getCountByStatus(RequestStatus status) =>
      _requests.where((r) => r.estado == status).length;

  List<RequestStatusModel> getFilteredRequests() =>
      _requests.where((r) => r.estado == _selectedStatus).toList(growable: false);

  bool isHighlighted(RequestStatusModel request) =>
      request.matchesReference(_highlightReference);
}
