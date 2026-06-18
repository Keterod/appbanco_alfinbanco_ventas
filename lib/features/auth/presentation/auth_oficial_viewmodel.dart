import 'package:flutter/foundation.dart';

import '../../../core/supabase/supabase_client.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../core/supabase/supabase_helper.dart';
import '../data/auth_oficial_repository.dart';
import '../data/asesor_repository.dart';

/// ViewModel de autentificación del oficial (HU-V01).
class AuthOficialViewModel extends ChangeNotifier {
  final AuthOficialRepository _authRepo = AuthOficialRepository.instance;

  bool _isLoading = false;
  bool _isSuccess = false;
  bool _isRestoring = false;
  String? _errorMessage;

  /// Credenciales de referencia para demo / Supabase.
  final String demoEmployeeCode = 'OFI001';
  final String demoPassword = 'alfin123';

  bool get isLoading => _isLoading;
  bool get isSuccess => _isSuccess;
  bool get isRestoring => _isRestoring;
  String? get errorMessage => _errorMessage;
  bool get usesSupabase => SupabaseHelper.isReady;

  Future<bool> tryRestoreSession() async {
    _isRestoring = true;
    notifyListeners();

    debugPrint('[AUTH] checking persisted session');

    if (!SupabaseHelper.isReady) {
      debugPrint('[AUTH] Supabase no disponible');
      _isRestoring = false;
      notifyListeners();
      return false;
    }

    final session = supabase.auth.currentSession;
    if (session == null) {
      debugPrint('[AUTH] no supabase session found');
      _isRestoring = false;
      notifyListeners();
      return false;
    }

    debugPrint('[AUTH] supabase session found userId=${session.user.id}');

    try {
      final asesor = await AsesorRepository.instance.loadCurrentAsesor();
      if (asesor != null) {
        debugPrint('[AUTH] asesor loaded from Supabase id=${asesor.id}');
        _isSuccess = true;
        _isRestoring = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      SupabaseHelper.log('loadCurrentAsesor falló en restauración: $e');
    }

    _isRestoring = false;
    notifyListeners();
    debugPrint('[AUTH] no valid session, showing login');
    return false;
  }

  Future<void> login(String employeeCode, String password) async {
    _errorMessage = null;
    _isSuccess = false;

    final codigo = employeeCode.trim();
    if (codigo.isEmpty) {
      _errorMessage = 'Ingrese su código de empleado.';
      notifyListeners();
      return;
    }
    if (password.isEmpty) {
      _errorMessage = 'Ingrese su contraseña.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      if (SupabaseHelper.isReady) {
        SupabaseHelper.log('login Supabase codigo=$codigo');
        await _authRepo.signInWithEmployeeCode(codigo, password);
      } else if (SupabaseConfig.isConfigured) {
        _errorMessage = SupabaseHelper.fallbackLoadMessage;
        _isLoading = false;
        notifyListeners();
        return;
      } else {
        SupabaseHelper.log('login modo demo local');
        await Future<void>.delayed(const Duration(milliseconds: 900));
      }

      _isSuccess = true;
    } catch (error, stackTrace) {
      SupabaseHelper.log('auth login falló');
      SupabaseHelper.logError(error, stackTrace);
      _errorMessage = SupabaseHelper.friendlyError(error);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> signOut() async {
    debugPrint('[AUTH] logout completed');
    _isSuccess = false;
    await _authRepo.signOut();
  }

  String? get asesorNombre =>
      AsesorRepository.instance.current?.nombreCompleto;

  void clearSuccess() {
    _isSuccess = false;
    notifyListeners();
  }

  void resetError() {
    _errorMessage = null;
    notifyListeners();
  }
}
