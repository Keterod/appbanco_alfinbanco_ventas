# Pendientes técnicos — App Fuerza de Ventas

> Este documento registra los pendientes técnicos identificados durante la Fase 1.
> Se actualizará en fases posteriores.

---

## 🔴 Críticos para integración final

| # | Pendiente | Archivo(s) | Impacto |
|---|-----------|------------|---------|
| 1 | **Supabase Auth real** — Reemplazar el login demo por autenticación contra `supabase_flutter` con tabla `oficiales` y roles. El código ya tiene la estructura lista. | `auth_oficial_repository.dart`, `auth_oficial_viewmodel.dart` | Sin esto no hay seguridad real |
| 2 | **Conectar repositorios a Supabase** — `CarteraRepository`, `FichaClienteRepository`, `BuroRepository`, `SolicitudRepository`, `CobranzaRepository` ya tienen la estructura para consultas Supabase pero no se usan en flujo demo (los ViewModels cargan datos mock directamente). | `cartera_repository.dart`, `ficha_cliente_repository.dart`, `buro_repository.dart`, `solicitud_repository.dart`, `cobranza_repository.dart` | Sin conexión real no hay datos de producción |
| 3 | **Configurar almacenamiento seguro de claves** — `supabase_config.dart` contiene URL y anon key hardcodeadas. Mover a variables de entorno o `flutter_secure_storage`. | `lib/core/supabase/supabase_config.dart` | Riesgo de seguridad |
| 4 | **Validar sintaxis `?clienteId`** — Revisar si `?clienteId` es sintaxis válida en Dart para null-aware spread en contextos de mapa. | `solicitud_repository.dart:47`, `buro_repository.dart:42` | Posible error de compilación |
| 5 | **Resolver IDs mock → UUID real** — `SupabaseLookup` ya implementa 8 estrategias de búsqueda; validar que funcionen correctamente con datos reales. | `supabase_lookup.dart` | Integridad de referencias |

---

## 🟡 Importantes para App Fuerza de Ventas

| # | Pendiente | Archivo(s) | Impacto |
|---|-----------|------------|---------|
| 6 | **Implementar SQLite offline** — Las tablas ya existen en `LocalDb` (`visitas_pendientes`, `solicitudes_borrador`, `cartera_cache`, `cartera_orden_local`). Falta conectar los repositorios y crear cola de sincronización. | `local_db.dart`, repositorios | Sin offline no hay trabajo en campo |
| 7 | **Persistencia entre sesiones** — Al reiniciar la app se pierden todos los datos mock. Implementar SharedPreferences o SQLite para mantener estado. | Todos los ViewModels | Experiencia de usuario |
| 8 | **Generación de expediente real** — `_generateExpediente()` en `solicitud_repository.dart` genera `EXP-ALF-2026-{timestamp}`. Debe integrarse con secuencia de Supabase. | `solicitud_repository.dart` | Trazabilidad de solicitudes |
| 9 | **Validación de fecha de nacimiento** — No hay validación de formato `dd/mm/aaaa` en el wizard de solicitud. | `solicitud_credito_viewmodel.dart` | Calidad de datos |
| 10 | **Marcador visual de campos obligatorios** — Los labels tienen "*" pero no hay validación visual de error en campos vacíos. | `solicitud_credito_screen.dart` | UX |
| 11 | **Datos mock para IDs de mora** — `cli-006` a `cli-010` existen en cobranza pero no tienen datos en `FichaClienteViewModel`. | `ficha_cliente_viewmodel.dart` | Navegación incompleta |
| 12 | **Simular carga real en repositorios** — Los ViewModels cargan datos mock directamente. Los repositorios Supabase deberían ser la fuente única. | Todos los ViewModels | Arquitectura |
| 13 | **Unificar nombre del proyecto en archivos de documentación existentes** — `README.md`, `docs/CHECKLIST_EVALUACION.md`, `docs/RESUMEN_TECNICO.md`, `docs/EVIDENCIAS_DEMO.md` aún usan "Alfin Banco" en lugar de "Banco Alfin". | `README.md`, `docs/*.md` | Consistencia de marca |

---

## 🟢 Opcionales o mejoras

