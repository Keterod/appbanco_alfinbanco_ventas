# Fase 1 — Base del Proyecto

## Datos generales

| Campo | Valor |
|---|---|
| **Nombre del proyecto** | Banco Alfin — App Fuerza de Ventas |
| **Nombre del paquete Dart** | `banco_alfinbanco_ventas` |
| **Tipo de aplicación** | Móvil multiplataforma (Android, iOS, Web, Windows, macOS, Linux) |
| **Lenguaje** | Dart 3.x (SDK `^3.11.4`) |
| **Framework** | Flutter (Material 3) |
| **Patrón arquitectónico** | MVVM con `ChangeNotifier` + Repositorios |
| **Backend** | Supabase (Auth + Database) con fallback a datos mock locales |
| **Base de datos local** | SQLite (`sqflite`) — esqueleto con tablas definidas, sin uso en flujo actual |
| **Navegación** | `MaterialApp` con rutas nombradas |
| **Versión** | `0.1.0+1` |

---

## Stack tecnológico actual

| Tecnología | Versión | Propósito |
|---|---|---|
| **Flutter** | 3.x | Framework UI multiplataforma |
| **Dart** | ^3.11.4 | Lenguaje de programación |
| **supabase_flutter** | ^2.8.0 | Backend: Auth + PostgreSQL |
| **sqflite** | ^2.3.3 | Persistencia local SQLite |
| **flutter_riverpod** | ^2.5.1 | Estado (infraestructura, no usado en UI de negocio) |
| **riverpod_annotation** | ^2.3.5 | Anotaciones Riverpod |
| **intl** | ^0.19.0 | Formateo de fechas y monedas |
| **connectivity_plus** | ^6.0.5 | Monitoreo de conectividad |
| **flutter_lints** | ^6.0.0 | Linting |

---

## Estructura de carpetas (real)

```
lib/
├── main.dart                                # Punto de entrada
├── app/
│   └── navigation/
│       └── app_navigation.dart              # MaterialApp + tabla de rutas
├── core/
│   ├── constants/
│   │   ├── app_colors.dart                  # Paleta de colores Banco Alfin
│   │   ├── app_routes.dart                  # Constantes de rutas (13)
│   │   ├── app_strings.dart                 # Textos centralizados (CREADO EN FASE 1)
│   │   └── app_theme.dart                   # Tema Material 3
│   ├── network/
│   │   └── network_monitor.dart             # Riverpod: monitoreo de conectividad
│   ├── storage/
│   │   └── local_db.dart                    # Singleton SQLite (esquema offline)
│   └── supabase/
│       ├── supabase_client.dart             # Getter del cliente Supabase
│       ├── supabase_config.dart             # URL + anon key
│       ├── supabase_helper.dart             # Timeouts, logs, errores amigables
│       └── supabase_lookup.dart             # Resolución de IDs mock → UUID real
├── features/
│   ├── auth/                                # HU-V01: Login
│   ├── home/                                # HU-V01: Dashboard
│   ├── cartera/                             # HU-V02: Cartera diaria
│   ├── ficha_cliente/                       # HU-V03: Ficha del cliente
│   ├── buro/                                # HU-V08: Consulta de buró
│   ├── solicitud/                           # HU-V04: Solicitud de crédito
│   ├── documentos/                          # HU-V05: Captura de documentos
│   ├── transmision/                         # HU-V06: Transmisión electrónica
│   ├── estado_solicitudes/                  # HU-V07: Estado de solicitudes
│   ├── ruta/                                # HU-V09: Ruta de visitas
│   ├── cobranza/                            # HU-V10: Cartera vencida
│   └── reportes/                            # Reportes de productividad
└── shared/
    └── widgets/
        ├── oficial_drawer.dart              # Menú lateral global
        └── app_filter_chip.dart             # Chip de filtro reutilizable
```

---

## Pantallas detectadas (14)

