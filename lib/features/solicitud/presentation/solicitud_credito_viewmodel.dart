import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../../core/location/location_service.dart';
import '../../../core/supabase/supabase_helper.dart';
import '../data/solicitud_repository.dart';
import '../domain/credit_request_model.dart';

/// ViewModel del wizard de solicitud de crédito (HU-V04).
class SolicitudCreditoViewModel extends ChangeNotifier {
  static const double teaReferencialDefault = 0.36;
  static int _expedienteSecuencia = 1;
  final LocationService _locationService = LocationService.instance;

  int _pasoActual = 0;
  bool _isLoading = false;
  bool _isLocating = false;
  String? _errorMessage;
  String? _successMessage;
  String? _locationStatus;

  double? _latCaptura;
  double? _lngCaptura;

  String? get locationStatus => _locationStatus;
  bool get isLocating => _isLocating;
  double? get latCaptura => _latCaptura;
  double? get lngCaptura => _lngCaptura;

  String? _clientId;
  String _nombres = '';
  String _apellidos = '';
  String _documento = '';
  String _fechaNacimiento = '';
  EstadoCivil? _estadoCivil;
  GradoInstruccion? _gradoInstruccion;
  String _telefono = '';
  String _correo = '';
  TipoNegocio? _tipoNegocio;
  String _nombreNegocio = '';
  String _direccionNegocio = '';
  int _antiguedadNegocioMeses = 0;
  double _ingresosMensuales = 0;
  double _gastosMensuales = 0;
  double _patrimonioEstimado = 0;
  String _destinoCredito = '';
  String _actividadEconomica = '';
  double _montoSolicitado = 5000;
  int _plazoMeses = 12;
  Moneda _moneda = Moneda.pen;
  TipoCuota? _tipoCuota;
  Garantia? _garantia;
  final double _teaReferencial = teaReferencialDefault;
  double _cuotaEstimada = 0;
  bool _aceptaDeclaracion = false;
  bool _firmaSimulada = false;
  EstadoSolicitud _estadoSolicitud = EstadoSolicitud.borrador;
  String? _numeroExpediente;

  int get pasoActual => _pasoActual;
  bool get isLoading => _isLoading;

  Future<void> captureLocation() async {
    if (_latCaptura != null) return;
    _isLocating = true;
    _locationStatus = 'Obteniendo ubicación…';
    notifyListeners();

    final result = await _locationService.getCurrentPositionWithFallback();

    _latCaptura = result.lat;
    _lngCaptura = result.lng;

    if (result.hasLocation && !result.fromFallback) {
      _locationStatus = 'Ubicación real capturada.';
    } else if (result.hasLocation && result.fromFallback) {
      _locationStatus = 'Usando ubicación de referencia.';
    } else {
      _locationStatus = result.errorMessage ?? 'Ubicación no disponible.';
    }

    _isLocating = false;
    notifyListeners();
  }
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  String? get clientId => _clientId;
  String? get numeroExpediente => _numeroExpediente;

  String get nombres => _nombres;
  String get apellidos => _apellidos;
  String get documento => _documento;
  String get fechaNacimiento => _fechaNacimiento;
  EstadoCivil? get estadoCivil => _estadoCivil;
  GradoInstruccion? get gradoInstruccion => _gradoInstruccion;
  String get telefono => _telefono;
  String get correo => _correo;
  TipoNegocio? get tipoNegocio => _tipoNegocio;
  String get nombreNegocio => _nombreNegocio;
  String get direccionNegocio => _direccionNegocio;
  int get antiguedadNegocioMeses => _antiguedadNegocioMeses;
  double get ingresosMensuales => _ingresosMensuales;
  double get gastosMensuales => _gastosMensuales;
  double get patrimonioEstimado => _patrimonioEstimado;
  String get destinoCredito => _destinoCredito;
  String get actividadEconomica => _actividadEconomica;
  double get montoSolicitado => _montoSolicitado;
  int get plazoMeses => _plazoMeses;
  Moneda get moneda => _moneda;
  TipoCuota? get tipoCuota => _tipoCuota;
  Garantia? get garantia => _garantia;
  double get teaReferencial => _teaReferencial;
  double get cuotaEstimada => _cuotaEstimada;
  bool get aceptaDeclaracion => _aceptaDeclaracion;
  bool get firmaSimulada => _firmaSimulada;
  EstadoSolicitud get estadoSolicitud => _estadoSolicitud;

