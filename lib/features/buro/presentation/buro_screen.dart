import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../shared/widgets/oficial_drawer.dart';
import '../domain/buro_result_model.dart';
import 'buro_viewmodel.dart';

/// Pantalla de consulta de buró y listas (HU-V08).
class BuroScreen extends StatefulWidget {
  const BuroScreen({super.key, this.clientId});

  final String? clientId;

  @override
  State<BuroScreen> createState() => _BuroScreenState();
}

class _BuroScreenState extends State<BuroScreen> {
  late final BuroViewModel _vm;
  final _currency = NumberFormat.currency(
    locale: 'es_PE',
    symbol: 'S/',
    decimalDigits: 2,
  );
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _vm = BuroViewModel();
    _vm.loadClient(widget.clientId);
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  void _showSnack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            error ? AppColors.gestionRecuperacionMora : AppColors.semaforoNormal,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _onConsultar() async {
    await _vm.consultarBuro();
    if (_vm.errorMessage != null) {
      _showSnack(_vm.errorMessage!, error: true);
    } else if (_vm.successMessage != null) {
      _showSnack(_vm.successMessage!);
    }
  }

  void _onContinuarSolicitud() {
    final id = _vm.clientId ?? _vm.resultado?.clientId;
    if (id == null || id.isEmpty) {
      _showSnack(
        'Seleccione un cliente desde la cartera para continuar la solicitud.',
        error: true,
      );
      return;
    }
    Navigator.pushNamed(
      context,
      AppRoutes.solicitudCredito,
      arguments: id,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Consulta de buró'),
          ),
          drawer: const OficialDrawer(),
          body: _vm.isLoading && _vm.dniConsultado.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    _ClientCard(vm: _vm),
                    const SizedBox(height: 12),
                    _DniCard(vm: _vm),
                    const SizedBox(height: 12),
                    _ConsentCard(vm: _vm),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _vm.canConsult() ? _onConsultar : null,
                        icon: _vm.isLoading && _vm.dniConsultado.isNotEmpty
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.white,
                                ),
                              )
                            : const Icon(Icons.search_rounded),
                        label: const Text('Consultar buró y listas'),
                      ),
                    ),
                    if (_vm.tieneResultado && _vm.resultado != null) ...[
                      const SizedBox(height: 20),
                      _ResultSection(
                        result: _vm.resultado!,
                        currency: _currency,
                        dateFormat: _dateFormat,
                      ),
                      const SizedBox(height: 16),
                      if (_vm.puedeContinuar)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _onContinuarSolicitud,
                            icon: const Icon(Icons.arrow_forward_rounded),
                            label: const Text('Continuar solicitud'),
                          ),
                        ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _vm.limpiarResultado,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Nueva consulta'),
                        ),
                      ),
                    ],
                  ],
                ),
        );
      },
    );
  }
}

class _ClientCard extends StatelessWidget {
  const _ClientCard({required this.vm});

  final BuroViewModel vm;

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
                Icon(Icons.person_search, color: AppColors.secondary),
                const SizedBox(width: 8),
                Text(
                  'Cliente',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              vm.nombresCliente.isNotEmpty
                  ? vm.nombresCliente
                  : 'Ingrese DNI para identificar',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'DNI: ${vm.dniConsultado.isNotEmpty ? vm.dniConsultado : "—"}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Chip(
              avatar: Icon(Icons.location_on_outlined, size: 16, color: AppColors.softOrange),
              label: const Text('Verificación en campo'),
              backgroundColor: AppColors.softOrange.withValues(alpha: 0.1),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}

class _DniCard extends StatelessWidget {
  const _DniCard({required this.vm});

  final BuroViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextFormField(
          initialValue: vm.dniConsultado,
          decoration: const InputDecoration(
            labelText: 'DNI a consultar *',
            hintText: '8 dígitos',
            prefixIcon: Icon(Icons.badge_outlined),
          ),
          keyboardType: TextInputType.number,
          maxLength: 8,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: vm.setDni,
        ),
      ),
    );
  }
}