| # | Pantalla | Archivo | Ruta |
|---|----------|---------|------|
| 1 | `LoginOficialScreen` | `login_oficial_screen.dart` | `/` |
| 2 | `HomeOficialScreen` | `home_oficial_screen.dart` | `/home-oficial` |
| 3 | `CarteraDiariaScreen` | `cartera_diaria_screen.dart` | `/cartera` |
| 4 | `FichaClienteScreen` | `ficha_cliente_screen.dart` | `/ficha-cliente` |
| 5 | `BuroScreen` | `buro_screen.dart` | `/buro` |
| 6 | `SolicitudCreditoScreen` | `solicitud_credito_screen.dart` | `/solicitud-credito` |
| 7 | `DocumentosScreen` | `documentos_screen.dart` | `/documentos` |
| 8 | `TransmisionScreen` | `transmision_screen.dart` | `/transmision` |
| 9 | `EstadoSolicitudesScreen` | `estado_solicitudes_screen.dart` | `/estado-solicitudes` |
| 10 | `EstadoSolicitudDetalleScreen` | `estado_solicitud_detalle_screen.dart` | `/estado-solicitud-detalle` |
| 11 | `RutaScreen` | `ruta_screen.dart` | `/ruta` |
| 12 | `CobranzaScreen` | `cobranza_screen.dart` | `/cobranza` |
| 13 | `CobranzaAccionScreen` | `cobranza_accion_screen.dart` | `/cobranza-accion` |
| 14 | `ReportesScreen` | `reportes_screen.dart` | `/reportes` |

---

## ViewModels detectados (12)

| ViewModel | Feature | Archivo |
|-----------|---------|---------|
| `AuthOficialViewModel` | auth | `auth_oficial_viewmodel.dart` |
| `HomeOficialViewModel` | home | `home_oficial_viewmodel.dart` |
| `CarteraViewModel` | cartera | `cartera_viewmodel.dart` |
| `FichaClienteViewModel` | ficha_cliente | `ficha_cliente_viewmodel.dart` |
| `BuroViewModel` | buro | `buro_viewmodel.dart` |
| `SolicitudCreditoViewModel` | solicitud | `solicitud_credito_viewmodel.dart` |
| `DocumentosViewModel` | documentos | `documentos_viewmodel.dart` |
| `TransmisionViewModel` | transmision | `transmision_viewmodel.dart` |
| `EstadoSolicitudesViewModel` | estado_solicitudes | `estado_solicitudes_viewmodel.dart` |
| `EstadoSolicitudDetalleViewModel` | estado_solicitudes | `estado_solicitud_detalle_viewmodel.dart` |
| `RutaViewModel` | ruta | `ruta_viewmodel.dart` |
| `CobranzaViewModel` | cobranza | `cobranza_viewmodel.dart` |
| `CobranzaAccionViewModel` | cobranza | `cobranza_accion_viewmodel.dart` |
| `ReportesViewModel` | reportes | `reportes_viewmodel.dart` |

---

## Modelos de dominio detectados (16)

| Modelo | Feature | Archivo |
|--------|---------|---------|
| `AsesorModel` | auth | `asesor_model.dart` |
| `ClientPortfolioModel` | cartera | `client_portfolio_model.dart` |
| `ClientDetailModel` | ficha_cliente | `client_detail_model.dart` |
| `CreditHistoryItem` | ficha_cliente | `client_detail_model.dart` |
| `BuroResultModel` | buro | `buro_result_model.dart` |
| `CreditRequestModel` | solicitud | `credit_request_model.dart` |
| `DocumentModel` | documentos | `document_model.dart` |
| `TransmissionModel` | transmision | `transmission_model.dart` |
| `TransmissionStepModel` | transmision | `transmission_model.dart` |
| `RequestStatusModel` | estado_solicitudes | `request_status_model.dart` |
| `RequestTimelineItem` | estado_solicitudes | `request_status_model.dart` |
| `RouteVisitModel` | ruta | `route_visit_model.dart` |
| `OverdueClientModel` | cobranza | `collection_model.dart` |
| `CollectionActionModel` | cobranza | `collection_model.dart` |
| `OfficerReportModel` | reportes | `report_model.dart` |
| `ReportActivityItem` | reportes | `report_model.dart` |

