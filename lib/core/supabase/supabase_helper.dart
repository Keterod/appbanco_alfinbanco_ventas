import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_client.dart';
import 'supabase_config.dart';

/// Utilidades compartidas para operaciones Supabase (timeout, logs, sesión).
abstract final class SupabaseHelper {
  static const Duration defaultTimeout = Duration(seconds: 15);

  static bool _initialized = false;

  static bool get isInitialized => _initialized;

  static bool get isReady => SupabaseConfig.isConfigured && _initialized;

  static bool get hasSession {
    if (!isReady) return false;
    return supabase.auth.currentSession != null;
  }

  static void markInitialized() => _initialized = true;

  static void log(String message) {
    if (kDebugMode) {
      debugPrint('DEBUG VENTAS SUPABASE: $message');
    }
  }

  static Future<T> withTimeout<T>(
    Future<T> future, {
    String? operation,
  }) {
    return future.timeout(
      defaultTimeout,
      onTimeout: () {
        throw TimeoutException(
          'Tiempo de espera agotado${operation != null ? ' ($operation)' : ''}',
        );
      },
    );
  }

  static void logError(Object error, StackTrace stackTrace) {
    log('ERROR tipo=${error.runtimeType}');
    log('message=$error');
    if (error is PostgrestException) {
      log('code=${error.code}');
      log('details=${error.details}');
      log('hint=${error.hint}');
    }
    if (kDebugMode) {
      debugPrint('DEBUG VENTAS SUPABASE: stackTrace=$stackTrace');
    }
  }

  static String get fallbackLoadMessage =>
      'No se pudo conectar con Supabase. Usando datos locales de demostración.';

  static String get fallbackSaveMessage =>
      'No se pudo guardar en Supabase. La operación continúa en modo local.';

  static String friendlyError(Object error) {
    if (error is TimeoutException) {
      return 'La operación tardó demasiado. Verifique su conexión e intente de nuevo.';
    }
    if (error is AuthException) {
      final msg = error.message.toLowerCase();
      if (msg.contains('invalid') || msg.contains('credentials')) {
        return 'Credenciales incorrectas.';
      }
      return 'No se pudo iniciar sesión. Verifique sus credenciales.';
    }
    if (error is PostgrestException) {
      return fallbackSaveMessage;
    }
    if (error is StateError) {
      final msg = error.message;
      if (msg.contains('asesor')) {
        return 'No se encontró perfil de asesor en Supabase.';
      }
      if (msg.contains('sesión')) {
        return fallbackLoadMessage;
      }
    }
    return 'Ocurrió un error de conexión. Intente nuevamente.';
  }
}
