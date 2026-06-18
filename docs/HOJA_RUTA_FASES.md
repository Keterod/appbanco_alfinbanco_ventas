# Hoja de ruta técnica — Banco Alfin · App Fuerza de Ventas

> **Leyenda**: ✅ Completado | 🔄 En progreso | 📅 Planificado | ⏸️ Pausado

---

## Fase 1 — Base del proyecto ✅

**Objetivo**: Unificar branding, centralizar constantes, documentar estado actual.

| Actividad | Estado |
|-----------|--------|
| Auditar proyecto completo | ✅ |
| Unificar nombre y branding ("Banco Alfin") | ✅ |
| Centralizar constantes (`app_strings.dart`) | ✅ |
| Crear documentación base (`FASE1_BASE_PROYECTO.md`) | ✅ |
| Crear lista de pendientes (`PENDIENTES_TECNICOS.md`) | ✅ |
| `flutter analyze` sin issues | ✅ |

**Archivos creados**: `app_strings.dart`, `FASE1_BASE_PROYECTO.md`, `PENDIENTES_TECNICOS.md`  
**Archivos modificados**: 18 archivos (screens + platform configs + docs)

---

## Fase 2A — Auditoría diferencial ✅

**Objetivo**: Clasificar estado real de cada módulo sin rehacer lo que funciona.

| Actividad | Estado |
|-----------|--------|
| Clasificar 26 módulos (IMPLEMENTADO/PARCIAL/PLACEHOLDER/FALTANTE) | ✅ |
| Crear `FASE2_AUDITORIA_DIFERENCIAL.md` | ✅ |
| Verificar sintaxis `?clienteId` (válida en Dart 3.x) | ✅ |
| Verificar Supabase Auth real vs demo | ✅ |
| Verificar perfil y roles | ✅ |
| Verificar GPS/geolocalización | ✅ |
| Verificar conexión Supabase por módulo | ✅ |
| Actualizar `PENDIENTES_TECNICOS.md` | ✅ |
| Crear `HOJA_RUTA_FASES.md` | ✅ |
| `flutter analyze` sin issues | ✅ |

**Archivos creados**: `FASE2_AUDITORIA_DIFERENCIAL.md`, `HOJA_RUTA_FASES.md`  
**Archivos modificados**: `PENDIENTES_TECNICOS.md`

---

## Fase 2B — GPS real en visitas, cobranza y ubicación del negocio ✅

**Objetivo**: Reemplazar coordenadas fijas por geolocalización real usando `geolocator`.

### Archivos modificados

| Archivo | Cambio |
|---------|--------|
| `lib/core/location/location_service.dart` | Servicio centralizado de geolocalización con `getCurrentPosition()`, `ensureLocationPermission()`, `getCurrentPositionWithFallback()` |
| `cobranza_accion_viewmodel.dart` | Reemplazar `simulatedLat/simulatedLng` con `_lat/_lng` reales mediante `captureLocation()` |
| `cobranza_accion_screen.dart` | Mostrar ubicación real con indicador GPS (verde real / naranja fallback) |
| `ruta_viewmodel.dart` | Capturar ubicación del oficial como origen, `captureOficialLocation()`, `openNavigation()` retorna URI Google Maps con coordenadas reales |
| `ruta_screen.dart` | Indicador de ubicación del oficial, navegación externa vía `url_launcher` + `launchUrl(externalApplication)` |
| `solicitud_repository.dart` | Parámetros opcionales `latCaptura/lngCaptura` en `insertSolicitud()` |
| `solicitud_credito_viewmodel.dart` | `captureLocation()` antes de envío, pasa coordenadas al repositorio |
| `solicitud_credito_screen.dart` | Indicador GPS en paso de confirmación |
| `android/app/src/main/AndroidManifest.xml` | Permisos `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION` |
| `ios/Runner/Info.plist` | `NSLocationWhenInUseUsageDescription` |
| `pubspec.yaml` | `url_launcher: ^6.3.0` |

### Gestión de riesgos
- **Batería**: Solo se consulta GPS al abrir formulario o al cargar ruta (no continuo)
- **Permisos**: `LocationService.ensureLocationPermission()` maneja denegado y denegado permanentemente
- **Offline**: GPS funciona sin internet; fallback `(-12.0464, -77.0428)` cuando no hay ubicación

