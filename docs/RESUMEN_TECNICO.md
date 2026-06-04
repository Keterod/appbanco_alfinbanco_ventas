# Resumen técnico — App Fuerza de Ventas Alfin Banco

## Estructura de carpetas

```
lib/
├── main.dart
├── app/
│   └── navigation/
│       └── app_navigation.dart
├── core/
│   ├── constants/          app_colors, app_theme, app_routes
│   ├── network/            network_monitor (Riverpod, no usado en demo UI)
│   ├── storage/            local_db.dart (esquema SQLite, no usado en flujo)
│   └── supabase/           supabase_client.dart (init en main, no usado en flujo)
├── features/
│   ├── auth/
│   ├── home/
│   ├── cartera/
│   ├── ruta/
│   ├── ficha_cliente/
│   ├── buro/
│   ├── solicitud/
│   ├── documentos/
│   ├── transmision/
│   ├── estado_solicitudes/
│   └── cobranza/
└── shared/                 reservado (widgets/utils)
```

Cada feature suele tener:

- `domain/` — modelos y enums  
- `data/` — repositorio local (opcional)  
- `presentation/` — `*_screen.dart`, `*_viewmodel.dart`  

## Módulos implementados

| Módulo | Pantallas | ViewModel(s) |
|--------|-----------|--------------|
| Auth | LoginOficialScreen | AuthOficialViewModel |
| Home | HomeOficialScreen | HomeOficialViewModel |
| Cartera | CarteraDiariaScreen | CarteraViewModel |
| Ruta | RutaScreen | RutaViewModel |
| Ficha cliente | FichaClienteScreen | FichaClienteViewModel |
| Buró | BuroScreen | BuroViewModel |
| Solicitud | SolicitudCreditoScreen | SolicitudCreditoViewModel |
| Documentos | DocumentosScreen | DocumentosViewModel |
| Transmisión | TransmisionScreen | TransmisionViewModel |
| Estado solicitudes | EstadoSolicitudesScreen, EstadoSolicitudDetalleScreen | EstadoSolicitudesViewModel, EstadoSolicitudDetalleViewModel |
| Cobranza | CobranzaScreen, CobranzaAccionScreen | CobranzaViewModel, CobranzaAccionViewModel |

## Patrón MVVM

```
┌─────────────┐     notifyListeners()     ┌──────────────┐
│   Screen    │ ◄──────────────────────── │  ViewModel   │
│  (View)     │ ── eventos / callbacks ─► │ ChangeNotifier│
└─────────────┘                           └──────┬───────┘
                                                 │
                                                 ▼
                                          ┌──────────────┐
                                          │ Model / Repo │
                                          │   (mock)     │
                                          └──────────────┘
```

- La **View** no contiene reglas de negocio ni fórmulas crediticias.  
- **Validaciones** y ordenamiento (ruta, buró, solicitud) viven en ViewModel.  
- **Repositorio en memoria** (`CobranzaLocalRepository`) preparado para sustituir por API/DB.

## Modelos principales

| Modelo | Ubicación |
|--------|-----------|
| ClientPortfolioModel | cartera/domain |
| ClientDetailModel, CreditHistoryItem | ficha_cliente/domain |
| BuroResultModel | buro/domain |
| CreditRequestModel | solicitud/domain |
| DocumentModel | documentos/domain |
| TransmissionModel, TransmissionStepModel | transmision/domain |
| RequestStatusModel, RequestTimelineItem | estado_solicitudes/domain |
| RouteVisitModel | ruta/domain |
| OverdueClientModel, CollectionActionModel | cobranza/domain |

## Rutas principales

| Ruta | Constante | Argumentos |
|------|-----------|------------|
| `/` | login | — |
| `/home-oficial` | homeOficial | — |
| `/cartera` | cartera | — |
| `/ficha-cliente` | fichaCliente | `clientId` (String) |
| `/buro` | buro | `clientId` opcional |
| `/solicitud-credito` | solicitudCredito | `clientId` opcional |
| `/documentos` | documentos | `solicitudId` opcional |
| `/transmision` | transmision | `solicitudId` opcional |
| `/estado-solicitudes` | estadoSolicitudes | highlight opcional |
| `/estado-solicitud-detalle` | estadoSolicitudDetalle | id o expediente |
| `/ruta` | ruta | — |
| `/cobranza` | cobranza | — |
| `/cobranza-accion` | cobranzaAccion | `overdueClientId` |

## Decisiones técnicas

1. **MaterialApp + rutas nombradas** — Simplicidad y alineación con entregables por sprint; GoRouter reservado para fase de refactor.  
2. **ChangeNotifier** — MVVM sin curva de Riverpod en cada pantalla; `ProviderScope` en `main` para infra futura.  
3. **Datos mock por feature** — Seeds en ViewModels o archivos `*_mock_data.dart` / repositorios singleton.  
4. **CobranzaLocalRepository** — Patrón explícito para persistencia futura y pruebas de listado/acción.  
5. **Branding centralizado** — `AppColors` + `AppTheme` en `core/constants`.  
6. **main.dart** inicializa Supabase y SQLite — Demuestra preparación técnica sin bloquear demo offline.

## Limitaciones actuales

- Sin autenticación ni autorización real.  
- Sin sincronización offline/online de solicitudes.  
- Sin cámara, GPS, mapas ni notificaciones reales.  
- Sin generación PDF ni integración buró real.  
- Estado entre sesiones no se conserva (reinicio app = datos seed).  
- Algunos `clientId` de mora no tienen ficha mock (solo `cli-001` a `cli-005` en ficha).  
- Riverpod declarado pero no adoptado en pantallas de negocio.

## Próximos pasos recomendados

1. **Supabase Auth** + tabla `oficiales` / roles.  
2. **API o Supabase** para cartera diaria y estado de solicitudes (Realtime opcional).  
3. **SQLite + cola de sync** para visitas, documentos y borradores.  
4. **Storage** + compresión de imágenes para documentos.  
5. **Google Maps + geolocator** en ruta y cobranza.  
6. **Migración gradual a go_router** y/o Riverpod si el equipo crece.  
7. **Tests** widget e integración en flujos críticos (login → solicitud → transmisión).  
8. **CI** con `flutter analyze` y build APK en pipeline.

## Comandos de verificación

```bash
flutter pub get
flutter analyze
flutter build apk --debug
```
