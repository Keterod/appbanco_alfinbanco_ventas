import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/storage/session_local_datasource.dart';
import '../../../core/supabase/supabase_helper.dart';
import '../../../core/sync/sync_manager.dart';
import '../data/asesor_repository.dart';

/// Pantalla de carga inicial que restaura sesión persistente.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _status = AppStrings.splashChecking;

  @override
  void initState() {
    super.initState();
    _tryRestore();
  }

  Future<void> _tryRestore() async {
    // 1. Verificar sesión persistente de Supabase
    setState(() => _status = AppStrings.splashChecking);
    await Future<void>.delayed(const Duration(milliseconds: 400));

    if (!SupabaseHelper.isReady) {
      debugPrint('[AUTH] Supabase no disponible, mostrando login');
      _goToLogin();
      return;
    }

    final session = supabase.auth.currentSession;
    if (session == null) {
      // Sin sesión Supabase → verificar si hay cache local
      final hasCache = await SessionLocalDataSource.instance.hasCachedSession();
      if (hasCache) {
        debugPrint('[AUTH] sin sesión Supabase pero hay cache local, '
            'usando datos cacheados');
        setState(() => _status = AppStrings.splashLoading);
      } else {
        // Sin sesión ni cache → login
        debugPrint('[AUTH] no valid session, showing login');
        _goToLogin();
        return;
      }
    } else {
      debugPrint('[AUTH] supabase session found userId=${session.user.id}');
    }

    // 2. Cargar asesor (Supabase o cache local)
    setState(() => _status = AppStrings.splashLoading);
    try {
      final asesor = await AsesorRepository.instance.loadCurrentAsesor();
      if (asesor != null && mounted) {
        debugPrint('[AUTH] asesor loaded id=${asesor.id}');
        // Procesar sync pendiente al iniciar sesión
        try {
          await SyncManager.instance.processPending();
        } catch (_) {}
        _goToHome();
        return;
      }
    } catch (e) {
      SupabaseHelper.log('splash restore falló: $e');
    }

    // 3. Si falló todo → login
    debugPrint('[AUTH] no valid session, showing login');
    _goToLogin();
  }

  void _goToLogin() {
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  void _goToHome() {
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.homeOficial);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.purpleSupport,
              Color(0xFF4B0360),
              AppColors.secondary,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.white,
                    border: Border.all(color: AppColors.primary, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(10),
                  alignment: Alignment.center,
                  child: Image.asset(
                    'assets/images/alfin_logo.png',
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  AppStrings.bankName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _status,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.white.withValues(alpha: 0.85),
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}