### Criterio de aceptación cumplido
- ✅ Al abrir cobranza y registrar gestión, se captura lat/lng real del dispositivo
- ✅ En ruta de visitas, se captura la ubicación actual del oficial como origen de navegación
- ✅ Las coordenadas se guardan en payload Supabase (cuando haya sesión) o local
- ✅ Fallback controlado con indicador visual "modo demo"
- ✅ `flutter analyze`: 0 issues

### Documentación
- `docs/FASE2B_GPS_REAL.md`
- `docs/FASE2B1_RUTA_SIN_MAPS_KEY.md`

---

## Fase 2B.1 — Mejora de Ruta sin Google Maps Embebido ✅

**Objetivo**: Reemplazar "mapa simulado" por vista operativa profesional usando timeline vertical, coordenadas reales del oficial, y navegación externa.

### Archivos modificados

| Archivo | Cambio |
|---------|--------|
| `ruta_screen.dart` | Eliminado `_SimulatedMapSection`. Nueva vista `_RutaOrdenadaView` con timeline de paradas numeradas. Coordenadas visibles en cada tarjeta. Indicador de ubicación en resumen. Navegación externa mejorada. |
| `ruta_viewmodel.dart` | `openNavigation()` con origen real si disponible, solo destino si no. Documentación de migración futura. |

### Archivos creados
- `docs/FASE2B1_RUTA_SIN_MAPS_KEY.md`

### Criterio de aceptación cumplido
- ✅ No aparece "mapa simulado" ni placeholder language
- ✅ Timeline vertical profesional con paradas numeradas y conectores
- ✅ Cada parada muestra: nombre, dirección, coordenadas, prioridad, distancia, tiempo
- ✅ Navegación externa: origen real → ruta completa; sin origen → solo destino
- ✅ SnackBar de error si Google Maps no se puede abrir
- ✅ Sin API Key de Google Maps
- ✅ `flutter analyze`: 0 issues

---

## Fase 2C — Conexión real de módulos prioritarios a Supabase ✅

**Objetivo**: Conectar dashboard, estado solicitudes y reportes a datos reales de Supabase.

### Archivos creados

| Archivo | Propósito |
|---------|-----------|
| `lib/features/estado_solicitudes/data/estado_solicitudes_repository.dart` | Consulta `solicitudes_credito` + join `clientes`, filtrado por `asesor_id` |
| `lib/features/reportes/data/reportes_repository.dart` | Consulta `solicitudes_credito`, `cartera_diaria`, `acciones_cobranza` con indicadores por periodo |
| `docs/sql/FASE2C_SUPABASE_DATOS_REALES.sql` | Documentación de tablas, columnas, inserts demo y consultas |

### Archivos modificados

| Archivo | Cambio |
|---------|--------|
| `home_oficial_viewmodel.dart` | `loadDashboard()` intenta `ReportesRepository` + `EstadoSolicitudesRepository`; fallback a mock hardcoded |
| `estado_solicitudes_viewmodel.dart` | `loadRequests()` intenta repositorio Supabase; si hay datos reales los usa; fallback a `RequestStatusMockData` |
| `estado_solicitud_detalle_viewmodel.dart` | `loadRequest()` intenta Supabase por ID/expediente; fallback a mock |
| `reportes_viewmodel.dart` | `loadReport()` intenta `ReportesRepository` + `loadActivities()`; fallback a mock hardcoded |

### Riesgo
- Dependencia de latencia de red: si Supabase está lento, la app se siente lenta
- Datos incompletos: las tablas pueden no tener datos de prueba

### Criterio de aceptación cumplido
- ✅ Dashboard muestra datos reales del asesor autenticado si existen (fallback a mock)
- ✅ Estado de solicitudes consulta `solicitudes_credito` real con join a `clientes`
- ✅ Reportes consultan `solicitudes_credito`, `cartera_diaria`, `acciones_cobranza` y calculan indicadores reales
- ✅ Detalle de solicitud busca en Supabase primero, fallback a mock
- ✅ Sin cambios en login, GPS, Ruta, cobranza ni solicitud
- ✅ `flutter analyze`: 0 issues

