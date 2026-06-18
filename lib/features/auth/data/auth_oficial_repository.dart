import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';
import '../../../core/supabase/supabase_helper.dart';
import 'asesor_repository.dart';

/// Autenticación del oficial vía Supabase Auth.
class AuthOficialRepository {
  AuthOficialRepository._();
  static final AuthOficialRepository instance = AuthOficialRepository._();

  User? get currentUser =>
      SupabaseHelper.hasSession ? supabase.auth.currentUser : null;

  String employeeCodeToEmail(String codigo) =>
      '${codigo.trim().toLowerCase()}@alfin.demo';

  Future<void> signInWithEmployeeCode(String codigo, String password) async {
    if (!SupabaseHelper.isReady) {
      throw StateError('Supabase no está disponible.');
    }

    final email = employeeCodeToEmail(codigo);
    SupabaseHelper.log('auth login iniciado email=$email');

    await SupabaseHelper.withTimeout(
      supabase.auth.signInWithPassword(email: email, password: password),
      operation: 'signInWithPassword',
    );

    final sessionUserId = supabase.auth.currentUser?.id;
    SupabaseHelper.log('auth sesión activa userId=$sessionUserId');

    await _ensureDemoData(codigo);
    await AsesorRepository.instance.loadCurrentAsesor();
    SupabaseHelper.log('auth login OK');
  }

  Future<void> _ensureDemoData(String codigo) async {
    try {
      SupabaseHelper.log('RPC crear_data_demo_ventas codigo=$codigo');
      await SupabaseHelper.withTimeout(
        supabase.rpc(
          'crear_data_demo_ventas',
          params: {'codigo_empleado': codigo.trim().toUpperCase()},
        ),
        operation: 'crear_data_demo_ventas',
      );
      SupabaseHelper.log('RPC crear_data_demo_ventas OK');
    } catch (error, stackTrace) {
      SupabaseHelper.log('RPC crear_data_demo_ventas omitido');
      SupabaseHelper.logError(error, stackTrace);
    }
  }

  Future<void> signOut() async {
    if (SupabaseHelper.isReady) {
      try {
        SupabaseHelper.log('auth signOut iniciado');
        await SupabaseHelper.withTimeout(
          supabase.auth.signOut(),
          operation: 'signOut',
        );
        SupabaseHelper.log('auth signOut OK');
      } catch (error, stackTrace) {
        SupabaseHelper.logError(error, stackTrace);
      }
    }
    AsesorRepository.instance.clear();
    await AsesorRepository.instance.clearCache();
  }
}
