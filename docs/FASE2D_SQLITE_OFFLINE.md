# Fase 2D — SQLite offline básico

> **Objetivo**: Implementar persistencia offline local con estrategia de fallback triple: **Supabase → SQLite → demo/mock**.

---

## Arquitectura de persistencia

```
┌─────────────────────────────────────────────────┐
│               ViewModel                          │
│  loadCartera() → try repo → catch → seed mock   │
└──────────────────────┬──────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────┐
│              CarteraRepository                   │
│  lastSource: 'live' | 'offline' | 'demo'        │
│                                                  │
│  1. check connectivity_plus                      │
│  2. try Supabase → on success: save to SQLite    │
│  3. if fail → try SQLite cache                   │
│  4. if empty → throw → ViewModel mock fallback   │
└──────────────────────┬──────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────┐
│           CarteraLocalDataSource                 │
│  saveCartera() / loadCartera() / hasCartera()   │
│  Tabla: cartera_cache                            │
│  PK: asesorId_clienteId_index                    │
└─────────────────────────────────────────────────┘
```

---

## Tablas SQLite utilizadas

### 1. `cartera_cache` — Cache de cartera diaria

| Columna | Tipo | Descripción |
|---------|------|-------------|
| `id` | TEXT PK | Compuesto: `{asesorId}_{clienteId}_{index}` |
| `asesor_id` | TEXT | FK al asesor |
| `cliente_id` | TEXT | FK al cliente |
| `cliente_nombre` | TEXT | Nombres + apellidos |
| `numero_documento` | TEXT | DNI/RUC |
| `tipo_gestion` | TEXT | Renovación, Nuevo, Cobranza |
| `prioridad` | TEXT | Prioridad del cliente |
| `score_prioridad` | INTEGER | Puntaje de prioridad |
| `estado_visita` | TEXT | Pendiente / Visitado |
| `monto_credito` | REAL | Monto referencial |
| `direccion` | TEXT | Dirección del cliente |
| `fecha_asignacion` | TEXT | Fecha de la cartera |
| `orden_manual` | INTEGER | Orden de visita |
| `lat` / `lng` | REAL | Coordenadas |

### 2. `solicitudes_borrador` — Borradores de solicitud

| Columna | Tipo | Descripción |
|---------|------|-------------|
| `id` | TEXT PK | `cliente_id` o `'default'` |
| `cliente_id` | TEXT | FK al cliente |
| `cliente_nombre` | TEXT | Nombre del cliente |
| `paso_actual` | INTEGER | Paso del wizard (0-3) |
| `datos_json` | TEXT | JSON con todos los campos del formulario |
| `monto_solicitado` | REAL | Monto solicitado |
| `asesor_id` | TEXT | FK al asesor |
| `updated_at` | INTEGER | Timestamp de última modificación |

### 3. `visitas_pendientes` — Estado de visitas de ruta

| Columna | Tipo | Descripción |
|---------|------|-------------|
| `id` | TEXT PK | ID de la visita |
| `cartera_id` | TEXT | FK cartera/cliente |
| `resultado` | TEXT | `'pendiente'` o `'visitado'` |
| `observacion` | TEXT | Notas (opcional) |
| `timestamp_visita` | TEXT | ISO 8601 |
| `lat` / `lng` | REAL | Coordenadas |
| `pendiente_sync` | INTEGER | 0 = synced, 1 = pending |

---

## Archivos creados

| Archivo | Propósito |
|---------|-----------|
| `lib/features/cartera/data/cartera_local_datasource.dart` | CRUD sobre `cartera_cache`: save/load/clear/has/updateEstadoVisita |
| `lib/core/storage/borrador_local_datasource.dart` | Persistencia de borrador de solicitud en `solicitudes_borrador` |
| `lib/core/storage/visitas_local_datasource.dart` | Persistencia de estado visitado en `visitas_pendientes` |

## Archivos modificados

