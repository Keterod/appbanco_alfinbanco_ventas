import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/supabase/supabase_client.dart';
import 'core/storage/local_db.dart';
import 'app/navigation/app_navigation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseConfig.initialize();
  await LocalDb.database;

  runApp(
    const ProviderScope(
      child: AppNavigation(),
    ),
  );
}
