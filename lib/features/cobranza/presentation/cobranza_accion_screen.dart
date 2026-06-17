import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../domain/collection_model.dart';
import 'cobranza_accion_viewmodel.dart';

/// Formulario de registro de gestión de cobranza (HU-V10).
class CobranzaAccionScreen extends StatefulWidget {
  const CobranzaAccionScreen({super.key, required this.overdueClientId});

  final String overdueClientId;

  @override
  State<CobranzaAccionScreen> createState() => _CobranzaAccionScreenState();
}

class _CobranzaAccionScreenState extends State<CobranzaAccionScreen> {
  late final CobranzaAccionViewModel _vm;
  final _currency = NumberFormat.currency(
    locale: 'es_PE',
    symbol: 'S/',
    decimalDigits: 2,
  );
  final _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _vm = CobranzaAccionViewModel(overdueClientId: widget.overdueClientId);
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  Future<void> _pickFechaCompromiso() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _vm.fechaCompromiso ?? now.add(const Duration(days: 3)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (picked != null) _vm.setFechaCompromiso(picked);
  }

  Future<void> _guardar() async {
    final ok = await _vm.guardarGestion();
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_vm.errorMessage ?? 'Error al guardar'),
          backgroundColor: AppColors.gestionRecuperacionMora,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_vm.successMessage ?? 'Gestión guardada'),
        backgroundColor: AppColors.semaforoNormal,
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final client = _vm.client;
        if (client == null) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.cobranzaAccionTitle)),
            body: const Center(child: Text('Cliente no encontrado')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text(AppStrings.cobranzaAccionTitle),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client.clienteNombre,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Monto vencido: ${_currency.format(client.montoVencido)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.gestionRecuperacionMora,
                        ),
                      ),
                      Text('Días de mora: ${client.diasMora}'),
                      Text('Crédito: ${client.creditoId}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      DropdownButtonFormField<CollectionManagementType>(
                        initialValue: _vm.tipoGestion,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de gestión *',
                        ),
                        items: CollectionManagementType.values
                            .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e.label),
                                ))
                            .toList(),
                        onChanged: _vm.setTipoGestion,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<CollectionResult>(
                        initialValue: _vm.resultado,
                        decoration: const InputDecoration(
                          labelText: 'Resultado *',
                        ),
                        items: CollectionResult.values
                            .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e.label),
                                ))
                            .toList(),
                        onChanged: _vm.setResultado,
                      ),
                      if (_vm.showMontoPagado) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Monto pagado *',
                            prefixText: 'S/ ',
                          ),
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (v) =>
                              _vm.setMontoPagado(double.tryParse(v) ?? 0),
                        ),
                      ],
                      if (_vm.showCompromiso) ...[
                        const SizedBox(height: 12),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Fecha compromiso *'),
                          subtitle: Text(
                            _vm.fechaCompromiso != null
                                ? _dateFormat.format(_vm.fechaCompromiso!)
                                : 'Seleccionar fecha',
                          ),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: _pickFechaCompromiso,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Monto compromiso *',
                            prefixText: 'S/ ',
                          ),
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (v) =>
                              _vm.setMontoCompromiso(double.tryParse(v) ?? 0),
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue: _vm.observaciones,
                        decoration: InputDecoration(
                          labelText: 'Observaciones *',
                          counterText:
                              '${_vm.observaciones.length}/${CobranzaAccionViewModel.maxObservaciones}',
                        ),
                        maxLength: CobranzaAccionViewModel.maxObservaciones,
                        maxLines: 3,
                        onChanged: _vm.setObservaciones,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.lightBackground,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Coordenadas simuladas: '
                          '${CobranzaAccionViewModel.simulatedLat}, '
                          '${CobranzaAccionViewModel.simulatedLng}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: Container(
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
                child: ElevatedButton(
                  onPressed: _vm.isLoading ? null : _guardar,
                  child: _vm.isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : const Text('Guardar gestión'),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
