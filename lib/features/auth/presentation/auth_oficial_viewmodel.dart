import 'package:flutter/foundation.dart';

import '../../../core/supabase/supabase_config.dart';
import '../../../core/supabase/supabase_helper.dart';
import '../data/auth_oficial_repository.dart';
import '../data/asesor_repository.dart';

/// ViewModel de autentificación del oficial (HU-V01).
class AuthOficialViewModel extends ChangeNotifier {
  final AuthOficialRepository _authRepo = AuthOficialRepository.instance;

  bool _isLoading = false;
  bool _isSuccess = false;
  String? _errorMessage;

  /// Credenciales de referencia para demo / Supabase.
  final String demoEmployeeCode = 'OFI001';
  final String demoPassword = 'alfin123';

  bool get isLoading => _isLoading;
  bool get isSuccess => _isSuccess;
  String? get errorMessage => _errorMessage;
  bool get usesSupabase => SupabaseHelper.isReady;

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

  Future<void> signOut() => _authRepo.signOut();

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