---

## Repositorios / Servicios detectados (9)

| Repositorio | Feature | Archivo | Tipo |
|-------------|---------|---------|------|
| `AuthOficialRepository` | auth | `auth_oficial_repository.dart` | Supabase |
| `AsesorRepository` | auth | `asesor_repository.dart` | Supabase |
| `CarteraRepository` | cartera | `cartera_repository.dart` | Supabase |
| `FichaClienteRepository` | ficha_cliente | `ficha_cliente_repository.dart` | Supabase |
| `BuroRepository` | buro | `buro_repository.dart` | Supabase |
| `SolicitudRepository` | solicitud | `solicitud_repository.dart` | Supabase |
| `CobranzaRepository` | cobranza | `cobranza_repository.dart` | Supabase |
| `CobranzaLocalRepository` | cobranza | `cobranza_local_repository.dart` | Local (memoria) |
| `LocalDb` | core | `local_db.dart` | SQLite (esqueleto) |

---

## Rutas detectadas (13)

| Ruta | Constante en `AppRoutes` | Argumentos |
|------|--------------------------|------------|
| `/` | `login` | — |
| `/home-oficial` | `homeOficial` | — |
| `/cartera` | `cartera` | — |
| `/ficha-cliente` | `fichaCliente` | `clientId` (String) |
| `/buro` | `buro` | `clientId` (String?, opcional) |
| `/solicitud-credito` | `solicitudCredito` | `clientId` (String?, opcional) |
| `/documentos` | `documentos` | `solicitudId` (String?, opcional) |
| `/transmision` | `transmision` | `solicitudId` (String?, opcional) |
| `/estado-solicitudes` | `estadoSolicitudes` | `highlightReference` (String?, opcional) |
| `/estado-solicitud-detalle` | `estadoSolicitudDetalle` | `requestId` o `numeroExpediente` (String) |
| `/ruta` | `ruta` | — |
| `/cobranza` | `cobranza` | — |
| `/cobranza-accion` | `cobranzaAccion` | `overdueClientId` (String) |
| `/reportes` | `reportes` | — |

---

## Funcionalidades implementadas