### Documentación
- `docs/FASE2C_SUPABASE_DATOS_REALES.md`
- `docs/sql/FASE2C_SUPABASE_DATOS_REALES.sql`

---

## Fase 2D — SQLite offline básico ✅

**Objetivo**: Persistencia offline local con fallback: Supabase → SQLite → demo/mock.

### Archivos creados

| Archivo | Propósito |
|---------|-----------|
| `lib/features/cartera/data/cartera_local_datasource.dart` | CRUD sobre `cartera_cache`: save/load/clear/has/updateEstado |
| `lib/core/storage/borrador_local_datasource.dart` | Persistencia de borrador de solicitud en `solicitudes_borrador` |
| `lib/core/storage/visitas_local_datasource.dart` | Persistencia de estado visitado en `visitas_pendientes` |

### Archivos modificados

| Archivo | Cambio |
|---------|--------|
| `client_portfolio_model.dart` | Agregados `toMap()`/`fromMap()` para serialización SQLite+Supabase |
| `cartera_repository.dart` | Triada: Supabase → SQLite cache → throw (VM→mock). `lastSource` tracker. `connectivity_plus` check. |
| `cartera_viewmodel.dart` | `_dataSource` getter (`live`/`offline`/`demo`), carga reactiva via `addListener` |
| `cartera_diaria_screen.dart` | Badge "Offline" o "Demo" en `_StatTile`, listener para actualización |
| `solicitud_credito_viewmodel.dart` | `saveDraft()` en cada paso, `_restoreFromDraft()` en `loadInitialData()`, borrado en `submitRequest()` |
| `ruta_viewmodel.dart` | Carga estados guardados de SQLite en `loadTodayRoute()`, `markAsVisited()` ahora `async` y persiste |
| `estado_solicitudes_repository.dart` | `clientes!inner` → `clientes!left` para incluir solicitudes sin cliente vinculado |

### Riesgo mitigado
- **Sin internet**: cartera se carga desde SQLite con badge "Offline"
- **Sin sesión**: repositorios usan SQLite + fallback mock
- **Solicitud a medio llenar**: borrador sobrevive cierre de app, se restaura al reabrir
- **Ruta interrumpida**: estado "visitado" persiste aunque la app se cierre

### Criterio de aceptación cumplido
- ✅ Cartera diaria visible sin conexión a internet (badge "Offline")
- ✅ Borradores de solicitud sobreviven al cierre de la app (restaura en 4 campos)
- ✅ Estado "visitado" de ruta persiste en SQLite (restaura al cargar ruta)
- ✅ LEFT JOIN en EstadoSolicitudesRepository (no excluye solicitudes sin cliente)
- ✅ `connectivity_plus` evita llamada Supabase si no hay red
- ✅ `flutter analyze`: 0 issues

### Documentación
- `docs/FASE2D_SQLITE_OFFLINE.md`

---

## Fase 2E — Cola de sincronización offline (sync_outbox / sync_log) ✅

**Objetivo**: Infraestructura base de sincronización offline→remoto con cola local, reintentos y log. Preparación para FastAPI/Core Mobile.

### Archivos creados

| Archivo | Propósito |
|---------|-----------|
| `lib/core/sync/sync_models.dart` | Modelos `SyncOutboxEntry`, `SyncLogEntry` con `toMap()`/`fromMap()`, constantes |
| `lib/core/sync/sync_local_datasource.dart` | CRUD SQLite sobre `sync_outbox` y `sync_log` |
| `lib/core/sync/sync_manager.dart` | Gestor de cola: `enqueueOperation()`, `processPending()`, `pendingCount()`, reintentos |

### Archivos modificados

| Archivo | Cambio |
|---------|--------|
| `lib/core/storage/local_db.dart` | DB version 1→2, `_createSyncTables()`, `onUpgrade` seguro |
| `lib/main.dart` | `SyncManager.instance.processPending()` al arrancar |
| `lib/features/home/presentation/home_oficial_viewmodel.dart` | `processPending()` en `loadDashboard()` |
| `lib/shared/widgets/oficial_drawer.dart` | `_SyncPendingTile` con contador de pendientes en drawer |
| `lib/features/ruta/presentation/ruta_viewmodel.dart` | Encolar `update_estado_visita` en `markAsVisited()` |
| `lib/features/cobranza/presentation/cobranza_accion_viewmodel.dart` | Encolar `accion_cobranza insert` si falla Supabase |
| `lib/features/solicitud/presentation/solicitud_credito_viewmodel.dart` | Encolar `solicitud_credito insert` si falla Supabase |

