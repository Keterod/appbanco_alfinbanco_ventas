# Fase 2B.1 — Mejora de Ruta sin Google Maps Embebido

## Objetivo
Transformar la pantalla Ruta de "mapa simulado" a una vista operativa profesional usando la ubicación real del oficial, coordenadas de clientes, direcciones y navegación externa (Google Maps app), sin API Key de Google Maps.

## ¿Por qué no se implementó Google Maps embebido?
- No hay API Key de Google Maps configurada en el proyecto
- `google_maps_flutter` requiere una API Key válida para renderizar el mapa embebido
- La API Key no debe ser falsa, placeholder ni hardcodeada
- Se usará en una fase posterior cuando se obtenga la Key

## Qué se dejó en su lugar
- `_RutaOrdenadaView`: vista tipo timeline vertical con paradas numeradas, conectores visuales entre paradas, coordenadas del oficial y del cliente, prioridad, distancia, tiempo estimado, botón "Navegar" por parada
- `_ParadaTimeline`: widget individual de parada dentro del timeline con círculo numerado, línea conectora, tarjeta informativa
- `_VisitCard`: tarjeta detallada por visita (se mantiene como lista expandida debajo del timeline)
- Botón "Navegar" reutiliza `url_launcher` + `launchUrl(externalApplication)` para abrir Google Maps externo

## Origen actual de datos de Ruta

### ¿Seed/mock o Supabase?

| Campo | Origen Actual | Destino Futuro |
|-------|--------------|----------------|
| `id` | Seed en `_buildInitialVisits()` | `cartera_diaria.id` |
| `clientId` | Seed (`cli-001` a `cli-005`) | `cartera_diaria.cliente_id` |
| `clienteNombre` | Seed | `clientes.nombres` + `clientes.apellidos` |
| `direccion` | Seed (hardcodeada) | `clientes.direccion` |
| `lat` / `lng` | Seed (coordenadas fijas) | `clientes.lat` / `clientes.lng` |
| `tipoGestion` | Seed | `cartera_diaria.tipo_gestion` |
| `prioridad` | Seed | Regla de negocio o `cartera_diaria.prioridad` |
| `distanciaKm` | Seed (estimación fija) | Calcular con Haversine o Google Distance Matrix |
| `tiempoEstimadoMin` | Seed (estimación fija) | Derivado de distancia + velocidad promedio |
| `ordenSugerido` | Seed | `cartera_diaria.orden_manual` o algoritmo |

**Conclusión:** 100% seed/mock. No hay conexión actual entre Ruta y cartera_diaria/clientes de Supabase.

### CarteraRepository (no usado por Ruta)
El repositorio `CarteraRepository.loadCarteraDiaria()` ya consulta Supabase (`cartera_diaria` + `clientes`) y retorna `ClientPortfolioModel`. Pero:
- `ClientPortfolioModel` **no tiene** `lat`, `lng`, `distanciaKm`, `tiempoEstimadoMin`
- Ruta no llama a `CarteraRepository` en absoluto

### RouteVisitModel
El modelo `RouteVisitModel` ya tiene todos los campos necesarios:
- `direccion` (String) ✅
- `lat` / `lng` (double) ✅
- `distanciaKm` / `tiempoEstimadoMin` ✅
- `prioridad` / `tipoGestion` / `estadoVisita` ✅

### Flujo de carga actual
```
RutaViewModel.loadTodayRoute()
  └─ captureOficialLocation()       ← GPS real del oficial
  └─ _buildInitialVisits()          ← 5 visits seed (clientes demo)
  └─ notifyListeners()
```

### Flujo deseado (Fase 2C/2D)
```
RutaViewModel.loadTodayRoute()
  └─ captureOficialLocation()       ← GPS real del oficial
  └─ CarteraRepository.loadCarteraDiaria()  ← cartera_diaria + clientes (Supabase)
  └─ mapear a List<RouteVisitModel> con direccion/lat/lng reales
  └─ calcular distancias con Haversine
  └─ notifyListeners()
```

