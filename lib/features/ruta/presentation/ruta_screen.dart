import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_routes.dart';
import '../../../shared/widgets/oficial_drawer.dart';
import '../domain/route_visit_model.dart';
import 'ruta_viewmodel.dart';

/// Pantalla de planificación de ruta diaria (HU-V09).
class RutaScreen extends StatefulWidget {
  const RutaScreen({super.key});

  @override
  State<RutaScreen> createState() => _RutaScreenState();
}

class _RutaScreenState extends State<RutaScreen> {
  late final RutaViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = RutaViewModel();
    _vm.loadTodayRoute();
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  void _showSnack(String? message, {bool isError = false}) {
    if (message == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? AppColors.gestionRecuperacionMora : null,
      ),
    );
  }

  void _onNavigate(String clientId) async {
    final uri = _vm.openNavigation(clientId);
    final url = Uri.tryParse(uri);
    if (url != null && await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
      _showSnack(_vm.successMessage);
    } else {
      _showSnack(
        'No se pudo abrir Google Maps. Verifique que tenga la aplicación instalada.',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(AppStrings.rutaTitle),
          ),
          drawer: const OficialDrawer(),
          body: _vm.isLoading && _vm.visitas.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    _SummaryCard(vm: _vm),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _vm.isLoading ? null : () async {
                              await _vm.optimizeRoute();
                              _showSnack(_vm.successMessage);
                            },
                            icon: const Icon(Icons.route_outlined),
                            label: const Text('Optimizar ruta'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _vm.resetRoute,
                            icon: const Icon(Icons.restore),
                            label: const Text('Restablecer'),
                          ),
                        ),
                      ],
                    ),
                    if (_vm.rutaOptimizada) ...[
                      const SizedBox(height: 8),
                      Chip(
                        avatar: Icon(
                          Icons.check_circle,
                          size: 18,
                          color: AppColors.semaforoNormal,
                        ),
                        label: const Text('Ruta referencial optimizada'),
                        backgroundColor:
                            AppColors.semaforoNormal.withValues(alpha: 0.12),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _RutaOrdenadaView(vm: _vm, onNavigate: _onNavigate),
                    const SizedBox(height: 16),
                    if (_vm.visitas.isNotEmpty)
                      _SectionHeader(title: 'Recorrido del día', count: _vm.visitas.length),
                    const SizedBox(height: 10),
                    ..._vm.visitas.map(
                      (v) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _VisitCard(
                          visita: v,
                          onVerFicha: () => Navigator.pushNamed(
                            context,
                            AppRoutes.fichaCliente,
                            arguments: v.clientId,
                          ),
                          onNavegar: () => _onNavigate(v.clientId),
                          onMarcarVisitado: v.isPendiente
                              ? () {
                                  _vm.markAsVisited(v.clientId);
                                  _showSnack(_vm.successMessage);
                                }
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.purpleSupport,
              ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.purpleSupport.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count paradas',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.purpleSupport,
                ),
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.vm});

  final RutaViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.route, color: AppColors.secondary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Resumen del día',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _MiniStat('Total', '${vm.totalVisitas}', AppColors.secondary),
                const SizedBox(width: 8),
                _MiniStat('Pendientes', '${vm.pendientes}', AppColors.softOrange),
                const SizedBox(width: 8),
                _MiniStat('Visitadas', '${vm.visitadas}', AppColors.semaforoNormal),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Distancia total: ${vm.distanciaTotalKm.toStringAsFixed(1)} km',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            Text(
              'Tiempo estimado: ${vm.tiempoTotalMin} min',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (vm.locationStatus != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.lightBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    vm.isLocating
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            vm.oficialLat != null
                                ? Icons.gps_fixed
                                : Icons.gps_off,
                            size: 16,
                            color: vm.oficialLat != null
                                ? AppColors.semaforoNormal
                                : AppColors.gestionRecuperacionMora,
                          ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        vm.locationStatus!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(this.label, this.value, this.color);

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: color,
                fontSize: 16,
              ),
            ),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _RutaOrdenadaView extends StatelessWidget {
  const _RutaOrdenadaView({
    required this.vm,
    required this.onNavigate,
  });

  final RutaViewModel vm;
  final void Function(String clientId) onNavigate;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.route_outlined, color: AppColors.secondary),
                const SizedBox(width: 8),
                Text(
                  'Vista de ruta del día',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Ubicación del oficial detectada',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 16),
            ...List.generate(vm.visitas.length, (index) {
              final v = vm.visitas[index];
              final isLast = index == vm.visitas.length - 1;
              return _ParadaTimeline(
                visita: v,
                index: index,
                isLast: isLast,
                onNavigate: () => onNavigate(v.clientId),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _ParadaTimeline extends StatelessWidget {
  const _ParadaTimeline({
    required this.visita,
    required this.index,
    required this.isLast,
    required this.onNavigate,
  });

  final RouteVisitModel visita;
  final int index;
  final bool isLast;
  final VoidCallback onNavigate;

  @override
  Widget build(BuildContext context) {
    final priorityColor = RutaUi.priorityColor(visita.prioridad);
    final isVisited = visita.isVisitado;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isVisited
                        ? AppColors.semaforoNormal
                        : AppColors.secondary,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppColors.divider,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isVisited
                    ? AppColors.semaforoNormal.withValues(alpha: 0.04)
                    : null,
                border: Border.all(
                  color: isVisited
                      ? AppColors.semaforoNormal.withValues(alpha: 0.2)
                      : AppColors.divider,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          visita.clienteNombre,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                decoration: isVisited
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: priorityColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          visita.prioridad.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: priorityColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.place_outlined, size: 14, color: AppColors.softOrange),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          visita.direccion,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.map, size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${visita.lat.toStringAsFixed(5)}, ${visita.lng.toStringAsFixed(5)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _InfoChip(label: visita.tipoGestion.label),
                      const SizedBox(width: 6),
                      _InfoChip(
                        label: '${visita.distanciaKm.toStringAsFixed(1)} km · ${visita.tiempoEstimadoMin} min',
                      ),
                      if (isVisited) ...[
                        const SizedBox(width: 6),
                        _InfoChip(
                          label: 'Visitado',
                          color: AppColors.semaforoNormal,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 32,
                    child: OutlinedButton.icon(
                      onPressed: onNavigate,
                      icon: const Icon(Icons.navigation_outlined, size: 16),
                      label: const Text('Navegar', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: chipColor,
        ),
      ),
    );
  }
}

class _VisitCard extends StatelessWidget {
  const _VisitCard({
    required this.visita,
    required this.onVerFicha,
    required this.onNavegar,
    this.onMarcarVisitado,
  });

  final RouteVisitModel visita;
  final VoidCallback onVerFicha;
  final VoidCallback onNavegar;
  final VoidCallback? onMarcarVisitado;

  @override
  Widget build(BuildContext context) {
    final priorityColor = RutaUi.priorityColor(visita.prioridad);
    final statusColor = visita.isVisitado
        ? AppColors.semaforoNormal
        : AppColors.statusPending;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.secondary.withValues(alpha: 0.15),
                  child: Text(
                    '${visita.ordenSugerido}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        visita.clienteNombre,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.place_outlined, size: 14, color: AppColors.softOrange),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              visita.direccion,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.map, size: 12, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            '${visita.lat.toStringAsFixed(5)}, ${visita.lng.toStringAsFixed(5)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                Chip(
                  label: Text(visita.tipoGestion.label, style: const TextStyle(fontSize: 11)),
                  visualDensity: VisualDensity.compact,
                ),
                Chip(
                  label: Text(
                    'Prioridad ${visita.prioridad.label}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  backgroundColor: priorityColor.withValues(alpha: 0.12),
                  labelStyle: TextStyle(color: priorityColor, fontWeight: FontWeight.w600),
                  visualDensity: VisualDensity.compact,
                ),
                Chip(
                  label: Text(visita.estadoVisita.label, style: const TextStyle(fontSize: 11)),
                  backgroundColor: statusColor.withValues(alpha: 0.12),
                  labelStyle: TextStyle(color: statusColor),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${visita.distanciaKm.toStringAsFixed(1)} km · ${visita.tiempoEstimadoMin} min',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onVerFicha,
                  icon: const Icon(Icons.person_outline, size: 18),
                  label: const Text('Ver ficha'),
                ),
                OutlinedButton.icon(
                  onPressed: onNavegar,
                  icon: const Icon(Icons.navigation_outlined, size: 18),
                  label: const Text('Navegar'),
                ),
                if (onMarcarVisitado != null)
                  FilledButton.icon(
                    onPressed: onMarcarVisitado,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Marcar visitado'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.semaforoNormal,
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

abstract final class RutaUi {
  static Color priorityColor(RoutePriority p) => switch (p) {
        RoutePriority.alta => AppColors.gestionRecuperacionMora,
        RoutePriority.media => AppColors.softOrange,
        RoutePriority.normal => AppColors.gestionRenovacion,
      };
}
