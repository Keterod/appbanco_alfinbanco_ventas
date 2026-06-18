# Pendientes técnicos — App Fuerza de Ventas

> Actualizado durante Fase 3A.2 — Pre-evaluación simple.
> Clasificación: ✅ Ya implementado | 🔴 Crítico | 🟡 Importante | ⏸️ Después | 🟢 Opcional

---

## ✅ Ya implementado, no rehacer

| # | Funcionalidad | Archivos clave | Notas |
|---|--------------|----------------|-------|
| 1 | Login Supabase Auth (signInWithPassword) | `auth_oficial_repository.dart`, `auth_oficial_viewmodel.dart` | Usa email derivado de código + RPC demo data |
| 2 | Perfil del asesor | `asesor_model.dart`, `asesor_repository.dart` | Carga desde `asesores_negocio` por `user_id` |
| 3 | Dashboard (interfaz) | `home_oficial_screen.dart`, `home_oficial_viewmodel.dart` | Resumen, accesos rápidos, actividad reciente |
| 4 | Cartera diaria (interfaz + repo) | `cartera_diaria_screen.dart`, `cartera_repository.dart` | Repository Supabase listo, ViewModel con fallback mock |
| 5 | Ficha del cliente (interfaz + repo) | `ficha_cliente_screen.dart`, `ficha_cliente_repository.dart` | Consulta 3 tablas Supabase |
| 6 | Solicitud crédito stepper 4 pasos | `solicitud_credito_screen.dart`, `solicitud_credito_viewmodel.dart` | 21 reglas validación, simulador, envío Supabase |
| 7 | Simulador de cuota (TEA) | `solicitud_credito_viewmodel.dart:257-280` | Fórmula TEA mensual, cuota fija |
| 8 | Checklist documentos | `documentos_screen.dart`, `documentos_viewmodel.dart` | 7 tipos, progreso, vista previa simulada |
| 9 | Transmisión (interfaz) | `transmision_screen.dart`, `transmision_viewmodel.dart` | 6 pasos, progreso, confirmación |
| 10 | Estado solicitudes (interfaz) | `estado_solicitudes_screen.dart`, `estado_solicitud_detalle_screen.dart` | Filtros, resumen, timeline |
| 11 | Ruta visitas (interfaz) | `ruta_screen.dart`, `ruta_viewmodel.dart` | Mapa simulado, optimización, marcar visitado |
| 12 | Cobranza (interfaz) | `cobranza_screen.dart`, `cobranza_accion_screen.dart` | Listado, filtros, formulario con validación |
| 13 | Reportes (interfaz) | `reportes_screen.dart`, `reportes_viewmodel.dart` | 3 periodos, 8 indicadores, progreso |
| 14 | SQLite esquema (4 tablas + datasources) | `local_db.dart`, `cartera_local_datasource.dart`, `borrador_local_datasource.dart`, `visitas_local_datasource.dart` | ✅ Conectado en Fase 2D |
| 15 | Repositorios Supabase (cartera, ficha, buró, solicitud, cobranza) | `*_repository.dart` | Estructura lista para datos reales |
| 16 | Branding unificado | `app_strings.dart`, `app_colors.dart` | "Banco Alfin · App Fuerza de Ventas" |
| 17 | **GPS real** — Ubicación real del oficial en cobranza, solicitud y ruta con fallback controlado | `location_service.dart`, `cobranza_accion_viewmodel.dart`, `solicitud_credito_viewmodel.dart`, `ruta_viewmodel.dart` | `geolocator` + `url_launcher` + permisos |
| 18 | **Ruta sin mapa simulado** — Timeline vertical con paradas numeradas, coordenadas visibles, navegación externa Google Maps | `ruta_screen.dart` (`_RutaOrdenadaView`, `_ParadaTimeline`) | Vista operativa profesional sin API Key |
| 19 | **Dashboard conectado a Supabase** — Visitas, solicitudes y actividad desde `ReportesRepository` + `EstadoSolicitudesRepository` | `home_oficial_viewmodel.dart` | Fallback mock si no hay datos |
| 20 | **Estado Solicitudes desde Supabase** — Consulta `solicitudes_credito` + join `clientes` | `estado_solicitudes_repository.dart`, `estado_solicitudes_viewmodel.dart` | Fallback `RequestStatusMockData` |
| 21 | **Detalle Solicitud desde Supabase** — Timeline generado del estado real | `estado_solicitudes_repository.dart`, `estado_solicitud_detalle_viewmodel.dart` | Fallback mock |
| 22 | **Reportes desde Supabase** — Consulta `solicitudes_credito`, `cartera_diaria`, `acciones_cobranza` | `reportes_repository.dart`, `reportes_viewmodel.dart` | Fallback mock hardcoded |
| 23 | **SQLite cartera_cache** — `CarteraLocalDataSource` con save/load/clear/has | `cartera_local_datasource.dart` | Cache de cartera diaria offline |
| 24 | **Cartera repository con fallback SQLite** — Supabase → cache SQLite → mock | `cartera_repository.dart` | `lastSource: 'live'/'offline'/'demo'` |
| 25 | **Indicador offline/demo en Cartera** — Badge "Offline" o "Demo" en UI | `cartera_diaria_screen.dart` | `_StatTile.badge` |
| 26 | **Borradores SQLite** — `BorradorLocalDataSource` persiste formulario en cada paso | `borrador_local_datasource.dart`, `solicitud_credito_viewmodel.dart` | Restaura al cargar, elimina al enviar |
| 27 | **Ruta persistente en SQLite** — `VisitasLocalDataSource` guarda estado visitado | `visitas_local_datasource.dart`, `ruta_viewmodel.dart` | Restaura estados al cargar ruta |
| 28 | **LEFT JOIN en EstadoSolicitudes** — `clientes!inner` → `clientes!left` | `estado_solicitudes_repository.dart` | Permite solicitudes sin cliente vinculado |
| 29 | **Conectividad en repositorios** — `connectivity_plus` para evitar llamada Supabase offline | `cartera_repository.dart` | Salta a SQLite si no hay red |
| 30 | **sync_outbox / sync_log** — Tablas + modelo + datasource + manager | `sync_models.dart`, `sync_local_datasource.dart`, `sync_manager.dart` | Cola de sincronización offline→remoto |
| 31 | **Encolado visita** — `markAsVisited()` encola `update_estado_visita` | `ruta_viewmodel.dart` | Siempre encola, procesa con internet |
| 32 | **Encolado cobranza** — Si Supabase falla, encola `accion_cobranza insert` | `cobranza_accion_viewmodel.dart` | Fallback offline |
| 33 | **Encolado solicitud** — Si Supabase falla, encola `solicitud_credito insert` | `solicitud_credito_viewmodel.dart` | Fallback offline |
| 34 | **Procesamiento al iniciar/Dashboard** — `SyncManager.processPending()` en startup y en `loadDashboard()` | `main.dart`, `home_oficial_viewmodel.dart` | Reintentos con backoff 5 min, máx 3 |
| 35 | **Indicador de pendientes en Drawer** — Muestra "Sincronización pendiente: N" | `oficial_drawer.dart` | Solo visible si hay > 0 |
| 36 | **Sesión persistente** — Auto‑login al abrir app con sesión Supabase válida | `splash_screen.dart`, `auth_oficial_viewmodel.dart` | `supabase_flutter` v2.8.0 persiste sesión automáticamente |
| 37 | **Cache local del asesor** — Datos mínimos en SQLite (`asesor_cache`) | `session_local_datasource.dart`, `asesor_repository.dart` | Fallback offline en `loadCurrentAsesor()` |
| 38 | **SplashScreen** — Pantalla de carga que restaura sesión y asesor | `splash_screen.dart`, `app_navigation.dart` | Verifica sesión → carga asesor → navega a Home/Login |
| 39 | **Cronograma de cuotas (cálculo + UI)** — Tabla de amortización mes a mes con sistema francés | `cronograma_row.dart`, `solicitud_credito_viewmodel.dart`, `solicitud_credito_screen.dart` | Cálculo en memoria, no persiste en Supabase (pendiente 3A.3). Solo cuota fija. |
| 40 | **Pre-evaluación simple (cálculo + UI)** — Score, elegibilidad (APTO/OBSERVADO/NO APTO), ratio de capacidad de pago, riesgo, motivos | `pre_evaluacion_result.dart`, `solicitud_credito_viewmodel.dart`, `solicitud_credito_screen.dart` | Evaluación en memoria basada en ingresos/gastos/cuota. No persiste en Supabase ni integra buró automáticamente (pendiente 3A.3). |