| HU | Módulo | Funcionalidad | Estado |
|----|--------|---------------|--------|
| HU-V01 | Auth | Login institucional con validación de campos | ✅ |
| HU-V01 | Auth | Integración Supabase Auth | ✅ |
| HU-V01 | Auth | Cierre de sesión | ✅ |
| HU-V01 | Auth | Fallback demo offline | ✅ |
| HU-V01 | Home | Dashboard con resumen del día | ✅ |
| HU-V01 | Home | Accesos rápidos (5 módulos) | ✅ |
| HU-V01 | Home | Actividad reciente | ✅ |
| HU-V01 | Home | Menú lateral global (8 opciones) | ✅ |
| HU-V02 | Cartera | Listado de clientes de cartera | ✅ |
| HU-V02 | Cartera | Contadores visitas/pendientes/visitados | ✅ |
| HU-V02 | Cartera | Chips de gestión y estado | ✅ |
| HU-V02 | Cartera | Navegación a ficha del cliente | ✅ |
| HU-V03 | Ficha | Vista 360° del cliente | ✅ |
| HU-V03 | Ficha | Semáforo de riesgo SBS (5 niveles) | ✅ |
| HU-V03 | Ficha | Datos de contacto y negocio | ✅ |
| HU-V03 | Ficha | Posición del cliente | ✅ |
| HU-V03 | Ficha | Historial crediticio | ✅ |
| HU-V03 | Ficha | Oferta vigente | ✅ |
| HU-V03 | Ficha | Barra de acciones (buró, solicitud, llamada) | ✅ |
| HU-V08 | Buró | Ingreso de DNI con validación 8 dígitos | ✅ |
| HU-V08 | Buró | Consentimiento informado + firma simulada | ✅ |
| HU-V08 | Buró | Resultado APTO/REVISAR/BLOQUEADO | ✅ |
| HU-V08 | Buró | Semáforo SBS + entidades + deuda + mora | ✅ |
| HU-V08 | Buró | Lista de restricción | ✅ |
| HU-V08 | Buró | Botón continuar a solicitud | ✅ |
| HU-V04 | Solicitud | Wizard de 4 pasos | ✅ |
| HU-V04 | Solicitud | Paso 1: Datos del solicitante (8 campos) | ✅ |
| HU-V04 | Solicitud | Paso 2: Datos del negocio (7 campos) | ✅ |
| HU-V04 | Solicitud | Paso 3: Condiciones y simulador de cuota | ✅ |
| HU-V04 | Solicitud | Paso 4: Confirmación y declaración jurada | ✅ |
| HU-V04 | Solicitud | Validación por paso (21 reglas) | ✅ |
| HU-V04 | Solicitud | Simulador de cuota (fórmula TEA) | ✅ |
| HU-V04 | Solicitud | Precarga de datos desde ficha cliente | ✅ |
| HU-V04 | Solicitud | Generación de expediente | ✅ |
| HU-V05 | Documentos | Checklist de 7 documentos (4 obligatorios) | ✅ |
| HU-V05 | Documentos | Barra de progreso | ✅ |
| HU-V05 | Documentos | Captura simulada con metadatos | ✅ |
| HU-V05 | Documentos | Retomar/Eliminar documento | ✅ |
| HU-V05 | Documentos | Vista previa simulada | ✅ |
| HU-V06 | Transmisión | Proceso de 6 pasos secuenciales | ✅ |
| HU-V06 | Transmisión | Barra de progreso lineal | ✅ |
| HU-V06 | Transmisión | Confirmación con expediente oficial | ✅ |
| HU-V06 | Transmisión | Botón reintentar en error | ✅ |
| HU-V06 | Transmisión | Navegación a estado de solicitud | ✅ |
| HU-V07 | Estado | Resumen operativo (total/aprobadas/desembolsadas) | ✅ |
| HU-V07 | Estado | Filtros por estado (7 chips) | ✅ |
| HU-V07 | Estado | Tarjetas de solicitud con resaltado reciente | ✅ |
| HU-V07 | Estado | Detalle con línea de tiempo (5-6 eventos) | ✅ |
| HU-V07 | Estado | Nota interna | ✅ |
| HU-V09 | Ruta | Resumen del día | ✅ |
| HU-V09 | Ruta | Optimización de ruta por prioridad + distancia | ✅ |
| HU-V09 | Ruta | Mapa simulado con chips | ✅ |
| HU-V09 | Ruta | Marcar visita como realizada | ✅ |
| HU-V09 | Ruta | 3 niveles de prioridad, 5 tipos de gestión | ✅ |
| HU-V10 | Cobranza | Listado de clientes en mora (7) | ✅ |
| HU-V10 | Cobranza | Resumen de mora (preventivos/prioritarios/urgentes) | ✅ |
| HU-V10 | Cobranza | Filtros por prioridad | ✅ |
| HU-V10 | Cobranza | Formulario de gestión (tipo, resultado, montos) | ✅ |
| HU-V10 | Cobranza | Validación de gestión (5 reglas) | ✅ |
| HU-V10 | Cobranza | Actualización de estado post-gestión | ✅ |
| — | Reportes | Filtro por periodo (hoy/semana/mes) | ✅ |
| — | Reportes | 8 indicadores operativos | ✅ |
| — | Reportes | Barras de progreso (cobertura/aprobación) | ✅ |
| — | Reportes | Etiqueta de productividad | ✅ |
| — | Reportes | Actividad reciente | ✅ |

---

## Funcionalidades simuladas o placeholder

