import 'package:flutter/material.dart';

import '../../navigation/app_routes.dart';
import '../../ui/theme/app_colors.dart';
import '../../viewmodel/auth_oficial_viewmodel.dart';

/// Pantalla de login del oficial de crédito (HU-V01).
class LoginOficialScreen extends StatefulWidget {
  const LoginOficialScreen({super.key});

  @override
  State<LoginOficialScreen> createState() => _LoginOficialScreenState();
}

class _LoginOficialScreenState extends State<LoginOficialScreen> {
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  late final AuthOficialViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = AuthOficialViewModel();
    _codeController.text = '';
    _passwordController.text = '';
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onIngresar() async {
    await _viewModel.login(
      _codeController.text,
      _passwordController.text,
    );
    if (!mounted) return;
    if (_viewModel.isSuccess) {
      _viewModel.clearSuccess();
      Navigator.pushReplacementNamed(context, AppRoutes.cartera);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _BrandHeader(viewModel: _viewModel),
                      const SizedBox(height: 28),
                      _LoginCard(
                        codeController: _codeController,
                        passwordController: _passwordController,
                        isLoading: _viewModel.isLoading,
                        onIngresar: _onIngresar,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.viewModel});

  final AuthOficialViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Column(
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
        const SizedBox(height: 16),
        Text(
          'Alfin Banco',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.6)),
          ),
          child: Text(
            'Portal Oficial de Crédito',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'S9: ingreso libre. Referencia en código: ${viewModel.demoEmployeeCode}',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.white.withValues(alpha: 0.85),
              ),
        ),
      ],
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.codeController,
    required this.passwordController,
    required this.isLoading,
    required this.onIngresar,
  });

  final TextEditingController codeController;
  final TextEditingController passwordController;
  final bool isLoading;
  final VoidCallback onIngresar;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shadowColor: Colors.black45,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Acceso de oficial',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.darkText,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Ingrese sus credenciales institucionales.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.darkText.withValues(alpha: 0.65),
                  ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: codeController,
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.text,
              decoration: const InputDecoration(
                labelText: 'Código de empleado',
                prefixIcon: Icon(Icons.badge_outlined, color: AppColors.secondary),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              onSubmitted: (_) => onIngresar(),
              decoration: const InputDecoration(
                labelText: 'Contraseña',
                prefixIcon: Icon(Icons.lock_outline, color: AppColors.secondary),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: isLoading ? null : onIngresar,
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : const Text('Ingresar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
