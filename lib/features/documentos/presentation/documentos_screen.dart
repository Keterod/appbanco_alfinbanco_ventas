import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../domain/document_model.dart';
import 'documentos_viewmodel.dart';

/// Pantalla de captura y revisión de documentos (HU-V05).
class DocumentosScreen extends StatefulWidget {
  const DocumentosScreen({super.key, this.solicitudId});

  final String? solicitudId;

  @override
  State<DocumentosScreen> createState() => _DocumentosScreenState();
}

class _DocumentosScreenState extends State<DocumentosScreen> {
  late final DocumentosViewModel _vm;
  static final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _vm = DocumentosViewModel();
    final id = widget.solicitudId ?? DocumentosViewModel.solicitudDemoDefault;
    _vm.loadDocuments(id);

    if (widget.solicitudId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Solicitud ${widget.solicitudId} registrada. '
              'Complete los documentos obligatorios.',
            ),
            backgroundColor: AppColors.semaforoNormal,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  void _showSnack(String? message, {bool error = false}) {
    if (message == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            error ? AppColors.gestionRecuperacionMora : AppColors.semaforoNormal,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onContinuar() {
    if (!_vm.allRequiredReady()) return;
    Navigator.pushNamed(
      context,
      AppRoutes.transmision,
      arguments: _vm.solicitudId,
    );
  }

  void _verDocumento(DocumentModel doc) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(doc.nombreVisible),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.lightBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.image_outlined,
                      size: 72,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Vista previa simulada',
                      style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (doc.imagePathSimulado != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        doc.imagePathSimulado!,
                        textAlign: TextAlign.center,
                        style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (doc.tamanioKb != null)
                _DialogInfoRow('Tamaño', '${doc.tamanioKb} KB'),
              if (doc.nitidezScore != null)
                _DialogInfoRow('Nitidez', '${doc.nitidezScore!.toStringAsFixed(1)}%'),
              if (doc.fechaCaptura != null)
                _DialogInfoRow(
                  'Captura',
                  _dateFormat.format(doc.fechaCaptura!),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
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
            title: const Text('Documentos de solicitud'),
          ),
          body: _vm.isLoading && _vm.documentos.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        children: [
                          _HeaderSection(vm: _vm),
                          if (_vm.successMessage != null) ...[
                            const SizedBox(height: 8),
                            _MessageBanner(
                              text: _vm.successMessage!,
                              color: AppColors.semaforoNormal,
                            ),
                          ],
                          const SizedBox(height: 16),
                          ..._vm.documentos.map(
                            (d) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _DocumentCard(
                                doc: d,
                                isBusy: _vm.isLoading,
                                onCapturar: () async {
                                  await _vm.captureDocument(d.id);
                                  _showSnack(_vm.successMessage);
                                  if (_vm.errorMessage != null) {
                                    _showSnack(_vm.errorMessage, error: true);
                                  }
                                },
                                onRetomar: () async {
                                  await _vm.retakeDocument(d.id);
                                  _showSnack(_vm.successMessage);
                                },
                                onEliminar: () async {
                                  await _vm.deleteDocument(d.id);
                                  _showSnack(_vm.successMessage);
                                },
                                onVer: () => _verDocumento(d),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _BottomBar(
                      enabled: _vm.allRequiredReady(),
                      onContinuar: _onContinuar,
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection({required this.vm});

  final DocumentosViewModel vm;

  @override
  Widget build(BuildContext context) {
    final completo = vm.allRequiredReady();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.folder_copy_outlined, color: AppColors.secondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Expediente: ${vm.solicitudId}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.purpleSupport,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${vm.readyCount()} de ${vm.requiredCount()} obligatorios listos',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: vm.progressRequired,
                minHeight: 10,
                backgroundColor: AppColors.divider,
                color: completo
                    ? AppColors.semaforoNormal
                    : AppColors.secondary,
              ),
            ),
            const SizedBox(height: 12),
            if (completo)
              Chip(
                avatar: const Icon(
                  Icons.check_circle,
                  color: AppColors.semaforoNormal,
                  size: 18,
                ),
                label: const Text('Completo'),
                backgroundColor:
                    AppColors.semaforoNormal.withValues(alpha: 0.12),
              )
            else
              Chip(
                avatar: Icon(
                  Icons.pending_actions,
                  color: AppColors.softOrange,
                  size: 18,
                ),
                label: Text(
                  'Faltan ${vm.requiredCount() - vm.readyCount()} obligatorios',
                ),
                backgroundColor: AppColors.softOrange.withValues(alpha: 0.1),
              ),
          ],
        ),
      ),
    );
  }
}

class _MessageBanner extends StatelessWidget {
  const _MessageBanner({required this.text, required this.color});

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
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    required this.doc,
    required this.isBusy,
    required this.onCapturar,
    required this.onRetomar,
    required this.onEliminar,
    required this.onVer,
  });

  final DocumentModel doc;
  final bool isBusy;
  final VoidCallback onCapturar;
  final VoidCallback onRetomar;
  final VoidCallback onEliminar;
  final VoidCallback onVer;

  Color _estadoColor(EstadoDocumento estado) => switch (estado) {
        EstadoDocumento.pendiente => AppColors.statusPending,
        EstadoDocumento.listo => AppColors.semaforoNormal,
        EstadoDocumento.rechazado => AppColors.semaforoDudoso,
      };

  @override
  Widget build(BuildContext context) {
    final estadoColor = _estadoColor(doc.estado);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: estadoColor.withValues(alpha: 0.15),
                  child: Icon(
                    doc.isListo
                        ? Icons.check_circle_outline
                        : Icons.description_outlined,
                    color: estadoColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc.nombreVisible,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          Chip(
                            label: Text(
                              doc.obligatorio ? 'Obligatorio' : 'Opcional',
                              style: const TextStyle(fontSize: 11),
                            ),
                            visualDensity: VisualDensity.compact,
                            backgroundColor: doc.obligatorio
                                ? AppColors.softOrange.withValues(alpha: 0.12)
                                : AppColors.lightBackground,
                          ),
                          Chip(
                            label: Text(
                              doc.estado.label,
                              style: const TextStyle(fontSize: 11),
                            ),
                            visualDensity: VisualDensity.compact,
                            backgroundColor:
                                estadoColor.withValues(alpha: 0.12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (doc.isListo) ...[
              const SizedBox(height: 10),
              if (doc.tamanioKb != null)
                _MetaLine(Icons.sd_storage_outlined, '${doc.tamanioKb} KB'),
              if (doc.nitidezScore != null)
                _MetaLine(
                  Icons.blur_on_outlined,
                  'Nitidez ${doc.nitidezScore!.toStringAsFixed(1)}%',
                ),
              if (doc.fechaCaptura != null)
                _MetaLine(
                  Icons.schedule_outlined,
                  dateFormat.format(doc.fechaCaptura!),
                ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (!doc.isListo)
                  FilledButton.icon(
                    onPressed: isBusy ? null : onCapturar,
                    icon: const Icon(Icons.camera_alt_outlined, size: 18),
                    label: const Text('Capturar'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  )
                else ...[
                  OutlinedButton.icon(
                    onPressed: isBusy ? null : onRetomar,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Retomar'),
                  ),
                  OutlinedButton.icon(
                    onPressed: isBusy ? null : onEliminar,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Eliminar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.gestionRecuperacionMora,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: onVer,
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: const Text('Ver'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.darkText.withValues(alpha: 0.8),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogInfoRow extends StatelessWidget {
  const _DialogInfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(value),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.enabled, required this.onContinuar});

  final bool enabled;
  final VoidCallback onContinuar;

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
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: enabled ? onContinuar : null,
            icon: const Icon(Icons.send_outlined),
            label: const Text('Continuar'),
          ),
        ),
      ),
    );
  }
}
