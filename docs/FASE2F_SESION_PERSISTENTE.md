# Fase 2F — Sesión persistente

## Objetivo

Que el oficial no tenga que iniciar sesión cada vez que abre la app, y que pueda acceder a módulos offline si ya tenía una sesión válida previa.

## Problema que resuelve

- Cada vez que la app se abría, mostraba la pantalla de login sin importar si el usuario ya había iniciado sesión antes.
- Si no había internet, la app no permitía entrar aunque el asesor ya estuviera autenticado y hubiera datos en caché.
- No existía un cache local del perfil del asesor; toda la app dependía de la respuesta de Supabase.

## Archivos creados

| Archivo | Propósito |
|---|---|
| `lib/core/storage/session_local_datasource.dart` | Cache local del perfil del asesor en SQLite (tabla `asesor_cache`, clave/valor) |
| `lib/features/auth/presentation/splash_screen.dart` | Pantalla de carga inicial que verifica sesión y restaura asesor |

## Archivos modificados

| Archivo | Cambio |
|---|---|
| `lib/core/storage/local_db.dart` | Agregada tabla `asesor_cache` en DB v3 (onCreate + onUpgrade) |
| `lib/core/constants/app_routes.dart` | Agregada ruta `splash` |
| `lib/core/constants/app_strings.dart` | Agregados `splashChecking`, `splashLoading` |
| `lib/app/navigation/app_navigation.dart` | `initialRoute` cambiada a `AppRoutes.splash`; agregada ruta `SplashScreen` |
| `lib/features/auth/data/asesor_repository.dart` | `loadCurrentAsesor()` guarda en cache tras éxito; fallback a cache local si Supabase falla; nuevo método `clearCache()` |
| `lib/features/auth/data/auth_oficial_repository.dart` | `signOut()` ahora también limpia cache del asesor (`clearCache()`) |
| `lib/features/auth/presentation/auth_oficial_viewmodel.dart` | Nuevo método `tryRestoreSession()`; `signOut()` ahora marca `_isSuccess = false` y agrega log `[AUTH] logout completed` |

## Flujo con internet

1. App inicia → `SplashScreen`
2. Muestra "Verificando sesión…"
3. `supabase_flutter` v2.8.0 restaura sesión automáticamente desde `flutter_secure_storage`
4. Splash detecta `supabase.auth.currentSession != null`
5. Llama a `AsesorRepository.loadCurrentAsesor()` → consulta `asesores_negocio` en Supabase
6. Asesor se carga y se guarda en cache local (SQLite)
7. Navega a Home

## Flujo sin internet (sesión previa)

1. App inicia → `SplashScreen`
2. `supabase_flutter` restaura sesión desde secure storage (incluso offline)
3. Si hay sesión, intenta `loadCurrentAsesor()` → falla por timeout
4. `loadCurrentAsesor()` atrapa el error y llama a `_tryRestoreFromCache()`
5. Si hay datos en `asesor_cache` → asesor restaurado desde cache local
6. Navega a Home
7. Cartera diaria entra en modo offline si hay `cartera_cache`
8. Sync pendiente visible si hay registros en `sync_outbox`

## Datos cacheados

En SQLite, tabla `asesor_cache` (clave/valor):

| Clave | Valor |
|---|---|
| `asesor_id` | UUID del asesor en `asesores_negocio` |
| `asesor_user_id` | UUID del usuario en `auth.users` |
| `asesor_codigo_empleado` | Código de empleado (ej. OFI001) |
| `asesor_nombres` | Nombres del asesor |
| `asesor_apellidos` | Apellidos del asesor |
| `asesor_agencia_id` | ID de la agencia (opcional) |
| `asesor_cache_version` | Versión del cache (para validación futura) |

## Cómo probar

1. **Login normal**: Instalar app limpia → abrir con internet → login OFI001 → Home
2. **Auto-login**: Cerrar app → abrir de nuevo con internet → debe ir directo a Home
3. **Offline con cache**: Cerrar app → apagar internet → abrir app → debe entrar a Home con asesor cacheados → cartera debe mostrar "Modo offline"
4. **Logout**: Cerrar sesión desde Home o Drawer → debe volver a Login → limpiar cache
5. **Post-logout**: Abrir app otra vez → debe pedir login nuevamente
6. **Sin sesión previa**: En app limpia sin internet → debe mostrar login con mensaje

## Limitaciones

- El cache del asesor no incluye contraseñas ni tokens de sesión (la sesión la persiste `supabase_flutter`).
- Si el asesor cambia de agencia/roles mientras está offline, esos cambios no se reflejarán hasta la próxima conexión.
- La detección offline usa timeout de `SupabaseHelper` (15 segundos); puede alargar el splash en condiciones de red muy lenta.
- `hasCachedSession()` verifica la existencia de la clave `asesor_cache_version` en SQLite; no valida vigencia del token.

## Pendientes de seguridad

- Evaluar si `asesor_cache` debe cifrarse (actualmente usa SQLite plano).
- Evaluar tiempo de expiración del cache local.
- En una fase posterior, considerar `flutter_secure_storage` para datos del asesor (actualmente ya se usa para la sesión de Supabase).
- No se almacena refresh_token ni access_token en `asesor_cache`; esos los maneja `supabase_flutter` internamente.