---

## 🔴 Pendiente crítico para integración final

| # | Pendiente | Archivos | Impacto |
|---|-----------|----------|---------|
| C1 | **Configuración segura de Supabase** — URL y anon key hardcodeadas en texto plano | `supabase_config.dart:2-5` | Riesgo de seguridad en producción |
| C2 | **Sin sesión persistente** ~~— No se configura `persistSession` en inicialización~~ | ~~`main.dart:13-23`~~ | ✅ **Fase 2F** — `supabase_flutter` v2.8.0 persiste sesión automáticamente; `SplashScreen` restaura sesión + cache asesor en SQLite |
| C3 | **Dashboard sin datos reales** — Métricas hardcodeadas, no consulta Supabase | ~~`home_oficial_viewmodel.dart`~~ | 🟡 **Parcial** — Ahora consulta `ReportesRepository` + `EstadoSolicitudesRepository` con fallback mock |
| C4 | **Estado solicitudes desde mock** — No consulta `solicitudes_credito` en Supabase | ~~`estado_solicitudes_viewmodel.dart`~~ | 🟡 **Parcial** — Ahora consulta `EstadoSolicitudesRepository` (join `clientes`) con fallback mock |
| C5 | **Reportes desde mock** — Indicadores no reflejan datos reales | ~~`reportes_viewmodel.dart`~~ | 🟡 **Parcial** — Ahora consulta `ReportesRepository` (3 tablas) con fallback mock |