class _ConsentCard extends StatelessWidget {
  const _ConsentCard({required this.vm});

  final BuroViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Consentimiento informado',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.purpleSupport,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'El cliente autoriza a Banco Alfin a consultar su historial '
              'crediticio en centrales de riesgo y listas de restricción, '
              'exclusivamente para evaluación de una solicitud de crédito.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: vm.consentimientoAceptado,
              onChanged: (v) => vm.toggleConsentimiento(v ?? false),
              title: const Text('Cliente autoriza la consulta'),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            OutlinedButton.icon(
              onPressed: vm.firmaSimulada ? null : vm.registrarFirmaSimulada,
              icon: const Icon(Icons.draw_outlined),
              label: Text(
                vm.firmaSimulada
                    ? 'Firma ya registrada'
                    : 'Registrar firma simulada',
              ),
            ),
            if (vm.firmaSimulada) ...[
              const SizedBox(height: 8),
              Chip(
                avatar: const Icon(
                  Icons.verified_outlined,
                  size: 18,
                  color: AppColors.semaforoNormal,
                ),
                label: const Text('Firma registrada'),
                backgroundColor:
                    AppColors.semaforoNormal.withValues(alpha: 0.12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResultSection extends StatelessWidget {
  const _ResultSection({
    required this.result,
    required this.currency,
    required this.dateFormat,
  });

  final BuroResultModel result;
  final NumberFormat currency;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    final statusColor = BuroUi.statusColor(result.status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resultado de consulta',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.purpleSupport,
              ),
        ),
        const SizedBox(height: 10),
        Card(
          color: statusColor.withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.flag_circle, color: statusColor, size: 28),
                    const SizedBox(width: 10),
                    Text(
                      result.status.label,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: statusColor,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Semáforo SBS',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: CalificacionSbsBuro.values.map((c) {
                    final active = c == result.calificacionSbs;
                    final color = BuroUi.sbsColor(c);
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: active
                            ? color.withValues(alpha: 0.2)
                            : AppColors.lightBackground,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: active ? color : AppColors.divider,
                          width: active ? 2 : 1,
                        ),
                      ),
                      child: Text(
                        c.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              active ? FontWeight.w800 : FontWeight.w500,
                          color: active ? color : AppColors.textSecondary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                _ResultRow('Entidades con deuda', '${result.entidadesConDeuda}'),
                _ResultRow(
                  'Deuda total',
                  currency.format(result.deudaTotalPen),
                ),
                _ResultRow(
                  'Mayor deuda',
                  currency.format(result.mayorDeuda),
                ),
                _ResultRow(
                  'Días mayor mora',
                  '${result.diasMayorMora}',
                ),
                const SizedBox(height: 10),
                Text(
                  result.recomendacion,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Consulta: ${dateFormat.format(result.fechaConsulta)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ),
        if (result.enListaNegra && result.motivoBloqueo != null) ...[
          const SizedBox(height: 12),
          Card(
            color: AppColors.semaforoDudoso.withValues(alpha: 0.08),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.block, color: AppColors.semaforoDudoso),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lista de restricción',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.semaforoDudoso,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(result.motivoBloqueo!),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

abstract final class BuroUi {
  static Color statusColor(BuroStatus status) => switch (status) {
        BuroStatus.apto => AppColors.semaforoNormal,
        BuroStatus.revisar => AppColors.semaforoCpp,
        BuroStatus.bloqueado => AppColors.semaforoDudoso,
      };

  static Color sbsColor(CalificacionSbsBuro sbs) => switch (sbs) {
        CalificacionSbsBuro.normal => AppColors.semaforoNormal,
        CalificacionSbsBuro.cpp => AppColors.semaforoCpp,
        CalificacionSbsBuro.deficiente => AppColors.semaforoDeficiente,
        CalificacionSbsBuro.dudoso => AppColors.semaforoDudoso,
        CalificacionSbsBuro.perdida => AppColors.semaforoPerdida,
      };
}