  double get totalAPagar => _cuotaEstimada * _plazoMeses;
  double get costoFinanciero => totalAPagar - _montoSolicitado;

  static const List<String> pasoTitulos = [
    'Solicitante',
    'Negocio',
    'Crédito',
    'Confirmación',
  ];

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
  }

  Future<void> loadInitialData(String? clientId) async {
    _isLoading = true;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 300));

    _clientId = clientId;
    if (clientId != null) {
      final seed = _clientSeed[clientId];
      if (seed != null) {
        _nombres = seed.nombres;
        _apellidos = seed.apellidos;
        _documento = seed.documento;
        _telefono = seed.telefono;
        _correo = seed.correo;
        _fechaNacimiento = seed.fechaNacimiento;
        _tipoNegocio = seed.tipoNegocio;
        _nombreNegocio = seed.nombreNegocio;
        _direccionNegocio = seed.direccionNegocio;
        _antiguedadNegocioMeses = seed.antiguedadMeses;
        _actividadEconomica = seed.actividadEconomica;
        if (seed.montoSugerido != null) {
          _montoSolicitado = seed.montoSugerido!.clamp(500, 150000);
        }
        if (seed.plazoSugerido != null &&
            plazosPermitidosMeses.contains(seed.plazoSugerido)) {
          _plazoMeses = seed.plazoSugerido!;
        }
      }
    }

    calculateInstallment();
    _isLoading = false;
    notifyListeners();
  }

  void setNombres(String v) {
    _nombres = v;
    notifyListeners();
  }

  void setApellidos(String v) {
    _apellidos = v;
    notifyListeners();
  }

  void setDocumento(String v) {
    _documento = v;
    notifyListeners();
  }

  void setFechaNacimiento(String v) {
    _fechaNacimiento = v;
    notifyListeners();
  }

  void setEstadoCivil(EstadoCivil? v) {
    _estadoCivil = v;
    notifyListeners();
  }

  void setGradoInstruccion(GradoInstruccion? v) {
    _gradoInstruccion = v;
    notifyListeners();
  }

  void setTelefono(String v) {
    _telefono = v;
    notifyListeners();
  }

  void setCorreo(String v) {
    _correo = v;
    notifyListeners();
  }

  void setTipoNegocio(TipoNegocio? v) {
    _tipoNegocio = v;
    notifyListeners();
  }

  void setNombreNegocio(String v) {
    _nombreNegocio = v;
    notifyListeners();
  }

  void setDireccionNegocio(String v) {
    _direccionNegocio = v;
    notifyListeners();
  }

  void setAntiguedadNegocioMeses(int v) {
    _antiguedadNegocioMeses = v;
    notifyListeners();
  }

  void setIngresosMensuales(double v) {
    _ingresosMensuales = v;
    notifyListeners();
  }

  void setGastosMensuales(double v) {
    _gastosMensuales = v;
    notifyListeners();
  }

  void setPatrimonioEstimado(double v) {
    _patrimonioEstimado = v;
    notifyListeners();
  }

  void setDestinoCredito(String v) {
    _destinoCredito = v;
    notifyListeners();
  }

  void setActividadEconomica(String v) {
    _actividadEconomica = v;
    notifyListeners();
  }

  void setMontoSolicitado(double v) {
    _montoSolicitado = v.clamp(500, 150000);
    calculateInstallment();
    notifyListeners();
  }

  void setPlazoMeses(int v) {
    _plazoMeses = v;
    calculateInstallment();
    notifyListeners();
  }

  void setMoneda(Moneda v) {
    _moneda = v;
    notifyListeners();
  }

  void setTipoCuota(TipoCuota? v) {
    _tipoCuota = v;
    notifyListeners();
  }

  void setGarantia(Garantia? v) {
    _garantia = v;
    notifyListeners();
  }

  void setAceptaDeclaracion(bool v) {
    _aceptaDeclaracion = v;
    notifyListeners();
  }

  void registrarFirmaSimulada() {
    _firmaSimulada = true;
    notifyListeners();
  }

  void calculateInstallment() {
    final tea = _teaReferencial;
    final monto = _montoSolicitado;
    final plazo = _plazoMeses;

    if (monto <= 0 || plazo <= 0) {
      _cuotaEstimada = 0;
      return;
    }

    final tasaMensual = math.pow(1 + tea, 1 / 12) - 1;
    if (tasaMensual <= 0) {
      _cuotaEstimada = monto / plazo;
      return;
    }

    final factor = 1 - math.pow(1 + tasaMensual, -plazo);
    if (factor == 0) {
      _cuotaEstimada = 0;
      return;
    }

    _cuotaEstimada = monto * tasaMensual / factor;
  }

  bool validateCurrentStep() {
    clearMessages();

    switch (_pasoActual) {
      case 0:
        if (_nombres.trim().isEmpty) {
          _errorMessage = 'Los nombres son obligatorios.';
          notifyListeners();
          return false;
        }
        if (_apellidos.trim().isEmpty) {
          _errorMessage = 'Los apellidos son obligatorios.';
          notifyListeners();
          return false;
        }
        final doc = _documento.replaceAll(RegExp(r'\D'), '');
        if (doc.length != 8) {
          _errorMessage = 'El DNI debe tener 8 dígitos.';
          notifyListeners();
          return false;
        }
        final tel = _telefono.replaceAll(RegExp(r'\D'), '');
        if (tel.length != 9) {
          _errorMessage = 'El teléfono debe tener 9 dígitos.';
          notifyListeners();
          return false;
        }
        return true;

      case 1:
        if (_tipoNegocio == null) {
          _errorMessage = 'Seleccione el tipo de negocio.';
          notifyListeners();
          return false;
        }
        if (_nombreNegocio.trim().isEmpty) {
          _errorMessage = 'El nombre del negocio es obligatorio.';
          notifyListeners();
          return false;
        }
        if (_direccionNegocio.trim().isEmpty) {
          _errorMessage = 'La dirección del negocio es obligatoria.';
          notifyListeners();
          return false;
        }
        if (_antiguedadNegocioMeses < 6) {
          _errorMessage = 'La antigüedad mínima del negocio es 6 meses.';
          notifyListeners();
          return false;
        }
        if (_ingresosMensuales <= 0) {
          _errorMessage = 'Los ingresos mensuales deben ser mayores a 0.';
          notifyListeners();
          return false;
        }
        if (_gastosMensuales < 0) {
          _errorMessage = 'Los gastos mensuales no pueden ser negativos.';
          notifyListeners();
          return false;
        }
        if (_destinoCredito.trim().isEmpty) {
          _errorMessage = 'El destino del crédito es obligatorio.';
          notifyListeners();
          return false;
        }
        return true;

      case 2:
        if (_montoSolicitado < 500 || _montoSolicitado > 150000) {
          _errorMessage = 'El monto debe estar entre S/ 500 y S/ 150,000.';
          notifyListeners();
          return false;
        }
        if (!plazosPermitidosMeses.contains(_plazoMeses)) {
          _errorMessage = 'Seleccione un plazo válido.';
          notifyListeners();
          return false;
        }
        if (_moneda != Moneda.pen && _moneda != Moneda.usd) {
          _errorMessage = 'Seleccione la moneda (PEN o USD).';
          notifyListeners();
          return false;
        }
        if (_tipoCuota == null) {
          _errorMessage = 'Seleccione el tipo de cuota.';
          notifyListeners();
          return false;
        }
        if (_garantia == null) {
          _errorMessage = 'Seleccione la garantía.';
          notifyListeners();
          return false;
        }
        calculateInstallment();
        return true;

      case 3:
        if (!_aceptaDeclaracion) {
          _errorMessage = 'Debe aceptar la declaración jurada.';
          notifyListeners();
          return false;
        }
        if (!_firmaSimulada) {
          _errorMessage = 'Debe registrar la firma simulada.';
          notifyListeners();
          return false;
        }
        return true;

      default:
        return true;
    }
  }

  bool nextStep() {
    if (!validateCurrentStep()) return false;
    if (_pasoActual < 3) {
      _pasoActual++;
      if (_pasoActual == 2) calculateInstallment();
      notifyListeners();
    }
    return true;
  }

  void previousStep() {
    if (_pasoActual > 0) {
      _pasoActual--;
      notifyListeners();
    }
  }

  Future<bool> submitRequest() async {
    if (!validateCurrentStep()) return false;

    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    await captureLocation();

    final model = buildModel();

    if (SupabaseHelper.hasSession) {
      try {
        SupabaseHelper.log('SolicitudCreditoViewModel submit Supabase');
        final result = await SolicitudRepository.instance.insertSolicitud(
          model,
          latCaptura: _latCaptura,
          lngCaptura: _lngCaptura,
        );
        _numeroExpediente = result.numeroExpediente;
        _estadoSolicitud = EstadoSolicitud.enviadoDemo;
        _successMessage =
            'Solicitud registrada en Supabase. Expediente $_numeroExpediente.';
        _isLoading = false;
        notifyListeners();
        return true;
      } catch (error, stackTrace) {
        SupabaseHelper.log('solicitud falló, usando fallback mock');
        SupabaseHelper.logError(error, stackTrace);
      }
    }

    await Future<void>.delayed(const Duration(milliseconds: 800));

    _numeroExpediente =
        'ALF-LOCAL-${_expedienteSecuencia.toString().padLeft(4, '0')}';
    _expedienteSecuencia++;
    _estadoSolicitud = EstadoSolicitud.enviadoDemo;

    _successMessage =
        'Solicitud registrada localmente. Expediente $_numeroExpediente (${_estadoSolicitud.label}).';

    _isLoading = false;
    notifyListeners();
    return true;
  }

  CreditRequestModel buildModel() {
    return CreditRequestModel(
      clientId: _clientId,
      nombres: _nombres,
      apellidos: _apellidos,
      documento: _documento,
      fechaNacimiento: _fechaNacimiento,
      estadoCivil: _estadoCivil,
      gradoInstruccion: _gradoInstruccion,
      telefono: _telefono,
      correo: _correo,
      tipoNegocio: _tipoNegocio,
      nombreNegocio: _nombreNegocio,
      direccionNegocio: _direccionNegocio,
      antiguedadNegocioMeses: _antiguedadNegocioMeses,
      ingresosMensuales: _ingresosMensuales,
      gastosMensuales: _gastosMensuales,
      patrimonioEstimado: _patrimonioEstimado,
      destinoCredito: _destinoCredito,
      actividadEconomica: _actividadEconomica,
      montoSolicitado: _montoSolicitado,
      plazoMeses: _plazoMeses,
      moneda: _moneda,
      tipoCuota: _tipoCuota,
      garantia: _garantia,
      teaReferencial: _teaReferencial,
      cuotaEstimada: _cuotaEstimada,
      aceptaDeclaracion: _aceptaDeclaracion,
      firmaSimulada: _firmaSimulada,
      estadoSolicitud: _estadoSolicitud,
      numeroExpediente: _numeroExpediente,
    );
  }
}

