import 'package:flutter/material.dart';

import '../domain/client_portfolio_model.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/widgets/oficial_drawer.dart';
import '../../auth/data/auth_oficial_repository.dart';
import 'cartera_viewmodel.dart';

/// Pantalla de cartera diaria en campo (HU-V02).
class CarteraDiariaScreen extends StatefulWidget {
  const CarteraDiariaScreen({super.key});

  @override
  State<CarteraDiariaScreen> createState() => _CarteraDiariaScreenState();
}

class _CarteraDiariaScreenState extends State<CarteraDiariaScreen> {
  late final CarteraViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = CarteraViewModel();
    _viewModel.addListener(_onVmChanged);
    _viewModel.loadCartera();
  }

  void _onVmChanged() => setState(() {});

  @override
  void dispose() {
    _viewModel.removeListener(_onVmChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _cerrarSesion() {
    AuthOficialRepository.instance.signOut();
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final vm = _viewModel;
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appTitle),
        actions: [
          IconButton(
            tooltip: 'Inicio',
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.homeOficial),
            icon: const Icon(Icons.home_outlined),
          ),
          IconButton(
            tooltip: 'Cartera vencida',
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.cobranza),
            icon: const Icon(Icons.warning_amber_rounded),
          ),
          TextButton.icon(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.ruta),
            icon: const Icon(Icons.route, color: AppColors.white),
            label: const Text(
              'Planificar ruta',
              style: TextStyle(color: AppColors.white),
            ),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: _cerrarSesion,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      drawer: const OficialDrawer(),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.lightBackground,
              AppColors.white,
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _HeaderSection(viewModel: vm),
            const SizedBox(height: 16),
            ...vm.clients.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ClientCard(
                    client: c,
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.fichaCliente,
                      arguments: c.id,
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection({required this.viewModel});

  final CarteraViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hola, Oficial ${viewModel.officerName}',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.purpleSupport,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              AppStrings.carteraTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.darkText,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _DataSourceBanner(source: viewModel.dataSource),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'Visitas del día',
                value: '${viewModel.totalVisits}',
                accent: AppColors.secondary,
                badge: viewModel.dataSource == 'offline'
                    ? 'Offline'
                    : viewModel.dataSource == 'demo'
                        ? 'Demo'
                        : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                label: 'Pendientes',
                value: '${viewModel.pendingVisits}',
                accent: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                label: 'Visitados',
                value: '${viewModel.visitedClients.length}',
                accent: AppColors.softOrange,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.accent,
    this.badge,
  });

  final String label;
  final String value;
  final Color accent;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                if (badge != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: badge == 'Offline'
                          ? Colors.orange.shade100
                          : AppColors.lightGraySecondary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badge!,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: badge == 'Offline'
                            ? Colors.orange.shade900
                            : AppColors.darkText,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.darkText.withValues(alpha: 0.7),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DataSourceBanner extends StatelessWidget {
  const _DataSourceBanner({required this.source});

  final String source;

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    IconData icon;
    String label;

    switch (source) {
      case 'live':
        bgColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF2E7D32);
        icon = Icons.cloud_done_outlined;
        label = 'Sincronizado con Supabase';
      case 'offline':
        bgColor = const Color(0xFFFFF3E0);
        textColor = const Color(0xFFE65100);
        icon = Icons.wifi_off_outlined;
        label = 'Modo offline · datos guardados';
      default:
        bgColor = const Color(0xFFF5F5F5);
        textColor = const Color(0xFF616161);
        icon = Icons.bug_report_outlined;
        label = 'Modo demo';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientCard extends StatelessWidget {
  const _ClientCard({required this.client, required this.onTap});

  final ClientPortfolioModel client;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final managementColor = _managementColor(client.managementType);
    final statusColor =
        client.isVisited ? AppColors.secondary : AppColors.primary;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.lightGraySecondary,
                  child: Text(
                    client.clientName.isNotEmpty
                        ? client.clientName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: AppColors.purpleSupport,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              client.clientName,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.darkText,
                                  ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.secondary.withValues(alpha: 0.7),
                          ),
                        ],
                      ),
                      if (client.address != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.place_outlined,
                              size: 16,
                              color: AppColors.softOrange,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                client.address!,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.darkText.withValues(alpha: 0.75),
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (client.amount != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Monto referencial: S/ ${client.amount!.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: Icon(Icons.assignment_outlined, size: 18, color: managementColor),
                  label: Text(
                    client.managementType,
                    style: TextStyle(
                      color: managementColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  backgroundColor: managementColor.withValues(alpha: 0.12),
                  side: BorderSide(color: managementColor.withValues(alpha: 0.45)),
                ),
                Chip(
                  avatar: Icon(
                    client.isVisited ? Icons.check_circle_outline : Icons.schedule,
                    size: 18,
                    color: statusColor,
                  ),
                  label: Text(
                    client.status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  backgroundColor: statusColor.withValues(alpha: 0.12),
                  side: BorderSide(color: statusColor.withValues(alpha: 0.45)),
                ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }

  Color _managementColor(String type) {
    final t = type.toLowerCase();
    if (t.contains('renov')) return AppColors.secondary;
    if (t.contains('nuevo')) return AppColors.purpleSupport;
    return AppColors.primary;
  }
}
