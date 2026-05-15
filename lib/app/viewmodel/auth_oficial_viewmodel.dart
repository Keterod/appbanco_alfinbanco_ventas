import 'package:flutter/foundation.dart';

/// ViewModel de autentificación del oficial (HU-V01). S9: sin validación real.
class AuthOficialViewModel extends ChangeNotifier {
  bool _isLoading = false;
  bool _isSuccess = false;
  String? _errorMessage;

  /// Credenciales de referencia (no bloquean el ingreso en S9).
  final String demoEmployeeCode = 'OFI001';
  final String demoPassword = 'alfin123';

  bool get isLoading => _isLoading;
  bool get isSuccess => _isSuccess;
  String? get errorMessage => _errorMessage;

  Future<void> login(String employeeCode, String password) async {
    if (kDebugMode) {
      debugPrint(
        'Auth S9 (sin validación): código len=${employeeCode.length}, '
        'contraseña len=${password.length}',
      );
    }
    _errorMessage = null;
    _isSuccess = false;
    _isLoading = true;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 900));

    _isLoading = false;
    _isSuccess = true;
    notifyListeners();
  }

  void clearSuccess() {
    _isSuccess = false;
    notifyListeners();
  }

  void resetError() {
    _errorMessage = null;
    notifyListeners();
  }
}
