# Fase 2 — Auditoría Diferencial

## Estado de cada módulo

| # | Módulo | Estado | Evidencia en código | Problema detectado | Acción recomendada |
|---|--------|--------|---------------------|--------------------|--------------------|
| 1 | **Autenticación Supabase Auth** | PARCIAL | `auth_oficial_repository.dart:18-37` — usa `signInWithPassword` con email derivado de código de empleado. `login_oficial_screen.dart` — login con código+contraseña. `main.dart` — inicializa Supabase. | Login demo acepta cualquier credencial sin sesión. Supabase Auth no tiene `persistSession` configurado. No hay renovación de token. | Mantener estructura actual. Agregar `persistSession: true` en `main.dart`. Reemplazar fallback demo con validación real. |
| 2 | **Sesión persistente** | FALTANTE | `main.dart:13-23` — inicializa Supabase sin `persistSession`. `AuthOficialRepository` no verifica sesión existente al iniciar. | Cada vez que se abre la app hay que hacer login de nuevo. No se almacena sesión entre reinicios. | Agregar `persistSession: true` en inicialización Supabase. Verificar `SupabaseHelper.hasSession` en splash/init para auto-login. |
| 3 | **Bloqueo por intentos fallidos** | FALTANTE | No existe contador de intentos, timeout ni lockout en ningún archivo. `auth_oficial_viewmodel.dart:25-67` — solo valida campos vacíos y delega a Supabase. | Sin protección contra fuerza bruta. Cualquier intento fallido no tiene consecuencia. | Implementar en Fase 3. Requiere capa de seguridad en backend. |
| 4 | **Perfil del asesor** | IMPLEMENTADO | `asesor_model.dart` — `AsesorModel` con `id, userId, codigoEmpleado, nombres, apellidos, agenciaId`. `asesor_repository.dart:16-43` — carga desde `asesores_negocio` por `user_id`. | Perfil completo para el flujo actual. Sin embargo, no tiene campo `rol` (ver #5). | Agregar campo `rol` al modelo. Ya está preparado para recibir más columnas. |
| 5 | **Roles: operador, super_operador, supervisor, administrador** | FALTANTE | `asesor_model.dart:3-22` — no tiene campo `rol`. Ningún archivo referencia `role`, `permisos` o control de acceso. Menú lateral no cambia según rol. | Sin roles, todos los usuarios ven las mismas opciones. No hay restricciones funcionales. | Agregar columna `rol` a `asesores_negocio` en Supabase. Agregar campo `rol` a `AsesorModel`. Implementar `RoleBasedAccess` en Fase 3. |
| 6 | **Dashboard** | IMPLEMENTADO | `home_oficial_screen.dart` — saludo, resumen, accesos rápidos, actividad reciente. `home_oficial_viewmodel.dart:43-86` — carga datos mock. | Datos mock, no conectado a Supabase. Actividad reciente hardcodeada. | Conectar a Supabase real: cartera, solicitudes pendientes, mora desde tablas reales. |
| 7 | **Cartera diaria** | PARCIAL | `cartera_repository.dart:11-73` — consulta Supabase `cartera_diaria` + `clientes`. `cartera_viewmodel.dart:35-61` — fallback a 5 clientes mock. | Repository listo para Supabase pero ViewModel prioriza mock si Supabase falla. Sin persistencia offline. | Priorizar Supabase sobre mock cuando haya sesión. Conectar SQLite como cache offline. |
| 8 | **Ficha del cliente** | PARCIAL | `ficha_cliente_repository.dart:10-56` — consulta Supabase `clientes`, `creditos`, `creditos_preaprobados`. `ficha_cliente_viewmodel.dart:57-244` — mock para `cli-001` a `cli-005`. | Solo 5 clientes tienen mock. Clientes de cobranza (`cli-006` a `cli-010`) no tienen ficha. | Agregar datos mock para todos los clientes de cobranza. Priorizar Supabase. |
| 9 | **Buró crediticio** | PARCIAL | `buro_repository.dart:12-67` — guarda resultados en Supabase `consultas_buro`. `buro_viewmodel.dart:86-138` — consulta simulada con 1.1s de delay, datos mock por DNI. | No hay integración real con central de riesgos. El resultado es 100% simulado. | Mantener mock como placeholder. Integración real con SBS/equifax en Fase 4. |
| 10 | **Pre-evaluación de cliente** | FALTANTE | No existe funcionalidad de pre-evaluación dedicada. El buró da un resultado (APTO/REVISAR/BLOQUEADO) pero no hay puntuación ni reglas de negocio. | No se puede filtrar clientes viables antes de iniciar solicitud. | Crear módulo de pre-evaluación en Fase 3. Usar datos de buró + historial + SBS. |
| 11 | **Solicitud de crédito por stepper** | IMPLEMENTADO | `solicitud_credito_screen.dart` — wizard 4 pasos completo. `solicitud_credito_viewmodel.dart` — validación de 21 reglas, precarga, envío a Supabase. `solicitud_repository.dart:26-96` — inserta en `solicitudes_credito`. | Stepper funcional. Envío a Supabase implementado. Validación completa. | No rehacer. Solo conectar dashboard y estado solicitudes a datos reales. |
| 12 | **Simulador de crédito** | IMPLEMENTADO | `solicitud_credito_viewmodel.dart:257-280` — `calculateInstallment()` con fórmula TEA mensual. | Simulador básico de cuota fija. No genera cronograma completo. | Agregar cronograma de cuotas en Fase 3. |
| 13 | **Cronograma de cuotas** | FALTANTE | No existe generación de cronograma. `solicitud_credito_viewmodel.dart` solo calcula cuota mensual estimada. | El oficial no puede ver el desglose mes a mes. | Implementar en Fase 3. Tabla con número cuota, fecha, capital, interés, saldo. |
| 14 | **Documentos** | PARCIAL | `documentos_screen.dart` — checklist 7 docs (4 obligatorios). `documentos_viewmodel.dart:85-116` — captura simulada con metadatos aleatorios. | Captura 100% simulada. Sin integración de cámara real. No sube a Supabase Storage. | Reemplazar captura simulada con cámara real en Fase 3. Conectar a Supabase Storage. |
| 15 | **Transmisión electrónica** | PARCIAL | `transmision_screen.dart` — 6 pasos con progreso. `transmision_viewmodel.dart:171-210` — 6 pasos secuenciales simulados. | Todos los pasos son simulados con delays. No envía datos reales a ningún backend. | Conectar a flujo real de comité en Fase 4. Por ahora mantener como demo visual. |
| 16 | **Estado de solicitudes** | PARCIAL | `estado_solicitudes_screen.dart` — filtros, resumen, tarjetas. `request_status_mock_data.dart` — 8 solicitudes mock con 7 estados diferentes. `estado_solicitudes_viewmodel.dart:10` — carga desde mock. | No hay consulta a Supabase para estado real. Datos 100% mock. | Conectar a Supabase `solicitudes_credito` para consultar estado real. |
| 17 | **Ruta de visitas** | PARCIAL | `ruta_screen.dart` — mapa simulado, resumen, marcar visitado. `ruta_viewmodel.dart:118-191` — 5 visitas seed con coordenadas. | Sin GPS. Sin conexión a Supabase. Sin persistencia. Mapa es UI simulada. | Agregar GPS en Fase 2B. Conectar a Supabase `cartera_diaria`. Persistir en SQLite. |
| 18 | **GPS/geolocalización** | PLACEHOLDER | `cobranza_accion_viewmodel.dart:20` — `simulatedLat = -12.0464, simulatedLng = -77.0428`. `ruta_viewmodel.dart` — coordenadas fijas por cliente. `solicitud_repository.dart:23-24` — mismas coords fijas. | Coordenadas fijas en todos los módulos. Sin `geolocator` en uso. Sin permisos GPS configurados. | Implementar GPS real en Fase 2B. Usar `geolocator` para obtener ubicación en visita y cobranza. |
| 19 | **Cobranza** | PARCIAL | `cobranza_screen.dart` — listado 7 clientes, filtros. `cobranza_local_repository.dart` — datos en memoria. `cobranza_repository.dart` — inserta acciones en Supabase. | Datos seed en memoria, no persisten entre sesiones. Sin GPS real. Sin conexión a cartera vencida real. | Conectar a Supabase para lista de morosos real. Persistir en SQLite. GPS real. |
| 20 | **Reportes** | IMPLEMENTADO | `reportes_screen.dart` — 3 periodos, 8 indicadores, progreso. `reportes_viewmodel.dart:81-137` — 3 conjuntos de datos mock por periodo. | Datos 100% mock. No conectado a Supabase. Sin exportación real. | Conectar a Supabase para indicadores reales. Exportación PDF en Fase 3. |
| 21 | **SQLite offline** | PLACEHOLDER | `local_db.dart:25-83` — 4 tablas creadas (`visitas_pendientes`, `solicitudes_borrador`, `cartera_cache`, `cartera_orden_local`). `main.dart:26` — inicializa BD. | Tablas creadas pero nunca escritas ni leídas por ningún módulo. Sin cola de sync. | Implementar en Fase 2D: persistencia offline con cola de sincronización. |
| 22 | **Cola de sincronización** | FALTANTE | No existe tabla `sync_outbox`, `sync_log` ni lógica de cola de sincronización. `local_db.dart` no tiene estas tablas. | Sin mecanismo de sincronización offline/online. | Crear tablas `sync_outbox` y `sync_log` en Fase 2E. Implementar cola. |
| 23 | **Notificaciones** | FALTANTE | `pubspec.yaml:33-34` — `flutter_local_notifications` y `firebase_messaging` declarados. No hay código que los use. | Dependencias declaradas pero 0 implementación. | Implementar en Fase 4. Notificaciones de cambio de estado de solicitud. |
| 24 | **Exportación PDF** | PLACEHOLDER | `estado_solicitud_detalle_screen.dart:53-55` — SnackBar "Exportación PDF — función en siguiente fase". `reportes_screen.dart:41-45` — mismo placeholder. | Botones existen pero no hacen nada real. Dependencias `pdf` y `printing` ya declaradas. | Implementar en Fase 3. Usar `pdf` + `printing`. |
| 25 | **Configuración segura de Supabase** | FALTANTE | `supabase_config.dart:2-5` — URL y anon key hardcodeadas en texto plano. Sin `.env`, sin `flutter_secure_storage`. | Exposición de credenciales en código fuente. Riesgo de seguridad en producción. | Migrar a variables de entorno o `flutter_secure_storage`. No cambiar ahora, documentar. |
| 26 | **Integración futura App Clientes/Core Mobile** | FALTANTE | No existe ninguna tabla, servicio, API ni código referente a App Clientes o Core Mobile. | Proyecto aislado sin preparación para integración. | Preparar en Fase 3: definir contratos API, tablas compartidas `sync_outbox`, `sync_log`. |

---

## Funcionalidades que NO se deben rehacer (ya funcionan)

| Funcionalidad | Razón |
|---------------|-------|
| Login con Supabase Auth | Ya implementado con `signInWithPassword`, conversión código→email, RPC demo data |
| Perfil del asesor | `AsesorModel` + `AsesorRepository` cargan desde `asesores_negocio` |
| Dashboard | Pantalla completa con resumen, accesos rápidos, actividad reciente |
| Cartera diaria | Repository Supabase listo, ViewModel con fallback mock |
| Ficha del cliente | Repository Supabase con consulta a 3 tablas, mock para 5 clientes |
| Solicitud de crédito (stepper 4 pasos) | Wizard completo con 21 reglas de validación, simulador, envío a Supabase |
| Simulador de crédito | Fórmula TEA, cálculo de cuota mensual estimada |
| Checklist de documentos | 7 tipos, 4 obligatorios, progreso visual, vista previa simulada |
| Transmisión (interfaz) | 6 pasos con barra de progreso, confirmación, reintento |
| Estado de solicitudes (interfaz) | Filtros, resumen, timeline, nota interna |
| Ruta de visitas (interfaz) | Mapa simulado, optimización, marcar visitado |
| Cobranza (interfaz) | Listado, filtros, formulario de gestión, validación |
| Reportes | 3 periodos, 8 indicadores, barras de progreso, etiqueta productividad |
| SQLite (esquema) | 4 tablas creadas listas para usar |

---

## Funcionalidades que solo necesitan ajustes pequeños

| Funcionalidad | Ajuste necesario | Archivos |
|---------------|-----------------|----------|
| Sesión persistente | Agregar `persistSession: true` en inicialización Supabase + verificar sesión al iniciar | `main.dart`, nuevo splash screen |
| Dashboard conectado a datos reales | Reemplazar datos mock por consultas a Supabase en `HomeOficialViewModel` | `home_oficial_viewmodel.dart` |
| Cartera priorizar Supabase | Invertir lógica: intentar Supabase primero, fallback mock solo si falla | `cartera_viewmodel.dart` |
| Mock para clientes de cobranza | Agregar `cli-006` a `cli-010` en `FichaClienteViewModel._mockDetails` | `ficha_cliente_viewmodel.dart` |
| Estado solicitudes desde Supabase | Consultar `solicitudes_credito` en lugar de `RequestStatusMockData` | `estado_solicitudes_viewmodel.dart`, nuevo repository |
| Reportes desde Supabase | Consultar indicadores reales en lugar de datos mock | `reportes_viewmodel.dart`, nuevo repository |

---

## Funcionalidades para implementar en fases siguientes

| Fase | Funcionalidad |
|------|---------------|
| **Fase 2B** | GPS real en visitas, cobranza y ubicación del negocio |
| **Fase 2C** | Conexión real de dashboard, estado solicitudes y reportes a Supabase |
| **Fase 2D** | SQLite offline básico con persistencia de cartera, visitas y borradores |
| **Fase 2E** | Preparación de tablas `sync_outbox`, `sync_log` para integración futura |
| **Fase 3** | Roles y permisos, cronograma de cuotas, cámara real, firma real, PDF, pre-evaluación, App Clientes |
| **Fase 4** | Core Mobile FastAPI mínimo, notificaciones push, integración buró real |
| **Fase 5** | Flujo end-to-end Ventas → Core → Clientes |

---

## Riesgos técnicos reales encontrados

| # | Riesgo | Archivo | Impacto | Mitigación |
|---|--------|---------|---------|------------|
| 1 | Supabase URL y anon key hardcodeadas | `supabase_config.dart:2-5` | Exposición de credenciales en repositorio | Mover a `.env` o `flutter_secure_storage` antes de producción |
| 2 | `?clienteId` como null-aware entry en map | `solicitud_repository.dart:47` `buro_repository.dart:42` | Sintaxis válida en Dart 3.x pero podría ser confusa para el equipo | Documentar que es null-aware spread de Dart 3.3+. Mantener. |
| 3 | Sin persistencia entre sesiones | Todos los ViewModels | Datos seed se pierden al reiniciar app | Implementar SQLite offline antes de producción |
| 4 | Ficha cliente sin datos para IDs de mora | `ficha_cliente_viewmodel.dart` | `cli-006` a `cli-010` no tienen ficha | Agregar datos mock pendientes |
| 5 | Riverpod + go_router declarados no usados | `pubspec.yaml` | Dependencias innecesarias, build más lento | Evaluar si se usarán; si no, eliminar |
| 6 | fl_chart, photo_view, workmanager sin usar | `pubspec.yaml` | Dependencias muertas | Eliminar si no hay planes inmediatos de uso |

---

## Orden recomendado de trabajo

1. **Fase 2B**: GPS real (mayor impacto operativo, desbloquea funcionalidad clave)
2. **Fase 2C**: Conectar dashboard, estado solicitudes y reportes a Supabase (datos reales)
3. **Fase 2D**: SQLite offline + cola de sync (operatividad sin internet)
4. **Fase 2E**: Tablas `sync_outbox`/`sync_log` y preparación App Clientes
5. **Fase 3**: Roles, cámara, firma, PDF, cronograma, pre-evaluación
6. **Fase 4**: Core Mobile, notificaciones, buró real
7. **Fase 5**: Flujo end-to-end

> **Nota**: La Fase 2B (GPS) debe priorizarse porque es el bloqueador principal para que los oficiales puedan usar la app en campo con ubicación real.
