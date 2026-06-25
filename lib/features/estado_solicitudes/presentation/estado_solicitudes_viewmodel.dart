import 'package:flutter/foundation.dart';

import '../../../core/supabase/supabase_helper.dart';
import '../../auth/data/asesor_repository.dart';
import '../data/estado_solicitudes_repository.dart';
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

  /// ID del asesor logueado actualmente.
  String? get asesorId => AsesorRepository.instance.current?.id;

  /// Reclama una solicitud (la asigna al asesor actual).
  Future<void> reclamarSolicitud(RequestStatusModel solicitud) async {
    _errorMessage = null;
    notifyListeners();

    try {
      await _repo.reclamarSolicitud(solicitud.id);
      await loadRequests(highlightedSolicitudId: _highlightReference);
    } catch (error, stackTrace) {
      debugPrint('DEBUG VENTAS ASESOR: error al reclamar: $error');
      SupabaseHelper.logError(error, stackTrace);
      _errorMessage = SupabaseHelper.friendlyError(error);
      notifyListeners();
    }
  }

  Future<void> loadRequests({String? highlightedSolicitudId}) async {
    _isLoading = true;
    _errorMessage = null;
    _highlightReference = highlightedSolicitudId;
    notifyListeners();

    _requests = await _repo.loadSolicitudes();
    _usandoDatosReales = _requests.isNotEmpty;

    if (_highlightReference != null) {
      final match = _requests.cast<RequestStatusModel?>().firstWhere(
            (r) => r!.matchesReference(_highlightReference),
            orElse: () => null,
          );
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
