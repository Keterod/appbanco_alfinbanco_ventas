import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../supabase/supabase_client.dart';
import '../supabase/supabase_helper.dart';
import '../supabase/supabase_lookup.dart';
import '../../features/auth/data/asesor_repository.dart';
import 'sync_local_datasource.dart';
import 'sync_models.dart';

/// Gestor de la cola de sincronización offline → remoto.
///
/// Encola operaciones realizadas sin conexión y las procesa cuando hay internet.
/// No bloquea la UI. No lanza errores al usuario.
class SyncManager {
  SyncManager._();
  static final SyncManager instance = SyncManager._();

  final SyncLocalDataSource _ds = SyncLocalDataSource.instance;
  static int _idCounter = 0;

  bool _processing = false;

  static String _generateId() =>
      'sync_${DateTime.now().microsecondsSinceEpoch}_${_idCounter++}';

  /// Encola una operación en sync_outbox.
  Future<String> enqueueOperation({
    required String entityType,
    String? entityId,
    required String operation,
    required Map<String, dynamic> payload,
  }) async {
    final id = _generateId();
    final now = DateTime.now();
    final entry = SyncOutboxEntry(
      id: id,
      entityType: entityType,
      entityId: entityId,
      operation: operation,
      payloadJson: jsonEncode(payload),
      status: SyncStatus.pending,
      retryCount: 0,
      createdAt: now,
      updatedAt: now,
    );
    await _ds.enqueue(entry);
    debugPrint('[SYNC] enqueued id=$id type=$entityType op=$operation');
    return id;
  }

  /// Cuenta pendientes en la cola.
  Future<int> pendingCount() => _ds.getPendingCount();

  /// Procesa los items pendientes si hay internet.
  Future<void> processPending({int limit = 10}) async {
    if (_processing) return;

    final connectivity = await Connectivity().checkConnectivity();
    final online = connectivity.isEmpty ||
        connectivity.any((r) => r != ConnectivityResult.none);
    if (!online) {
      debugPrint('[SYNC] sin conexión, skip processPending');
      return;
    }

    _processing = true;
    debugPrint('[SYNC] iniciando processPending');

    try {
      final items = await _ds.getPending(limit: limit);
      if (items.isEmpty) {
        debugPrint('[SYNC] no hay items pendientes');
        _processing = false;
        return;
      }

      for (final item in items) {
        await _ds.markProcessing(item.id);
        try {
          debugPrint('[SYNC] processing type=${item.entityType} op=${item.operation} id=${item.id}');
          await _processItem(item);
          await _ds.markSynced(item.id);
          await _ds.writeLog(SyncLogEntry(
            id: _generateId(),
            outboxId: item.id,
            status: SyncStatus.synced,
            message: '${item.operation} exitoso en ${item.entityType}',
            createdAt: DateTime.now(),
          ));
          debugPrint('[SYNC] synced id=${item.id}');
        } catch (e) {
          final errorMsg = e.toString();
          await _ds.markFailed(item.id, errorMsg);
          await _ds.writeLog(SyncLogEntry(
            id: _generateId(),
            outboxId: item.id,
            status: SyncStatus.failed,
            message: errorMsg,
            createdAt: DateTime.now(),
          ));
          debugPrint('[SYNC] failed id=${item.id} reason=$errorMsg');
        }
      }
    } finally {
      _processing = false;
    }

    try {
      await _ds.deleteSyncedOlderThan(const Duration(days: 7));
      await _ds.deleteLogsOlderThan(const Duration(days: 30));
    } catch (_) {}
  }

  Future<void> _processItem(SyncOutboxEntry item) async {
    final payload = jsonDecode(item.payloadJson) as Map<String, dynamic>;

    switch (item.entityType) {
      case SyncEntityType.accionCobranza:
        await _processAccionCobranza(item, payload);
      case SyncEntityType.solicitudCredito:
        await _processSolicitudCredito(payload);
      case SyncEntityType.visita:
        await _processVisita(payload);
      default:
        throw UnsupportedError('Tipo de entidad no soportado: ${item.entityType}');
    }
  }

