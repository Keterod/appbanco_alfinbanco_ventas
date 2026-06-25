import 'dart:convert';
import 'dart:math' show min, pow;

import 'package:flutter/foundation.dart';

import '../../../core/supabase/supabase_client.dart';
import '../../../core/supabase/supabase_helper.dart';
import '../../auth/data/asesor_repository.dart';
import '../domain/request_status_model.dart';

class EstadoSolicitudesRepository {
  EstadoSolicitudesRepository._();
  static final EstadoSolicitudesRepository instance =
      EstadoSolicitudesRepository._();

  Future<List<RequestStatusModel>> loadSolicitudes() async {
    debugPrint('DEBUG VENTAS SUPABASE: estado_solicitudes query simple iniciado');

    if (!SupabaseHelper.hasSession) {
      debugPrint('DEBUG VENTAS SUPABASE: estado_solicitudes sin sesión');
      return [];
    }

    try {
      final rows = await SupabaseHelper.withTimeout(
        supabase
            .from('solicitudes_credito')
            .select('*')
            .order('created_at', ascending: false)
            .limit(100),
        operation: 'solicitudes_credito lista',
      );

      debugPrint('DEBUG VENTAS SUPABASE: solicitudes count=${rows.length}');
      debugPrint('DEBUG VENTAS SUPABASE: solicitudes first=${rows.isNotEmpty ? rows.first : null}');

      if (rows.isEmpty) {
        debugPrint('DEBUG VENTAS SUPABASE: estado_solicitudes vacío real en Supabase');
        return [];
      }

      return rows.map((row) => _mapRow(row)).toList();
    } catch (error, stackTrace) {
      SupabaseHelper.log('estado_solicitudes falló');
      SupabaseHelper.logError(error, stackTrace);
      return [];
    }
  }

  Future<RequestStatusModel?> loadSolicitudById(String id) async {
    SupabaseHelper.log('estado_solicitud detalle id=$id');

    if (!SupabaseHelper.hasSession) {
      return null;
    }

    try {
      final row = await SupabaseHelper.withTimeout(
        supabase
            .from('solicitudes_credito')
            .select('*')
            .eq('id', id)
            .maybeSingle(),
        operation: 'solicitudes_credito detalle',
      );

      if (row == null) return null;

      return _mapRow(row);
    } catch (error, stackTrace) {
      SupabaseHelper.logError(error, stackTrace);
      return null;
    }
  }

  Future<RequestStatusModel?> loadSolicitudByExpediente(
      String expediente) async {
    if (!SupabaseHelper.hasSession) return null;

    try {
      final row = await SupabaseHelper.withTimeout(
        supabase
            .from('solicitudes_credito')
            .select('*')
            .eq('numero_expediente', expediente)
            .maybeSingle(),
        operation: 'solicitudes_credito por expediente',
      );

      if (row == null) return null;

      return _mapRow(row);
    } catch (error, stackTrace) {
      SupabaseHelper.logError(error, stackTrace);
      return null;
    }
  }

  RequestStatusModel _mapRow(Map<String, dynamic> row) {
    final nombres = row['solicitante_nombre']?.toString() ?? '';
    final apellidos = row['solicitante_apellido']?.toString() ?? '';
    final clienteNombre = '$nombres $apellidos'.trim();
    final documento = row['solicitante_documento']?.toString() ?? '';
    final montoSolicitado = _toDouble(row['monto_solicitado']) ?? 0;
    final montoAprobado = _toDouble(row['monto_aprobado']);
    final createdAt = _parseDateTime(row['created_at']);
    final estadoStr = row['estado']?.toString() ?? 'enviada';

    final estado = _parseEstado(estadoStr);

    final timeline = _buildTimeline(
      estado: estado,
      createdAt: createdAt,
      row: row,
    );

    final diasDesdeEnvio = createdAt != null
        ? DateTime.now().difference(createdAt).inDays
        : 0;

    return RequestStatusModel(
      id: row['id']?.toString() ?? '',
      numeroExpediente:
          row['numero_expediente']?.toString() ?? 'SIN-EXP',
      clienteNombre: clienteNombre.isNotEmpty ? clienteNombre : 'Cliente',
      documento: documento,
      montoSolicitado: montoSolicitado,
      montoAprobado: montoAprobado,
      fechaEnvio: createdAt ?? DateTime.now(),
      diasDesdeEnvio: diasDesdeEnvio,
      analistaAsignado: row['analista_asignado']?.toString() ?? '—',
      estado: estado,
      motivoRechazo: row['motivo_rechazo']?.toString(),
      condicionAdicional: row['condicion_adicional']?.toString(),
      timeline: timeline,
      solicitudLocalId: row['solicitud_local_id']?.toString(),
      rawData: row,
    );
  }