| Funcionalidad | Estado | Detalle |
|---------------|--------|---------|
| Autenticación real | Simulado | Cualquier credencial funciona en modo demo |
| Cámara para documentos | Simulado | Captura simulada con metadatos aleatorios |
| Firma digital | Simulado | Solo marca booleano `firmaSimulada` |
| GPS / Geolocalización | Simulado | Coordenadas fijas `(-12.0464, -77.0428)` |
| Mapa (Google Maps) | Placeholder | Mensaje: "integración de mapas en siguiente fase" |
| Navegación externa (Waze/Maps) | Placeholder | Mensaje: "función en siguiente fase" |
| Exportación PDF | Placeholder | Mensaje: "función en siguiente fase" |
| Exportación de reportes | Placeholder | Mensaje: "disponible en siguiente fase" |
| Notificaciones push | No implementado | Dependencias declaradas, sin implementación |
| Tareas en segundo plano | No implementado | Dependencia declarada, sin implementación |
| Datos offline persistentes | No implementado | SQLite con tablas creadas, sin uso en flujo |
| Gráficos (fl_chart) | No implementado | Dependencia declarada, no usada |

---

## Dependencias declaradas pero no usadas

| Dependencia | Declarada en | Propósito | ¿Se usa? |
|-------------|-------------|-----------|----------|
| `go_router` | `pubspec.yaml` | Navegación declarativa | No (usa rutas nombradas) |
| `google_maps_flutter` | `pubspec.yaml` | Mapas | No |
| `geolocator` | `pubspec.yaml` | GPS | No |
| `geocoding` | `pubspec.yaml` | Geocodificación | No |
| `camera` | `pubspec.yaml` | Cámara | No |
| `image_picker` | `pubspec.yaml` | Selección imágenes | No |
| `image` | `pubspec.yaml` | Procesamiento imágenes | No |
| `fl_chart` | `pubspec.yaml` | Gráficos | No |
| `flutter_local_notifications` | `pubspec.yaml` | Notificaciones locales | No |
| `firebase_messaging` | `pubspec.yaml` | Push notifications | No |
| `signature` | `pubspec.yaml` | Firma digital | No |
| `pdf` | `pubspec.yaml` | Generación PDF | No |
| `printing` | `pubspec.yaml` | Impresión | No |
| `workmanager` | `pubspec.yaml` | Tareas en segundo plano | No |
| `flutter_secure_storage` | `pubspec.yaml` | Almacenamiento seguro | No |
| `photo_view` | `pubspec.yaml` | Visor de imágenes | No |
| `flutter_riverpod` (en UI) | `pubspec.yaml` | Estado | No (solo `ProviderScope` en `main`) |
| `riverpod_annotation` | `pubspec.yaml` | Anotaciones Riverpod | No |
| `go_router` | `pubspec.yaml` | Navegación | No |

---

## Riesgos técnicos encontrados

1. **Sintaxis `?clienteId`** en `solicitud_repository.dart:47` y `buro_repository.dart:42` — null-aware spread en contexto de mapa que podría no compilar correctamente.
2. **Riverpod + go_router** declarados pero no utilizados en UI de negocio — añaden dependencias innecesarias y complejidad al build.
3. **fl_chart** declarado pero reportes usan solo indicadores numéricos sin gráficos.
4. **Ficha cliente** solo responde para IDs `cli-001` a `cli-005`; clientes de mora (`cli-006` a `cli-010`) no tienen datos mock.
5. **Sin persistencia entre sesiones** — al reiniciar la app se pierden todos los datos.
6. **Supabase URL y anon key** hardcodeadas en `supabase_config.dart` — riesgo de seguridad en producción.
7. **Validación de fecha de nacimiento** no implementada en wizard de solicitud.
8. **Campos obligatorios** sin marcador visual de error en wizard de solicitud.

---

## Recomendaciones para Fase 2

1. **Migrar a Supabase Auth real** con tabla `oficiales` y roles.
2. **Conectar repositorios a Supabase** para cartera, fichas, solicitudes y cobranza.
3. **Implementar SQLite offline** con cola de sincronización.
4. **Integrar geolocalización real** en ruta de visitas y cobranza.
5. **Implementar cámara real** para captura de documentos.
6. **Agregar Google Maps** en ruta de visitas.
7. **Generación de PDF** para reportes y fichas.
8. **Migrar a go_router** si el equipo crece.
9. **Agregar tests** widget e integración para flujos críticos.
10. **Configurar CI** con `flutter analyze` y build APK.
