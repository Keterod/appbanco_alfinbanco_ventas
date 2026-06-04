import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../domain/transmission_model.dart';
import 'transmision_viewmodel.dart';

/// Pantalla de transmisión electrónica al comité (HU-V06).
class TransmisionScreen extends StatefulWidget {
  const TransmisionScreen({super.key, this.solicitudId});

  final String? solicitudId;

  @override
  State<TransmisionScreen> createState() => _TransmisionScreenState();
}

class _TransmisionScreenState extends State<TransmisionScreen> {
  late final TransmisionViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = TransmisionViewModel();
    final id = widget.solicitudId ?? TransmisionViewModel.solicitudDemoDefault;
    _vm.loadTransmission(id);
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  Future<void> _onIniciarTransmision() async {
    await _vm.startTransmission();
  }

  Future<void> _onReintentar() async {
    await _vm.retryTransmission();
  }

  void _onVerEstadoSolicitud() {
    final reference =
        _vm.numeroExpedienteOficial ?? _vm.solicitudId;
    Navigator.pushNamed(
      context,
      AppRoutes.estadoSolicitudes,
      arguments: reference,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Transmisión electrónica'),
          ),
          body: _vm.isLoading && _vm.pasos.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        children: [
                          _SummaryCard(vm: _vm),
                          if (_vm.isCompletado) ...[
                            const SizedBox(height: 16),
                            _ConfirmationCard(vm: _vm),
                          ],
                          const SizedBox(height: 16),
                          Text(
                            'Proceso de envío',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.purpleSupport,
                                ),
                          ),
                          const SizedBox(height: 10),
                          ..._vm.pasos.map(
                            (p) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _StepCard(
                                step: p,
                                isActive: _vm.pasos.indexOf(p) == _vm.pasoActual &&
                                    _vm.isTransmitting,
                              ),
                            ),
                          ),
                          if (_vm.errorMessage != null) ...[
                            const SizedBox(height: 8),
                            _ErrorBanner(message: _vm.errorMessage!),
                          ],
                        ],
                      ),
                    ),
                    _BottomBar(
                      vm: _vm,
                      onIniciar: _onIniciarTransmision,
                      onReintentar: _onReintentar,
                      onVerEstado: _onVerEstadoSolicitud,
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

  final TransmisionViewModel vm;

  Color _statusColor(TransmissionStatus status) => switch (status) {
        TransmissionStatus.pendiente => AppColors.statusPending,
        TransmissionStatus.transmitiendo => AppColors.secondary,
        TransmissionStatus.completado => AppColors.semaforoNormal,
        TransmissionStatus.error => AppColors.semaforoDudoso,
      };

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(vm.estadoGeneral);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud_upload_outlined, color: AppColors.secondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Solicitud: ${vm.solicitudId}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Estado general: ',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Chip(
                  label: Text(vm.estadoGeneral.label),
                  backgroundColor: color.withValues(alpha: 0.12),
                  labelStyle: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            if (vm.isCompletado) ...[
              const SizedBox(height: 12),
              _InfoLine(
                icon: Icons.folder_special_outlined,
                label: 'Expediente oficial',
                value: vm.numeroExpedienteOficial ?? '—',
              ),
              _InfoLine(
                icon: Icons.schedule_outlined,
                label: 'Tiempo estimado de respuesta',
                value: vm.tiempoEstimadoRespuesta ?? '—',
              ),
            ],
            if (vm.isTransmitting) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }
}

class _ConfirmationCard extends StatelessWidget {
  const _ConfirmationCard({required this.vm});

  final TransmisionViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.semaforoNormal.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.semaforoNormal),
                const SizedBox(width: 8),
                Text(
                  'Transmisión completada',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.semaforoNormal,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              vm.mensajeFinal ?? '',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (vm.fechaEnvio != null) ...[
              const SizedBox(height: 8),
              Text(
                'Enviado: ${_dateFormatStatic.format(vm.fechaEnvio!)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
            if (vm.numeroExpedienteOficial != null) ...[
              const SizedBox(height: 8),
              Text(
                'N° expediente: ${vm.numeroExpedienteOficial}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
            const SizedBox(height: 10),
            Chip(
              avatar: Icon(
                Icons.hourglass_top,
                size: 18,
                color: AppColors.purpleSupport,
              ),
              label: const Text('En evaluación'),
              backgroundColor: AppColors.purpleSupport.withValues(alpha: 0.1),
            ),
          ],
        ),
      ),
    );
  }

  static final _dateFormatStatic = DateFormat('dd/MM/yyyy HH:mm');
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.step, required this.isActive});

  final TransmissionStepModel step;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _iconForStatus(step.estado, isActive);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (step.estado == TransmissionStepStatus.enProceso && isActive)
              Padding(
                padding: const EdgeInsets.only(right: 12, top: 2),
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.secondary,
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(icon, color: color, size: 28),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.titulo,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    step.descripcion,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Chip(
                        label: Text(
                          step.estado.label,
                          style: const TextStyle(fontSize: 11),
                        ),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: color.withValues(alpha: 0.12),
                      ),
                    ],
                  ),
                  if (step.id == 'subiendo-documentos' &&
                      (step.estado == TransmissionStepStatus.enProceso ||
                          step.estado == TransmissionStepStatus.completado)) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: step.progreso.clamp(0, 1),
                        minHeight: 6,
                        backgroundColor: AppColors.divider,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(step.progreso * 100).toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  (IconData, Color) _iconForStatus(
    TransmissionStepStatus status,
    bool active,
  ) {
    return switch (status) {
      TransmissionStepStatus.pendiente => (
          Icons.radio_button_unchecked,
          AppColors.textSecondary,
        ),
      TransmissionStepStatus.enProceso => (
          Icons.autorenew,
          AppColors.secondary,
        ),
      TransmissionStepStatus.completado => (
          Icons.check_circle,
          AppColors.semaforoNormal,
        ),
      TransmissionStepStatus.error => (
          Icons.error_outline,
          AppColors.semaforoDudoso,
        ),
    };
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.softOrange),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.semaforoDudoso.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.semaforoDudoso.withValues(alpha: 0.4)),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: AppColors.semaforoDudoso,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.vm,
    required this.onIniciar,
    required this.onReintentar,
    required this.onVerEstado,
  });

  final TransmisionViewModel vm;
  final Future<void> Function() onIniciar;
  final Future<void> Function() onReintentar;
  final VoidCallback onVerEstado;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (vm.isError)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: vm.isTransmitting ? null : onReintentar,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ),
            if (vm.isError) const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: vm.isCompletado
                    ? onVerEstado
                    : vm.canStart
                        ? onIniciar
                        : null,
                icon: Icon(
                  vm.isCompletado
                      ? Icons.dashboard_outlined
                      : Icons.play_arrow_rounded,
                ),
                label: Text(
                  vm.isCompletado
                      ? 'Ver estado de solicitud'
                      : 'Iniciar transmisión',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