  // ─── Cobranza ───────────────────────────────────────────────────

  Future<void> _processAccionCobranza(
    SyncOutboxEntry item,
    Map<String, dynamic> payload,
  ) async {
    if (!SupabaseHelper.hasSession) {
      throw StateError('Sin sesión activa para sincronizar cobranza');
    }
    final asesor = await AsesorRepository.instance.requireCurrentAsesor();
    debugPrint('[SYNC] payload original keys=${payload.keys.toList()}');

    // Resolver cliente_id real (mock cli-XXX → UUID real)
    final clienteId = await SupabaseLookup.resolveClienteIdForCobranza(
      clienteId: payload['cliente_id']?.toString(),
      documento: payload['documento']?.toString(),
      clienteNombre: payload['cliente_nombre']?.toString(),
    );
    if (clienteId == null) {
      throw StateError(
        'No se pudo resolver cliente_id real. '
        'clienteId=${payload['cliente_id']} '
        'documento=${payload['documento']} '
        'nombre=${payload['cliente_nombre']}',
      );
    }
    debugPrint('[SYNC] cliente_id resuelto=$clienteId');

    // Resolver crédito
    final creditoId = await SupabaseLookup.resolveCreditoIdForCobranza(
      creditoRef: payload['credito_id']?.toString(),
      clienteId: clienteId,
    );

    // Construir payload limpio SOLO con columnas reales de acciones_cobranza
    final cleanPayload = <String, dynamic>{
      'asesor_id': asesor.id,
      'cliente_id': clienteId,
    };
    if (creditoId != null) cleanPayload['credito_id'] = creditoId;
    cleanPayload['tipo_gestion'] =
        payload['tipo_gestion']?.toString() ?? 'Gestión';
    cleanPayload['resultado'] =
        payload['resultado']?.toString() ?? 'Sin resultado';
    cleanPayload['monto_pagado'] = _toNum(payload['monto_gestionado'])
        ?? _toNum(payload['monto_pagado']);
    cleanPayload['fecha_compromiso'] = payload['fecha_compromiso']?.toString();
    cleanPayload['monto_compromiso'] = _toNum(payload['monto_compromiso']);
    cleanPayload['observaciones'] =
        payload['observacion']?.toString() ?? payload['observaciones']?.toString() ?? '';
    cleanPayload['lat'] = _toNum(payload['lat']);
    cleanPayload['lng'] = _toNum(payload['lng']);
    cleanPayload['timestamp_gestion'] =
        payload['timestamp_gestion']?.toString()
            ?? payload['timestamp']?.toString()
            ?? DateTime.now().toIso8601String();

    debugPrint('[SYNC] payload limpio keys=${cleanPayload.keys.toList()}');

    await supabase.from('acciones_cobranza').insert(cleanPayload);
  }

  // ─── Solicitud de crédito ───────────────────────────────────────

  Future<void> _processSolicitudCredito(
    Map<String, dynamic> payload,
  ) async {
    if (!SupabaseHelper.hasSession) {
      throw StateError('Sin sesión activa para sincronizar solicitud');
    }
    final asesor = await AsesorRepository.instance.requireCurrentAsesor();

    // Resolver cliente_id si es mock
    String? clienteId;
    if (payload['cliente_id'] != null) {
      clienteId = await SupabaseLookup.resolveClienteId(
        clienteId: payload['cliente_id']?.toString(),
        numeroDocumento: payload['documento']?.toString(),
      );
    }

    final cleanPayload = <String, dynamic>{
      'asesor_id': asesor.id,
      'nombres': payload['nombres']?.toString() ?? '',
      'apellidos': payload['apellidos']?.toString() ?? '',
      'numero_documento': payload['documento']?.toString() ?? '',
      'telefono': payload['telefono']?.toString() ?? '',
      'correo': payload['correo']?.toString() ?? '',
      'monto_solicitado': _toNum(payload['monto_solicitado']) ?? 0,
      'plazo_meses': _toInt(payload['plazo_meses']) ?? 12,
      'moneda': payload['moneda']?.toString() ?? 'PEN',
      'estado': 'enviada',
      'lat_captura': _toNum(payload['lat_captura']),
      'lng_captura': _toNum(payload['lng_captura']),
      'created_at': DateTime.now().toIso8601String(),
    };
    if (clienteId != null) cleanPayload['cliente_id'] = clienteId;
    if (payload['numero_expediente'] != null) {
      cleanPayload['numero_expediente'] = payload['numero_expediente']?.toString();
    }

    debugPrint('[SYNC] solicitud payload keys=${cleanPayload.keys.toList()}');
    await supabase.from('solicitudes_credito').insert(cleanPayload);
  }

