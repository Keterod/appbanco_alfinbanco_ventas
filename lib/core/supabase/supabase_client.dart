import 'package:supabase_flutter/supabase_flutter.dart';

/// Instancia global única del cliente Supabase.
/// Usar: SupabaseConfig.client para acceder desde cualquier parte.
class SupabaseConfig {
  static const String supabaseUrl =
      'https://lynkauvinqfzamixszqo.supabase.co';
  static const String supabasePublishableKey =
      'sb_publishable_OgLuncsis39bnavWzixZNQ_oZC_MeiI';

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabasePublishableKey,
    );
  }
}
