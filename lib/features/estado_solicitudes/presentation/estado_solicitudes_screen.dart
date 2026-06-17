import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/widgets/oficial_drawer.dart';
import '../../../shared/widgets/app_filter_chip.dart';
import '../domain/request_status_model.dart';
import 'estado_solicitudes_viewmodel.dart';

/// Tablero de estado de solicitudes (HU-V07).
class EstadoSolicitudesScreen extends StatefulWidget {
  const EstadoSolicitudesScreen({super.key, this.highlightReference});

  final String? highlightReference;

  @override
  State<EstadoSolicitudesScreen> createState() => _EstadoSolicitudesScreenState();
}

class _EstadoSolicitudesScreenState extends State<EstadoSolicitudesScreen> {
  late final EstadoSolicitudesViewModel _vm;
  final _currency = NumberFormat.currency(
    locale: 'es_PE',
    symbol: 'S/',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _vm = EstadoSolicitudesViewModel();
    _vm.loadRequests(highlightedSolicitudId: widget.highlightReference);
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  void _openDetalle(RequestStatusModel request) {
    Navigator.pushNamed(
      context,
      AppRoutes.estadoSolicitudDetalle,
      arguments: request.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(AppStrings.estadoTitle),
          ),
          drawer: const OficialDrawer(),
          body: _vm.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SummaryCard(vm: _vm, currency: _currency),
                    _StatusChips(vm: _vm),
                    Expanded(
                      child: _vm.getFilteredRequests().isEmpty
                          ? Center(
                              child: Text(
                                'No hay solicitudes en ${_vm.selectedStatus.label}',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              itemCount: _vm.getFilteredRequests().length,
                              itemBuilder: (context, index) {
                                final item = _vm.getFilteredRequests()[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _RequestCard(
                                    request: item,
                                    highlighted: _vm.isHighlighted(item),
                                    currency: _currency,
                                    onTap: () => _openDetalle(item),
                                  ),
                                );
                              },
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
  const _SummaryCard({required this.vm, required this.currency});

  final EstadoSolicitudesViewModel vm;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen operativo',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.purpleSupport,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatBox(
                    label: 'Total',
                    value: '${vm.totalSolicitudes}',
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatBox(
                    label: 'Aprobadas*',
                    value: '${vm.totalAprobadas}',
                    color: AppColors.semaforoNormal,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatBox(
                    label: 'Desembolsadas',
                    value: '${vm.totalDesembolsadas}',
                    color: AppColors.gestionRenovacion,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Monto total aprobado: ${currency.format(vm.montoTotalAprobado)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '*Incluye aprobadas, condicionadas y desembolsadas',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
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
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _StatusChips extends StatelessWidget {
  const _StatusChips({required this.vm});

  final EstadoSolicitudesViewModel vm;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: RequestStatus.values.map((status) {
          final selected = vm.selectedStatus == status;
          final count = vm.getCountByStatus(status);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AppFilterChip(
              label: '${status.label} ($count)',
              selected: selected,
              onSelected: (_) => vm.selectStatus(status),
              accentColor: RequestStatusUi.color(status),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.highlighted,
    required this.currency,
    required this.onTap,
  });

  final RequestStatusModel request;
  final bool highlighted;
  final NumberFormat currency;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = RequestStatusUi.color(request.estado);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: highlighted ? AppColors.softOrange : AppColors.divider,
          width: highlighted ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (highlighted)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Chip(
                    label: const Text('Solicitud reciente'),
                    backgroundColor: AppColors.softOrange.withValues(alpha: 0.15),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      request.clienteNombre,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  Icon(Icons.chevron_right, color: AppColors.secondary),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                request.numeroExpediente,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Monto: ${currency.format(request.montoSolicitado)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  Text(
                    '${request.diasDesdeEnvio} días',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Analista: ${request.analistaAsignado}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              Chip(
                label: Text(request.estado.label),
                backgroundColor: statusColor.withValues(alpha: 0.12),
                labelStyle: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Colores por estado para UI.
abstract final class RequestStatusUi {
  static Color color(RequestStatus status) => switch (status) {
        RequestStatus.enviada => AppColors.statusRescheduled,
        RequestStatus.enComite => AppColors.purpleSupport,
        RequestStatus.enEvaluacion => AppColors.secondary,
        RequestStatus.aprobada => AppColors.semaforoNormal,
        RequestStatus.condicionada => AppColors.semaforoCpp,
        RequestStatus.rechazada => AppColors.semaforoDudoso,
        RequestStatus.desembolsada => AppColors.gestionRenovacion,
      };
}
