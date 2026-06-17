import '../../../core/supabase/supabase_client.dart';
import '../../../core/supabase/supabase_helper.dart';
import '../../../core/supabase/supabase_lookup.dart';
import '../../auth/data/asesor_repository.dart';
import '../domain/collection_model.dart';

/// Persistencia de acciones de cobranza en Supabase.
class CobranzaRepository {
  CobranzaRepository._();
  static final CobranzaRepository instance = CobranzaRepository._();

  Future<void> insertAccion(CollectionActionModel action) async {
    SupabaseHelper.log('cobranza insert iniciado');
    SupabaseHelper.log('cobranza clienteId recibido=${action.clientId}');
    SupabaseHelper.log('cobranza clienteNombre recibido=${action.clienteNombre}');
    SupabaseHelper.log('cobranza documento recibido=${action.documento}');
    SupabaseHelper.log('cobranza creditoId recibido=${action.creditoId}');

    if (!SupabaseHelper.hasSession) {
      throw StateError('Sin sesión activa.');
    }

    try {
      final asesor = await AsesorRepository.instance.requireCurrentAsesor();
      SupabaseHelper.log('cobranza asesor_id=${asesor.id}');

      final clienteId = await SupabaseLookup.resolveClienteIdForCobranza(
        clienteId: action.clientId,
        documento: action.documento,
        clienteNombre: action.clienteNombre,
      );

      if (clienteId == null) {
        throw StateError(
          'No se pudo resolver cliente_id para cobranza. '
          'clienteId=${action.clientId}, documento=${action.documento}, '
          'clienteNombre=${action.clienteNombre}',
        );
      }

      final creditoId = await SupabaseLookup.resolveCreditoIdForCobranza(
        creditoRef: action.creditoId,
        clienteId: clienteId,
      );

      SupabaseHelper.log('cobranza cliente_id resuelto=$clienteId');
      SupabaseHelper.log(
        'cobranza credito_id resuelto=${creditoId ?? 'null'}',
      );

      final payload = <String, dynamic>{
        'asesor_id': asesor.id,
        'cliente_id': clienteId,
        'credito_id': creditoId,
        'tipo_gestion': action.tipoGestion.label,
        'resultado': action.resultado.label,
        'monto_pagado': action.montoPagado,
        'fecha_compromiso': action.fechaCompromiso?.toIso8601String(),
        'monto_compromiso': action.montoCompromiso,
        'observaciones': action.observaciones,
        'lat': action.lat,
        'lng': action.lng,
        'timestamp_gestion': action.timestampGestion.toIso8601String(),
      };

      SupabaseHelper.log(
        'cobranza payload keys=${payload.keys.toList()}',
      );

      await SupabaseHelper.withTimeout(
        supabase.from('acciones_cobranza').insert(payload),
        operation: 'acciones_cobranza insert',
      );

      SupabaseHelper.log('cobranza insert OK');
    } catch (error, stackTrace) {
      SupabaseHelper.logError(error, stackTrace);
      rethrow;
    }
  }
}
