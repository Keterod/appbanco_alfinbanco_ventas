import 'package:flutter/foundation.dart';

import '../domain/transmission_model.dart';

/// ViewModel de transmisión electrónica (HU-V06). Simulación local.
class TransmisionViewModel extends ChangeNotifier {
  static const String solicitudDemoDefault = 'SOL-DEMO-001';
  static const String mensajeFinalExito =
      'Solicitud enviada correctamente al comité de evaluación.';
  static int _expedienteSecuencia = 1;

  bool _isLoading = false;
  bool _isTransmitting = false;
  String? _errorMessage;
  String? _successMessage;
  String _solicitudId = solicitudDemoDefault;
  TransmissionStatus _estadoGeneral = TransmissionStatus.pendiente;
  List<TransmissionStepModel> _pasos = [];
  int _pasoActual = 0;
  String? _numeroExpedienteOficial;
  String? _tiempoEstimadoRespuesta;
  DateTime? _fechaEnvio;
  String? _mensajeFinal;

  bool get isLoading => _isLoading;
  bool get isTransmitting => _isTransmitting;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  String get solicitudId => _solicitudId;
  TransmissionStatus get estadoGeneral => _estadoGeneral;
  List<TransmissionStepModel> get pasos => List.unmodifiable(_pasos);
  int get pasoActual => _pasoActual;
  String? get numeroExpedienteOficial => _numeroExpedienteOficial;
  String? get tiempoEstimadoRespuesta => _tiempoEstimadoRespuesta;
  DateTime? get fechaEnvio => _fechaEnvio;
  String? get mensajeFinal => _mensajeFinal;

  bool get isCompletado => _estadoGeneral == TransmissionStatus.completado;
  bool get isError => _estadoGeneral == TransmissionStatus.error;
  bool get canStart =>
      _estadoGeneral == TransmissionStatus.pendiente && !_isTransmitting;

  bool canContinueToStatus() => isCompletado;

  TransmissionModel get model => TransmissionModel(
        solicitudId: _solicitudId,
        estadoGeneral: _estadoGeneral,
        pasos: _pasos,
        numeroExpedienteOficial: _numeroExpedienteOficial,
        tiempoEstimadoRespuesta: _tiempoEstimadoRespuesta,
        fechaEnvio: _fechaEnvio,
        mensajeFinal: _mensajeFinal,
      );

  Future<void> loadTransmission(String solicitudId) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    _solicitudId =
        solicitudId.isNotEmpty ? solicitudId : solicitudDemoDefault;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 350));

    resetTransmission(silent: true);
    _isLoading = false;
    notifyListeners();
  }

  void resetTransmission({bool silent = false}) {
    _isTransmitting = false;
    _estadoGeneral = TransmissionStatus.pendiente;
    _pasoActual = 0;
    _numeroExpedienteOficial = null;
    _tiempoEstimadoRespuesta = null;
    _fechaEnvio = null;
    _mensajeFinal = null;
    _pasos = _buildInitialSteps();
    if (!silent) {
      _successMessage = 'Transmisión reiniciada.';
      notifyListeners();
    }
  }

  Future<void> startTransmission() async {
    if (_isTransmitting || _estadoGeneral == TransmissionStatus.completado) {
      return;
    }

    _isTransmitting = true;
    _estadoGeneral = TransmissionStatus.transmitiendo;
    _errorMessage = null;
    _successMessage = null;
    _numeroExpedienteOficial = null;
    _tiempoEstimadoRespuesta = null;
    _fechaEnvio = null;
    _mensajeFinal = null;
    _pasos = _buildInitialSteps();
    notifyListeners();

    try {
      for (var i = 0; i < _pasos.length; i++) {
        _pasoActual = i;
        await _runStep(i);
      }

      _numeroExpedienteOficial =
          'EXP-ALF-2026-${_expedienteSecuencia.toString().padLeft(4, '0')}';
      _expedienteSecuencia++;
      _tiempoEstimadoRespuesta = '24 a 48 horas';
      _fechaEnvio = DateTime.now();
      _mensajeFinal = mensajeFinalExito;
      _estadoGeneral = TransmissionStatus.completado;
      _successMessage = _mensajeFinal;
    } catch (e) {
      _estadoGeneral = TransmissionStatus.error;
      _errorMessage = 'Error en la transmisión. Intente nuevamente.';
      _markCurrentStepError();
    } finally {
      _isTransmitting = false;
      notifyListeners();
    }
  }

  Future<void> retryTransmission() async {
    resetTransmission(silent: true);
    await startTransmission();
  }

  Future<void> _runStep(int index) async {
    _updateStep(index, TransmissionStepStatus.enProceso, progreso: 0);
    notifyListeners();

    final step = _pasos[index];

    if (step.id == 'subiendo-documentos') {
      for (var p = 0; p <= 10; p++) {
        await Future<void>.delayed(const Duration(milliseconds: 120));
        _updateStep(
          index,
          TransmissionStepStatus.enProceso,
          progreso: p / 10,
        );
        notifyListeners();
      }
    } else {
      await Future<void>.delayed(const Duration(milliseconds: 700));
    }

    _updateStep(index, TransmissionStepStatus.completado, progreso: 1);
    notifyListeners();
  }

  void _updateStep(
    int index,
    TransmissionStepStatus estado, {
    double? progreso,
  }) {
    _pasos[index] = _pasos[index].copyWith(
      estado: estado,
      progreso: progreso ?? _pasos[index].progreso,
    );
  }

  void _markCurrentStepError() {
    if (_pasoActual >= 0 && _pasoActual < _pasos.length) {
      _updateStep(_pasoActual, TransmissionStepStatus.error);
    }
  }

  static List<TransmissionStepModel> _buildInitialSteps() {
    return const [
      TransmissionStepModel(
        id: 'validando-datos',
        titulo: 'Validando datos',
        descripcion: 'Revisión de consistencia de la solicitud y del solicitante.',
        estado: TransmissionStepStatus.pendiente,
      ),
      TransmissionStepModel(
        id: 'verificando-documentos',
        titulo: 'Verificando documentos obligatorios',
        descripcion: 'Control de checklist documental mínimo requerido.',
        estado: TransmissionStepStatus.pendiente,
      ),
      TransmissionStepModel(
        id: 'subiendo-documentos',
        titulo: 'Subiendo documentos',
        descripcion: 'Carga simulada de imágenes y archivos adjuntos.',
        estado: TransmissionStepStatus.pendiente,
      ),
      TransmissionStepModel(
        id: 'registrando-sistema',
        titulo: 'Registrando en sistema central',
        descripcion: 'Sincronización con el núcleo operativo del banco.',
        estado: TransmissionStepStatus.pendiente,
      ),
      TransmissionStepModel(
        id: 'asignando-expediente',
        titulo: 'Asignando expediente',
        descripcion: 'Generación del expediente oficial de evaluación.',
        estado: TransmissionStepStatus.pendiente,
      ),
      TransmissionStepModel(
        id: 'enviado-comite',
        titulo: 'Solicitud enviada al comité',
        descripcion: 'Derivación al comité de evaluación crediticia.',
        estado: TransmissionStepStatus.pendiente,
      ),
    ];
  }
}
