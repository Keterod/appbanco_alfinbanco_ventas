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

  void _showSnack(String? message) {
    if (message == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
                    if (_vm.locationStatus != null) ...[
                      const SizedBox(height: 8),
                      Card(
                        color: AppColors.lightBackground,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              _vm.isLocating
                                  ? const SizedBox(
                                      width: 16, height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : Icon(
                                      _vm.oficialLat != null
                                          ? Icons.gps_fixed
                                          : Icons.gps_off,
                                      size: 18,
                                      color: _vm.oficialLat != null
                                          ? AppColors.semaforoNormal
                                          : AppColors.gestionRecuperacionMora,
                                    ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _vm.locationStatus!,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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
                        label: const Text('Ruta optimizada'),
                        backgroundColor:
                            AppColors.semaforoNormal.withValues(alpha: 0.12),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _SimulatedMapSection(visitas: _vm.visitas),
                    const SizedBox(height: 16),
                    Text(
                      'Visitas del día',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.purpleSupport,
                          ),
                    ),
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
                          onNavegar: () async {
                              final uri = _vm.openNavigation(v.clientId);
                              final url = Uri.tryParse(uri);
                              if (url != null && await canLaunchUrl(url)) {
                                await launchUrl(url, mode: LaunchMode.externalApplication);
                              } else {
                                _showSnack('No se pudo abrir el mapa.');
                              }
                            },
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.vm});

  final RutaViewModel vm;

  @override
  Widget build(BuildContext context) {
    final progress = vm.totalVisitas == 0
        ? 0.0
        : vm.visitadas / vm.totalVisitas;

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
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: AppColors.divider,
                color: AppColors.semaforoNormal,
              ),
            ),
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

class _SimulatedMapSection extends StatelessWidget {
  const _SimulatedMapSection({required this.visitas});

  final List<RouteVisitModel> visitas;

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
                Icon(Icons.map_outlined, color: AppColors.secondary),
                const SizedBox(width: 8),
                Text(
                  'Mapa de ruta',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                color: AppColors.lightBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.location_on_outlined,
                      size: 48,
                      color: AppColors.secondary.withValues(alpha: 0.25),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: visitas.map((v) {
                        return Chip(
                          avatar: CircleAvatar(
                            radius: 10,
                            backgroundColor:
                                RutaUi.priorityColor(v.prioridad),
                            child: Text(
                              '${v.ordenSugerido}',
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          label: Text(
                            v.clienteNombre.split(' ').first,
                            style: const TextStyle(fontSize: 11),
                          ),
                          visualDensity: VisualDensity.compact,
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Mapa simulado — integración de mapas en siguiente fase',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              children: [
                _LegendDot(color: RutaUi.priorityColor(RoutePriority.alta), label: 'Alta'),
                _LegendDot(color: RutaUi.priorityColor(RoutePriority.media), label: 'Media'),
                _LegendDot(color: RutaUi.priorityColor(RoutePriority.normal), label: 'Normal'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
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
