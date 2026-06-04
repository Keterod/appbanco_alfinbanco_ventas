import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../domain/collection_model.dart';
import 'cobranza_viewmodel.dart';

/// Listado de cartera vencida / cobranza (HU-V10).
class CobranzaScreen extends StatefulWidget {
  const CobranzaScreen({super.key});

  @override
  State<CobranzaScreen> createState() => _CobranzaScreenState();
}

class _CobranzaScreenState extends State<CobranzaScreen> {
  late final CobranzaViewModel _vm;
  final _currency = NumberFormat.currency(
    locale: 'es_PE',
    symbol: 'S/',
    decimalDigits: 2,
  );
  final _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _vm = CobranzaViewModel();
    _vm.loadOverdueClients();
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  Future<void> _openRegistrarGestion(String overdueClientId) async {
    await Navigator.pushNamed(
      context,
      AppRoutes.cobranzaAccion,
      arguments: overdueClientId,
    );
    if (mounted) await _vm.loadOverdueClients();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final filtered = _vm.getFilteredClients();
        return Scaffold(
          appBar: AppBar(
            title: const Text('Cartera vencida'),
          ),
          body: _vm.isLoading && _vm.overdueClients.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    _SummaryCard(vm: _vm, currency: _currency),
                    const SizedBox(height: 12),
                    _FilterChips(vm: _vm),
                    const SizedBox(height: 12),
                    if (filtered.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text('No hay clientes en este filtro.'),
                        ),
                      )
                    else
                      ...filtered.map(
                        (c) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _ClientCard(
                            client: c,
                            currency: _currency,
                            dateFormat: _dateFormat,
                            onRegistrar: () => _openRegistrarGestion(c.id),
                            onVerFicha: () => Navigator.pushNamed(
                              context,
                              AppRoutes.fichaCliente,
                              arguments: c.clientId,
                            ),
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
  const _SummaryCard({required this.vm, required this.currency});

  final CobranzaViewModel vm;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen de mora',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.purpleSupport,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Clientes en mora: ${vm.overdueClients.length}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            Text(
              'Monto total vencido: ${currency.format(vm.getTotalOverdueAmount())}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.gestionRecuperacionMora,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _Pill(
                    label: 'Preventivos',
                    count: vm.getCountByPriority(OverduePriority.preventiva),
                    color: AppColors.semaforoNormal,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _Pill(
                    label: 'Prioritarios',
                    count: vm.getCountByPriority(OverduePriority.prioritaria),
                    color: AppColors.softOrange,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _Pill(
                    label: 'Urgentes',
                    count: vm.getCountByPriority(OverduePriority.urgente),
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

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: color,
              fontSize: 16,
            ),
          ),
          Text(label, style: const TextStyle(fontSize: 10), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.vm});

  final CobranzaViewModel vm;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          FilterChip(
            label: const Text('Todos'),
            selected: vm.selectedPriorityFilter == null,
            onSelected: (_) => vm.setPriorityFilter(null),
          ),
          const SizedBox(width: 8),
          ...OverduePriority.values.map((p) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text('${p.label} (${vm.getCountByPriority(p)})'),
                selected: vm.selectedPriorityFilter == p,
                onSelected: (_) => vm.setPriorityFilter(p),
                selectedColor:
                    CobranzaUi.priorityColor(p).withValues(alpha: 0.2),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ClientCard extends StatelessWidget {
  const _ClientCard({
    required this.client,
    required this.currency,
    required this.dateFormat,
    required this.onRegistrar,
    required this.onVerFicha,
  });

  final OverdueClientModel client;
  final NumberFormat currency;
  final DateFormat dateFormat;
  final VoidCallback onRegistrar;
  final VoidCallback onVerFicha;

  @override
  Widget build(BuildContext context) {
    final priorityColor = CobranzaUi.priorityColor(client.prioridad);
    final statusColor = CobranzaUi.statusColor(client.estadoGestion);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    client.clienteNombre,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                Chip(
                  label: Text(
                    '${client.diasMora} días',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                  backgroundColor: priorityColor.withValues(alpha: 0.15),
                  labelStyle: TextStyle(color: priorityColor),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'DNI ${client.documentoCensurado}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Monto vencido: ${currency.format(client.montoVencido)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.gestionRecuperacionMora,
                  ),
            ),
            Text(
              'Último contacto: ${dateFormat.format(client.fechaUltimoContacto)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                Chip(
                  label: Text('Prioridad ${client.prioridad.label}'),
                  backgroundColor: priorityColor.withValues(alpha: 0.12),
                  labelStyle: TextStyle(color: priorityColor, fontSize: 11),
                  visualDensity: VisualDensity.compact,
                ),
                Chip(
                  label: Text(client.estadoGestion.label),
                  backgroundColor: statusColor.withValues(alpha: 0.12),
                  labelStyle: TextStyle(color: statusColor, fontSize: 11),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: onRegistrar,
                  icon: const Icon(Icons.edit_note, size: 18),
                  label: const Text('Registrar gestión'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: onVerFicha,
                  icon: const Icon(Icons.person_outline, size: 18),
                  label: const Text('Ver ficha'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

abstract final class CobranzaUi {
  static Color priorityColor(OverduePriority p) => switch (p) {
        OverduePriority.preventiva => AppColors.semaforoNormal,
        OverduePriority.prioritaria => AppColors.softOrange,
        OverduePriority.urgente => AppColors.gestionRecuperacionMora,
      };

  static Color statusColor(CollectionStatus s) => switch (s) {
        CollectionStatus.pendiente => AppColors.statusPending,
        CollectionStatus.gestionado => AppColors.gestionRenovacion,
        CollectionStatus.compromisoVigente => AppColors.secondary,
      };
}
