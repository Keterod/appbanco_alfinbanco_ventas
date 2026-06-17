# Fase 2C — Conexión real de módulos prioritarios a Supabase

## Objetivo
Conectar Dashboard, Estado de Solicitudes y Reportes a datos reales de Supabase, manteniendo fallback mock/demo cuando Supabase falle, no haya sesión o la tabla esté vacía.

## Módulos conectados

| Módulo | Origen anterior | Origen actual | Archivo |
|--------|----------------|---------------|---------|
| **Dashboard (Home)** | Hardcoded + `RequestStatusMockData` + `CobranzaLocalRepository` | `ReportesRepository.loadReport()` + `EstadoSolicitudesRepository.loadSolicitudes()` + `ReportesRepository.loadActivities()`; fallback a hardcoded mock | `home_oficial_viewmodel.dart` |
| **Estado de Solicitudes** | `RequestStatusMockData.all()` 100% | `EstadoSolicitudesRepository.loadSolicitudes()` con join a `clientes`; fallback a mock | `estado_solicitudes_viewmodel.dart`, `estado_solicitudes_repository.dart` |
| **Detalle de Solicitud** | `RequestStatusMockData.findById/ByExpediente` 100% | `EstadoSolicitudesRepository.loadSolicitudById/ByExpediente()` primero; fallback a mock | `estado_solicitud_detalle_viewmodel.dart` |
| **Reportes** | `_buildReportForPeriod()` hardcoded 100% | `ReportesRepository.loadReport()`; fallback a mock | `reportes_viewmodel.dart`, `reportes_repository.dart` |

## Archivos creados

| Archivo | Propósito |
|---------|-----------|
| `lib/features/estado_solicitudes/data/estado_solicitudes_repository.dart` | Consulta `solicitudes_credito` con join a `clientes`, filtrado por `asesor_id`. `loadSolicitudes()`, `loadSolicitudById()`, `loadSolicitudByExpediente()`. Fallback a `RequestStatusMockData`. |
| `lib/features/reportes/data/reportes_repository.dart` | Consulta `solicitudes_credito`, `cartera_diaria`, `acciones_cobranza`. Calcula indicadores por periodo. `loadReport()`, `loadActivities()`. |
| `docs/sql/FASE2C_SUPABASE_DATOS_REALES.sql` | Documentación de tablas, columnas, inserts demo y consultas de prueba. |

## Archivos modificados

| Archivo | Cambio |
|---------|--------|
| `lib/features/estado_solicitudes/presentation/estado_solicitudes_viewmodel.dart` | `loadRequests()` intenta `EstadoSolicitudesRepository.loadSolicitudes()` primero; si hay datos reales (IDs no empiezan con "req-") los usa; sino fallback a mock. |
| `lib/features/estado_solicitudes/presentation/estado_solicitud_detalle_viewmodel.dart` | `loadRequest()` intenta repositorio Supabase primero por ID o expediente; si no encuentra, busca en mock. |
| `lib/features/reportes/presentation/reportes_viewmodel.dart` | `loadReport()` intenta `ReportesRepository.loadReport()` + `loadActivities()`; si retorna null o vacío, usa mock hardcoded. |
| `lib/features/home/presentation/home_oficial_viewmodel.dart` | `loadDashboard()` intenta `ReportesRepository.loadReport()` + `EstadoSolicitudesRepository.loadSolicitudes()` + `ReportesRepository.loadActivities()`; fallback a mock. |

## Tablas Supabase consultadas

| Tabla | Consultada por | Columnas usadas |
|-------|---------------|-----------------|
| `solicitudes_credito` | `EstadoSolicitudesRepository`, `ReportesRepository` | `id, numero_expediente, asesor_id, cliente_id, estado, monto_solicitado, monto_aprobado, created_at, updated_at, motivo_rechazo, condicion_adicional, analista_asignado` |
| `clientes` (join) | `EstadoSolicitudesRepository` | `id, nombres, apellidos, numero_documento` |
| `cartera_diaria` | `ReportesRepository` | `asesor_id, fecha_asignacion, estado_visita` |
| `acciones_cobranza` | `ReportesRepository` | `asesor_id, cliente_id, monto_gestionado, created_at` |
| `asesores_negocio` | `AsesorRepository` (existente) | `id, user_id, nombres, apellidos` |

## Estrategia de fallback mock

1. **Sin sesión Supabase**: todos los módulos usan su mock directamente
2. **Sin asesor en `asesores_negocio`**: fallback a mock (EstadoSolicitudesRepository, ReportesRepository)
3. **Tabla vacía**: `EstadoSolicitudesRepository` retorna `RequestStatusMockData.all()` si rows está vacío
4. **Error de conexión o timeout**: catch genérico que retorna null, ViewModel usa mock
5. **Dashboard**: si `_tryLoadReal()` no obtiene datos, `_loadMock()` se ejecuta con valores hardcoded

