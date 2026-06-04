import 'package:flutter/foundation.dart';

import '../domain/buro_result_model.dart';

/// ViewModel de consulta de buró y listas (HU-V08).
class BuroViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  String? _clientId;
  String _nombresCliente = '';
  String _dniConsultado = '';
  bool _consentimientoAceptado = false;
  bool _firmaSimulada = false;
  BuroResultModel? _resultado;
  BuroStatus? _status;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  String? get clientId => _clientId;
  String get nombresCliente => _nombresCliente;
  String get dniConsultado => _dniConsultado;
  bool get consentimientoAceptado => _consentimientoAceptado;
  bool get firmaSimulada => _firmaSimulada;
  BuroResultModel? get resultado => _resultado;
  BuroStatus? get status => _status;

  bool get tieneResultado =>
      _resultado != null && _resultado!.resultadoDisponible;

  bool get puedeContinuar =>
      tieneResultado && (_resultado?.puedeContinuarSolicitud ?? false);

  Future<void> loadClient(String? clientId) async {
    _isLoading = true;
    _clientId = clientId;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 300));

    if (clientId != null) {
      final seed = _clientSeed[clientId];
      if (seed != null) {
        _nombresCliente = seed.nombres;
        _dniConsultado = seed.documento;
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  void setDni(String value) {
    _dniConsultado = value;
    notifyListeners();
  }

  void toggleConsentimiento(bool value) {
    _consentimientoAceptado = value;
    notifyListeners();
  }

  void registrarFirmaSimulada() {
    _firmaSimulada = true;
    notifyListeners();
  }

  bool canConsult() {
    final dni = _dniConsultado.replaceAll(RegExp(r'\D'), '');
    return dni.length == 8 &&
        _consentimientoAceptado &&
        _firmaSimulada &&
        !_isLoading;
  }

  Future<void> consultarBuro() async {
    final dni = _dniConsultado.replaceAll(RegExp(r'\D'), '');
    if (dni.length != 8) {
      _errorMessage = 'El DNI debe tener 8 dígitos.';
      notifyListeners();
      return;
    }
    if (!_consentimientoAceptado) {
      _errorMessage = 'Debe registrar el consentimiento del cliente.';
      notifyListeners();
      return;
    }
    if (!_firmaSimulada) {
      _errorMessage = 'Debe registrar la firma simulada del cliente.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    _resultado = null;
    _status = null;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 1100));

    final mock = _resolveMockResult(dni);
    _resultado = mock;
    _status = mock.status;
    _successMessage = 'Consulta de buró completada.';
    _isLoading = false;
    notifyListeners();
  }

  void limpiarResultado() {
    _resultado = null;
    _status = null;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  BuroResultModel _resolveMockResult(String dni) {
    final builder = _mockByDni[dni];
    if (builder != null) {
      return builder(
        clientId: _clientId,
        nombres:
            _nombresCliente.isNotEmpty ? _nombresCliente : 'Cliente consultado',
        documento: dni,
        firmaOk: _firmaSimulada,
      );
    }

    return BuroResultModel(
      clientId: _clientId,
      nombres: _nombresCliente.isNotEmpty ? _nombresCliente : 'Cliente consultado',
      documento: dni,
      calificacionSbs: CalificacionSbsBuro.normal,
      entidadesConDeuda: 1,
      deudaTotalPen: 2500,
      mayorDeuda: 2500,
      diasMayorMora: 0,
      enListaNegra: false,
      recomendacion:
          'Sin alertas relevantes en centrales. Puede continuar evaluación comercial.',
      fechaConsulta: DateTime.now(),
      firmaConsentimientoRegistrada: _firmaSimulada,
      resultadoDisponible: true,
      status: BuroStatus.apto,
    );
  }
}

class _ClientSeed {
  const _ClientSeed({required this.nombres, required this.documento});
  final String nombres;
  final String documento;
}

final Map<String, _ClientSeed> _clientSeed = {
  'cli-001': const _ClientSeed(nombres: 'Rosa Quispe', documento: '45678912'),
  'cli-002': const _ClientSeed(nombres: 'Miguel Huamán', documento: '72345618'),
  'cli-003': const _ClientSeed(nombres: 'Carmen Flores', documento: '40123456'),
  'cli-004': const _ClientSeed(nombres: 'José Ramos', documento: '10876543'),
  'cli-005': const _ClientSeed(nombres: 'Ana Torres', documento: '71234567'),
};

typedef _MockBuilder = BuroResultModel Function({
  String? clientId,
  required String nombres,
  required String documento,
  required bool firmaOk,
});

BuroResultModel _mockRosa({
  String? clientId,
  required String nombres,
  required String documento,
  required bool firmaOk,
}) =>
    BuroResultModel(
      clientId: clientId ?? 'cli-001',
      nombres: nombres,
      documento: documento,
      calificacionSbs: CalificacionSbsBuro.normal,
      entidadesConDeuda: 2,
      deudaTotalPen: 3200,
      mayorDeuda: 2800,
      diasMayorMora: 0,
      enListaNegra: false,
      recomendacion:
          'Cliente con comportamiento normal. Proceder con solicitud estándar.',
      fechaConsulta: DateTime.now(),
      firmaConsentimientoRegistrada: firmaOk,
      resultadoDisponible: true,
      status: BuroStatus.apto,
    );

BuroResultModel _mockMiguel({
  String? clientId,
  required String nombres,
  required String documento,
  required bool firmaOk,
}) =>
    BuroResultModel(
      clientId: clientId ?? 'cli-002',
      nombres: nombres,
      documento: documento,
      calificacionSbs: CalificacionSbsBuro.cpp,
      entidadesConDeuda: 3,
      deudaTotalPen: 5400,
      mayorDeuda: 3100,
      diasMayorMora: 15,
      enListaNegra: false,
      recomendacion:
          'Requiere revisión de flujo de caja y garantías adicionales antes de aprobar.',
      fechaConsulta: DateTime.now(),
      firmaConsentimientoRegistrada: firmaOk,
      resultadoDisponible: true,
      status: BuroStatus.revisar,
    );

BuroResultModel _mockCarmen({
  String? clientId,
  required String nombres,
  required String documento,
  required bool firmaOk,
}) =>
    BuroResultModel(
      clientId: clientId ?? 'cli-003',
      nombres: nombres,
      documento: documento,
      calificacionSbs: CalificacionSbsBuro.deficiente,
      entidadesConDeuda: 4,
      deudaTotalPen: 8900,
      mayorDeuda: 4200,
      diasMayorMora: 45,
      enListaNegra: false,
      recomendacion:
          'Historial con mora significativa. Escalar a analista senior.',
      fechaConsulta: DateTime.now(),
      firmaConsentimientoRegistrada: firmaOk,
      resultadoDisponible: true,
      status: BuroStatus.revisar,
    );

BuroResultModel _mockJose({
  String? clientId,
  required String nombres,
  required String documento,
  required bool firmaOk,
}) =>
    BuroResultModel(
      clientId: clientId ?? 'cli-004',
      nombres: nombres,
      documento: documento,
      calificacionSbs: CalificacionSbsBuro.normal,
      entidadesConDeuda: 3,
      deudaTotalPen: 12400,
      mayorDeuda: 7500,
      diasMayorMora: 5,
      enListaNegra: false,
      recomendacion:
          'Deuda vigente controlada. Puede continuar con condiciones estándar.',
      fechaConsulta: DateTime.now(),
      firmaConsentimientoRegistrada: firmaOk,
      resultadoDisponible: true,
      status: BuroStatus.apto,
    );

BuroResultModel _mockAna({
  String? clientId,
  required String nombres,
  required String documento,
  required bool firmaOk,
}) =>
    BuroResultModel(
      clientId: clientId ?? 'cli-005',
      nombres: nombres,
      documento: documento,
      calificacionSbs: CalificacionSbsBuro.perdida,
      entidadesConDeuda: 5,
      deudaTotalPen: 18500,
      mayorDeuda: 9200,
      diasMayorMora: 120,
      enListaNegra: true,
      motivoBloqueo:
          'Cliente reportado en lista de restricción interna por fraude documentario.',
      recomendacion:
          'No iniciar nueva solicitud. Derivar a área de cumplimiento.',
      fechaConsulta: DateTime.now(),
      firmaConsentimientoRegistrada: firmaOk,
      resultadoDisponible: true,
      status: BuroStatus.bloqueado,
    );

final Map<String, _MockBuilder> _mockByDni = {
  '45678912': _mockRosa,
  '72345618': _mockMiguel,
  '40123456': _mockCarmen,
  '10876543': _mockJose,
  '71234567': _mockAna,
};
