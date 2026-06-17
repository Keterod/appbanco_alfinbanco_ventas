import '../../../core/supabase/supabase_client.dart';
import '../../../core/supabase/supabase_helper.dart';
import '../domain/client_detail_model.dart';

/// Repositorio de ficha de cliente desde Supabase.
class FichaClienteRepository {
  FichaClienteRepository._();
  static final FichaClienteRepository instance = FichaClienteRepository._();

  Future<ClientDetailModel?> loadClientDetail(String clientId) async {
    SupabaseHelper.log('ficha load iniciado');
    SupabaseHelper.log('ficha cliente_id=$clientId');

    if (!SupabaseHelper.hasSession) {
      throw StateError('Sin sesión activa.');
    }

    try {
      final cliente = await SupabaseHelper.withTimeout(
        supabase.from('clientes').select().eq('id', clientId).maybeSingle(),
        operation: 'clientes',
      );

      if (cliente == null) {
        SupabaseHelper.log('ficha cliente no encontrado');
        return null;
      }

      final creditos = await SupabaseHelper.withTimeout(
        supabase.from('creditos').select().eq('cliente_id', clientId),
        operation: 'creditos',
      );
      SupabaseHelper.log('ficha creditos rows=${creditos.length}');

      final preaprobado = await SupabaseHelper.withTimeout(
        supabase
            .from('creditos_preaprobados')
            .select()
            .eq('cliente_id', clientId)
            .eq('vigente', true)
            .order('fecha_vencimiento', ascending: false)
            .limit(1)
            .maybeSingle(),
        operation: 'creditos_preaprobados',
      );
      SupabaseHelper.log(
        'ficha preaprobados rows=${preaprobado == null ? 0 : 1}',
      );

      return _mapDetail(cliente, creditos, preaprobado);
    } catch (error, stackTrace) {
      SupabaseHelper.log('ficha load falló');
      SupabaseHelper.logError(error, stackTrace);
      rethrow;
    }
  }

  ClientDetailModel _mapDetail(
    Map<String, dynamic> cliente,
    List<Map<String, dynamic>> creditos,
    Map<String, dynamic>? preaprobado,
  ) {
    final historial = creditos.map(_mapCredito).toList();
    final vigente = creditos.where(
      (c) {
        final estado = c['estado']?.toString().toLowerCase() ?? '';
        return estado == 'vigente' || estado == 'activo';
      },
    );

    double deudaTotal = 0;
    int cuotasAlDia = 0;
    int cuotasMora = 0;
    DateTime ultimoPago = DateTime.now();

    for (final c in vigente) {
      deudaTotal += _toDouble(c['saldo_actual']) ?? 0;
      cuotasAlDia += _toInt(c['cuotas_pagadas']) ?? 0;
      final diasMora = _toInt(c['dias_mora']) ?? 0;
      if (diasMora > 0) cuotasMora += 1;
      final pago = _parseDate(c['fecha_desembolso']);
      if (pago != null && pago.isAfter(ultimoPago)) ultimoPago = pago;
    }

    if (vigente.isEmpty && creditos.isNotEmpty) {
      final first = creditos.first;
      deudaTotal = _toDouble(first['saldo_actual']) ?? 0;
      cuotasAlDia = _toInt(first['cuotas_pagadas']) ?? 0;
      cuotasMora = (_toInt(first['dias_mora']) ?? 0) > 0 ? 1 : 0;
      ultimoPago = _parseDate(first['fecha_desembolso']) ?? ultimoPago;
    }

    return ClientDetailModel(
      id: cliente['id']?.toString() ?? '',
      nombres: cliente['nombres']?.toString() ?? '',
      apellidos: cliente['apellidos']?.toString() ?? '',
      documento: cliente['numero_documento']?.toString() ?? '',
      telefono: cliente['telefono']?.toString() ?? '',
      direccion: cliente['direccion']?.toString() ?? '',
      tipoNegocio: cliente['tipo_negocio']?.toString() ?? 'Negocio',
      nombreNegocio: cliente['nombre_negocio']?.toString() ?? '',
      antiguedadNegocio: _formatAntiguedad(cliente),
      deudaTotal: deudaTotal,
      cuotasAlDia: cuotasAlDia,
      cuotasEnMora: cuotasMora,
      ultimoPago: ultimoPago,
      calificacionSbs: _parseSbs(cliente['calificacion_sbs']),
      montoPreaprobado: _toDouble(preaprobado?['monto_maximo']),
      plazoSugerido: _toInt(preaprobado?['plazo_sugerido_meses']),
      teaReferencial: _toDouble(preaprobado?['tea_referencial']),
      fechaVencimientoOferta: _parseDate(preaprobado?['fecha_vencimiento']),
      historialCreditos: historial,
    );
  }

  CreditHistoryItem _mapCredito(Map<String, dynamic> row) {
    final cuotasTotal = _toInt(row['cuotas_total']) ?? 0;
    final cuotasPagadas = _toInt(row['cuotas_pagadas']) ?? 0;
    final puntualidad = cuotasTotal > 0
        ? (cuotasPagadas / cuotasTotal) * 100
        : 0.0;

    return CreditHistoryItem(
      producto: row['producto']?.toString() ?? 'Crédito',
      monto: _toDouble(row['monto_desembolsado']) ?? 0,
      plazoMeses: _toInt(row['plazo_meses']) ?? 0,
      tasa: _toDouble(row['tea']) ?? 0,
      estado: row['estado']?.toString() ?? '—',
      porcentajePagosPuntuales: puntualidad,
    );
  }

  String _formatAntiguedad(Map<String, dynamic> cliente) {
    final meses = _toInt(cliente['antiguedad_negocio_meses']);
    if (meses != null && meses > 0) {
      if (meses >= 12) return '${meses ~/ 12} años';
      return '$meses meses';
    }
    return '—';
  }

  CalificacionSbs _parseSbs(dynamic value) {
    switch (value?.toString().toLowerCase()) {
      case 'cpp':
        return CalificacionSbs.cpp;
      case 'deficiente':
        return CalificacionSbs.deficiente;
      case 'dudoso':
        return CalificacionSbs.dudoso;
      case 'perdida':
      case 'pérdida':
        return CalificacionSbs.perdida;
      default:
        return CalificacionSbs.normal;
    }
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}
