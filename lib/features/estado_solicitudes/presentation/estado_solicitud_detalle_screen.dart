import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../domain/request_status_model.dart';
import 'estado_solicitud_detalle_viewmodel.dart';

/// Detalle y línea de tiempo de solicitud (HU-V07).
class EstadoSolicitudDetalleScreen extends StatefulWidget {
  const EstadoSolicitudDetalleScreen({
    super.key,
    this.requestId,
    this.numeroExpediente,
  });

  final String? requestId;
  final String? numeroExpediente;

  @override
  State<EstadoSolicitudDetalleScreen> createState() =>
      _EstadoSolicitudDetalleScreenState();
}

class _EstadoSolicitudDetalleScreenState
    extends State<EstadoSolicitudDetalleScreen> {
  late final EstadoSolicitudDetalleViewModel _vm;
  final _currency = NumberFormat.currency(
    locale: 'es_PE',
    symbol: 'S/',
    decimalDigits: 2,
  );
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _vm = EstadoSolicitudDetalleViewModel();
    _vm.loadRequest(
      requestId: widget.requestId,
      numeroExpediente: widget.numeroExpediente,
    );
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  void _compartirEstado() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exportación PDF — función en siguiente fase'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _agregarNota() async {
    final controller = TextEditingController(text: _vm.notaInterna);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nota interna'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Escriba una observación para seguimiento...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (result == null || !mounted) return;
    _vm.guardarNotaInterna(result);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.trim().isEmpty
              ? 'Nota eliminada'
              : 'Nota interna guardada localmente',
        ),
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
            title: const Text('Detalle de solicitud'),
          ),
          body: _buildBody(),
          bottomNavigationBar: _vm.request != null
              ? _ActionBar(
                  onCompartir: _compartirEstado,
                  onNota: _agregarNota,
                )
              : null,
        );
      },
    );
  }

  Widget _buildBody() {
    if (_vm.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_vm.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_vm.errorMessage!, textAlign: TextAlign.center),
        ),
      );
    }

    final r = _vm.request!;
    final statusColor = RequestStatusUi.color(r.estado);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.clienteNombre,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                _DetailRow('Expediente', r.numeroExpediente),
                _DetailRow('Documento', r.documento),
                _DetailRow(
                  'Monto solicitado',
                  _currency.format(r.montoSolicitado),
                ),
                if (r.montoAprobado != null)
                  _DetailRow(
                    'Monto aprobado',
                    _currency.format(r.montoAprobado),
                  ),
                _DetailRow('Analista', r.analistaAsignado),
                const SizedBox(height: 8),
                Chip(
                  label: Text(r.estado.label),
                  backgroundColor: statusColor.withValues(alpha: 0.12),
                  labelStyle: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (r.estado == RequestStatus.rechazada &&
                    r.motivoRechazo != null) ...[
                  const SizedBox(height: 12),
                  _AlertBox(
                    title: 'Motivo de rechazo',
                    text: r.motivoRechazo!,
                    color: AppColors.semaforoDudoso,
                  ),
                ],
                if (r.estado == RequestStatus.condicionada &&
                    r.condicionAdicional != null) ...[
                  const SizedBox(height: 12),
                  _AlertBox(
                    title: 'Condición adicional',
                    text: r.condicionAdicional!,
                    color: AppColors.semaforoCpp,
                  ),
                ],
                if (_vm.notaInterna.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _AlertBox(
                    title: 'Nota interna',
                    text: _vm.notaInterna,
                    color: AppColors.purpleSupport,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Línea de tiempo',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.purpleSupport,
              ),
        ),
        const SizedBox(height: 12),
        ...r.timeline.map(
          (item) => _TimelineTile(
            item: item,
            dateFormat: _dateFormat,
            isLast: item == r.timeline.last,
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertBox extends StatelessWidget {
  const _AlertBox({
    required this.title,
    required this.text,
    required this.color,
  });

  final String title;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.w700, color: color),
          ),
          const SizedBox(height: 4),
          Text(text),
        ],
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({
    required this.item,
    required this.dateFormat,
    required this.isLast,
  });

  final RequestTimelineItem item;
  final DateFormat dateFormat;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = item.completado
        ? RequestStatusUi.color(item.estado)
        : AppColors.textSecondary;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Icon(
                  item.completado
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: color,
                  size: 22,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: item.completado
                          ? color.withValues(alpha: 0.5)
                          : AppColors.divider,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Card(
                color: item.completado
                    ? AppColors.white
                    : AppColors.lightBackground,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.titulo,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: item.completado
                                  ? AppColors.darkText
                                  : AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.descripcion,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${item.responsable} · ${dateFormat.format(item.fechaHora)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.onCompartir, required this.onNota});

  final VoidCallback onCompartir;
  final VoidCallback onNota;

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
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onNota,
                icon: const Icon(Icons.note_alt_outlined),
                label: const Text('Agregar nota'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onCompartir,
                icon: const Icon(Icons.share_outlined),
                label: const Text('Compartir'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Colores por estado (compartido con tablero).
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
