# Pendientes técnicos — App Fuerza de Ventas

> Actualizado durante Fase 2 — Auditoría Diferencial.
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
| 14 | SQLite esquema (4 tablas) | `local_db.dart` | Tablas creadas, pendiente conectar |
| 15 | Repositorios Supabase (cartera, ficha, buró, solicitud, cobranza) | `*_repository.dart` | Estructura lista para datos reales |
| 16 | Branding unificado | `app_strings.dart`, `app_colors.dart` | "Banco Alfin · App Fuerza de Ventas" |

---

## 🔴 Pendiente crítico para integración final

| # | Pendiente | Archivos | Impacto |
|---|-----------|----------|---------|
| C1 | **Configuración segura de Supabase** — URL y anon key hardcodeadas en texto plano | `supabase_config.dart:2-5` | Riesgo de seguridad en producción |
| C2 | **Sin sesión persistente** — No se configura `persistSession` en inicialización | `main.dart:13-23` | Usuario debe loguearse cada vez que abre la app |
| C3 | **Dashboard sin datos reales** — Métricas hardcodeadas, no consulta Supabase | `home_oficial_viewmodel.dart:43-86` | Sin valor real para el oficial |
| C4 | **Estado solicitudes desde mock** — No consulta `solicitudes_credito` en Supabase | `estado_solicitudes_viewmodel.dart`, `request_status_mock_data.dart` | El oficial no puede ver estado real de sus solicitudes |
| C5 | **Reportes desde mock** — Indicadores no reflejan datos reales | `reportes_viewmodel.dart:81-137` | Reportes no útiles para gestión |

---

## 🟡 Pendiente importante para App Fuerza de Ventas

| # | Pendiente | Archivos | Impacto |
|---|-----------|----------|---------|
| I1 | **GPS real** — Coordenadas fijas en cobranza, solicitud y ruta. No se usa `geolocator` | `cobranza_accion_viewmodel.dart:20`, `ruta_viewmodel.dart`, `solicitud_repository.dart:23-24` | Sin ubicación real no hay trazabilidad de campo |
| I2 | **SQLite offline** — 4 tablas creadas pero nunca escritas ni leídas | `local_db.dart`, todos los ViewModels | Sin offline no hay operatividad sin internet |
| I3 | **Cola de sincronización** — No existe `sync_outbox`/`sync_log` | — | Sin cola no se puede sincronizar offline→online |
| I4 | **Ficha cliente sin datos para IDs de mora** — `cli-006` a `cli-010` sin mock | `ficha_cliente_viewmodel.dart` | Navegación incompleta desde cobranza |
| I5 | **Roles** — No existe campo `rol` en `AsesorModel`. Sin control de acceso | `asesor_model.dart` | Todos los usuarios ven lo mismo |

---

## ⏸️ Pendiente para después (Fase 3+)

| # | Pendiente | Dependencias |
|---|-----------|-------------|
| D1 | **Cámara real** — Reemplazar captura simulada en documentos | `camera`, `image_picker` |
| D2 | **Firma digital real** — Reemplazar `registrarFirmaSimulada()` | `signature` |
| D3 | **PDF real** — Exportación de reportes y fichas | `pdf`, `printing` |
| D4 | **Notificaciones push** — Cambio de estado de solicitud | `firebase_messaging`, `flutter_local_notifications` |
| D5 | **Cronograma de cuotas** — Desglose mes a mes en simulación | — |
| D6 | **Pre-evaluación de cliente** — Puntuación y reglas de negocio | — |
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
