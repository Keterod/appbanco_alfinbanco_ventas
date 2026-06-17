# Fase 2B: GPS Real

## Objetivo
Reemplazar coordenadas simuladas/fijas por ubicación GPS real del oficial de crédito en los módulos de cobranza, solicitud y ruta. Mantener flujo demo funcional con fallback controlado.

## Cambios Realizados

### 1. Servicio Centralizado de Geolocalización
- **Archivo:** `lib/core/location/location_service.dart`
- `getCurrentPosition()` — obtiene ubicación real vía `Geolocator.getCurrentPosition` con alta precisión y timeout de 15s
- `ensureLocationPermission()` — solicita permiso de ubicación (`whenInUse`), retorna si fue concedido, denegado, o denegado permanentemente
- `getCurrentPositionWithFallback()` — wrapper que maneja permisos, GPS apagado, timeout, y retorna `LocationResult` con fallbook seguro `(-12.0464, -77.0428)` más indicador `fromFallback`

### 2. Permisos de Plataforma
- **Android** (`android/app/src/main/AndroidManifest.xml`): agregados `ACCESS_FINE_LOCATION` y `ACCESS_COARSE_LOCATION`
- **iOS** (`ios/Runner/Info.plist`): agregado `NSLocationWhenInUseUsageDescription` con descripción en español

### 3. Módulo Cobranza (HU-V10)
- `cobranza_accion_viewmodel.dart`:
  - Reemplazadas `simulatedLat/simulatedLng` por campos `_lat/_lng` obtenidos desde `LocationService`
  - Nuevo método `captureLocation()` — captura ubicación al inicializar pantalla
  - `guardarGestion()` usa `_lat/_lng` si están disponibles, caso contrario fallback
  - Indicadores visuales: `_isLocating`, `_locationStatus`, `locationIsReal`
- `cobranza_accion_screen.dart`:
  - Llama `_vm.captureLocation()` en `initState`
  - Muestra spinner "Obteniendo ubicación…" mientras captura
  - Muestra icono GPS (verde si real, naranja si fallback) + coordenadas

### 4. Módulo Solicitud de Crédito (HU-V04)
- `solicitud_credito_viewmodel.dart`:
  - Nuevo método `captureLocation()` — captura ubicación antes del envío
  - `submitRequest()` llama `captureLocation()` antes de `buildModel()`
  - Pasa `latCaptura/lngCaptura` a `SolicitudRepository.insertSolicitud()`
- `solicitud_repository.dart`:
  - `insertSolicitud()` acepta parámetros opcionales `latCaptura/lngCaptura`
  - Reemplazados `_simulatedLat/_simulatedLng` por los valores capturados con fallback
- `solicitud_credito_screen.dart`:
  - Llama `_vm.captureLocation()` en `initState`
  - Muestra indicador GPS en paso de confirmación (icono y texto)

### 5. Módulo Ruta (HU-V09)
- `ruta_viewmodel.dart`:
  - Nuevos campos: `_oficialLat/_oficialLng`, `_isLocating`, `_locationStatus`
  - Nuevo método `captureOficialLocation()` — captura ubicación del oficial
  - `loadTodayRoute()` llama `captureOficialLocation()` antes de cargar visitas
  - `openNavigation()` retorna URI de Google Maps con origen real y destino del cliente
- `ruta_screen.dart`:
  - Muestra tarjeta con estado de ubicación del oficial
  - Botón "Navegar" ahora abre Google Maps con `url_launcher` y `launchUrl(externalApplication)`
- `pubspec.yaml`: agregado `url_launcher: ^6.3.0`

## Flujo de Fallback
1. Si permiso denegado → `LocationResult(errorMessage, permissionDenied: true, fromFallback: true)` con coordenadas `(-12.0464, -77.0428)`
2. Si GPS apagado → `LocationResult(errorMessage, gpsDisabled: true, fromFallback: true)` con coordenadas `(-12.0464, -77.0428)`
3. Si timeout (15s) → `LocationResult(errorMessage, fromFallback: true)` con coordenadas `(-12.0464, -77.0428)`
4. En UI: icono GPS de color naranja y texto "usando coordenadas de referencia"

## Fase 2B.1 — Mejora de Ruta sin Google Maps Embebido (completada)
Ver `FASE2B1_RUTA_SIN_MAPS_KEY.md` para detalles completos.
- Reemplazado "mapa simulado" por vista timeline operativa profesional
- Cada parada muestra: nombre, dirección, coordenadas, prioridad, distancia, tiempo
- Navegación externa mejorada: origen real → ruta completa, sin origen → solo destino
- Ubicación del oficial integrada en tarjeta de resumen
- Coordenadas visibles en cada tarjeta de visita
- `flutter analyze`: 0 issues

## Pendiente
- Google Maps embebido `(google_maps_flutter)` — requiere API Key
- Cálculo real de distancias (Haversine o Distance Matrix)
- Conexión de Ruta a cartera_diaria + clientes desde Supabase (Fase 2C/2D)

## Próximos Pasos (Fase 2C)
- Conexión real a Supabase en lugar de mock
- Dashboard, estado solicitudes y reportes desde datos reales
- Almacenar ubicación en DB local para tracking offline
- Validar coordenadas en backend y dashboard

## Archivos Modificados
| Archivo | Cambio |
|---------|--------|
| `lib/core/location/location_service.dart` | Nuevo servicio centralizado de geolocalización |
| `lib/features/cobranza/presentation/cobranza_accion_viewmodel.dart` | GPS real + fallback |
| `lib/features/cobranza/presentation/cobranza_accion_screen.dart` | UI GPS indicator |
| `lib/features/solicitud/presentation/solicitud_credito_viewmodel.dart` | GPS real + fallback |
| `lib/features/solicitud/data/solicitud_repository.dart` | Parámetros latCaptura/lngCaptura |
| `lib/features/solicitud/presentation/solicitud_credito_screen.dart` | UI GPS indicator |
| `lib/features/ruta/presentation/ruta_viewmodel.dart` | GPS oficial + navegación |
| `lib/features/ruta/presentation/ruta_screen.dart` | UI GPS + launchUrl |
| `android/app/src/main/AndroidManifest.xml` | Permisos ubicación |
| `ios/Runner/Info.plist` | Descripción ubicación |
| `pubspec.yaml` | url_launcher dependency |