  List<RequestTimelineItem> _buildTimeline({
    required RequestStatus estado,
    required DateTime? createdAt,
    required Map<String, dynamic> row,
  }) {
    final base = createdAt ?? DateTime.now();
    final items = <RequestTimelineItem>[
      RequestTimelineItem(
        id: 'tl-1',
        titulo: 'Solicitud registrada',
        descripcion: 'Registro en canal oficial de ventas.',
        responsable: row['asesor_id']?.toString() ?? 'Oficial de crédito',
        fechaHora: base,
        completado: true,
        estado: RequestStatus.enviada,
      ),
    ];

    final updatedAt = _parseDateTime(row['updated_at']);
    final estadoActual = estado;

    if (estadoActual.index >= RequestStatus.enComite.index) {
      items.add(RequestTimelineItem(
        id: 'tl-2',
        titulo: 'Enviada a comité',
        descripcion: 'Asignación al comité de evaluación.',
        responsable: 'Mesa de entrada',
        fechaHora: updatedAt ?? base.add(const Duration(hours: 4)),
        completado: true,
        estado: RequestStatus.enComite,
      ));
    }

    if (estadoActual.index >= RequestStatus.enEvaluacion.index) {
      items.add(RequestTimelineItem(
        id: 'tl-3',
        titulo: 'En evaluación',
        descripcion: 'Análisis de riesgo y capacidad de pago.',
        responsable: 'Analista crediticio',
        fechaHora: updatedAt ?? base.add(const Duration(days: 1)),
        completado: true,
        estado: RequestStatus.enEvaluacion,
      ));
    }

    if (estadoActual == RequestStatus.rechazada) {
      items.add(RequestTimelineItem(
        id: 'tl-4',
        titulo: 'Rechazada',
        descripcion: row['motivo_rechazo']?.toString() ??
            'No cumple política vigente.',
        responsable: 'Comité de crédito',
        fechaHora: updatedAt ?? base.add(const Duration(days: 2)),
        completado: true,
        estado: RequestStatus.rechazada,
      ));
    } else if (estadoActual == RequestStatus.condicionada) {
      items.add(RequestTimelineItem(
        id: 'tl-4',
        titulo: 'Condicionada',
        descripcion: 'Aprobación sujeta a condiciones.',
        responsable: 'Comité de crédito',
        fechaHora: updatedAt ?? base.add(const Duration(days: 2)),
        completado: true,
        estado: RequestStatus.condicionada,
      ));
    } else if (estadoActual.index >= RequestStatus.aprobada.index) {
      items.add(RequestTimelineItem(
        id: 'tl-4',
        titulo: 'Aprobada',
        descripcion: 'Resolución favorable del comité.',
        responsable: 'Comité de crédito',
        fechaHora: updatedAt ?? base.add(const Duration(days: 2)),
        completado: true,
        estado: RequestStatus.aprobada,
      ));
    }

    if (estadoActual == RequestStatus.desembolsada) {
      items.add(RequestTimelineItem(
        id: 'tl-5',
        titulo: 'Desembolsada',
        descripcion: 'Abono de fondos al cliente.',
        responsable: 'Operaciones',
        fechaHora: updatedAt ?? base.add(const Duration(days: 4)),
        completado: true,
        estado: RequestStatus.desembolsada,
      ));
    }

    return items;
  }

