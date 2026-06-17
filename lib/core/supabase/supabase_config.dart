class SupabaseConfig {
  static const String supabaseUrl =
      'https://lynkauvinqfzamixszqo.supabase.co';
  static const String supabaseAnonKey =
      'sb_publishable_OgLuncsis39bnavWzixZNQ_oZC_MeiI';

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty &&
      !supabaseUrl.contains('TU_SUPABASE_URL') &&
      !supabaseAnonKey.contains('TU_SUPABASE_ANON_KEY');
}
