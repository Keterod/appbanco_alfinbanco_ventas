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

## Fase 2B — GPS real en visitas, cobranza y ubicación del negocio 📅

**Objetivo**: Reemplazar coordenadas fijas por geolocalización real usando `geolocator`.

### Archivos probables a modificar

| Archivo | Cambio |
|---------|--------|
| `cobranza_accion_viewmodel.dart` | Reemplazar `simulatedLat/simulatedLng` con `Geolocator.getCurrentPosition()` |
| `cobranza_accion_screen.dart` | Mostrar ubicación real, agregar permisos |
| `ruta_viewmodel.dart` | Actualizar coordenadas según ubicación actual del oficial |
| `ruta_screen.dart` | Reemplazar mapa simulado con Google Maps |
| `solicitud_repository.dart` | Usar coordenadas reales en lugar de fijas |
| `solicitud_credito_viewmodel.dart` | Capturar ubicación al iniciar solicitud |
| `android/app/src/main/AndroidManifest.xml` | Agregar permisos `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION` |
| `ios/Runner/Info.plist` | Agregar `NSLocationWhenInUseUsageDescription` |

### Riesgo
- Batería: el uso continuo de GPS puede agotar batería del dispositivo
- Permisos: el usuario debe aceptar permisos de ubicación
- Offline: GPS funciona sin internet pero la geocodificación inversa no

### Criterio de aceptación
- Al abrir cobranza y registrar gestión, se captura lat/lng real del dispositivo
- En ruta de visitas, se muestra la ubicación actual del oficial en el mapa
- Las coordenadas se guardan en Supabase y SQLite

### Qué NO tocar todavía
- Cámara, firma, PDF, notificaciones, roles, pre-evaluación

---

## Fase 2C — Conexión real de módulos prioritarios a Supabase 📅

**Objetivo**: Conectar dashboard, estado solicitudes y reportes a datos reales de Supabase.

### Archivos probables a modificar

| Archivo | Cambio |
|---------|--------|
| `home_oficial_viewmodel.dart` | Consultar cartera, solicitudes y mora desde Supabase en lugar de mock |
| `estado_solicitudes_viewmodel.dart` | Consultar `solicitudes_credito` filtrado por `asesor_id` |
| `reportes_viewmodel.dart` | Calcular indicadores desde datos reales de Supabase |
| Nuevo: `estado_solicitudes_repository.dart` | Repositorio para consultar estado desde Supabase |
| Nuevo: `reportes_repository.dart` | Repositorio para consultar indicadores desde Supabase |
| `home_oficial_screen.dart` | Pequeños ajustes si cambia estructura de datos |

### Riesgo
- Dependencia de latencia de red: si Supabase está lento, la app se siente lenta
- Datos incompletos: las tablas pueden no tener datos de prueba

### Criterio de aceptación
- Dashboard muestra datos reales del asesor autenticado
- Estado de solicitudes consulta `solicitudes_credito` real
- Reportes muestran indicadores reales

### Qué NO tocar todavía
- GPS, cámara, firma, PDF, roles, SQLite offline completo

---

## Fase 2D — SQLite offline básico con cola de pendientes 📅

**Objetivo**: Implementar persistencia offline para cartera diaria y borradores de solicitud.

### Archivos probables a modificar

| Archivo | Cambio |
|---------|--------|
| `local_db.dart` | Agregar helpers de inserción/consulta para las 4 tablas existentes |
| `cartera_viewmodel.dart` | Guardar cartera en SQLite al cargar, leer desde SQLite si offline |
| `solicitud_credito_viewmodel.dart` | Guardar borrador en SQLite al cambiar de paso |
| `cartera_repository.dart` | Estrategia: intentar Supabase, fallback a SQLite |
| `ruta_viewmodel.dart` | Persistir visitas y estado en SQLite |

### Riesgo
- Consistencia de datos entre SQLite local y Supabase remoto
- Migraciones de esquema SQLite cuando cambien tablas de Supabase

### Criterio de aceptación
- La cartera diaria se puede ver sin conexión a internet
- Los borradores de solicitud sobreviven al cierre de la app
- Al volver a internet, los datos locales se actualizan (sin cola todavía)

### Qué NO tocar todavía
- Cola de sincronización bidireccional, sync_outbox, conflictos

---

## Fase 2E — Preparación de tablas sync_outbox/sync_log para integración futura 📅

**Objetivo**: Crear infraestructura de sincronización para App Clientes y Core Mobile.

### Archivos a crear/modificar

| Archivo | Cambio |
|---------|--------|
| `local_db.dart` | Agregar tablas `sync_outbox`, `sync_log` |
| Nuevo: `core/sync/sync_manager.dart` | Gestor de cola: encolar, procesar, reintentar |
| Nuevo: `core/sync/sync_models.dart` | Modelos `SyncOutboxEntry`, `SyncLogEntry` |
| `main.dart` | Inicializar `SyncManager` al arrancar |

### Riesgo
- Conflictos de sincronización si el oficial modifica datos offline mientras otro usuario los modificó online
- Orden de operaciones: las operaciones deben aplicarse en orden correcto

### Criterio de aceptación
- Las operaciones offline se guardan en `sync_outbox`
- Al volver online, la cola se procesa automáticamente
- Los errores de sync se registran en `sync_log`
- No hay pérdida de datos por conflictos no resueltos

### Qué NO tocar todavía
- App Clientes real, Core Mobile, FastAPI

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
| **2B** | GPS real | **Crítica** | 1-2 semanas | Fase 2A |
| **2C** | Conexión Supabase real | Alta | 2-3 semanas | Fase 2A |
| **2D** | SQLite offline | Alta | 2-3 semanas | Fase 2A |
| **2E** | Sync outbox/log | Media | 1 semana | Fase 2D |
| **3** | App Clientes + features avanzadas | Media | 4-6 semanas | Fase 2B, 2C, 2D |
| **4** | Core Mobile FastAPI | Media | 6-8 semanas | Fase 3 |
| **5** | Flujo end-to-end | Baja | 4-6 semanas | Fase 4 |
