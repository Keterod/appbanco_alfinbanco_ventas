import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../shared/widgets/oficial_drawer.dart';
import '../domain/credit_request_model.dart';
import 'solicitud_credito_viewmodel.dart';

/// Wizard de nueva solicitud de crédito (HU-V04).
class SolicitudCreditoScreen extends StatefulWidget {
  const SolicitudCreditoScreen({super.key, this.clientId});

  final String? clientId;

  @override
  State<SolicitudCreditoScreen> createState() => _SolicitudCreditoScreenState();
}

class _SolicitudCreditoScreenState extends State<SolicitudCreditoScreen> {
  late final SolicitudCreditoViewModel _vm;
  final _currencyFormat = NumberFormat.currency(
    locale: 'es_PE',
    symbol: 'S/',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    _vm = SolicitudCreditoViewModel();
    _vm.loadInitialData(widget.clientId);
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  void _showError(String? message) {
    if (message == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.gestionRecuperacionMora,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onSiguiente() {
    if (!_vm.nextStep()) _showError(_vm.errorMessage);
  }

  void _onAnterior() => _vm.previousStep();

  Future<void> _onEnviar() async {
    final ok = await _vm.submitRequest();
    if (!mounted) return;
    if (!ok) {
      _showError(_vm.errorMessage);
      return;
    }
    final expediente = _vm.numeroExpediente;
    if (expediente == null) {
      _showError('No se generó el número de expediente.');
      return;
    }

    if (!mounted) return;
    Navigator.pushReplacementNamed(
      context,
      AppRoutes.documentos,
      arguments: expediente,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Nueva solicitud de crédito'),
          ),
          drawer: const OficialDrawer(),
          body: _vm.isLoading && _vm.pasoActual == 0 && _vm.nombres.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    _StepIndicator(
                      pasoActual: _vm.pasoActual,
                      titulos: SolicitudCreditoViewModel.pasoTitulos,
                    ),
                    if (_vm.errorMessage != null && _vm.pasoActual < 3)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          _vm.errorMessage!,
                          style: TextStyle(
                            color: AppColors.gestionRecuperacionMora,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        children: [
                          if (_vm.pasoActual == 0)
                            _PasoSolicitante(vm: _vm)
                          else if (_vm.pasoActual == 1)
                            _PasoNegocio(vm: _vm)
                          else if (_vm.pasoActual == 2)
                            _PasoCredito(vm: _vm, currencyFormat: _currencyFormat)
                          else
                            _PasoConfirmacion(
                              vm: _vm,
                              currencyFormat: _currencyFormat,
                            ),
                        ],
                      ),
                    ),
                    _BottomBar(
                      pasoActual: _vm.pasoActual,
                      isLoading: _vm.isLoading,
                      onAnterior: _vm.pasoActual > 0 ? _onAnterior : null,
                      onSiguiente: _vm.pasoActual < 3 ? _onSiguiente : null,
                      onEnviar: _vm.pasoActual == 3 ? _onEnviar : null,
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.pasoActual, required this.titulos});

  final int pasoActual;
  final List<String> titulos;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: List.generate(titulos.length, (i) {
          final active = i == pasoActual;
          final done = i < pasoActual;
          final color = active
              ? AppColors.secondary
              : done
                  ? AppColors.semaforoNormal
                  : AppColors.textSecondary;
          return Expanded(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: color.withValues(alpha: 0.15),
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  titulos[i],
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.pasoActual,
    required this.isLoading,
    this.onAnterior,
    this.onSiguiente,
    this.onEnviar,
  });

  final int pasoActual;
  final bool isLoading;
  final VoidCallback? onAnterior;
  final VoidCallback? onSiguiente;
  final VoidCallback? onEnviar;

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
            if (onAnterior != null)
              Expanded(
                child: OutlinedButton(
                  onPressed: isLoading ? null : onAnterior,
                  child: const Text('Anterior'),
                ),
              ),
            if (onAnterior != null) const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: onEnviar != null
                  ? ElevatedButton(
                      onPressed: isLoading ? null : onEnviar,
                      child: isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white,
                              ),
                            )
                          : const Text('Enviar solicitud'),
                    )
                  : ElevatedButton(
                      onPressed: isLoading ? null : onSiguiente,
                      child: const Text('Siguiente'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.purpleSupport,
                  ),
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _PasoSolicitante extends StatelessWidget {
  const _PasoSolicitante({required this.vm});

  final SolicitudCreditoViewModel vm;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: '1. Datos del solicitante',
      child: Column(
        children: [
          TextFormField(
            initialValue: vm.nombres,
            decoration: const InputDecoration(labelText: 'Nombres *'),
            textCapitalization: TextCapitalization.words,
            onChanged: vm.setNombres,
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: vm.apellidos,
            decoration: const InputDecoration(labelText: 'Apellidos *'),
            textCapitalization: TextCapitalization.words,
            onChanged: vm.setApellidos,
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: vm.documento,
            decoration: const InputDecoration(labelText: 'DNI *'),
            keyboardType: TextInputType.number,
            maxLength: 8,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: vm.setDocumento,
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: vm.fechaNacimiento,
            decoration: const InputDecoration(
              labelText: 'Fecha de nacimiento',
              hintText: 'dd/mm/aaaa',
            ),
            onChanged: vm.setFechaNacimiento,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<EstadoCivil>(
            initialValue: vm.estadoCivil,
            decoration: const InputDecoration(labelText: 'Estado civil'),
            items: EstadoCivil.values
                .map((e) => DropdownMenuItem(value: e, child: Text(e.label)))
                .toList(),
            onChanged: vm.setEstadoCivil,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<GradoInstruccion>(
            initialValue: vm.gradoInstruccion,
            decoration: const InputDecoration(labelText: 'Grado de instrucción'),
            items: GradoInstruccion.values
                .map((e) => DropdownMenuItem(value: e, child: Text(e.label)))
                .toList(),
            onChanged: vm.setGradoInstruccion,
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: vm.telefono,
            decoration: const InputDecoration(labelText: 'Teléfono *'),
            keyboardType: TextInputType.phone,
            maxLength: 9,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: vm.setTelefono,
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: vm.correo,
            decoration: const InputDecoration(labelText: 'Correo electrónico'),
            keyboardType: TextInputType.emailAddress,
            onChanged: vm.setCorreo,
          ),
        ],
      ),
    );
  }
}

class _PasoNegocio extends StatelessWidget {
  const _PasoNegocio({required this.vm});

  final SolicitudCreditoViewModel vm;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: '2. Datos del negocio',
      child: Column(
        children: [
          DropdownButtonFormField<TipoNegocio>(
            initialValue: vm.tipoNegocio,
            decoration: const InputDecoration(labelText: 'Tipo de negocio *'),
            items: TipoNegocio.values
                .map((e) => DropdownMenuItem(value: e, child: Text(e.label)))
                .toList(),
            onChanged: vm.setTipoNegocio,
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: vm.nombreNegocio,
            decoration: const InputDecoration(labelText: 'Nombre del negocio *'),
            onChanged: vm.setNombreNegocio,
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: vm.direccionNegocio,
            decoration: const InputDecoration(labelText: 'Dirección del negocio *'),
            maxLines: 2,
            onChanged: vm.setDireccionNegocio,
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: vm.antiguedadNegocioMeses > 0
                ? '${vm.antiguedadNegocioMeses}'
                : '',
            decoration: const InputDecoration(
              labelText: 'Antigüedad del negocio (meses) *',
              hintText: 'Mínimo 6',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (v) =>
                vm.setAntiguedadNegocioMeses(int.tryParse(v) ?? 0),
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue:
                vm.ingresosMensuales > 0 ? '${vm.ingresosMensuales}' : '',
            decoration: const InputDecoration(labelText: 'Ingresos mensuales *'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (v) =>
                vm.setIngresosMensuales(double.tryParse(v) ?? 0),
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: vm.gastosMensuales > 0 ? '${vm.gastosMensuales}' : '',
            decoration: const InputDecoration(labelText: 'Gastos mensuales'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (v) => vm.setGastosMensuales(double.tryParse(v) ?? 0),
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue:
                vm.patrimonioEstimado > 0 ? '${vm.patrimonioEstimado}' : '',
            decoration: const InputDecoration(labelText: 'Patrimonio estimado'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (v) =>
                vm.setPatrimonioEstimado(double.tryParse(v) ?? 0),
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: vm.destinoCredito,
            decoration: const InputDecoration(labelText: 'Destino del crédito *'),
            onChanged: vm.setDestinoCredito,
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: vm.actividadEconomica,
            decoration: const InputDecoration(labelText: 'Actividad económica'),
            onChanged: vm.setActividadEconomica,
          ),
        ],
      ),
    );
  }
}

class _PasoCredito extends StatelessWidget {
  const _PasoCredito({required this.vm, required this.currencyFormat});

  final SolicitudCreditoViewModel vm;
  final NumberFormat currencyFormat;

  @override
  Widget build(BuildContext context) {
    final symbol = vm.moneda == Moneda.usd ? 'US\$' : 'S/';

    return Column(
      children: [
        _SectionCard(
          title: '3. Condiciones del crédito',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Monto solicitado: ${currencyFormat.format(vm.montoSolicitado)}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Slider(
                value: vm.montoSolicitado.clamp(500, 150000),
                min: 500,
                max: 150000,
                divisions: 299,
                label: '$symbol ${vm.montoSolicitado.toStringAsFixed(0)}',
                onChanged: vm.setMontoSolicitado,
              ),
              TextFormField(
                initialValue: vm.montoSolicitado.toStringAsFixed(0),
                decoration: InputDecoration(
                  labelText: 'Monto ($symbol) *',
                  hintText: '500 - 150000',
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) =>
                    vm.setMontoSolicitado(double.tryParse(v) ?? 500),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: plazosPermitidosMeses.contains(vm.plazoMeses)
                    ? vm.plazoMeses
                    : 12,
                decoration: const InputDecoration(labelText: 'Plazo (meses) *'),
                items: plazosPermitidosMeses
                    .map((p) => DropdownMenuItem(
                          value: p,
                          child: Text('$p meses'),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) vm.setPlazoMeses(v);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Moneda>(
                initialValue: vm.moneda,
                decoration: const InputDecoration(labelText: 'Moneda *'),
                items: Moneda.values
                    .map((e) =>
                        DropdownMenuItem(value: e, child: Text(e.label)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) vm.setMoneda(v);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<TipoCuota>(
                initialValue: vm.tipoCuota,
                decoration: const InputDecoration(labelText: 'Tipo de cuota *'),
                items: TipoCuota.values
                    .map((e) =>
                        DropdownMenuItem(value: e, child: Text(e.label)))
                    .toList(),
                onChanged: vm.setTipoCuota,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Garantia>(
                initialValue: vm.garantia,
                decoration: const InputDecoration(labelText: 'Garantía *'),
                items: Garantia.values
                    .map((e) =>
                        DropdownMenuItem(value: e, child: Text(e.label)))
                    .toList(),
                onChanged: vm.setGarantia,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          color: AppColors.purpleSupport.withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.calculate_outlined, color: AppColors.secondary),
                    const SizedBox(width: 8),
                    Text(
                      'Simulación',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _SimRow(
                  label: 'Cuota estimada',
                  value: currencyFormat.format(vm.cuotaEstimada),
                  highlight: true,
                ),
                _SimRow(
                  label: 'Total a pagar',
                  value: currencyFormat.format(vm.totalAPagar),
                ),
                _SimRow(
                  label: 'Costo financiero',
                  value: currencyFormat.format(vm.costoFinanciero),
                ),
                _SimRow(
                  label: 'TEA referencial',
                  value: '${(vm.teaReferencial * 100).toStringAsFixed(1)}%',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SimRow extends StatelessWidget {
  const _SimRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
              color: highlight ? AppColors.secondary : AppColors.darkText,
            ),
          ),
        ],
      ),
    );
  }
}

class _PasoConfirmacion extends StatelessWidget {
  const _PasoConfirmacion({required this.vm, required this.currencyFormat});

  final SolicitudCreditoViewModel vm;
  final NumberFormat currencyFormat;

  @override
  Widget build(BuildContext context) {
    final model = vm.buildModel();

    return Column(
      children: [
        Card(
          color: AppColors.softOrange.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: AppColors.softOrange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Verifique la consulta de buró del cliente antes de enviar la solicitud.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: '4. Resumen y confirmación',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ResumenLine('Cliente', model.nombreCompleto),
              _ResumenLine('DNI', model.documento),
              _ResumenLine('Teléfono', model.telefono),
              _ResumenLine('Negocio', model.nombreNegocio),
              _ResumenLine(
                'Tipo negocio',
                model.tipoNegocio?.label ?? '—',
              ),
              _ResumenLine(
                'Monto',
                currencyFormat.format(model.montoSolicitado),
              ),
              _ResumenLine('Plazo', '${model.plazoMeses} meses'),
              _ResumenLine('Moneda', model.moneda.label),
              _ResumenLine(
                'Cuota estimada',
                currencyFormat.format(model.cuotaEstimada),
              ),
              _ResumenLine(
                'Garantía',
                model.garantia?.label ?? '—',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: vm.aceptaDeclaracion,
                  onChanged: (v) => vm.setAceptaDeclaracion(v ?? false),
                  title: const Text(
                    'Declaro que la información proporcionada es veraz y '
                    'autorizo el tratamiento de datos para evaluación crediticia.',
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: 8),
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
                if (vm.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    vm.errorMessage!,
                    style: const TextStyle(
                      color: AppColors.gestionRecuperacionMora,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ResumenLine extends StatelessWidget {
  const _ResumenLine(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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
