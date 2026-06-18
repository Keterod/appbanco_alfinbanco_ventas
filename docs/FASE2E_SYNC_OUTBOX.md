# Fase 2E — Cola de sincronización offline (sync_outbox / sync_log)

> **Objetivo**: Crear infraestructura base de sincronización offline→remoto con cola local, reintentos y log de errores. Preparar el camino para FastAPI/Core Mobile sin implementarlos todavía.

---

## Tablas SQLite nuevas

### `sync_outbox` — Cola de operaciones offline

| Columna | Tipo | Descripción |
|---------|------|-------------|
| `id` | TEXT PK | ID único generado localmente |
| `entity_type` | TEXT NOT NULL | `visita`, `accion_cobranza`, `solicitud_credito` |
| `entity_id` | TEXT | ID de la entidad (opcional) |
| `operation` | TEXT NOT NULL | `insert`, `update`, `delete`, `update_estado_visita` |
| `payload_json` | TEXT NOT NULL | Payload completo de la operación |
| `status` | TEXT NOT NULL | `pending`, `processing`, `synced`, `failed` |
| `retry_count` | INTEGER NOT NULL DEFAULT 0 | Intentos realizados (máx 3) |
| `last_error` | TEXT | Último error registrado |
| `created_at` | TEXT NOT NULL | Timestamp ISO 8601 |
| `updated_at` | TEXT NOT NULL | Última modificación |
| `next_retry_at` | TEXT | Próximo reintento (backoff) |

### `sync_log` — Registro de eventos de sincronización

| Columna | Tipo | Descripción |
|---------|------|-------------|
| `id` | TEXT PK | ID único |
| `outbox_id` | TEXT | FK a `sync_outbox.id` |
| `status` | TEXT NOT NULL | `synced` o `failed` |
| `message` | TEXT | Detalle del resultado o error |
| `created_at` | TEXT NOT NULL | Timestamp ISO 8601 |

---

## Archivos creados

| Archivo | Propósito |
|---------|-----------|
| `lib/core/sync/sync_models.dart` | Modelos `SyncOutboxEntry`, `SyncLogEntry` con `toMap()`/`fromMap()`, constantes de estado y operación |
| `lib/core/sync/sync_local_datasource.dart` | CRUD SQLite sobre `sync_outbox` y `sync_log` |
| `lib/core/sync/sync_manager.dart` | Gestor de cola: encolar, procesar, reintentar con lógica de negocio |

## Archivos modificados

| Archivo | Cambio |
|---------|--------|
| `lib/core/storage/local_db.dart` | Versión 1→2. `_createSyncTables()`. `onUpgrade` seguro. |
| `lib/main.dart` | `SyncManager.instance.processPending()` al arrancar |
| `lib/features/home/presentation/home_oficial_viewmodel.dart` | `SyncManager.instance.processPending()` en `loadDashboard()` |
| `lib/shared/widgets/oficial_drawer.dart` | `_SyncPendingTile` con contador de pendientes |
| `lib/features/ruta/presentation/ruta_viewmodel.dart` | Encolar `update_estado_visita` en `markAsVisited()` |
| `lib/features/cobranza/presentation/cobranza_accion_viewmodel.dart` | Encolar `accion_cobranza insert` si falla Supabase |
| `lib/features/solicitud/presentation/solicitud_credito_viewmodel.dart` | Encolar `solicitud_credito insert` si falla Supabase |

---

## Estados de sync

```
pending ──→ processing ──→ synced  ✓
                │
                ↓
           retry_count < 3 ──→ pending (backoff 5 min)
                │
                ↓
           retry_count >= 3 ──→ failed ✗
```

---

## Operaciones que se encolan

| Operación | Origen | Payload mínimo |
|-----------|--------|---------------|
| `visita update_estado_visita` | `ruta_viewmodel.markAsVisited()` | `visita_id`, `cliente_id`, `resultado`, `timestamp`, `lat/lng`, `asesor_id` |
| `accion_cobranza insert` | `cobranza_accion_viewmodel.guardarGestion()` (catch) | `asesor_id`, `cliente_id`, `tipo_gestion`, `resultado`, `monto`, `observacion`, `lat/lng`, `timestamp` |
| `solicitud_credito insert` | `solicitud_credito_viewmodel.submitRequest()` (catch) | `asesor_id`, `nombres`, `apellidos`, `documento`, `monto`, `plazo`, `moneda`, `lat/lng`, `numero_expediente` |

## Operaciones que se procesan realmente contra Supabase

| Operación | Procesamiento | Estado |
|-----------|--------------|--------|
| `accion_cobranza insert` | `supabase.from('acciones_cobranza').insert(payload)` | ✅ Implementado |
| `solicitud_credito insert` | `supabase.from('solicitudes_credito').insert(payload)` | ✅ Implementado |
| `visita update_estado_visita` | Busca `cartera_diaria.id` por `cliente_id`+`asesor_id`, hace update | ⚠️ Implementado con lookup |

## Operaciones que quedan preparadas (no se procesan todavía)

| Operación | Motivo | Solución futura |
|-----------|--------|----------------|
| Cualquier operación con `retry_count >= 3` | Máximo de reintentos alcanzado | Core Mobile / FastAPI con resolución de conflictos |
| Operaciones sin sesión Supabase | No hay token de autenticación | Gestión de sesión persistente (Fase 3) |
| Sincronización bidireccional | No hay endpoint FastAPI | Core Mobile / FastAPI |

---

## Cómo probar offline

1. **Abrir app con internet** → verificar que Cartera muestra "Sincronizado con Supabase"
2. **Desactivar internet** → verificar que Cartera muestra "Modo offline · datos guardados"
3. **Marcar visita como visitado en Ruta** (sin internet) → se crea registro en `sync_outbox`
4. **Registrar acción de cobranza** (sin internet) → se encola en `sync_outbox`
5. **Enviar solicitud de crédito** (sin internet) → se encola en `sync_outbox`
6. **Reactivar internet** → al abrir Dashboard, `SyncManager.processPending()` procesa la cola
7. **Verificar logs** → registros en `sync_log` con estado `synced` o `failed`

## Cómo probar reintentos

- Forzar un error en Supabase (payload inválido o sin sesión)
- Verificar en `sync_log` que aparece `failed` con el mensaje de error
- Verificar que `retry_count` se incrementa
- Después de 3 intentos, el estado cambia a `failed` definitivo

---

## Pendiente para Fase 3 / Core Mobile / FastAPI

- Resolución avanzada de conflictos (versión de datos, merge)
- Sincronización bidireccional completa
- Endpoint FastAPI para procesamiento batch de `sync_outbox`
- App Clientes: notificaciones de cambio de estado
- Sesión persistente (actualmente se pierde al cerrar la app)