---

## 🟡 Pendiente importante para App Fuerza de Ventas

| # | Pendiente | Archivos | Impacto |
|---|-----------|----------|---------|
| I1 | **SQLite offline** — cartera, borradores, visitas | `cartera_local_datasource.dart`, `borrador_local_datasource.dart`, `visitas_local_datasource.dart` | ✅ **Fase 2D** — Cartera cacheada, borradores persistidos, visitas guardadas |
| I3 | **Cola de sincronización** — `sync_outbox` + `sync_log` con reintentos | `sync_models.dart`, `sync_local_datasource.dart`, `sync_manager.dart` | ✅ **Fase 2E** — Pendientes: resolución conflictos, FastAPI |
| I4 | **Ficha cliente sin datos para IDs de mora** — `cli-006` a `cli-010` sin mock | `ficha_cliente_viewmodel.dart` | Navegación incompleta desde cobranza |
| I5 | **Roles** — No existe campo `rol` en `AsesorModel`. Sin control de acceso | `asesor_model.dart` | Todos los usuarios ven lo mismo |
| I6 | **Cache asesor en SQLite plano** — No cifrado, sin expiración | `session_local_datasource.dart` | Evaluar `flutter_secure_storage` en producción |

---

## ⏸️ Pendiente para después (Fase 3+)

| # | Pendiente | Dependencias |
|---|-----------|-------------|
| D1 | **Cámara real** — Reemplazar captura simulada en documentos | `camera`, `image_picker` |
| D2 | **Firma digital real** — Reemplazar `registrarFirmaSimulada()` | `signature` |
| D3 | **PDF real** — Exportación de reportes y fichas | `pdf`, `printing` |
| D4 | **Notificaciones push** — Cambio de estado de solicitud | `firebase_messaging`, `flutter_local_notifications` |
| D5 | **Cronograma de cuotas** ~~— Desglose mes a mes en simulación~~ | ~~—~~ | 🟡 **Fase 3A.1** — Implementado en UI y cálculo (sistema francés, solo cuota fija). Falta persistencia en Supabase (3A.3). |
| D6 | **Pre-evaluación de cliente** — Puntuación y reglas de negocio | 🟡 **Fase 3A.2** — Implementado en UI y cálculo (score, elegibilidad, ratio, riesgo, motivos). Falta persistencia en Supabase e integración automática con buró (3A.3). |
| D7 | **Bloqueo por intentos fallidos** — Protección contra fuerza bruta | — |
| D8 | **Integración buró real (SBS/Equifax)** — Reemplazar datos mock | — |

---

## 🟢 Opcional

| # | Pendiente | Beneficio |
|---|-----------|-----------|
| O1 | **Migrar a go_router** — Navegación declarativa | Deep linking, mejor mantenibilidad |
| O2 | **Adoptar Riverpod en UI** — Mejor testabilidad | Menos boilerplate, estado más predecible |
| O3 | **Agregar fl_chart** — Gráficos en reportes | Visualización de datos |
| O4 | **Eliminar dependencias no usadas** — Reducir build time | Menos vulnerabilidades |
| O5 | **Tests unitarios y widget** — Cobertura en flujos críticos | Calidad y regresión |
| O6 | **Modo oscuro** — Tema Material 3 alternativo | Experiencia de usuario |
| O7 | **Internacionalización (i18n)** — Soporte multilingüe | Escalabilidad |
