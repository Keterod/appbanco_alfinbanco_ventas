import '../../../core/supabase/supabase_client.dart';
import '../../../core/supabase/supabase_helper.dart';
import '../../../core/supabase/supabase_lookup.dart';
import '../../auth/data/asesor_repository.dart';
import '../domain/credit_request_model.dart';

/// Resultado de inserción de solicitud en Supabase.
class SolicitudInsertResult {
  const SolicitudInsertResult({
    required this.id,
    required this.numeroExpediente,
  });

  final String id;
  final String numeroExpediente;
}

/// Repositorio de solicitudes de crédito en Supabase.
class SolicitudRepository {
  SolicitudRepository._();
  static final SolicitudRepository instance = SolicitudRepository._();

  static const double _fallbackLat = -12.0464;
  static const double _fallbackLng = -77.0428;

  Future<SolicitudInsertResult> insertSolicitud(
    CreditRequestModel model, {
    double? latCaptura,
    double? lngCaptura,
  }) async {
    SupabaseHelper.log('solicitud insert iniciado');

    if (!SupabaseHelper.hasSession) {
      throw StateError('Sin sesión activa.');
    }

    try {
      final asesor = await AsesorRepository.instance.requireCurrentAsesor();
      SupabaseHelper.log('solicitud asesor_id=${asesor.id}');

      final clienteId = await SupabaseLookup.resolveClienteId(
        clienteId: model.clientId,
        numeroDocumento: model.documento.replaceAll(RegExp(r'\D'), ''),
      );

      final expediente = _generateExpediente();

      final payload = <String, dynamic>{
        'numero_expediente': expediente,
        'asesor_id': asesor.id,
        'cliente_id': ?clienteId,
        'agencia_id': ?asesor.agenciaId,
        'tipo_negocio': model.tipoNegocio?.label,
        'nombre_negocio': model.nombreNegocio,
        'actividad_economica': model.actividadEconomica,
        'antiguedad_negocio_meses': model.antiguedadNegocioMeses,
        'ingresos_estimados': model.ingresosMensuales,
        'gastos_mensuales': model.gastosMensuales,
        'patrimonio_estimado': model.patrimonioEstimado,
        'monto_solicitado': model.montoSolicitado,
        'plazo_meses': model.plazoMeses,
        'moneda': model.moneda.label,
        'tipo_cuota': model.tipoCuota?.label,
        'garantia': model.garantia?.label,
        'destino_credito': model.destinoCredito,
        'cuota_estimada': model.cuotaEstimada,
        'tea_referencial': model.teaReferencial,
        'estado': 'enviada',
        if (model.firmaSimulada) 'firma_cliente_base64': 'SIMULADA',
        'lat_captura': latCaptura ?? _fallbackLat,
        'lng_captura': lngCaptura ?? _fallbackLng,
        'pendiente_sync': false,
      };

      SupabaseHelper.log('solicitud payload keys=${payload.keys.join(', ')}');

      final row = await SupabaseHelper.withTimeout(
        supabase.from('solicitudes_credito').insert(payload).select().single(),
        operation: 'solicitudes_credito insert',
      );

      final numeroExpediente =
          row['numero_expediente']?.toString() ?? expediente;
      SupabaseHelper.log('solicitud insert OK expediente=$numeroExpediente');

      return SolicitudInsertResult(
        id: row['id']?.toString() ?? '',
        numeroExpediente: numeroExpediente,
      );
    } catch (error, stackTrace) {
      SupabaseHelper.logError(error, stackTrace);
      rethrow;
    }
  }

  String _generateExpediente() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    return 'EXP-ALF-2026-$ts';
  }
}
