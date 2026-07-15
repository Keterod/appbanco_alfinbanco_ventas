import 'package:flutter/foundation.dart';

import '../../../core/supabase/supabase_helper.dart';
import '../../auth/data/asesor_repository.dart';
import '../data/estado_solicitudes_repository.dart';
import '../domain/request_status_model.dart';

/// ViewModel del detalle de solicitud (HU-V07).
class EstadoSolicitudDetalleViewModel extends ChangeNotifier {
  final EstadoSolicitudesRepository _repo =
      EstadoSolicitudesRepository.instance;

  bool _isLoading = false;
  bool _isProcesando = false;
  bool _isDesembolsando = false;
  bool _isEnviando = false;
  String? _errorMessage;
  String? _successMessage;
  RequestStatusModel? _request;
  String _notaInterna = '';

  bool get isLoading => _isLoading;
  bool get isProcesando => _isProcesando;
  bool get isDesembolsando => _isDesembolsando;
  bool get isEnviando => _isEnviando;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  RequestStatusModel? get request => _request;
  String get notaInterna => _notaInterna;

  /// ID del asesor logueado actualmente.
  String? get asesorId => AsesorRepository.instance.current?.id;

  Future<void> reclamarSolicitud() async {
    if (_request == null) return;

    _isProcesando = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _repo.reclamarSolicitud(_request!.id);
      await loadRequest(requestId: _request!.id);
      _successMessage = 'Solicitud reclamada correctamente.';
    } catch (error, stackTrace) {
      SupabaseHelper.logError(error, stackTrace);
      _errorMessage = SupabaseHelper.friendlyError(error);
    }

    _isProcesando = false;
    notifyListeners();
  }

  Future<bool> enviarAEvaluacion(String observacion) async {
    if (_request == null) return false;

    _isEnviando = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _repo.enviarAEvaluacion(
        solicitud: _request!.rawData,
        observacion: observacion,
      );
      _successMessage = 'Expediente enviado a evaluación correctamente.';
      _isEnviando = false;
      notifyListeners();
      return true;
    } catch (error, stackTrace) {
      SupabaseHelper.logError(error, stackTrace);
      _errorMessage = SupabaseHelper.friendlyError(error);
      _isEnviando = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadRequest(
      {String? requestId, String? numeroExpediente}) async {
    _isLoading = true;
    _errorMessage = null;
    _request = null;
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

  RequestStatusModel _copyWithEstado(RequestStatus nuevoEstado) {
    return RequestStatusModel(
      id: _request!.id,
      numeroExpediente: _request!.numeroExpediente,
      clienteNombre: _request!.clienteNombre,
      documento: _request!.documento,
      montoSolicitado: _request!.montoSolicitado,
      montoAprobado: _request!.montoAprobado,
      fechaEnvio: _request!.fechaEnvio,
      diasDesdeEnvio: _request!.diasDesdeEnvio,
      analistaAsignado: _request!.analistaAsignado,
      estado: nuevoEstado,
      timeline: _request!.timeline,
      solicitudLocalId: _request!.solicitudLocalId,
      rawData: _request!.rawData,
    );
  }

  Future<bool> aprobar() async {
    if (_request == null) return false;

    _isProcesando = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _repo.aprobarSolicitud(solicitud: _request!.rawData);
      _successMessage = 'Solicitud aprobada correctamente.';
      _request = _copyWithEstado(RequestStatus.aprobada);
      _isProcesando = false;
      notifyListeners();
      return true;
    } catch (error, stackTrace) {
      SupabaseHelper.logError(error, stackTrace);
      _errorMessage = SupabaseHelper.friendlyError(error);
      _isProcesando = false;
      notifyListeners();
      return false;
    }
  }

  /// Monto recomendado para condicionar (monto menor basado en capacidad).
  double get montoRecomendado =>
      _request != null ? _repo.calcularMontoRecomendadoCondicionado(_request!.rawData) : 0;

  Future<bool> condicionar({
    required double montoAprobado,
    required String condicion,
  }) async {
    if (_request == null) return false;

    _isProcesando = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _repo.condicionarSolicitud(
        solicitud: _request!.rawData,
        condicion: condicion,
        montoAprobado: montoAprobado,
      );
      _successMessage = 'Solicitud condicionada correctamente.';
      _request = _copyWithEstado(RequestStatus.condicionada);
      _isProcesando = false;
      notifyListeners();
      return true;
    } catch (error, stackTrace) {
      SupabaseHelper.logError(error, stackTrace);
      _errorMessage = SupabaseHelper.friendlyError(error);
      _isProcesando = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> rechazar(String motivo) async {
    if (_request == null) return false;

    _isProcesando = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _repo.rechazarSolicitud(
        solicitud: _request!.rawData,
        motivo: motivo,
      );
      _successMessage = 'Solicitud rechazada.';
      _request = _copyWithEstado(RequestStatus.rechazada);
      _isProcesando = false;
      notifyListeners();
      return true;
    } catch (error, stackTrace) {
      SupabaseHelper.logError(error, stackTrace);
      _errorMessage = SupabaseHelper.friendlyError(error);
      _isProcesando = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> desembolsar() async {
    if (_request == null) return false;

    _isDesembolsando = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _repo.desembolsarSolicitud(
        solicitud: _request!.rawData,
      );

      _successMessage = 'Solicitud desembolsada correctamente.';
      _request = RequestStatusModel(
        id: _request!.id,
        numeroExpediente: _request!.numeroExpediente,
        clienteNombre: _request!.clienteNombre,
        documento: _request!.documento,
        montoSolicitado: _request!.montoSolicitado,
        montoAprobado: _request!.montoAprobado,
        fechaEnvio: _request!.fechaEnvio,
        diasDesdeEnvio: _request!.diasDesdeEnvio,
        analistaAsignado: _request!.analistaAsignado,
        estado: RequestStatus.desembolsada,
        timeline: _request!.timeline,
        solicitudLocalId: _request!.solicitudLocalId,
        rawData: _request!.rawData,
      );

      _isDesembolsando = false;
      notifyListeners();
      return true;
    } catch (error, stackTrace) {
      SupabaseHelper.logError(error, stackTrace);
      _errorMessage = SupabaseHelper.friendlyError(error);
      _isDesembolsando = false;
      notifyListeners();
      return false;
    }
  }
}