  // ─── Visita / Ruta ──────────────────────────────────────────────

  Future<void> _processVisita(Map<String, dynamic> payload) async {
    if (!SupabaseHelper.hasSession) {
      throw StateError('Sin sesión activa');
    }
    final asesor = await AsesorRepository.instance.requireCurrentAsesor();

    final clienteId = payload['cliente_id']?.toString() ?? '';

    // Si cliente_id no es UUID (ej: cli-001), no se puede sincronizar aún
    if (!SupabaseLookup.isUuid(clienteId)) {
      // Intentar resolver por documento
      if (payload['numero_documento'] != null) {
        final resolved = await SupabaseLookup.resolveClienteId(
          clienteId: clienteId,
          numeroDocumento: payload['numero_documento']?.toString(),
        );
        if (resolved != null) {
          debugPrint('[SYNC] visita cliente_id resuelto=$resolved');
          await _updateCarteraDiaria(resolved, payload, asesor.id);
          return;
        }
      }
      throw StateError(
        'Visita cliente_id=$clienteId no es UUID real y no se pudo resolver. '
        'La ruta usa datos mock. Se requiere Core Mobile para sincronizar.',
      );
    }

    // cliente_id ya es UUID → buscar cartera_diaria
    await _updateCarteraDiaria(clienteId, payload, asesor.id);
  }

  Future<void> _updateCarteraDiaria(
    String clienteId,
    Map<String, dynamic> payload,
    String asesorId,
  ) async {
    // Buscar cartera_diaria.id por cliente_id + asesor_id + fecha
    final fecha = payload['fecha_asignacion']?.toString();
    var query = supabase
        .from('cartera_diaria')
        .select('id')
        .eq('cliente_id', clienteId)
        .eq('asesor_id', asesorId);

    if (fecha != null && fecha.isNotEmpty) {
      query = query.eq('fecha_asignacion', fecha);
    }

    final rows = await query.limit(1);
    if (rows.isEmpty) {
      throw StateError(
        'No se encontró cartera_diaria para cliente_id=$clienteId '
        'asesor_id=$asesorId fecha=$fecha',
      );
    }
    final carteraId = rows.first['id']?.toString();
    if (carteraId == null || carteraId.isEmpty) {
      throw StateError('cartera_diaria.id nulo');
    }

    debugPrint('[SYNC] visita cartera_id resuelto=$carteraId');

    final updateData = <String, dynamic>{
      'estado_visita': payload['resultado']?.toString() ?? 'visitado',
    };
    if (payload['lat'] != null) updateData['lat_visita'] = _toNum(payload['lat']);
    if (payload['lng'] != null) updateData['lng_visita'] = _toNum(payload['lng']);
    if (payload['timestamp_visita'] != null) {
      updateData['timestamp_visita'] = payload['timestamp_visita']?.toString();
    }

    await supabase
        .from('cartera_diaria')
        .update(updateData)
        .eq('id', carteraId);
  }

  // ─── Helpers ────────────────────────────────────────────────────

  static double? _toNum(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }
}
