import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../shared/widgets/oficial_drawer.dart';
import 'home_oficial_viewmodel.dart';

/// Dashboard principal del oficial de crédito.
class HomeOficialScreen extends StatefulWidget {
  const HomeOficialScreen({super.key});

  @override
  State<HomeOficialScreen> createState() => _HomeOficialScreenState();
}

class _HomeOficialScreenState extends State<HomeOficialScreen> {
  late final HomeOficialViewModel _vm;
  final _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _vm = HomeOficialViewModel();
    _vm.loadDashboard();
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  void _cerrarSesion() {
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Alfin Banco — Ventas'),
          ),
          drawer: const OficialDrawer(),
          body: _vm.isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _vm.loadDashboard,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      _WelcomeHeader(
                        dateText: _dateFormat.format(DateTime.now()),
                      ),
                      const SizedBox(height: 16),
                      _SummaryCard(vm: _vm),
                      const SizedBox(height: 20),
                      Text(
                        'Accesos rápidos',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.purpleSupport,
                            ),
                      ),
                      const SizedBox(height: 12),
                      _QuickAccessGrid(
                        onCartera: () =>
                            Navigator.pushNamed(context, AppRoutes.cartera),
                        onRuta: () =>
                            Navigator.pushNamed(context, AppRoutes.ruta),
                        onCobranza: () =>
                            Navigator.pushNamed(context, AppRoutes.cobranza),
                        onEstado: () => Navigator.pushNamed(
                          context,
                          AppRoutes.estadoSolicitudes,
                        ),
                        onReportes: () =>
                            Navigator.pushNamed(context, AppRoutes.reportes),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Actividad reciente',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.purpleSupport,
                            ),
                      ),
                      const SizedBox(height: 10),
                      ..._vm.actividadReciente.map(
                        (a) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _ActivityTile(item: a),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _cerrarSesion,
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text('Cerrar sesión'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.gestionRecuperacionMora,
                            side: const BorderSide(
                              color: AppColors.gestionRecuperacionMora,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader({required this.dateText});

  final String dateText;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.purpleSupport.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hola, ${HomeOficialViewModel.officerName}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.purpleSupport,
                  ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 18, color: AppColors.secondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    dateText,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Chip(
              label: const Text('Modo demostración'),
              backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.vm});

  final HomeOficialViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen del día',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatBox(
                    label: 'Visitas',
                    value: '${vm.visitasDelDia}',
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatBox(
                    label: 'Pendientes',
                    value: '${vm.pendientes}',
                    color: AppColors.softOrange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _StatBox(
                    label: 'En evaluación',
                    value: '${vm.solicitudesEnEvaluacion}',
                    color: AppColors.gestionRenovacion,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatBox(
                    label: 'En mora',
                    value: '${vm.clientesEnMora}',
                    color: AppColors.gestionRecuperacionMora,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _QuickAccessGrid extends StatelessWidget {
  const _QuickAccessGrid({
    required this.onCartera,
    required this.onRuta,
    required this.onCobranza,
    required this.onEstado,
    required this.onReportes,
  });

  final VoidCallback onCartera;
  final VoidCallback onRuta;
  final VoidCallback onCobranza;
  final VoidCallback onEstado;
  final VoidCallback onReportes;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.35,
      children: [
        _QuickTile(
          icon: Icons.groups_outlined,
          label: 'Cartera diaria',
          color: AppColors.secondary,
          onTap: onCartera,
        ),
        _QuickTile(
          icon: Icons.route_outlined,
          label: 'Planificar ruta',
          color: AppColors.purpleSupport,
          onTap: onRuta,
        ),
        _QuickTile(
          icon: Icons.warning_amber_rounded,
          label: 'Cartera vencida',
          color: AppColors.gestionRecuperacionMora,
          onTap: onCobranza,
        ),
        _QuickTile(
          icon: Icons.dashboard_outlined,
          label: 'Estado solicitudes',
          color: AppColors.gestionRenovacion,
          onTap: onEstado,
        ),
        _QuickTile(
          icon: Icons.bar_chart_rounded,
          label: 'Reportes',
          color: AppColors.gestionSeguimiento,
          onTap: onReportes,
        ),
      ],
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.item});

  final RecentActivityItem item;

  IconData _icon() => switch (item.iconName) {
        'send' => Icons.send_rounded,
        'visit' => Icons.check_circle_outline,
        _ => Icons.receipt_long_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm').format(item.fechaHora);
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.lightBackground,
          child: Icon(_icon(), color: AppColors.secondary, size: 22),
        ),
        title: Text(
          item.titulo,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('${item.descripcion}\n$time'),
        isThreeLine: true,
      ),
    );
  }
}
