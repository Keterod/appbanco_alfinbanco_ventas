import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/sync/sync_manager.dart';
import '../../features/auth/data/auth_oficial_repository.dart';
import '../../features/home/presentation/home_oficial_viewmodel.dart';

/// Menú lateral global del oficial de crédito.
class OficialDrawer extends StatelessWidget {
  const OficialDrawer({super.key});

  static const _menuItems = <_DrawerMenuItem>[
    _DrawerMenuItem(
      label: AppStrings.drawerHome,
      route: AppRoutes.homeOficial,
      icon: Icons.home_outlined,
    ),
    _DrawerMenuItem(
      label: AppStrings.drawerCartera,
      route: AppRoutes.cartera,
      icon: Icons.groups_outlined,
    ),
    _DrawerMenuItem(
      label: AppStrings.drawerRuta,
      route: AppRoutes.ruta,
      icon: Icons.route_outlined,
    ),
    _DrawerMenuItem(
      label: AppStrings.drawerBuro,
      route: AppRoutes.buro,
      icon: Icons.fact_check_outlined,
    ),
    _DrawerMenuItem(
      label: AppStrings.drawerSolicitud,
      route: AppRoutes.solicitudCredito,
      icon: Icons.note_add_outlined,
    ),
    _DrawerMenuItem(
      label: AppStrings.drawerEstado,
      route: AppRoutes.estadoSolicitudes,
      icon: Icons.dashboard_outlined,
    ),
    _DrawerMenuItem(
      label: AppStrings.drawerCobranza,
      route: AppRoutes.cobranza,
      icon: Icons.warning_amber_rounded,
    ),
    _DrawerMenuItem(
      label: AppStrings.drawerReportes,
      route: AppRoutes.reportes,
      icon: Icons.bar_chart_rounded,
    ),
  ];

  void _navigateTo(BuildContext context, String route) {
    Navigator.pop(context);

    final currentRoute = ModalRoute.of(context)?.settings.name;
    if (currentRoute == route) return;

    Navigator.pushReplacementNamed(context, route);
  }

  void _cerrarSesion(BuildContext context) {
    Navigator.pop(context);
    AuthOficialRepository.instance.signOut();
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name;

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DrawerHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 4),
                children: [
                  ..._menuItems.map(
                    (item) => _DrawerNavTile(
                      item: item,
                      selected: currentRoute == item.route,
                      onTap: () => _navigateTo(context, item.route),
                    ),
                  ),
                  _SyncPendingTile(),
                  const Divider(height: 24, indent: 16, endIndent: 16),
                  ListTile(
                    leading: Icon(
                      Icons.logout_rounded,
                      color: AppColors.gestionRecuperacionMora,
                    ),
                    title: Text(
                      AppStrings.drawerLogout,
                      style: TextStyle(
                        color: AppColors.gestionRecuperacionMora,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () => _cerrarSesion(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader();

  @override
  Widget build(BuildContext context) {
    return DrawerHeader(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.purpleSupport,
            AppColors.secondary,
          ],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.account_balance_rounded,
                  color: AppColors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.bankName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    Text(
                      AppStrings.appName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.white.withValues(alpha: 0.85),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            HomeOficialViewModel.officerName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 2),
          Text(
                    AppStrings.officerRole,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.white.withValues(alpha: 0.9),
                ),
          ),
          const SizedBox(height: 8),
          Chip(
            label: const Text(AppStrings.demoBadge),
            backgroundColor: AppColors.white.withValues(alpha: 0.15),
            labelStyle: const TextStyle(
              color: AppColors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}

class _DrawerMenuItem {
  const _DrawerMenuItem({
    required this.label,
    required this.route,
    required this.icon,
  });

  final String label;
  final String route;
  final IconData icon;
}

class _SyncPendingTile extends StatefulWidget {
  @override
  State<_SyncPendingTile> createState() => _SyncPendingTileState();
}

class _SyncPendingTileState extends State<_SyncPendingTile> {
  int _count = 0;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final count = await SyncManager.instance.pendingCount();
    if (mounted) {
      setState(() {
        _count = count;
        _loaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const SizedBox.shrink();
    if (_count == 0) return const SizedBox.shrink();

    return ListTile(
      leading: Icon(
        Icons.sync_outlined,
        color: Colors.orange.shade700,
        size: 22,
      ),
      title: Text(
        'Sincronización pendiente: $_count',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.orange.shade800,
        ),
      ),
      dense: true,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _DrawerNavTile extends StatelessWidget {
  const _DrawerNavTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _DrawerMenuItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        item.icon,
        color: selected ? AppColors.secondary : AppColors.textSecondary,
      ),
      title: Text(
        item.label,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? AppColors.purpleSupport : AppColors.textPrimary,
        ),
      ),
      selected: selected,
      selectedTileColor: AppColors.secondary.withValues(alpha: 0.08),
      onTap: onTap,
      dense: true,
      visualDensity: VisualDensity.compact,
    );
  }
}
