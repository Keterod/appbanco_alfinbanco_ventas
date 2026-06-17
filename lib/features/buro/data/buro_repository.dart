import '../../../core/supabase/supabase_client.dart';
import '../../../core/supabase/supabase_helper.dart';
import '../../../core/supabase/supabase_lookup.dart';
import '../../auth/data/asesor_repository.dart';
import '../domain/buro_result_model.dart';

/// Persistencia de consultas de buró en Supabase.
class BuroRepository {
  BuroRepository._();
  static final BuroRepository instance = BuroRepository._();

  Future<void> saveConsulta({
    required BuroResultModel resultado,
    required bool consentimientoAceptado,
  }) async {
    SupabaseHelper.log('buro insert iniciado');

    if (!SupabaseHelper.hasSession) {
      SupabaseHelper.log('buro sin sesión, no se insertará');
      return;
    }

    final userId = supabase.auth.currentUser!.id;
    SupabaseHelper.log('currentUser.id=$userId');

    try {
      final asesor = await AsesorRepository.instance.requireCurrentAsesor();
      SupabaseHelper.log('asesor_id=${asesor.id}');

      final clienteId = await SupabaseLookup.resolveClienteId(
        clienteId: resultado.clientId,
        numeroDocumento: resultado.documento,
      );
      if (clienteId != null) {
        SupabaseHelper.log('cliente_id=$clienteId');
      } else {
        SupabaseHelper.log('cliente_id no resuelto, insert sin FK cliente');
      }

      final payload = <String, dynamic>{
        'asesor_id': asesor.id,
        'cliente_id': ?clienteId,
        'dni_consultado': resultado.documento,
        'calificacion_sbs': resultado.calificacionSbs.label,
        'entidades_con_deuda': resultado.entidadesConDeuda,
        'deuda_total_pen': resultado.deudaTotalPen,
        'mayor_deuda': resultado.mayorDeuda,
        'dias_mayor_mora': resultado.diasMayorMora,
        'en_lista_negra': resultado.enListaNegra,
        'motivo_bloqueo': resultado.motivoBloqueo,
        'resultado_json': _buildResultadoJson(resultado, consentimientoAceptado),
        if (resultado.firmaConsentimientoRegistrada)
          'firma_consentimiento_base64': 'SIMULADA',
      };

      SupabaseHelper.log('buro payload keys=${payload.keys.join(', ')}');

      await SupabaseHelper.withTimeout(
        supabase.from('consultas_buro').insert(payload),
        operation: 'consultas_buro insert',
      );
      SupabaseHelper.log('buro insert OK');
    } catch (error, stackTrace) {
      SupabaseHelper.logError(error, stackTrace);
      rethrow;
    }
  }

  Map<String, dynamic> _buildResultadoJson(
    BuroResultModel resultado,
    bool consentimientoAceptado,
  ) {
    return {
      'clientId': resultado.clientId,
      'nombres': resultado.nombres,
      'documento': resultado.documento,
      'calificacionSbs': resultado.calificacionSbs.label,
      'entidadesConDeuda': resultado.entidadesConDeuda,
      'deudaTotalPen': resultado.deudaTotalPen,
      'mayorDeuda': resultado.mayorDeuda,
      'diasMayorMora': resultado.diasMayorMora,
      'enListaNegra': resultado.enListaNegra,
      'motivoBloqueo': resultado.motivoBloqueo,
      'recomendacion': resultado.recomendacion,
      'fechaConsulta': resultado.fechaConsulta.toIso8601String(),
      'firmaConsentimientoRegistrada': resultado.firmaConsentimientoRegistrada,
      'consentimientoAceptado': consentimientoAceptado,
      'resultadoDisponible': resultado.resultadoDisponible,
      'status': resultado.status.label,
    };
  }
}
