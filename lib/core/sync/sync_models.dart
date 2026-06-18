/// Estados de un item en la cola de sincronización.
abstract class SyncStatus {
  static const String pending = 'pending';
  static const String processing = 'processing';
  static const String synced = 'synced';
  static const String failed = 'failed';
}

/// Operaciones de sincronización.
abstract class SyncOperation {
  static const String insert = 'insert';
  static const String update = 'update';
  static const String delete = 'delete';
  static const String updateEstadoVisita = 'update_estado_visita';
}

/// Tipos de entidad sincronizable.
abstract class SyncEntityType {
  static const String visita = 'visita';
  static const String accionCobranza = 'accion_cobranza';
  static const String solicitudCredito = 'solicitud_credito';
}

/// Item en la cola de sincronización (sync_outbox).
class SyncOutboxEntry {
  final String id;
  final String entityType;
  final String? entityId;
  final String operation;
  final String payloadJson;
  final String status;
  final int retryCount;
  final String? lastError;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? nextRetryAt;

  const SyncOutboxEntry({
    required this.id,
    required this.entityType,
    this.entityId,
    required this.operation,
    required this.payloadJson,
    this.status = SyncStatus.pending,
    this.retryCount = 0,
    this.lastError,
    required this.createdAt,
    required this.updatedAt,
    this.nextRetryAt,
  });

  SyncOutboxEntry copyWith({
    String? status,
    int? retryCount,
    String? lastError,
    DateTime? updatedAt,
    DateTime? nextRetryAt,
  }) =>
      SyncOutboxEntry(
        id: id,
        entityType: entityType,
        entityId: entityId,
        operation: operation,
        payloadJson: payloadJson,
        status: status ?? this.status,
        retryCount: retryCount ?? this.retryCount,
        lastError: lastError ?? this.lastError,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        nextRetryAt: nextRetryAt ?? this.nextRetryAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'entity_type': entityType,
        'entity_id': entityId,
        'operation': operation,
        'payload_json': payloadJson,
        'status': status,
        'retry_count': retryCount,
        'last_error': lastError,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'next_retry_at': nextRetryAt?.toIso8601String(),
      };

  factory SyncOutboxEntry.fromMap(Map<String, dynamic> map) =>
      SyncOutboxEntry(
        id: (map['id'] ?? '').toString(),
        entityType: (map['entity_type'] ?? '').toString(),
        entityId: map['entity_id']?.toString(),
        operation: (map['operation'] ?? '').toString(),
        payloadJson: (map['payload_json'] ?? '{}').toString(),
        status: (map['status'] ?? SyncStatus.pending).toString(),
        retryCount: _toInt(map['retry_count']),
        lastError: map['last_error']?.toString(),
        createdAt: _parseDateTime(map['created_at']),
        updatedAt: _parseDateTime(map['updated_at']),
        nextRetryAt: map['next_retry_at'] != null
            ? _parseDateTime(map['next_retry_at'])
            : null,
      );

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  static DateTime _parseDateTime(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString()) ?? DateTime.now();
  }
}

/// Entrada de log de sincronización (sync_log).
class SyncLogEntry {
  final String id;
  final String? outboxId;
  final String status;
  final String? message;
  final DateTime createdAt;

  const SyncLogEntry({
    required this.id,
    this.outboxId,
    required this.status,
    this.message,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'outbox_id': outboxId,
        'status': status,
        'message': message,
        'created_at': createdAt.toIso8601String(),
      };

  factory SyncLogEntry.fromMap(Map<String, dynamic> map) => SyncLogEntry(
        id: (map['id'] ?? '').toString(),
        outboxId: map['outbox_id']?.toString(),
        status: (map['status'] ?? '').toString(),
        message: map['message']?.toString(),
        createdAt: SyncOutboxEntry._parseDateTime(map['created_at']),
      );
}
