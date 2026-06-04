# Checklist de evaluación — App Fuerza de Ventas Alfin Banco

**Versión:** mock/local demostrativa  
**Fecha de referencia:** junio 2026  

| Requisito | Estado | Evidencia / pantalla | Observación |
|-----------|--------|----------------------|-------------|
| Login del oficial | Cumple | `LoginOficialScreen` — `/` | Modo demo: cualquier credencial con campos completos. Referencia `OFI001` / `alfin123`. |
| Dashboard / Home del oficial | Cumple | `HomeOficialScreen` — `/home-oficial` | Resumen, accesos rápidos, actividad reciente, cerrar sesión. |
| Cartera diaria | Cumple | `CarteraDiariaScreen` — `/cartera` | 5 clientes, chips gestión/estado, navegación a ficha. |
| Ruta de visitas | Cumple | `RutaScreen` — `/ruta` | Optimizar ruta, mapa simulado, marcar visitado, ver ficha. |
| Ficha del cliente | Cumple | `FichaClienteScreen` — `/ficha-cliente` | Semáforo SBS, posición, historial, oferta, acciones. |
| Consulta de buró y listas | Cumple | `BuroScreen` — `/buro` | Consentimiento, firma simulada, resultados por DNI mock. |
| Solicitud de crédito en 4 pasos | Cumple | `SolicitudCreditoScreen` — `/solicitud-credito` | Solicitante, negocio, crédito (simulador), confirmación. |
| Captura de documentos | Cumple | `DocumentosScreen` — `/documentos` | 4 obligatorios + opcionales, vista previa simulada. |
| Transmisión electrónica | Cumple | `TransmisionScreen` — `/transmision` | 6 pasos con progreso, expediente oficial mock. |
| Estado de solicitudes | Cumple | `EstadoSolicitudesScreen` — `/estado-solicitudes` | Filtros por estado, resumen, tarjetas. |
| Detalle con línea de tiempo | Cumple | `EstadoSolicitudDetalleScreen` — `/estado-solicitud-detalle` | Timeline vertical, motivo/condición según caso. |
| Cartera vencida | Cumple | `CobranzaScreen` — `/cobranza` | Prioridad preventiva/prioritaria/urgente, filtros. |
| Registro de acción de cobranza | Cumple | `CobranzaAccionScreen` — `/cobranza-accion` | Formulario con validaciones, actualiza listado. |
| Branding Alfin Banco | Cumple | Login, Home, AppBars, `AppColors` | Logo, morado/naranja institucional. |
| Arquitectura MVVM | Cumple | `features/*/presentation/*_viewmodel.dart` | Screens + ChangeNotifier + modelos domain. |
| Navegación funcional | Cumple | `app_routes.dart`, flujo end-to-end | MaterialApp rutas nombradas, sin rutas huérfanas críticas. |
| Datos hardcodeados / mock | Cumple | ViewModels y `*_mock_data.dart` / repositorios locales | Sin backend en flujo evaluable. |
| Build APK debug OK | Cumple | `flutter build apk --debug` | Ver README — ruta del APK. |
| Analyze sin issues | Cumple | `flutter analyze` | Sin warnings/errors al entregar. |

## Resumen

| Métrica | Valor |
|---------|-------|
| Requisitos evaluados | 19 |
| Cumplidos | 19 |
| Pendientes funcionales | 0 (alcance demo) |
| Integraciones backend | Fase siguiente |

## Observaciones generales

- No se evalúa conectividad real ni seguridad de producción.  
- Algunas capacidades muestran mensaje **“función en siguiente fase”** (PDF, mapas, navegación externa).  
- `ProviderScope` en `main.dart` existe por dependencias futuras; los flujos demo usan `ChangeNotifier` directo.
