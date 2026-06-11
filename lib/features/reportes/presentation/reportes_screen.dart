import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/oficial_drawer.dart';
import '../domain/report_model.dart';
import 'reportes_viewmodel.dart';

/// Reportes de productividad y resumen operativo del oficial.
class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  late final ReportesViewModel _vm;
  final _currency = NumberFormat.currency(
    locale: 'es_PE',
    symbol: 'S/',
    decimalDigits: 0,
  );
  final _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _vm = ReportesViewModel();
    _vm.loadReport();
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  void _exportReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exportación de reportes disponible en siguiente fase'),
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
            title: const Text('Reportes'),
          ),
          drawer: const OficialDrawer(),
          body: _vm.isLoading && _vm.report == null
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _vm.loadReport,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      if (_vm.errorMessage != null) ...[
                        Card(
                          color: AppColors.gestionRecuperacionMora
                              .withValues(alpha: 0.08),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              _vm.errorMessage!,
                              style: TextStyle(
                                color: AppColors.gestionRecuperacionMora,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      _PeriodChips(vm: _vm),
                      const SizedBox(height: 16),
                      if (_vm.report != null) ...[
                        _MainReportCard(vm: _vm),
                        const SizedBox(height: 16),
                        _IndicatorsGrid(vm: _vm, currency: _currency),
                        const SizedBox(height: 16),
                        _ProgressSection(vm: _vm),
                        const SizedBox(height: 20),
                        Text(
                          'Actividad reciente',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.purpleSupport,
                                  ),
                        ),
                        const SizedBox(height: 10),
                        ..._vm.activities.map(
                          (a) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _ActivityCard(
                              item: a,
                              dateTimeFormat: _dateTimeFormat,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _exportReport,
                            icon: const Icon(Icons.file_download_outlined),
                            label: const Text('Exportar reporte'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.secondary,
                              side: const BorderSide(color: AppColors.secondary),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class _PeriodChips extends StatelessWidget {
  const _PeriodChips({required this.vm});

  final ReportesViewModel vm;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ReportesViewModel.periodos.map((period) {
          final selected = vm.selectedPeriod == period;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(period),
              selected: selected,
              onSelected: (_) => vm.changePeriod(period),
              selectedColor: AppColors.secondary.withValues(alpha: 0.2),
              checkmarkColor: AppColors.secondary,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MainReportCard extends StatelessWidget {
  const _MainReportCard({required this.vm});

  final ReportesViewModel vm;

  @override
  Widget build(BuildContext context) {
    final report = vm.report!;

    return Card(
      color: AppColors.purpleSupport.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.secondary.withValues(alpha: 0.15),
                  child: const Icon(
                    Icons.insights_outlined,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.asesorNombre,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.purpleSupport,
                                ),
                      ),
                      Text(
                        'Periodo: ${report.periodo}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Chip(
              label: Text(vm.getProductivityLabel()),
              backgroundColor: AppColors.secondary.withValues(alpha: 0.12),
              labelStyle: const TextStyle(
                color: AppColors.secondary,
                fontWeight: FontWeight.w700,
              ),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}

class _IndicatorsGrid extends StatelessWidget {
  const _IndicatorsGrid({required this.vm, required this.currency});

  final ReportesViewModel vm;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final report = vm.report!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Indicadores operativos',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.purpleSupport,
              ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.45,
          children: [
            _IndicatorCard(
              label: 'Cobertura visitas',
              value: '${vm.getCoveragePercentage().toStringAsFixed(0)}%',
              subtitle:
                  '${report.visitasRealizadas}/${report.visitasAsignadas}',
              color: AppColors.secondary,
            ),
            _IndicatorCard(
              label: 'Solicitudes enviadas',
              value: '${report.solicitudesEnviadas}',
              color: AppColors.gestionRenovacion,
            ),
            _IndicatorCard(
              label: 'Aprobadas',
              value: '${report.solicitudesAprobadas}',
              color: AppColors.semaforoNormal,
            ),
            _IndicatorCard(
              label: 'Desembolsadas',
              value: '${report.solicitudesDesembolsadas}',
              color: AppColors.gestionAmpliacion,
            ),
            _IndicatorCard(
              label: 'Monto aprobado',
              value: currency.format(report.montoAprobado),
              color: AppColors.purpleSupport,
            ),
            _IndicatorCard(
              label: 'Clientes en mora',
              value: '${report.clientesEnMora}',
              color: AppColors.gestionRecuperacionMora,
            ),
            _IndicatorCard(
              label: 'Monto vencido',
              value: currency.format(report.montoVencido),
              color: AppColors.mora60plus,
            ),
            _IndicatorCard(
              label: 'Gestiones cobranza',
              value: '${report.gestionesCobranza}',
              color: AppColors.softOrange,
            ),
          ],
        ),
      ],
    );
  }
}

class _IndicatorCard extends StatelessWidget {
  const _IndicatorCard({
    required this.label,
    required this.value,
    required this.color,
    this.subtitle,
  });

  final String label;
  final String value;
  final Color color;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressSection extends StatelessWidget {
  const _ProgressSection({required this.vm});

  final ReportesViewModel vm;

  @override
  Widget build(BuildContext context) {
    final coverage = vm.getCoveragePercentage() / 100;
    final approval = vm.getApprovalPercentage() / 100;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Avance del periodo',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 16),
            _ProgressRow(
              label: 'Cobertura de visitas',
              valueLabel: '${vm.getCoveragePercentage().toStringAsFixed(0)}%',
              progress: coverage,
              color: AppColors.secondary,
            ),
            const SizedBox(height: 16),
            _ProgressRow(
              label: 'Tasa de aprobación',
              valueLabel: '${vm.getApprovalPercentage().toStringAsFixed(0)}%',
              progress: approval,
              color: AppColors.gestionAmpliacion,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.label,
    required this.valueLabel,
    required this.progress,
    required this.color,
  });

  final String label;
  final String valueLabel;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            Text(
              valueLabel,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress.clamp(0, 1),
            minHeight: 10,
            backgroundColor: color.withValues(alpha: 0.12),
            color: color,
          ),
        ),
      ],
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.item,
    required this.dateTimeFormat,
  });

  final ReportActivityItem item;
  final DateFormat dateTimeFormat;

  @override
  Widget build(BuildContext context) {
    final typeColor = _activityColor(item.tipo);

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: typeColor.withValues(alpha: 0.12),
          child: Icon(_activityIcon(item.tipo), color: typeColor, size: 22),
        ),
        title: Text(
          item.titulo,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${item.descripcion}\n${dateTimeFormat.format(item.fecha)}',
        ),
        isThreeLine: true,
        trailing: Chip(
          label: Text(
            item.tipo.label,
            style: TextStyle(fontSize: 10, color: typeColor),
          ),
          backgroundColor: typeColor.withValues(alpha: 0.1),
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }

  static IconData _activityIcon(ReportActivityType type) => switch (type) {
        ReportActivityType.visita => Icons.check_circle_outline,
        ReportActivityType.solicitud => Icons.send_rounded,
        ReportActivityType.cobranza => Icons.payments_outlined,
        ReportActivityType.desembolso => Icons.account_balance_wallet_outlined,
        ReportActivityType.alerta => Icons.notifications_active_outlined,
      };

  static Color _activityColor(ReportActivityType type) => switch (type) {
        ReportActivityType.visita => AppColors.statusVisited,
        ReportActivityType.solicitud => AppColors.gestionRenovacion,
        ReportActivityType.cobranza => AppColors.softOrange,
        ReportActivityType.desembolso => AppColors.gestionAmpliacion,
        ReportActivityType.alerta => AppColors.gestionRecuperacionMora,
      };
}
