import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/supabase/supabase_config.dart';
import 'core/supabase/supabase_helper.dart';
import 'core/storage/local_db.dart';
import 'core/sync/sync_manager.dart';
import 'app/navigation/app_navigation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (SupabaseConfig.isConfigured) {
    try {
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        anonKey: SupabaseConfig.supabaseAnonKey,
      );
      SupabaseHelper.markInitialized();
      SupabaseHelper.log('Inicialización OK');
    } catch (e) {
      SupabaseHelper.log('Inicialización fallida: $e');
    }
  }

  await LocalDb.database;

  // Intentar procesar pendientes de sincronización al arrancar
  try {
    await SyncManager.instance.processPending();
  } catch (_) {}

  runApp(
    const ProviderScope(
      child: AppNavigation(),
    ),
  );
} 
