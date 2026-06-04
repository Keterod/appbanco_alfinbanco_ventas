import 'package:flutter/foundation.dart';

import '../domain/request_status_mock_data.dart';
import '../domain/request_status_model.dart';

/// ViewModel del detalle de solicitud (HU-V07).
class EstadoSolicitudDetalleViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  RequestStatusModel? _request;
  String _notaInterna = '';

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  RequestStatusModel? get request => _request;
  String get notaInterna => _notaInterna;

  Future<void> loadRequest({String? requestId, String? numeroExpediente}) async {
    _isLoading = true;
    _errorMessage = null;
    _request = null;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 350));

    RequestStatusModel? found;
    if (requestId != null && requestId.isNotEmpty) {
      found = RequestStatusMockData.findById(requestId) ??
          RequestStatusMockData.findByReference(requestId);
    }
    if (found == null &&
        numeroExpediente != null &&
        numeroExpediente.isNotEmpty) {
      found = RequestStatusMockData.findByExpediente(numeroExpediente);
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