## Cómo probar con datos reales

### Prerrequisitos en Supabase
1. Tener al menos 1 asesor en `asesores_negocio` con `user_id` vinculado a un usuario de auth
2. Tener al menos 3 solicitudes en `solicitudes_credito` con `asesor_id` del asesor
3. Tener al menos 2 registros en `cartera_diaria` para el asesor
4. Tener al menos 1 registro en `acciones_cobranza` para el asesor

### Dashboard
1. Iniciar sesión en la app
2. Verificar que las tarjetas muestren números > 0 (visitas, pendientes, en evaluación, en mora)
3. Verificar que aparezca actividad reciente con datos reales
4. Si no hay datos, deben verse los valores mock (5 visitas, 3 pendientes, etc.)

### Estado de Solicitudes
1. Navegar a "Estado solicitudes"
2. Verificar que aparezcan las solicitudes reales con nombre de cliente, expediente, monto
3. Tocar un chip de estado para filtrar
4. Tocar una solicitud → ver detalle con timeline generado del estado real
5. Si no hay solicitudes reales, deben verse las 8 solicitudes mock

### Reportes
1. Navegar a "Reportes"
2. Verificar que los indicadores muestren valores reales
3. Cambiar entre periodos Hoy / Semana / Mes
4. Verificar que la actividad reciente muestre datos reales
5. Si no hay datos reales, deben verse los valores mock (8 visitas, 2 solicitudes para Hoy)

## Datos mínimos necesarios en Supabase

```sql
-- 1 asesor (reemplazar user_id con UUID real de auth.users)
INSERT INTO asesores_negocio (id, user_id, codigo_empleado, nombres, apellidos)
VALUES ('asesor-001', 'UUID-DE-AUTH', 'EMP-001', 'Oficial', 'Demo');

-- 3 solicitudes (reemplazar cliente_id con UUID real de clientes)
INSERT INTO solicitudes_credito (numero_expediente, asesor_id, cliente_id, estado, monto_solicitado, plazo_meses, moneda, destino_credito)
VALUES
  ('EXP-TEST-001', 'asesor-001', 'cliente-uuid-1', 'en_evaluacion', 12000, 12, 'PEN', 'Capital'),
  ('EXP-TEST-002', 'asesor-001', 'cliente-uuid-2', 'aprobada', 8000, 6, 'PEN', 'Mercadería'),
  ('EXP-TEST-003', 'asesor-001', 'cliente-uuid-3', 'desembolsada', 15000, 18, 'PEN', 'Local');

-- 2 registros cartera diaria
INSERT INTO cartera_diaria (asesor_id, cliente_id, fecha_asignacion, tipo_gestion, estado_visita)
VALUES
  ('asesor-001', 'cliente-uuid-1', CURRENT_DATE, 'Renovación', 'pendiente'),
  ('asesor-001', 'cliente-uuid-2', CURRENT_DATE, 'Cobranza', 'visitado');

-- 1 acción cobranza
INSERT INTO acciones_cobranza (asesor_id, cliente_id, tipo_gestion, resultado, monto_gestionado, lat, lng)
VALUES ('asesor-001', 'cliente-uuid-2', 'Visita', 'Compromiso', 500, -12.0464, -77.0428);
```

## Qué quedó pendiente para Fase 2D

1. **SQLite offline** — persistencia local de solicitudes, cartera, reportes
2. **Cola de sincronización** — `sync_outbox`/`sync_log` para operaciones offline
3. **Ruta conectada a Supabase** — migrar `_buildInitialVisits()` seed a `cartera_diaria` + `clientes`
4. **Clientes con lat/lng** — agregar campos de ubicación a `clientes` en Supabase
5. **Validar joins con `clientes`** — si algunos clientes no existen, el INNER JOIN puede excluir solicitudes
6. **Timeline más rico** — tabla `solicitud_timeline` con eventos reales (vs generados del estado)

## Recomendación para Fase 2D
1. Implementar SQLite offline primero (cartera diaria + borradores solicitud)
2. Luego migrar Ruta a cartera_diaria + clientes desde Supabase
3. Agregar columna `lat`/`lng` a `clientes` en Supabase
4. Reemplazar `INNER JOIN` por `LEFT JOIN` en `EstadoSolicitudesRepository` para no excluir solicitudes sin cliente

## Resultado
- `flutter analyze`: 0 issues
- `flutter build apk --debug`: éxito
- Dashboard, Estado Solicitudes y Reportes consultan Supabase primero, fallback a mock
- Cero cambios en login, GPS, Ruta, cobranza, solicitud, cámara, firma, PDF, roles, notificaciones, FastAPI