## Cambios realizados en Fase 2B.1

### Archivos modificados

| Archivo | Cambio |
|---------|--------|
| `lib/features/ruta/presentation/ruta_screen.dart` | Reemplazo completo: eliminado `_SimulatedMapSection`, eliminado `_LegendDot`, eliminados textos "Mapa simulado" / "integración de mapas en siguiente fase". Nueva vista `_RutaOrdenadaView` con timeline vertical profesional. Integrado indicador de ubicación en `_SummaryCard`. Agregadas coordenadas en tarjetas de visita. Mejorado manejo de error de navegación. |
| `lib/features/ruta/presentation/ruta_viewmodel.dart` | `openNavigation()` mejorado: usa origen real del oficial si disponible, o solo destino si no hay ubicación real. Agregada documentación técnica sobre migración futura a Supabase. |

### Archivos creados
| Archivo | Propósito |
|---------|-----------|
| `docs/FASE2B1_RUTA_SIN_MAPS_KEY.md` | Esta documentación |

## Cómo probar en celular

### Prerrequisitos
- App instalada vía `flutter build apk --debug` e instalada en celular físico
- GPS activado y permisos de ubicación concedidos
- Google Maps app instalada en el dispositivo

### Pasos
1. Abrir la app e iniciar sesión
2. Navegar a "Ruta del día" desde el menú lateral
3. Verificar:
   - **Resumen del día**: muestra total/pendientes/visitadas/distancia/tiempo
   - **Ubicación del oficial**: indicador GPS (icono verde si real)
   - **Vista de ruta del día**: timeline vertical con paradas numeradas
   - **Cada parada**: nombre, dirección, coordenadas, tipo de gestión, prioridad, distancia, tiempo
   - **Coordendas**: lat/lng visibles en cada tarjeta (formato `-12.04637, -77.04280`)
4. Tocar "Navegar" en cualquier parada:
   - Si hay ubicación real → Google Maps abre ruta desde mi ubicación hasta el cliente
   - Si no hay ubicación real → Google Maps abre solo el destino del cliente
   - Si Google Maps no está instalado → SnackBar de error informativo
5. Tocar "Marcar visitado" → estado cambia, línea de tachado aparece, chip "Visitado"
6. Tocar "Optimizar ruta" → orden se reordena por prioridad + distancia
7. Tocar "Restablecer" → vuelve al orden inicial

### Cómo probar fallback
- Denegar permiso de ubicación
- Verificar que aparece "Usando coordenadas de referencia"
- Botón Navegar abre Google Maps solo con destino

## Qué quedó pendiente para Supabase (Fase 2C/2D)

1. **Agregar `lat`/`lng`/`direccion` a `ClientPortfolioModel`** para que `CarteraRepository` los devuelva
2. **Crear `RutaRepository`** que consulte `cartera_diaria` + `clientes` y mapee a `List<RouteVisitModel>`
3. **Calcular distancia real** con fórmula Haversine entre oficial y cada cliente
4. **Poblar `tipo_gestion` y `prioridad`** en `cartera_diaria` de Supabase
5. **Conectar `RutaViewModel.loadTodayRoute()`** al repositorio real con fallback a seed si no hay datos
6. **Google Maps embebido** cuando se tenga API Key

## Dependencias
- `url_launcher: ^6.3.0` — navegación externa a Google Maps
- `geolocator: ^12.0.0` — GPS real del oficial
- `google_maps_flutter: ^2.9.0` — declarado en pubspec pero **no implementado** (requiere API Key)

## Resultado esperado post-implementación
- ✅ No aparece "mapa simulado" en ningún lado
- ✅ La pantalla Ruta se ve profesional: timeline, coordenadas, direcciones, prioridades
- ✅ No se usa API Key de Google Maps
- ✅ El botón "Navegar" abre Google Maps externo correctamente
- ✅ Documentado origen seed vs Supabase de direcciones/coordenadas
- ✅ `flutter analyze`: 0 issues
- ✅ `flutter build apk --debug`: éxito