| # | Pendiente | Archivo(s) | Beneficio |
|---|-----------|------------|-----------|
| 14 | **Migrar a go_router** — Actualmente se usa `MaterialApp` con `routes: {}`. `go_router` ya está declarado en `pubspec.yaml`. Migrar cuando el equipo crezca. | `app_navigation.dart` | Navegación declarativa, deep linking |
| 15 | **Adoptar Riverpod en UI** — `ProviderScope` ya existe en `main.dart`. Migrar pantallas de `ChangeNotifier` a `Riverpod` gradualmente. | Todos los screens | Mejor testabilidad, menos boilerplate |
| 16 | **Agregar fl_chart para gráficos** — Dependencia ya declarada. Reportes usan solo números; se podrían agregar gráficos de barras. | `reportes_screen.dart` | Visualización de datos |
| 17 | **Eliminar dependencias no usadas** — Limpiar `pubspec.yaml` eliminando dependencias que no se usan (ver lista en FASE1_BASE_PROYECTO.md). | `pubspec.yaml` | Build más rápido, menos vulnerabilidades |
| 18 | **Agregar tests unitarios** — Especialmente para ViewModels con lógica de negocio (simulador de cuota, validación de buró, optimización de ruta). | — | Calidad y regresión |
| 19 | **Agregar tests de widgets** — Para flujos críticos (login → solicitud → transmisión). | — | Calidad y regresión |
| 20 | **Internacionalización (i18n)** — Preparar para soporte multilingüe usando `intl` (ya declarado). | — | Escalabilidad |
| 21 | **Modo oscuro** — El tema Material 3 está preparado; solo falta definir paleta oscura en `AppTheme`. | `app_theme.dart` | Experiencia de usuario |
| 22 | **Documentar API de los ViewModels** — Agregar doc comments a métodos públicos. | ViewModels | Mantenibilidad |

---

## ⏸️ Funcionalidades para después (Fase 3+)

| Funcionalidad | Dependencia declarada | Notas |
|---------------|-----------------------|-------|
| **Cámara real para documentos** | `camera`, `image_picker`, `image` | Reemplazar `_simulateCapture()` en `documentos_viewmodel.dart` |
| **Firma digital real** | `signature` | Reemplazar `registrarFirmaSimulada()` con widget de firma |
| **PDF real** | `pdf`, `printing` | Implementar exportación en estado solicitudes y reportes |
| **Notificaciones push** | `firebase_messaging`, `flutter_local_notifications` | Implementar Firebase Cloud Messaging |
| **Mapa avanzado (Google Maps)** | `google_maps_flutter` | Reemplazar mapa simulado en `ruta_screen.dart` |
| **Tareas en segundo plano** | `workmanager` | Sincronización offline programada |
| **Almacenamiento seguro** | `flutter_secure_storage` | Para tokens y claves de sesión |
| **Visor de imágenes** | `photo_view` | Para vista previa de documentos capturados |
| **Navegación externa (Waze/Maps)** | — | Abrir app externa con coordenadas desde ruta |

---

## Resumen de Fase 1 — Cambios realizados

| Categoría | Detalle |
|-----------|---------|
| **Branding** | Nombre del banco unificado a "Banco Alfin" en todas las pantallas. App bars, drawer, login, consentimiento de buró. |
| **Constantes centralizadas** | Creado `lib/core/constants/app_strings.dart` con todos los textos visibles del sistema. |
| **Android label** | Cambiado de `"ventas"` a `"App Fuerza de Ventas"` en `AndroidManifest.xml`. |
| **iOS labels** | `CFBundleDisplayName` y `CFBundleName` actualizados a `"App Fuerza de Ventas"` en `Info.plist`. |
| **Análisis estático** | `flutter analyze` sin issues (0 errores, 0 warnings). |
| **Documentación** | Creados `docs/FASE1_BASE_PROYECTO.md` y `docs/PENDIENTES_TECNICOS.md`. |
| **Archivos modificados** | `app_navigation.dart`, `login_oficial_screen.dart`, `home_oficial_screen.dart`, `cartera_diaria_screen.dart`, `oficial_drawer.dart`, `buro_screen.dart`, `transmision_screen.dart`, `ruta_screen.dart`, `documentos_screen.dart`, `estado_solicitudes_screen.dart`, `cobranza_screen.dart`, `cobranza_accion_screen.dart`, `reportes_screen.dart`, `AndroidManifest.xml`, `Info.plist`. |
| **Archivos creados** | `app_strings.dart`, `docs/FASE1_BASE_PROYECTO.md`, `docs/PENDIENTES_TECNICOS.md`. |

### Recomendación concreta para iniciar Fase 2

**Prioridad máxima:** Conectar Supabase Auth real y reemplazar el login demo. Esto habilita sesiones reales y permite probar el flujo completo con datos del backend. Paralelamente, implementar SQLite offline con cola de sincronización para garantizar operatividad en campo sin conectividad.
