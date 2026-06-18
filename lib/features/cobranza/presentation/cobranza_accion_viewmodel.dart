import 'package:flutter/foundation.dart';

import '../../../core/location/location_service.dart';
import '../../../core/supabase/supabase_helper.dart';
import '../../../core/sync/sync_manager.dart';
import '../../../core/sync/sync_models.dart';
import '../../auth/data/asesor_repository.dart';
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
  final LocationService _locationService = LocationService.instance;

  static const double fallbackLat = -12.0464;
  static const double fallbackLng = -77.0428;
  static const int maxObservaciones = 200;

  bool _isLoading = false;
  bool _isLocating = false;
  String? _errorMessage;
  String? _successMessage;
  String? _locationStatus;

  double? _lat;
  double? _lng;
  bool _locationFromFallback = false;

  CollectionManagementType? _tipoGestion;
  CollectionResult? _resultado;
  double _montoPagado = 0;
  DateTime? _fechaCompromiso;
  double _montoCompromiso = 0;
  String _observaciones = '';

  double? get lat => _lat;
  double? get lng => _lng;
  bool get isLocating => _isLocating;
  String? get locationStatus => _locationStatus;
  bool get locationIsReal => !_locationFromFallback && _lat != null;

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

  Future<void> captureLocation() async {
    _isLocating = true;
    _locationStatus = 'Obteniendo ubicación…';
    _lat = null;
    _lng = null;
    _locationFromFallback = false;
    notifyListeners();

    final result = await _locationService.getCurrentPositionWithFallback();

    _lat = result.lat;
    _lng = result.lng;
    _locationFromFallback = result.fromFallback;

    if (result.hasLocation && !result.fromFallback) {
      _locationStatus = 'Ubicación real: ${result.lat!.toStringAsFixed(5)}, ${result.lng!.toStringAsFixed(5)}';
    } else if (result.hasLocation && result.fromFallback) {
      _locationStatus = '${result.errorMessage ?? "Ubicación no disponible"} — usando coordenadas de referencia.';
    } else {
      _locationStatus = result.errorMessage ?? 'Ubicación no disponible.';
    }

    _isLocating = false;
    notifyListeners();
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

    if (_lat == null) {
      await captureLocation();
    }

    _isLoading = true;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 600));

    final effectiveLat = _lat ?? fallbackLat;
    final effectiveLng = _lng ?? fallbackLng;

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
      lat: effectiveLat,
      lng: effectiveLng,
      timestampGestion: DateTime.now(),
    );

    _listVm.registerAction(overdueClientId, action);

    if (SupabaseHelper.hasSession) {
      try {
        await CobranzaRepository.instance.insertAccion(action);
        _successMessage =
            'Gestión guardada y registrada en Supabase.';
      } catch (error, stackTrace) {
        SupabaseHelper.log('cobranza falló, encolando sync');
        SupabaseHelper.logError(error, stackTrace);
        final asesor = AsesorRepository.instance.current;
        await SyncManager.instance.enqueueOperation(
          entityType: SyncEntityType.accionCobranza,
          entityId: action.id,
          operation: SyncOperation.insert,
          payload: {
            'asesor_id': asesor?.id,
            'cliente_id': action.clientId,
            'credito_id': action.creditoId,
            'documento': action.documento,
            'cliente_nombre': action.clienteNombre,
            'tipo_gestion': action.tipoGestion.name,
            'resultado': action.resultado.name,
            'monto_gestionado': action.montoPagado,
            'fecha_compromiso': action.fechaCompromiso?.toIso8601String(),
            'monto_compromiso': action.montoCompromiso,
            'observacion': action.observaciones,
            'lat': action.lat,
            'lng': action.lng,
            'timestamp_gestion': action.timestampGestion.toIso8601String(),
          },
        );
        _successMessage = SupabaseHelper.fallbackSaveMessage;
      }
    } else {
      _successMessage = 'Gestión guardada. Coordenadas ${_locationFromFallback ? "de referencia" : "reales"} registradas.';
    }

    _isLoading = false;
    notifyListeners();
    return true;
  }
}