### Riesgo
- Conflictos de sincronización si datos offline y online divergen (pendiente para Fase 3)
- Orden de operaciones: se procesa en orden FIFO por `created_at ASC`

### Criterio de aceptación cumplido
- ✅ Tablas `sync_outbox` y `sync_log` creadas con migración segura v1→v2
- ✅ `SyncOutboxEntry` y `SyncLogEntry` modelos con estados y operaciones tipadas
- ✅ `SyncLocalDataSource` con CRUD completo: enqueue, getPending, markProcessing/Synced/Failed, writeLog
- ✅ `SyncManager` con enqueue, processPending, pendingCount, reintentos (máx 3, backoff 5 min)
- ✅ Visita se encola en `markAsVisited()`
- ✅ Cobranza se encola si falla Supabase
- ✅ Solicitud se encola si falla Supabase
- ✅ Procesamiento automático: al arrancar app y al abrir Dashboard
- ✅ Indicador de pendientes en Drawer: "Sincronización pendiente: N"
- ✅ `flutter analyze`: 0 issues
- ✅ `flutter build apk --debug`: exitoso

### Documentación
- `docs/FASE2E_SYNC_OUTBOX.md`

---

## Fase 2F — Sesión persistente ✅

**Objetivo**: Que el oficial no tenga que iniciar sesión cada vez que abre la app y que pueda entrar a módulos offline con sesión/cache previa.

### Archivos creados

| Archivo | Propósito |
|---------|-----------|
| `lib/core/storage/session_local_datasource.dart` | Cache local del perfil del asesor en SQLite (tabla `asesor_cache`, clave/valor) |
| `lib/features/auth/presentation/splash_screen.dart` | Pantalla de carga inicial que verifica sesión y restaura asesor |

### Archivos modificados

| Archivo | Cambio |
|---------|--------|
| `lib/core/storage/local_db.dart` | DB versión 2→3, tabla `asesor_cache` en `onCreate`+`onUpgrade` |
| `lib/core/constants/app_routes.dart` | Ruta `splash` agregada |
| `lib/core/constants/app_strings.dart` | Textos `splashChecking`, `splashLoading` |
| `lib/app/navigation/app_navigation.dart` | `initialRoute`→`AppRoutes.splash`, ruta SplashScreen |
| `lib/features/auth/data/asesor_repository.dart` | Cache asesor tras carga exitosa, fallback a cache local si Supabase falla |
| `lib/features/auth/data/auth_oficial_repository.dart` | `signOut()` limpia cache local |
| `lib/features/auth/presentation/auth_oficial_viewmodel.dart` | Nuevo `tryRestoreSession()`, `signOut()` marca isSuccess+log |

### Riesgo
- Cache asesor en SQLite plano (no cifrado); evaluar `flutter_secure_storage` en producción
- Si el asesor cambia de agencia/roles offline, no se refleja hasta próxima conexión
- Timeout de 15s puede alargar splash en redes lentas

### Criterio de aceptación cumplido
- ✅ Login actual sigue funcionando igual
- ✅ Al abrir app con sesión previa e internet → navega directo a Home
- ✅ Al abrir app sin internet pero con sesión/cache previa → permite entrar con datos cacheados
- ✅ Cartera diaria offline funciona con cache SQLite y badge "Offline"
- ✅ Logout limpia sesión Supabase + cache local + vuelve a Login
- ✅ `flutter analyze`: 0 issues

### Documentación
- `docs/FASE2F_SESION_PERSISTENTE.md`

---

## Fase 3 — App Clientes, roles, cámara, firma, PDF, cronograma, pre-evaluación 📅

**Objetivo**: Agregar funcionalidades avanzadas y preparar integración con App Clientes.

### Archivos probables a modificar