class _ClientSeed {
  const _ClientSeed({
    required this.nombres,
    required this.apellidos,
    required this.documento,
    required this.telefono,
    required this.correo,
    required this.fechaNacimiento,
    required this.tipoNegocio,
    required this.nombreNegocio,
    required this.direccionNegocio,
    required this.antiguedadMeses,
    required this.actividadEconomica,
    this.montoSugerido,
    this.plazoSugerido,
  });

  final String nombres;
  final String apellidos;
  final String documento;
  final String telefono;
  final String correo;
  final String fechaNacimiento;
  final TipoNegocio tipoNegocio;
  final String nombreNegocio;
  final String direccionNegocio;
  final int antiguedadMeses;
  final String actividadEconomica;
  final double? montoSugerido;
  final int? plazoSugerido;
}

final Map<String, _ClientSeed> _clientSeed = {
  'cli-001': const _ClientSeed(
    nombres: 'Rosa',
    apellidos: 'Quispe',
    documento: '45678912',
    telefono: '987654321',
    correo: 'rosa.quispe@email.demo',
    fechaNacimiento: '12/08/1988',
    tipoNegocio: TipoNegocio.comercioMinorista,
    nombreNegocio: 'Bodega Quispe',
    direccionNegocio: 'Av. Los Olivos 234, Los Olivos, Lima',
    antiguedadMeses: 48,
    actividadEconomica: 'Venta al por menor',
    montoSugerido: 12000,
    plazoSugerido: 18,
  ),
  'cli-002': const _ClientSeed(
    nombres: 'Miguel',
    apellidos: 'Huamán',
    documento: '72345618',
    telefono: '912345678',
    correo: 'miguel.huaman@email.demo',
    fechaNacimiento: '03/05/1990',
    tipoNegocio: TipoNegocio.servicios,
    nombreNegocio: 'Taller Huamán',
    direccionNegocio: 'Jr. Huascar 120, Huancayo',
    antiguedadMeses: 24,
    actividadEconomica: 'Reparación mecánica',
    montoSugerido: 18000,
    plazoSugerido: 24,
  ),
  'cli-003': const _ClientSeed(
    nombres: 'Carmen',
    apellidos: 'Flores',
    documento: '40123456',
    telefono: '956112233',
    correo: 'carmen.flores@email.demo',
    fechaNacimiento: '20/11/1985',
    tipoNegocio: TipoNegocio.alimentos,
    nombreNegocio: 'Pollería Flores',
    direccionNegocio: 'Mz. B Lt. 8 Urb. Santa Rosa, Callao',
    antiguedadMeses: 72,
    actividadEconomica: 'Restaurante / pollería',
    montoSugerido: 3500,
    plazoSugerido: 6,
  ),
  'cli-004': const _ClientSeed(
    nombres: 'José',
    apellidos: 'Ramos',
    documento: '10876543',
    telefono: '934567890',
    correo: 'jose.ramos@email.demo',
    fechaNacimiento: '07/02/1982',
    tipoNegocio: TipoNegocio.transporte,
    nombreNegocio: 'Transportes Ramos EIRL',
    direccionNegocio: 'Av. Universitaria 890, SMP',
    antiguedadMeses: 96,
    actividadEconomica: 'Transporte de carga',
    montoSugerido: 8000,
    plazoSugerido: 12,
  ),
  'cli-005': const _ClientSeed(
    nombres: 'Ana',
    apellidos: 'Torres',
    documento: '71234567',
    telefono: '998776554',
    correo: 'ana.torres@email.demo',
    fechaNacimiento: '15/09/1987',
    tipoNegocio: TipoNegocio.textil,
    nombreNegocio: 'Confecciones Torres',
    direccionNegocio: 'Calle Las Flores 45, SJL',
    antiguedadMeses: 60,
    actividadEconomica: 'Confección textil',
    montoSugerido: 25000,
    plazoSugerido: 30,
  ),
};