  RequestStatus _parseEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'enviada':
        return RequestStatus.enviada;
      case 'en_comite':
      case 'en comité':
      case 'en comite':
        return RequestStatus.enComite;
      case 'en_evaluacion':
      case 'en evaluación':
      case 'en evaluacion':
        return RequestStatus.enEvaluacion;
      case 'aprobada':
        return RequestStatus.aprobada;
      case 'condicionada':
        return RequestStatus.condicionada;
      case 'rechazada':
        return RequestStatus.rechazada;
      case 'desembolsada':
        return RequestStatus.desembolsada;
      default:
        return RequestStatus.enviada;
    }
  }

  Future<void> desembolsarSolicitud({
    required Map<String, dynamic> solicitud,
  }) async {
    SupabaseHelper.log('desembolsar solicitud iniciado');

    if (!SupabaseHelper.hasSession) {
      throw StateError('Sin sesión activa de Supabase.');
    }

    final solicitudId = solicitud['id']?.toString();
    final clienteSolicitudId = solicitud['cliente_id']?.toString();
    final clienteAppId = solicitud['created_by_auth_id']?.toString();
    final montoAprobado = _toDouble(solicitud['monto_aprobado']) ??
        _toDouble(solicitud['monto_solicitado']) ??
        0;
    final plazoMeses =
        (solicitud['plazo_meses'] as num?)?.toInt() ?? 0;
    final tea = _toDouble(solicitud['tea_referencial']) ?? 0.36;
    final cuotaMensual = _calcularCuota(montoAprobado, tea, plazoMeses);

    debugPrint('DEBUG VENTAS SUPABASE: solicitudId=$solicitudId');
    debugPrint('DEBUG VENTAS SUPABASE: clienteSolicitudId=$clienteSolicitudId');
    debugPrint('DEBUG VENTAS SUPABASE: clienteAppId=$clienteAppId');

    if (solicitudId == null || solicitudId.isEmpty) {
      throw StateError('La solicitud no tiene id.');
    }
    if (clienteAppId == null || clienteAppId.isEmpty || clienteAppId == 'null') {
      throw Exception(
        'La solicitud no tiene created_by_auth_id. No se puede crear el crédito visible para App Clientes.',
      );
    }
    if (montoAprobado <= 0) {
      throw StateError('El monto a desembolsar no es válido (monto_aprobado o monto_solicitado debe ser > 0).');
    }
    if (plazoMeses <= 0) {
      throw StateError('El plazo_meses no es válido.');
    }
    if (cuotaMensual <= 0) {
      throw StateError('La cuota calculada no es válida.');
    }

    final asesorId = await _obtenerAsesorActualId();
    final asesorActual = solicitud['asesor_id']?.toString();
    if (asesorActual != null && asesorActual.isNotEmpty && asesorActual != asesorId) {
      throw Exception('Esta solicitud está asignada a otro asesor.');
    }

    final numeroCredito = 'CRE-ALF-${DateTime.now().millisecondsSinceEpoch}';
    final primeraFechaPago = DateTime(
      DateTime.now().year,
      DateTime.now().month + 1,
      DateTime.now().day.clamp(1, 28),
    );

    // 1. Crear crédito en clientes_creditos
    SupabaseHelper.log('desembolsar creando credito');
    final creditoRow = await SupabaseHelper.withTimeout(
      supabase.from('clientes_creditos').insert({
        'cliente_id': clienteAppId,
        'producto': 'Crédito Empresarial Alfin',
        'nombre_producto': 'Crédito Empresarial - Microempresa',
        'monto_original': montoAprobado,
        'monto_pendiente': montoAprobado,
        'cuota_mensual': cuotaMensual,
        'proxima_fecha_pago': primeraFechaPago.toIso8601String(),
        'fecha_proximo_pago': primeraFechaPago.toIso8601String(),
        'tea_referencial': tea,
        'tea': tea,
        'estado': 'activo',
        'activo': true,
      }).select().single(),
      operation: 'clientes_creditos insert',
    );
    final creditoId = creditoRow['id']?.toString() ?? '';
    SupabaseHelper.log('desembolsar credito creado id=$creditoId');

    // Buscar o crear cuenta principal del cliente
    final cuentasExistentes = await supabase
        .from('clientes_cuentas')
        .select('*')
        .eq('cliente_id', clienteAppId)
        .eq('es_principal', true)
        .limit(1);
    Map<String, dynamic> cuenta;
    if (cuentasExistentes.isNotEmpty) {
      cuenta = cuentasExistentes.first;
    } else {
      final numeroCuentaGenerado = 'CTA-${DateTime.now().millisecondsSinceEpoch}';
      final cciGenerado = 'CCI-${DateTime.now().millisecondsSinceEpoch}';
      cuenta = await supabase.from('clientes_cuentas').insert({
        'cliente_id': clienteAppId,
        'numero_cuenta': numeroCuentaGenerado,
        'cci': cciGenerado,
        'tipo_cuenta': 'Cuenta de Ahorros',
        'saldo': 0,
        'saldo_disponible': 0,
        'saldo_contable': 0,
        'moneda': 'PEN',
        'activa': true,
        'es_principal': true,
      }).select().single();
    }
    final cuentaId = cuenta['id']?.toString() ?? '';
    final saldoActual = double.tryParse('${cuenta['saldo'] ?? 0}') ?? 0;
    final saldoDisponibleActual = double.tryParse('${cuenta['saldo_disponible'] ?? 0}') ?? 0;
    final saldoContableActual = double.tryParse('${cuenta['saldo_contable'] ?? 0}') ?? 0;
    debugPrint('DEBUG VENTAS SUPABASE: cuentaId=$cuentaId');
    debugPrint('DEBUG VENTAS SUPABASE: saldo antes=$saldoActual');
    debugPrint('DEBUG VENTAS SUPABASE: monto desembolso=$montoAprobado');
    debugPrint('DEBUG VENTAS SUPABASE: saldo despues=${saldoActual + montoAprobado}');

    // 2. Crear cronograma en clientes_cronograma_pagos
    SupabaseHelper.log('desembolsar creando cronograma plazo=$plazoMeses');
    final ahora = DateTime.now();
    for (var i = 1; i <= plazoMeses; i++) {
      final fechaVencimiento = DateTime(
        ahora.year,
        ahora.month + i,
        ahora.day.clamp(1, 28),
      );
      await SupabaseHelper.withTimeout(
        supabase.from('clientes_cronograma_pagos').insert({
          'cliente_id': clienteAppId,
          'credito_id': creditoId,
          'numero_cuota': i,
          'fecha_vencimiento': fechaVencimiento.toIso8601String(),
          'monto': cuotaMensual,
          'estado': 'pendiente',
        }),
        operation: 'clientes_cronograma_pagos insert cuota $i',
      );
    }
    SupabaseHelper.log('desembolsar cronograma creado $plazoMeses cuotas');

    // 3. Crear movimiento en clientes_movimientos
    final numeroOperacion = 'OP-${DateTime.now().millisecondsSinceEpoch}';
    await SupabaseHelper.withTimeout(
      supabase.from('clientes_movimientos').insert({
        'cliente_id': clienteAppId,
        'cuenta_id': cuentaId,
        'descripcion': 'Desembolso de crédito empresarial',
        'categoria': 'Crédito',
        'referencia': numeroCredito,
        'monto': montoAprobado,
        'es_abono': true,
        'fecha': DateTime.now().toIso8601String(),
      }),
      operation: 'clientes_movimientos insert',
    );
    SupabaseHelper.log('desembolsar movimiento creado');

    // 4. Crear operación en clientes_operaciones
    await SupabaseHelper.withTimeout(
      supabase.from('clientes_operaciones').insert({
        'cliente_id': clienteAppId,
        'tipo_operacion': 'DESEMBOLSO',
        'monto': montoAprobado,
        'descripcion': 'Desembolso de crédito empresarial',
        'numero_operacion': numeroOperacion,
        'estado': 'exitosa',
        'fecha': DateTime.now().toIso8601String(),
      }),
      operation: 'clientes_operaciones insert',
    );
    SupabaseHelper.log('desembolsar operacion creada');

    // 5. Actualizar saldo de la cuenta
    await SupabaseHelper.withTimeout(
      supabase.from('clientes_cuentas').update({
        'saldo': saldoActual + montoAprobado,
        'saldo_disponible': saldoDisponibleActual + montoAprobado,
        'saldo_contable': saldoContableActual + montoAprobado,
      }).eq('id', cuentaId),
      operation: 'clientes_cuentas update saldo',
    );
    SupabaseHelper.log('desembolsar cuenta actualizada');

    // 6. Actualizar solicitudes_credito
    await SupabaseHelper.withTimeout(
      supabase.from('solicitudes_credito').update({
        'estado': 'desembolsada',
        'fecha_desembolso': DateTime.now().toIso8601String(),
        if (asesorActual == null || asesorActual.isEmpty) 'asesor_id': asesorId,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', solicitudId),
      operation: 'solicitudes_credito update estado desembolsada',
    );
    SupabaseHelper.log('desembolsar solicitud actualizada OK');
  }

  Future<void> aprobarSolicitud({
    required Map<String, dynamic> solicitud,
  }) async {
    final solicitudId = solicitud['id']?.toString();
    if (solicitudId == null || solicitudId.isEmpty) {
      throw StateError('La solicitud no tiene id.');
    }

    final asesorId = await _obtenerAsesorActualId();
    final asesorActual = solicitud['asesor_id']?.toString();
    if (asesorActual != null && asesorActual.isNotEmpty && asesorActual != asesorId) {
      throw Exception('Esta solicitud está asignada a otro asesor.');
    }

    SupabaseHelper.log('aprobar solicitud id=$solicitudId');
    await SupabaseHelper.withTimeout(
      supabase.from('solicitudes_credito').update({
        'estado': 'aprobada',
        'monto_aprobado': solicitud['monto_solicitado'],
        if (asesorActual == null || asesorActual.isEmpty) 'asesor_id': asesorId,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', solicitudId),
      operation: 'solicitudes_credito aprobar',
    );
    SupabaseHelper.log('aprobar solicitud OK');
  }

  Future<void> condicionarSolicitud({
    required Map<String, dynamic> solicitud,
    required String condicion,
    required double montoAprobado,
  }) async {
    final solicitudId = solicitud['id']?.toString();
    if (solicitudId == null || solicitudId.isEmpty) {
      throw StateError('La solicitud no tiene id.');
    }
    if (montoAprobado <= 0) {
      throw Exception('El monto aprobado debe ser mayor a 0.');
    }
    if (condicion.trim().isEmpty) {
      throw Exception('La observación no puede estar vacía.');
    }

    final asesorId = await _obtenerAsesorActualId();
    final asesorActual = solicitud['asesor_id']?.toString();
    if (asesorActual != null && asesorActual.isNotEmpty && asesorActual != asesorId) {
      throw Exception('Esta solicitud está asignada a otro asesor.');
    }

    final montoSolicitado = _toDouble(solicitud['monto_solicitado']) ?? 0;
    if (montoAprobado >= montoSolicitado) {
      throw Exception('Para condicionar, el monto aprobado debe ser menor al solicitado.');
    }

    final plazoMeses = (solicitud['plazo_meses'] as num?)?.toInt() ?? 0;
    final tea = _toDouble(solicitud['tea_referencial']) ?? 0.36;
    final nuevaCuota = _calcularCuota(montoAprobado, tea, plazoMeses);

    debugPrint('DEBUG VENTAS CONDICION: montoSolicitado=$montoSolicitado');
    debugPrint('DEBUG VENTAS CONDICION: montoAprobado=$montoAprobado');
    debugPrint('DEBUG VENTAS CONDICION: nuevaCuota=$nuevaCuota');

    final ingresosEstimados = _toDouble(solicitud['ingresos_estimados']) ?? 0;
    final gastosMensuales = _toDouble(solicitud['gastos_mensuales']) ?? 0;
    final capacidadNeta = ingresosEstimados - gastosMensuales;
    final ratioCapacidad = capacidadNeta > 0 ? nuevaCuota / capacidadNeta : 999;

    final cronogramaNuevo = _generarCronograma(
      monto: montoAprobado,
      tea: tea,
      plazoMeses: plazoMeses,
    );

    debugPrint('DEBUG VENTAS CONDICION: ratio=$ratioCapacidad');

    SupabaseHelper.log('condicionar solicitud id=$solicitudId');
    await SupabaseHelper.withTimeout(
      supabase.from('solicitudes_credito').update({
        'estado': 'condicionada',
        'condicion_adicional': condicion,
        'monto_aprobado': montoAprobado,
        'cuota_estimada': nuevaCuota,
        'ratio_capacidad_pago': ratioCapacidad,
        'cronograma_json': jsonEncode(cronogramaNuevo),
        'fecha_decision': DateTime.now().toIso8601String(),
        if (asesorActual == null || asesorActual.isEmpty) 'asesor_id': asesorId,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', solicitudId),
      operation: 'solicitudes_credito condicionar',
    );
    SupabaseHelper.log('condicionar solicitud OK');
  }

  Future<void> rechazarSolicitud({
    required Map<String, dynamic> solicitud,
    required String motivo,
  }) async {
    final solicitudId = solicitud['id']?.toString();
    if (solicitudId == null || solicitudId.isEmpty) {
      throw StateError('La solicitud no tiene id.');
    }

    final asesorId = await _obtenerAsesorActualId();
    final asesorActual = solicitud['asesor_id']?.toString();
    if (asesorActual != null && asesorActual.isNotEmpty && asesorActual != asesorId) {
      throw Exception('Esta solicitud está asignada a otro asesor.');
    }

    SupabaseHelper.log('rechazar solicitud id=$solicitudId');
    await SupabaseHelper.withTimeout(
      supabase.from('solicitudes_credito').update({
        'estado': 'rechazada',
        'motivo_rechazo': motivo,
        if (asesorActual == null || asesorActual.isEmpty) 'asesor_id': asesorId,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', solicitudId),
      operation: 'solicitudes_credito rechazar',
    );
    SupabaseHelper.log('rechazar solicitud OK');
  }

  Future<String> _obtenerAsesorActualId() async {
    final asesor = await AsesorRepository.instance.requireCurrentAsesor();
    return asesor.id;
  }

  double _calcularTEM(double tea) {
    final result = pow(1 + tea / 100, 1 / 12) - 1;
    return result.toDouble();
  }

  double _calcularCuota(double monto, double tea, int plazoMeses) {
    final tem = _calcularTEM(tea);
    if (tem <= 0) return monto / plazoMeses;
    final denominador = 1 - pow(1 + tem, -plazoMeses);
    if (denominador == 0) return monto / plazoMeses;
    return monto * tem / denominador;
  }

  /// Calcula el monto recomendado para condicionar (monto menor).
  double calcularMontoRecomendadoCondicionado(Map<String, dynamic> solicitud) {
    final ingresosEstimados = _toDouble(solicitud['ingresos_estimados']) ?? 0;
    final gastosMensuales = _toDouble(solicitud['gastos_mensuales']) ?? 0;
    final montoSolicitado = _toDouble(solicitud['monto_solicitado']) ?? 0;
    final plazoMeses = (solicitud['plazo_meses'] as num?)?.toInt() ?? 0;
    final tea = _toDouble(solicitud['tea_referencial']) ?? 0.36;

    if (ingresosEstimados <= 0 || plazoMeses <= 0) return 0;

    final capacidadNeta = ingresosEstimados - gastosMensuales;
    if (capacidadNeta <= 0) return 0;

    final cuotaMaximaAceptable = capacidadNeta * 0.35;
    final tem = _calcularTEM(tea);

    double montoMaximo;
    if (tem <= 0) {
      montoMaximo = cuotaMaximaAceptable * plazoMeses;
    } else {
      montoMaximo = cuotaMaximaAceptable * (1 - pow(1 + tem, -plazoMeses)) / tem;
    }

    final recomendado = min(montoSolicitado, montoMaximo);
    final redondeado = (recomendado / 100).floor() * 100;

    return redondeado.clamp(0, montoSolicitado).toDouble();
  }

  /// Genera cronograma francés como lista de mapas.
  List<Map<String, dynamic>> _generarCronograma({
    required double monto,
    required double tea,
    required int plazoMeses,
  }) {
    final cuota = _calcularCuota(monto, tea, plazoMeses);
    final tem = _calcularTEM(tea);
    final cronograma = <Map<String, dynamic>>[];
    double saldo = monto;

    for (var i = 1; i <= plazoMeses; i++) {
      final interes = saldo * tem;
      final capital = cuota - interes;
      saldo = (saldo - capital).clamp(0, double.infinity);
      final fechaPago = DateTime(
        DateTime.now().year,
        DateTime.now().month + i,
        DateTime.now().day.clamp(1, 28),
      );

      cronograma.add({
        'numero_cuota': i,
        'fecha_vencimiento': fechaPago.toIso8601String(),
        'cuota': cuota,
        'capital': capital,
        'interes': interes,
        'saldo': saldo,
        'estado': 'pendiente',
      });
    }

    return cronograma;
  }

  Future<void> reclamarSolicitud(String solicitudId) async {
    debugPrint('DEBUG VENTAS ASESOR: reclamando solicitud=$solicitudId');

    final asesorId = await _obtenerAsesorActualId();
    debugPrint('DEBUG VENTAS ASESOR: asesorId=$asesorId');

    final response = await SupabaseHelper.withTimeout(
      supabase
          .from('solicitudes_credito')
          .update({
            'asesor_id': asesorId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', solicitudId)
          .filter('asesor_id', 'is', 'null')
          .select(),
      operation: 'solicitudes_credito reclamar',
    );

    if (response.isEmpty) {
      throw Exception('La solicitud ya fue reclamada por otro asesor.');
    }

    debugPrint('DEBUG VENTAS ASESOR: solicitud reclamada OK');
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