| Módulo | Cambio |
|--------|--------|
| Roles | Agregar campo `rol` a `AsesorModel`, implementar `RoleBasedAccess` |
| Cámara | Reemplazar `_simulateCapture()` con `camera`/`image_picker` + Supabase Storage |
| Firma | Reemplazar `registrarFirmaSimulada()` con `signature` widget |
| PDF | Implementar exportación con `pdf` + `printing` |
| Cronograma | Generar tabla de amortización con cuota, interés, saldo |
| Pre-evaluación | Módulo con puntuación basada en buró + historial + SBS |
| App Clientes | Definir contratos API, tabla `clientes_app` compartida |

### Riesgo
- Scope grande: muchas funcionalidades en una sola fase
- Dependencia del diseño de App Clientes (puede requerir cambios posteriores)

### Criterio de aceptación
- Roles funcionales: menú cambia según rol
- Cámara captura y sube documentos reales
- Firma digital se captura con widget táctil
- PDF se genera y puede compartirse
- Cronograma muestra desglose completo
- Pre-evaluación clasifica clientes viables

### Qué NO tocar todavía
- Core Mobile, notificaciones push, buró real

---

## Fase 4 — Core Mobile FastAPI mínimo 📅

**Objetivo**: Implementar backend mínimo FastAPI para sincronización y lógica de negocio central.

### Archivos probables a crear

| Archivo | Propósito |
|---------|-----------|
| `backend/main.py` | FastAPI app con endpoints CRUD |
| `backend/models.py` | Modelos SQLAlchemy |
| `backend/routes/auth.py` | Autenticación y roles |
| `backend/routes/solicitudes.py` | Gestión de solicitudes |
| `backend/routes/cobranza.py` | Gestión de cobranza |
| `backend/sync/sync_outbox.py` | Procesamiento de cola de sincronización |
| `backend/sync/sync_log.py` | Registro de sincronización |

### Riesgo
- Mayor complejidad de infraestructura (servidor, BD, deploy)
- Latencia de red entre app mobile y backend

### Criterio de aceptación
- API REST funcional para los 6 módulos principales
- Sincronización bidireccional funcional
- Autenticación con JWT

### Qué NO tocar todavía
- Notificaciones push, buró real

---

## Fase 5 — Flujo end-to-end Ventas → Core → Clientes 📅

**Objetivo**: Integrar App Fuerza de Ventas con App Clientes y Core Mobile.

### Archivos probables a modificar

| Módulo | Cambio |
|--------|--------|
| App Fuerza de Ventas | Consumir API de Core Mobile para datos maestros |
| App Clientes | Compartir estado de solicitudes, notificaciones de aprobación |
| Core Mobile | Centralizar reglas de negocio, buró real, scoring |

### Riesgo
- Dependencia de múltiples equipos
- Coordinación de despliegue entre 3 aplicaciones

### Criterio de aceptación
- Una solicitud creada en Ventas se refleja en Core Mobile
- El cliente recibe notificación en App Clientes cuando su solicitud cambia de estado
- Los reportes de Ventas incluyen datos de todas las fuentes

---

## Resumen de hitos

| Fase | Nombre | Prioridad | Duración estimada | Dependencias |
|------|--------|-----------|-------------------|--------------|
| **1** | Base del proyecto | Alta | Completada | — |
| **2A** | Auditoría diferencial | Alta | Completada | Fase 1 |
| **2B** | GPS real | **Crítica** | Completada | Fase 2A |
| **2B.1** | Mejora Ruta sin API Key | Alta | Completada | Fase 2B |
| **2C** | Conexión Supabase real (Dashboard, Estado Solicitudes, Reportes) | Alta | Completada | Fase 2A |
| **2D** | SQLite offline | Alta | Completada | Fase 2A |
| **2E** | Sync outbox/log | Media | Completada | Fase 2D |
| **2F** | Sesión persistente | **Crítica** | Completada | Fase 2E |
| **3** | App Clientes + features avanzadas | Media | 4-6 semanas | Fase 2B, 2C, 2D |
| **4** | Core Mobile FastAPI | Media | 6-8 semanas | Fase 3 |
| **5** | Flujo end-to-end | Baja | 4-6 semanas | Fase 4 |