| Archivo | Cambio |
|---------|--------|
| `lib/features/cartera/domain/client_portfolio_model.dart` | Agregados `toMap()` y `fromMap()` para serialización dual SQLite + Supabase |
| `lib/features/cartera/data/cartera_repository.dart` | Estrategia triple: `connectivity_plus` → Supabase → SQLite cache → throw. Campo `lastSource: String` |
| `lib/features/cartera/presentation/cartera_viewmodel.dart` | `_dataSource` getter (`live`/`offline`/`demo`), listener reactivo en screen |
| `lib/features/cartera/presentation/cartera_diaria_screen.dart` | Badge "Offline" o "Demo" en `_StatTile`; listener `_onVmChanged` |
| `lib/features/solicitud/presentation/solicitud_credito_viewmodel.dart` | `saveDraft()` en cada paso; `_restoreFromDraft()` en `loadInitialData()`; borrado en `submitRequest()` |
| `lib/features/ruta/presentation/ruta_viewmodel.dart` | `markAsVisited()` ahora `Future<void>`; persiste en SQLite; carga estados guardados en `loadTodayRoute()` |
| `lib/features/estado_solicitudes/data/estado_solicitudes_repository.dart` | `clientes!inner` → `clientes!left` para incluir solicitudes sin cliente vinculado |

---

## Flujo de datos offline

### Cartera diaria (pilar de F2D)

```
Usuario abre cartera
  └→ ViewModel.loadCartera()
       └→ CarteraRepository.loadCarteraDiaria()
            ├→ ¿hasSession? NO → _loadFromSqlite()
            ├→ ¿connectivity offline? → _loadFromSqlite()
            ├→ try Supabase → éxito → save SQLite → return [lastSource='live']
            └→ catch → _loadFromSqlite()
                 ├→ ¿hasCartera? → return SQLite data [lastSource='offline']
                 └→ no → throw → ViewModel usa _seedClients [lastSource='demo']
```

Visual indicator: badge "Offline" (naranja) o "Demo" (gris) junto al contador de visitas.

### Borrador de solicitud

```
Usuario completa paso 1 → nextStep()
  └→ saveDraft() → SQLite solicitudes_borrador
Usuario completa paso 2 → nextStep()
  └→ saveDraft() → SQLite solicitudes_borrador (actualiza)
Usuario reabre solicitud → loadInitialData(clientId)
  └→ loadBorrador(clienteId) → si existe → restaurar campos + paso_actual
Usuario envía solicitud → submitRequest()
  └→ éxito → deleteBorrador(clienteId)
```

### Ruta de visitas

```
Usuario abre ruta → loadTodayRoute()
  └→ _buildInitialVisits()
  └→ loadAllEstados() desde SQLite
  └→ aplicar estados guardados (sobreescribe visitados)
Usuario marca cliente como visitado → markAsVisited(clientId)
  └→ actualiza _visitas[index]
  └→ saveVisitaEstado(..., resultado:'visitado') → SQLite
Usuario cierra y reabre app → ruta carga con estados previos
```

---

## Casos de borde cubiertos

| Escenario | Comportamiento |
|-----------|---------------|
| Sin internet, sin cache previo | Mock _seedClients (badge "Demo") |
| Sin internet, con cache previo | Datos SQLite (badge "Offline") |
| Vuelve internet, con cache | Sobrescribe cache con datos frescos |
| Solicitud a medio llenar, cierra app | Borrador restaurado al reabrir |
| Ruta visitados, cierra app | Estado "visitado" preservado |
| Solicitud sin cliente vinculado | LEFT JOIN permite consultar igual |
| Sin sesión activa | _loadFromSqlite o mock según disponibilidad |

---

## Pendiente para Fase 2E

- **Sync outbox/log**: cola de sincronización bidireccional
- **Conflictos**: resolución de datos modificados offline vs online
- **Migraciones SQLite**: cuando cambien tablas de Supabase
- **Actualización automática**: al volver online, refrescar cache sin interacción

---

## Verificación

```bash
flutter analyze          # 0 issues
flutter build apk --debug  # build exitoso
```
