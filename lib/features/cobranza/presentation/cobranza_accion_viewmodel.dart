import 'package:flutter/foundation.dart';

import '../../../core/supabase/supabase_helper.dart';
import '../data/cobranza_local_repository.dart';
import '../data/cobranza_repository.dart';
import '../domain/collection_model.dart';
import 'cobranza_viewmodel.dart';

/// ViewModel del formulario de acción de cobranza (HU-V10).
class CobranzaAccionViewModel extends ChangeNotifier {
  CobranzaAccionViewModel({
    required this.overdueClientId,
    CobranzaViewModel? listViewModel,
  }) : _listVm = listViewModel ?? CobranzaViewModel();

  final String overdueClientId;
  final CobranzaViewModel _listVm;
  final CobranzaLocalRepository _repo = CobranzaLocalRepository.instance;

  static const double simulatedLat = -12.0464;
  static const double simulatedLng = -77.0428;
  static const int maxObservaciones = 200;

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  CollectionManagementType? _tipoGestion;
  CollectionResult? _resultado;
  double _montoPagado = 0;
  DateTime? _fechaCompromiso;
  double _montoCompromiso = 0;
  String _observaciones = '';

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  CollectionManagementType? get tipoGestion => _tipoGestion;
  CollectionResult? get resultado => _resultado;
  double get montoPagado => _montoPagado;
  DateTime? get fechaCompromiso => _fechaCompromiso;
  double get montoCompromiso => _montoCompromiso;
  String get observaciones => _observaciones;

  OverdueClientModel? get client {
    _repo.ensureInitialized();
    return _repo.getById(overdueClientId);
  }

  bool get showMontoPagado => _resultado == CollectionResult.pagoParcial;
  bool get showCompromiso => _resultado == CollectionResult.compromisoPago;

  void setTipoGestion(CollectionManagementType? v) {
    _tipoGestion = v;
    notifyListeners();
  }

  void setResultado(CollectionResult? v) {
    _resultado = v;
    notifyListeners();
  }

  void setMontoPagado(double v) {
    _montoPagado = v;
    notifyListeners();
  }

  void setFechaCompromiso(DateTime? v) {
    _fechaCompromiso = v;
    notifyListeners();
  }

  void setMontoCompromiso(double v) {
    _montoCompromiso = v;
    notifyListeners();
  }

  void setObservaciones(String v) {
    _observaciones = v.length > maxObservaciones
        ? v.substring(0, maxObservaciones)
        : v;
    notifyListeners();
  }

  bool validate() {
    if (_tipoGestion == null) {
      _errorMessage = 'Seleccione el tipo de gestión.';
      notifyListeners();
      return false;
    }
    if (_resultado == null) {
      _errorMessage = 'Seleccione el resultado.';
      notifyListeners();
      return false;
    }
    if (_resultado == CollectionResult.pagoParcial && _montoPagado <= 0) {
      _errorMessage = 'El monto pagado debe ser mayor a 0.';
      notifyListeners();
      return false;
    }
    if (_resultado == CollectionResult.compromisoPago) {
      if (_fechaCompromiso == null) {
        _errorMessage = 'Indique la fecha de compromiso.';
        notifyListeners();
        return false;
      }
      if (_montoCompromiso <= 0) {
        _errorMessage = 'El monto de compromiso debe ser mayor a 0.';
        notifyListeners();
        return false;
      }
    }
    if (_observaciones.trim().isEmpty) {
      _errorMessage = 'Las observaciones son obligatorias.';
      notifyListeners();
      return false;
    }
    _errorMessage = null;
    return true;
  }

  Future<bool> guardarGestion() async {
    if (!validate()) return false;

    final c = client;
    if (c == null) {
      _errorMessage = 'Cliente no encontrado.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 600));

    final action = CollectionActionModel(
      id: _repo.nextActionId(),
      clientId: c.clientId,
      creditoId: c.creditoId,
      documento: c.documento,
      clienteNombre: c.clienteNombre,
      tipoGestion: _tipoGestion!,
      resultado: _resultado!,
      montoPagado:
          _resultado == CollectionResult.pagoParcial ? _montoPagado : null,
      fechaCompromiso:
          _resultado == CollectionResult.compromisoPago ? _fechaCompromiso : null,
      montoCompromiso:
          _resultado == CollectionResult.compromisoPago ? _montoCompromiso : null,
      observaciones: _observaciones.trim(),
      lat: simulatedLat,
      lng: simulatedLng,
      timestampGestion: DateTime.now(),
    );

    _listVm.registerAction(overdueClientId, action);

    if (SupabaseHelper.hasSession) {
      try {
        await CobranzaRepository.instance.insertAccion(action);
        _successMessage =
            'Gestión guardada y registrada en Supabase.';
      } catch (error, stackTrace) {
        SupabaseHelper.log('cobranza falló, usando fallback mock');
        SupabaseHelper.logError(error, stackTrace);
        _successMessage = SupabaseHelper.fallbackSaveMessage;
      }
    } else {
      _successMessage = 'Gestión guardada. Coordenadas simuladas registradas.';
    }

    _isLoading = false;
    notifyListeners();
    return true;
  }
}
