import 'package:flutter/foundation.dart';

import '../data/estado_solicitudes_repository.dart';
import '../domain/request_status_mock_data.dart';
import '../domain/request_status_model.dart';

/// ViewModel del detalle de solicitud (HU-V07).
class EstadoSolicitudDetalleViewModel extends ChangeNotifier {
  final EstadoSolicitudesRepository _repo =
      EstadoSolicitudesRepository.instance;

  bool _isLoading = false;
  String? _errorMessage;
  RequestStatusModel? _request;
  String _notaInterna = '';
  bool _usandoDatosReales = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  RequestStatusModel? get request => _request;
  String get notaInterna => _notaInterna;
  bool get usandoDatosReales => _usandoDatosReales;

  Future<void> loadRequest(
      {String? requestId, String? numeroExpediente}) async {
    _isLoading = true;
    _errorMessage = null;
    _request = null;
    _usandoDatosReales = false;
    notifyListeners();

    RequestStatusModel? found;

    if (requestId != null && requestId.isNotEmpty) {
      found = await _repo.loadSolicitudById(requestId);
    }

    if (found == null &&
        numeroExpediente != null &&
        numeroExpediente.isNotEmpty) {
      found = await _repo.loadSolicitudByExpediente(numeroExpediente);
    }

    if (found != null) {
      _usandoDatosReales = true;
    } else {
      if (requestId != null && requestId.isNotEmpty) {
        found = RequestStatusMockData.findById(requestId) ??
            RequestStatusMockData.findByReference(requestId);
      }
      if (found == null &&
          numeroExpediente != null &&
          numeroExpediente.isNotEmpty) {
        found = RequestStatusMockData.findByExpediente(numeroExpediente);
      }
    }

    if (found == null) {
      _errorMessage = 'No se encontró la solicitud.';
    } else {
      _request = found;
    }

    _isLoading = false;
    notifyListeners();
  }

  void guardarNotaInterna(String nota) {
    _notaInterna = nota.trim();
    notifyListeners();
  }
}
