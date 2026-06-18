import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../domain/client_detail_model.dart';
import 'ficha_cliente_viewmodel.dart';

/// Pantalla de ficha completa del cliente (HU-V03).
class FichaClienteScreen extends StatefulWidget {
  const FichaClienteScreen({super.key, required this.clientId});

  final String clientId;

  @override
  State<FichaClienteScreen> createState() => _FichaClienteScreenState();
}

class _FichaClienteScreenState extends State<FichaClienteScreen> {
  late final FichaClienteViewModel _viewModel;
  static final _dateFormat = DateFormat('dd/MM/yyyy');
  static final _currencyFormat = NumberFormat.currency(
    locale: 'es_PE',
    symbol: 'S/',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    _viewModel = FichaClienteViewModel();
    _viewModel.loadClientDetail(widget.clientId);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _onLlamar(ClientDetailModel client) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Llamar a ${client.telefono}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onConsultarBuro() {
    Navigator.pushNamed(
      context,
      AppRoutes.buro,
      arguments: widget.clientId,
    );
  }

  void _onIniciarSolicitud() {
    final client = _viewModel.client;
    final args = <String, dynamic>{
      'clientId': widget.clientId,
    };
    if (client != null) {
      // Parse antigüedad string like "72 meses" to int months
      final antiguedadMatch = RegExp(r'(\d+)').firstMatch(client.antiguedadNegocio);
      args['nombres'] = client.nombres;
      args['apellidos'] = client.apellidos;
      args['documento'] = client.documento;
      args['telefono'] = client.telefono;
      args['direccion'] = client.direccion;
      args['tipoNegocio'] = client.tipoNegocio;
      args['nombreNegocio'] = client.nombreNegocio;
      args['antiguedadMeses'] = antiguedadMatch != null
          ? int.tryParse(antiguedadMatch.group(1) ?? '0') ?? 0
          : 0;
      args['montoSugerido'] = client.montoPreaprobado;
      args['plazoSugerido'] = client.plazoSugerido;
    }
    Navigator.pushNamed(
      context,
      AppRoutes.solicitudCredito,
      arguments: args,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Ficha del cliente'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: _buildBody(),
          bottomNavigationBar: _viewModel.client != null
              ? _ActionBar(
                  onLlamar: () => _onLlamar(_viewModel.client!),
                  onConsultarBuro: _onConsultarBuro,
                  onIniciarSolicitud: _onIniciarSolicitud,
                )
              : null,
        );
      },
    );
  }

  Widget _buildBody() {
    if (_viewModel.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.secondary),
      );
    }

    if (_viewModel.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.softOrange),
              const SizedBox(height: 16),
              Text(
                _viewModel.errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Volver'),
              ),
            ],
          ),
        ),
      );
    }

    final client = _viewModel.client!;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.lightBackground, AppColors.white],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          _HeaderCard(client: client),
          const SizedBox(height: 16),
          _SbsSemaforoCard(calificacion: client.calificacionSbs),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Datos de contacto y negocio',
            icon: Icons.storefront_outlined,
            children: [
              _InfoRow(
                icon: Icons.badge_outlined,
                label: 'Documento',
                value: client.documentoCensurado,
              ),
              _InfoRow(
                icon: Icons.phone_outlined,
                label: 'Teléfono',
                value: client.telefono,
              ),
              _InfoRow(
                icon: Icons.place_outlined,
                label: 'Dirección',
                value: client.direccion,
              ),
              _InfoRow(
                icon: Icons.category_outlined,
                label: 'Tipo de negocio',
                value: client.tipoNegocio,
              ),
              _InfoRow(
                icon: Icons.business_outlined,
                label: 'Nombre del negocio',
                value: client.nombreNegocio,
              ),
              _InfoRow(
                icon: Icons.schedule_outlined,
                label: 'Antigüedad',
                value: client.antiguedadNegocio,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Posición del cliente',
            icon: Icons.account_balance_wallet_outlined,
            children: [
              _MetricTile(
                label: 'Deuda total',
                value: _currencyFormat.format(client.deudaTotal),
                color: client.deudaTotal > 0
                    ? AppColors.gestionRecuperacionMora
                    : AppColors.semaforoNormal,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _MetricTile(
                      label: 'Cuotas al día',
                      value: '${client.cuotasAlDia}',
                      color: AppColors.semaforoNormal,
                      compact: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MetricTile(
                      label: 'Cuotas en mora',
                      value: '${client.cuotasEnMora}',
                      color: client.cuotasEnMora > 0
                          ? AppColors.semaforoDudoso
                          : AppColors.textSecondary,
                      compact: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.payments_outlined,
                label: 'Último pago',
                value: _dateFormat.format(client.ultimoPago),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Historial crediticio',
            icon: Icons.history_edu_outlined,
            children: client.historialCreditos.isEmpty
                ? [
                    Text(
                      'Sin historial registrado.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ]
                : client.historialCreditos
                    .map((h) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _CreditHistoryCard(item: h),
                        ))
                    .toList(),
          ),
          const SizedBox(height: 16),
          _OfertaVigenteCard(client: client),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.client});

  final ClientDetailModel client;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: AppColors.purpleSupport.withValues(alpha: 0.15),
              child: Text(
                client.iniciales,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.purpleSupport,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    client.nombreCompleto,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.darkText,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'ID interno: ${client.id}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Chip(
                    avatar: const Icon(
                      Icons.verified_user_outlined,
                      size: 18,
                      color: AppColors.secondary,
                    ),
                    label: const Text('Cliente cartera oficial'),
                    backgroundColor: AppColors.secondary.withValues(alpha: 0.08),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SbsSemaforoCard extends StatelessWidget {
  const _SbsSemaforoCard({required this.calificacion});

  final CalificacionSbs calificacion;

  Color get _color => switch (calificacion) {
        CalificacionSbs.normal => AppColors.semaforoNormal,
        CalificacionSbs.cpp => AppColors.semaforoCpp,
        CalificacionSbs.deficiente => AppColors.semaforoDeficiente,
        CalificacionSbs.dudoso => AppColors.semaforoDudoso,
        CalificacionSbs.perdida => AppColors.semaforoPerdida,
      };

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
                Icon(Icons.traffic_outlined, color: AppColors.purpleSupport),
                const SizedBox(width: 8),
                Text(
                  'Semáforo de riesgo SBS',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: CalificacionSbs.values.map((c) {
                final selected = c == calificacion;
                final color = switch (c) {
                  CalificacionSbs.normal => AppColors.semaforoNormal,
                  CalificacionSbs.cpp => AppColors.semaforoCpp,
                  CalificacionSbs.deficiente => AppColors.semaforoDeficiente,
                  CalificacionSbs.dudoso => AppColors.semaforoDudoso,
                  CalificacionSbs.perdida => AppColors.semaforoPerdida,
                };
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected
                        ? color.withValues(alpha: 0.25)
                        : AppColors.lightBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected ? color : AppColors.divider,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    c.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                      color: selected ? color : AppColors.textSecondary,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _color.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Icon(Icons.flag_circle, color: _color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Calificación actual: ${calificacion.label}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

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
                Icon(icon, color: AppColors.secondary, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
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
      padding: const EdgeInsets.only(bottom: 10),
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
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.darkText,
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

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.color,
    this.compact = false,
  });

  final String label;
  final String value;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}

class _CreditHistoryCard extends StatelessWidget {
  const _CreditHistoryCard({required this.item});

  final CreditHistoryItem item;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: 'es_PE',
      symbol: 'S/',
      decimalDigits: 2,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.lightBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.producto,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _MiniChip(label: currency.format(item.monto)),
              _MiniChip(label: '${item.plazoMeses} meses'),
              _MiniChip(label: 'TEA ${item.tasa}%'),
              _MiniChip(
                label: item.estado,
                color: AppColors.gestionRenovacion,
              ),
              _MiniChip(
                label: 'Puntualidad ${item.porcentajePagosPuntuales.toStringAsFixed(1)}%',
                color: item.porcentajePagosPuntuales >= 90
                    ? AppColors.semaforoNormal
                    : AppColors.semaforoCpp,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.purpleSupport;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: c,
        ),
      ),
    );
  }
}

class _OfertaVigenteCard extends StatelessWidget {
  const _OfertaVigenteCard({required this.client});

  final ClientDetailModel client;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currency = NumberFormat.currency(
      locale: 'es_PE',
      symbol: 'S/',
      decimalDigits: 2,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_offer_outlined, color: AppColors.softOrange),
                const SizedBox(width: 8),
                Text(
                  'Oferta vigente',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (!client.tieneOfertaVigente)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.lightBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Sin oferta vigente',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                ),
              )
            else ...[
              _InfoRow(
                icon: Icons.savings_outlined,
                label: 'Monto preaprobado',
                value: currency.format(client.montoPreaprobado),
              ),
              _InfoRow(
                icon: Icons.calendar_month_outlined,
                label: 'Plazo sugerido',
                value: '${client.plazoSugerido} meses',
              ),
              _InfoRow(
                icon: Icons.percent_outlined,
                label: 'TEA referencial',
                value: '${client.teaReferencial}%',
              ),
              _InfoRow(
                icon: Icons.event_busy_outlined,
                label: 'Vencimiento de oferta',
                value: dateFormat.format(client.fechaVencimientoOferta!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.onLlamar,
    required this.onConsultarBuro,
    required this.onIniciarSolicitud,
  });

  final VoidCallback onLlamar;
  final VoidCallback onConsultarBuro;
  final VoidCallback onIniciarSolicitud;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onConsultarBuro,
                icon: const Icon(Icons.fact_check_outlined),
                label: const Text('Consultar buró'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.purpleSupport,
                  side: const BorderSide(color: AppColors.purpleSupport),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onIniciarSolicitud,
                icon: const Icon(Icons.note_add_outlined),
                label: const Text('Iniciar solicitud'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onLlamar,
                icon: const Icon(Icons.phone_outlined),
                label: const Text('Llamar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.secondary,
                  side: const BorderSide(color: AppColors.secondary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
