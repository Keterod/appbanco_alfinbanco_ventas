import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../../core/location/location_service.dart';
import '../../../core/storage/borrador_local_datasource.dart';
import '../../../core/supabase/supabase_helper.dart';
import '../../../core/sync/sync_manager.dart';
import '../../../core/sync/sync_models.dart';
import '../../auth/data/asesor_repository.dart';
import '../../buro/domain/buro_result_model.dart';
import '../data/solicitud_repository.dart';
import '../domain/credit_request_model.dart';
import '../domain/cronograma_row.dart';
import '../domain/pre_evaluacion_result.dart';

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
  List<CronogramaRow> _cronograma = [];
  bool _cronogramaVisible = false;
  PreEvaluacionResult? _preEvaluacion;
  BuroStatus? _buroStatus;

  int get pasoActual => _pasoActual;
  bool get isLoading => _isLoading;
  List<CronogramaRow> get cronograma => _cronograma;
  bool get cronogramaVisible => _cronogramaVisible;
  PreEvaluacionResult? get preEvaluacion => _preEvaluacion;
  BuroStatus? get buroStatus => _buroStatus;

  void setBuroStatus(BuroStatus? status) {
    _buroStatus = status;
    evaluarCliente();
  }

  void toggleCronograma() {
    _cronogramaVisible = !_cronogramaVisible;
    notifyListeners();
  }

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

    // Intentar restaurar borrador previo
    final draft =
        await BorradorLocalDataSource.instance.loadBorrador(clienteId: clientId);
    if (draft != null) {
      _restoreFromDraft(draft);
    } else if (clientId != null) {
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
    evaluarCliente();
    notifyListeners();
  }

  void setGastosMensuales(double v) {
    _gastosMensuales = v;
    evaluarCliente();
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
    generarCronograma();
    evaluarCliente();
  }

  void generarCronograma() {
    final monto = _montoSolicitado;
    final plazo = _plazoMeses;
    final tea = _teaReferencial;

    if (monto <= 0 || plazo <= 0 || tea <= 0) {
      _cronograma = [];
      return;
    }

    debugPrint('[CRONOGRAMA] generando monto=$monto plazo=$plazo tea=$tea');

    final tem = (math.pow(1 + tea, 1 / 12) - 1).toDouble();
    final cuota = _cuotaEstimada;
    final fechaInicio = DateTime.now();
    final rows = <CronogramaRow>[];
    var saldo = monto;

    for (var i = 1; i <= plazo; i++) {
      final interes = saldo * tem;
      var capital = cuota - interes;
      if (capital < 0) capital = 0;
      saldo -= capital;
      if (saldo < 0) saldo = 0;

      // Ajuste última cuota: capital + saldo residual
      if (i == plazo && saldo > 0) {
        capital += saldo;
        saldo = 0;
      }

      rows.add(CronogramaRow(
        numeroCuota: i,
        fechaPago: _sumarMeses(fechaInicio, i),
        capital: _r2(capital),
        interes: _r2(interes),
        cuota: _r2(capital + interes),
        saldo: _r2(saldo),
      ));
    }

    _cronograma = rows;
    debugPrint(
        '[CRONOGRAMA] cuotas generadas=${rows.length} saldoFinal=${rows.last.saldo}');
  }

  static DateTime _sumarMeses(DateTime from, int meses) {
    final dia = from.day.clamp(1, 28);
    return DateTime(from.year, from.month + meses, dia);
  }

  static double _r2(double v) => (v * 100).roundToDouble() / 100;

  void evaluarCliente() {
    final ingresos = _ingresosMensuales;
    final gastos = _gastosMensuales;
    final cuota = _cuotaEstimada;

    debugPrint(
        '[PRE-EVAL] evaluando ingresos=$ingresos gastos=$gastos cuota=$cuota');

    if (ingresos <= 0) {
      _preEvaluacion = PreEvaluacionResult(
        score: 20,
        elegibilidad: Elegibilidad.noApto,
        ratioCapacidadPago: 0,
        capacidadDisponible: 0,
        riesgo: RiesgoCrediticio.alto,
        mensaje: 'Ingresos mensuales no válidos',
        motivos: ['Ingresos mensuales no válidos'],
      );
      debugPrint(
          '[PRE-EVAL] resultado=NO APTO score=${_preEvaluacion!.score} ratio=0');
      return;
    }

    final disponible = ingresos - gastos;
    if (disponible <= 0) {
      _preEvaluacion = PreEvaluacionResult(
        score: 30,
        elegibilidad: Elegibilidad.noApto,
        ratioCapacidadPago: 0,
        capacidadDisponible: disponible < 0 ? disponible : 0,
        riesgo: RiesgoCrediticio.alto,
        mensaje: 'Los gastos igualan o superan los ingresos',
        motivos: ['Los gastos igualan o superan los ingresos'],
      );
      debugPrint(
          '[PRE-EVAL] resultado=NO APTO score=${_preEvaluacion!.score} ratio=0');
      return;
    }

    final ratio = (cuota / disponible).clamp(0, 10).toDouble();
    var score = 100;
    Elegibilidad elegibilidad;
    RiesgoCrediticio riesgo;
    String mensaje;
    final motivos = <String>[];

    if (ratio <= 0.40) {
      elegibilidad = Elegibilidad.apto;
      riesgo = RiesgoCrediticio.bajo;
      mensaje = 'La cuota se encuentra dentro de la capacidad de pago';
      score -= 0;
    } else if (ratio <= 0.60) {
      elegibilidad = Elegibilidad.observado;
      riesgo = RiesgoCrediticio.medio;
      mensaje =
          'La cuota compromete una parte importante de la capacidad de pago';
      score -= 25;
      motivos.add(mensaje);
    } else {
      elegibilidad = Elegibilidad.noApto;
      riesgo = RiesgoCrediticio.alto;
      mensaje = 'La cuota supera la capacidad de pago recomendada';
      score -= 50;
      motivos.add(mensaje);
    }

    if (_buroStatus == BuroStatus.revisar) {
      if (elegibilidad == Elegibilidad.apto) {
        elegibilidad = Elegibilidad.observado;
        mensaje = 'Aprobado por capacidad, pero buró requiere revisión';
      }
      score -= 20;
      motivos.add('Buró del cliente requiere revisión');
    } else if (_buroStatus == BuroStatus.bloqueado) {
      elegibilidad = Elegibilidad.noApto;
      riesgo = RiesgoCrediticio.alto;
      mensaje = 'Cliente bloqueado por buró';
      score = 20;
      motivos.add('Cliente bloqueado por buró');
    }

    score = score.clamp(0, 100);

    _preEvaluacion = PreEvaluacionResult(
      score: score,
      elegibilidad: elegibilidad,
      ratioCapacidadPago: _r2(ratio),
      capacidadDisponible: _r2(disponible),
      riesgo: riesgo,
      mensaje: mensaje,
      motivos: motivos,
    );

    debugPrint(
        '[PRE-EVAL] resultado=${elegibilidad.label} score=$score ratio=$ratio');
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
      saveDraft();
      notifyListeners();
    }
    return true;
  }

  void previousStep() {
    if (_pasoActual > 0) {
      _pasoActual--;
      saveDraft();
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
        await _deleteCurrentDraft();
        _isLoading = false;
        notifyListeners();
        return true;
      } catch (error, stackTrace) {
        SupabaseHelper.log('solicitud falló, encolando sync');
        SupabaseHelper.logError(error, stackTrace);
        final asesor = AsesorRepository.instance.current;
        await SyncManager.instance.enqueueOperation(
          entityType: SyncEntityType.solicitudCredito,
          entityId: _numeroExpediente,
          operation: SyncOperation.insert,
          payload: {
            'asesor_id': asesor?.id,
            'cliente_id': model.clientId,
            'nombres': model.nombres,
            'apellidos': model.apellidos,
            'documento': model.documento,
            'telefono': model.telefono,
            'correo': model.correo,
            'monto_solicitado': model.montoSolicitado,
            'plazo_meses': model.plazoMeses,
            'moneda': model.moneda.name,
            'tipo_cuota': model.tipoCuota?.name,
            'garantia': model.garantia?.name,
            'destino_credito': model.destinoCredito,
            'actividad_economica': model.actividadEconomica,
            'ingresos_mensuales': model.ingresosMensuales,
            'gastos_mensuales': model.gastosMensuales,
            'lat_captura': _latCaptura,
            'lng_captura': _lngCaptura,
            'numero_expediente': _numeroExpediente,
          },
        );
      }
    }

    await Future<void>.delayed(const Duration(milliseconds: 800));

    _numeroExpediente =
        'ALF-LOCAL-${_expedienteSecuencia.toString().padLeft(4, '0')}';
    _expedienteSecuencia++;
    _estadoSolicitud = EstadoSolicitud.enviadoDemo;

    _successMessage =
        'Solicitud registrada localmente. Expediente $_numeroExpediente (${_estadoSolicitud.label}).';

    await _deleteCurrentDraft();
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

  /// Guarda el estado actual del formulario como borrador en SQLite.
  Future<void> saveDraft() {
    final asesor = AsesorRepository.instance.current;
    if (asesor == null) return Future<void>.value();
    return BorradorLocalDataSource.instance.saveBorrador(
      asesorId: asesor.id,
      clienteId: _clientId,
      clienteNombre: '$nombres $apellidos'.trim(),
      pasoActual: _pasoActual,
      formData: _buildDraftData(),
      montoSolicitado: _montoSolicitado,
    );
  }

  Map<String, dynamic> _buildDraftData() => {
        'nombres': _nombres,
        'apellidos': _apellidos,
        'documento': _documento,
        'fechaNacimiento': _fechaNacimiento,
        'estadoCivil': _estadoCivil?.name,
        'gradoInstruccion': _gradoInstruccion?.name,
        'telefono': _telefono,
        'correo': _correo,
        'tipoNegocio': _tipoNegocio?.name,
        'nombreNegocio': _nombreNegocio,
        'direccionNegocio': _direccionNegocio,
        'antiguedadNegocioMeses': _antiguedadNegocioMeses,
        'ingresosMensuales': _ingresosMensuales,
        'gastosMensuales': _gastosMensuales,
        'patrimonioEstimado': _patrimonioEstimado,
        'destinoCredito': _destinoCredito,
        'actividadEconomica': _actividadEconomica,
        'montoSolicitado': _montoSolicitado,
        'plazoMeses': _plazoMeses,
        'moneda': _moneda.name,
        'tipoCuota': _tipoCuota?.name,
        'garantia': _garantia?.name,
        'aceptaDeclaracion': _aceptaDeclaracion,
        'firmaSimulada': _firmaSimulada,
        'estadoSolicitud': _estadoSolicitud.name,
        'numeroExpediente': _numeroExpediente,
      };

  void _restoreFromDraft(Map<String, dynamic> draft) {
    final data = draft['datos_json'] as Map<String, dynamic>;
    _pasoActual = draft['paso_actual'] as int? ?? 0;
    _nombres = data['nombres'] as String? ?? '';
    _apellidos = data['apellidos'] as String? ?? '';
    _documento = data['documento'] as String? ?? '';
    _fechaNacimiento = data['fechaNacimiento'] as String? ?? '';
    _estadoCivil = (data['estadoCivil'] as String?) != null
        ? EstadoCivil.values.firstWhere(
            (e) => e.name == data['estadoCivil'],
            orElse: () => EstadoCivil.soltero,
          )
        : null;
    _gradoInstruccion = (data['gradoInstruccion'] as String?) != null
        ? GradoInstruccion.values.firstWhere(
            (e) => e.name == data['gradoInstruccion'],
            orElse: () => GradoInstruccion.secundaria,
          )
        : null;
    _telefono = data['telefono'] as String? ?? '';
    _correo = data['correo'] as String? ?? '';
    _tipoNegocio = (data['tipoNegocio'] as String?) != null
        ? TipoNegocio.values.firstWhere(
            (e) => e.name == data['tipoNegocio'],
            orElse: () => TipoNegocio.otro,
          )
        : null;
    _nombreNegocio = data['nombreNegocio'] as String? ?? '';
    _direccionNegocio = data['direccionNegocio'] as String? ?? '';
    _antiguedadNegocioMeses = data['antiguedadNegocioMeses'] as int? ?? 0;
    _ingresosMensuales = _toDouble(data['ingresosMensuales']) ?? 0;
    _gastosMensuales = _toDouble(data['gastosMensuales']) ?? 0;
    _patrimonioEstimado = _toDouble(data['patrimonioEstimado']) ?? 0;
    _destinoCredito = data['destinoCredito'] as String? ?? '';
    _actividadEconomica = data['actividadEconomica'] as String? ?? '';
    _montoSolicitado = _toDouble(data['montoSolicitado']) ?? 5000;
    _plazoMeses = data['plazoMeses'] as int? ?? 12;
    _moneda = (data['moneda'] as String?) != null
        ? Moneda.values.firstWhere(
            (e) => e.name == data['moneda'],
            orElse: () => Moneda.pen,
          )
        : Moneda.pen;
    _tipoCuota = (data['tipoCuota'] as String?) != null
        ? TipoCuota.values.firstWhere(
            (e) => e.name == data['tipoCuota'],
            orElse: () => TipoCuota.fija,
          )
        : null;
    _garantia = (data['garantia'] as String?) != null
        ? Garantia.values.firstWhere(
            (e) => e.name == data['garantia'],
            orElse: () => Garantia.personal,
          )
        : null;
    _aceptaDeclaracion = data['aceptaDeclaracion'] as bool? ?? false;
    _firmaSimulada = data['firmaSimulada'] as bool? ?? false;
    _numeroExpediente = data['numeroExpediente'] as String?;
  }

  Future<void> _deleteCurrentDraft() =>
      BorradorLocalDataSource.instance.deleteBorrador(clienteId: _clientId);

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
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
