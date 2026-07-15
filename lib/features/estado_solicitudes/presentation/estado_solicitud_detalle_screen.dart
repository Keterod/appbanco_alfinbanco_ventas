// ignore_for_file: unused_element

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

  Future<void> _aprobar() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar aprobación'),
        content: Text(
          '¿Está seguro de aprobar la solicitud '
          '${_vm.request?.numeroExpediente ?? ''} por '
          '${_currency.format(_vm.request?.montoAprobado ?? _vm.request?.montoSolicitado ?? 0)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Aprobar'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final ok = await _vm.aprobar();
    if (!mounted) return;

    _mostrarResultado(ok, 'aprobada');
    if (ok && mounted) Navigator.pop(context, true);
  }

  Future<void> _condicionar() async {
    final montoSolicitado = _vm.request?.montoSolicitado ?? 0;
    final montoRecomendado = _vm.montoRecomendado;
    final montoController = TextEditingController(
      text: montoRecomendado > 0 ? montoRecomendado.toStringAsFixed(0) : '',
    );
    final condController = TextEditingController();
    String? validationError;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Condicionar solicitud'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _DetailRow('Monto solicitado', _currency.format(montoSolicitado)),
                _DetailRow(
                  'Monto recomendado',
                  _currency.format(montoRecomendado),
                ),
                const SizedBox(height: 12),
                if (validationError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      validationError!,
                      style: TextStyle(
                        color: AppColors.gestionRecuperacionMora,
                        fontSize: 13,
                      ),
                    ),
                  ),
                TextField(
                  controller: montoController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Monto aprobado',
                    prefixText: 'S/ ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: condController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Condición',
                    hintText: 'Describa la condición...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final montoText = montoController.text.trim();
                final monto = double.tryParse(montoText);
                final condicion = condController.text.trim();

                if (monto == null || monto <= 0) {
                  setDialogState(() => validationError = 'El monto aprobado debe ser mayor a 0.');
                  return;
                }
                if (monto >= montoSolicitado) {
                  setDialogState(
                    () => validationError = 'Para condicionar, el monto aprobado debe ser menor al solicitado.',
                  );
                  return;
                }
                if (condicion.isEmpty) {
                  setDialogState(() => validationError = 'La observación no puede estar vacía.');
                  return;
                }

                Navigator.pop(ctx, {'monto': monto, 'condicion': condicion});
              },
              child: const Text('Confirmar condición'),
            ),
          ],
        ),
      ),
    );

    if (result == null || !mounted) return;

    final ok = await _vm.condicionar(
      montoAprobado: result['monto'] as double,
      condicion: result['condicion'] as String,
    );
    if (!mounted) return;

    _mostrarResultado(ok, 'condicionada');
    if (ok && mounted) Navigator.pop(context, true);
  }

  Future<void> _rechazar() async {
    final controller = TextEditingController();
    final motivo = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rechazar solicitud'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Describa el motivo del rechazo...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );

    if (motivo == null || motivo.trim().isEmpty || !mounted) return;

    final ok = await _vm.rechazar(motivo.trim());
    if (!mounted) return;

    _mostrarResultado(ok, 'rechazada');
  }

  Future<void> _desembolsar() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar desembolso'),
        content: Text(
          '¿Está seguro de desembolsar la solicitud '
          '${_vm.request?.numeroExpediente ?? ''} por '
          '${_currency.format(_vm.request?.montoAprobado ?? _vm.request?.montoSolicitado ?? 0)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Desembolsar'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final ok = await _vm.desembolsar();
    if (!mounted) return;

    _mostrarResultado(ok, 'desembolsada');
    if (ok && mounted) Navigator.pop(context, true);
  }

  Future<void> _reclamarSolicitud() async {
    await _vm.reclamarSolicitud();
    if (!mounted) return;
    if (_vm.errorMessage != null) {
      _mostrarResultado(false, 'reclamar');
    } else {
      _mostrarResultado(true, 'reclamada');
    }
  }

  Future<void> _enviarAEvaluacion() async {
    final controller = TextEditingController(
      text: 'Expediente validado por asesor y listo para evaluación.',
    );
    final observacion = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enviar a evaluación'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Observación del asesor',
            hintText: 'Describa el estado del expediente...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );

    if (observacion == null || observacion.trim().isEmpty || !mounted) return;

    final ok = await _vm.enviarAEvaluacion(observacion.trim());
    if (!mounted) return;

    _mostrarResultado(ok, 'enviada a evaluación');
    if (ok && mounted) Navigator.pop(context, true);
  }

  void _mostrarResultado(bool ok, String accion) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Solicitud $accion correctamente.'
              : _vm.errorMessage ?? 'Error al $accion.',
        ),
        backgroundColor: ok ? AppColors.semaforoNormal : AppColors.gestionRecuperacionMora,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  bool get _asignadoAOtroAsesor =>
      _vm.request?.asesorId != null && _vm.request?.asesorId != _vm.asesorId;

  Widget _buildBottomBar() {
    if (_vm.request == null) return const SizedBox.shrink();

    if (_asignadoAOtroAsesor) {
      return _ActionBar(
        onCompartir: _compartirEstado,
        onNota: _agregarNota,
      );
    }

    final esDueno = _vm.request!.asesorId == _vm.asesorId;
    final estadolibre = _vm.request!.asesorId == null;
    final puedeEnviar = esDueno || estadolibre;

    if (puedeEnviar && _vm.request!.estado == RequestStatus.enviada) {
      final cargando = _vm.isEnviando;
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
          child: ElevatedButton.icon(
            onPressed: cargando ? null : _enviarAEvaluacion,
            icon: cargando
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                  )
                : const Icon(Icons.send_outlined),
            label: Text(
              cargando ? 'Enviando…' : 'Marcar listo para evaluación',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      );
    }

    return _ActionBar(
      onCompartir: _compartirEstado,
      onNota: _agregarNota,
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
          bottomNavigationBar: _buildBottomBar(),
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
                const SizedBox(height: 12),
                _PreEvalCard(rawData: r.rawData, currency: _currency),
                const SizedBox(height: 12),
                _AlertBox(
                  title: 'Comité web',
                  text: 'Este expediente será evaluado por el comité en el Front Core Web.',
                  color: AppColors.purpleSupport,
                ),
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
        if (r.asesorId == null) ...[
          const SizedBox(height: 12),
          _AlertBox(
            title: 'Sin asesor asignado',
            text: 'Esta solicitud aún no tiene asesor asignado. Reclámala para gestionarla.',
            color: AppColors.semaforoCpp,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _vm.isProcesando ? null : _reclamarSolicitud,
              icon: _vm.isProcesando
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.person_add_alt_1),
              label: const Text('Reclamar solicitud'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
        if (r.asesorId != null && r.asesorId != _vm.asesorId) ...[
          const SizedBox(height: 12),
          _AlertBox(
            title: 'Asignada a otro asesor',
            text: 'Esta solicitud ya fue asignada a otro asesor.',
            color: AppColors.gestionRecuperacionMora,
          ),
        ],
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

class _PreEvalCard extends StatelessWidget {
  const _PreEvalCard({required this.rawData, required this.currency});

  final Map<String, dynamic> rawData;
  final NumberFormat currency;

  String? _str(String key) => rawData[key]?.toString();
  double? _num(String key) {
    final v = rawData[key];
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  @override
  Widget build(BuildContext context) {
    final score = _num('score_pre_evaluacion');
    final elegibilidad = _str('elegibilidad');
    final riesgo = _str('riesgo_asignado');
    final ratio = _num('ratio_capacidad_pago');
    final motivo = _str('motivo_pre_evaluacion');

    if (score == null && elegibilidad == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preevaluación',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.purpleSupport,
                ),
          ),
          const SizedBox(height: 8),
          if (score != null) _row('Score', score.toStringAsFixed(0)),
          if (elegibilidad != null) _row('Elegibilidad', elegibilidad),
          if (riesgo != null) _row('Riesgo', riesgo),
          if (ratio != null) _row('Ratio capacidad', ratio.toStringAsFixed(4)),
          if (motivo != null) _row('Motivo', motivo),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
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
