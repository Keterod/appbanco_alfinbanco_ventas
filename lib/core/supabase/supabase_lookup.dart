import 'supabase_client.dart';
import 'supabase_helper.dart';

/// Resolución de IDs reales en Supabase a partir de referencias mock/UI.
abstract final class SupabaseLookup {
  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  static bool isUuid(String? value) =>
      value != null && value.isNotEmpty && _uuidPattern.hasMatch(value);

  static Future<String?> resolveClienteId({
    String? clienteId,
    String? numeroDocumento,
  }) async {
    return resolveClienteIdForCobranza(
      clienteId: clienteId,
      documento: numeroDocumento,
    );
  }

  /// Resolución robusta de cliente para cobranza (mock IDs, DNI, nombre).
  static Future<String?> resolveClienteIdForCobranza({
    String? clienteId,
    String? documento,
    String? clienteNombre,
  }) async {
    try {
      SupabaseHelper.log(
        'resolveClienteIdForCobranza inicio '
        'clienteId=$clienteId documento=$documento clienteNombre=$clienteNombre',
      );

      // A. UUID válido existente en Supabase
      if (isUuid(clienteId)) {
        final byId = await _fetchClienteIdById(clienteId!);
        if (byId != null) {
          SupabaseHelper.log('resolveClienteIdForCobranza por UUID=$byId');
          return byId;
        }
      }

      final docDigits = _extractDocumentDigits(documento);
      final docFull = documento?.replaceAll(RegExp(r'\D'), '') ?? '';

      // B. Documento completo (8 dígitos)
      if (docFull.length == 8) {
        final byDoc = await _fetchClienteIdByDocumento(docFull);
        if (byDoc != null) {
          SupabaseHelper.log('resolveClienteIdForCobranza por documento=$byDoc');
          return byDoc;
        }
      }

      // C. Documento enmascarado (***3456)
      if (docDigits.length == 4) {
        final bySuffix = await _fetchClienteIdByDocumentoSuffix(docDigits);
        if (bySuffix != null) {
          SupabaseHelper.log(
            'resolveClienteIdForCobranza por sufijo documento=$bySuffix',
          );
          return bySuffix;
        }
      }

      // E. Fallback demo explícito (antes de búsqueda genérica por nombre)
      final demoDoc = _demoDocumentoPorNombre(clienteNombre);
      if (demoDoc != null) {
        final byDemo = await _fetchClienteIdByDocumento(demoDoc);
        if (byDemo != null) {
          SupabaseHelper.log('resolveClienteIdForCobranza por demo=$byDemo');
          return byDemo;
        }
      }

      // D. Búsqueda por nombre y apellido
      if (clienteNombre != null && clienteNombre.trim().isNotEmpty) {
        final byName = await _fetchClienteIdByNombre(clienteNombre);
        if (byName != null) {
          SupabaseHelper.log('resolveClienteIdForCobranza por nombre=$byName');
          return byName;
        }
      }

      // Último intento: clienteId mock en tabla (p. ej. cli-003)
      if (clienteId != null && clienteId.isNotEmpty) {
        final byMockId = await _fetchClienteIdById(clienteId);
        if (byMockId != null) {
          SupabaseHelper.log('resolveClienteIdForCobranza por id mock=$byMockId');
          return byMockId;
        }
      }
    } catch (error, stackTrace) {
      SupabaseHelper.log('resolveClienteIdForCobranza falló');
      SupabaseHelper.logError(error, stackTrace);
    }
    return null;
  }

  static Future<String?> resolveCreditoId({
    required String creditoRef,
    String? clienteId,
  }) async {
    return resolveCreditoIdForCobranza(
      creditoRef: creditoRef,
      clienteId: clienteId,
    );
  }

  /// Resolución opcional de crédito; no lanza error si no encuentra.
  static Future<String?> resolveCreditoIdForCobranza({
    String? creditoRef,
    String? clienteId,
  }) async {
    try {
      if (creditoRef != null &&
          creditoRef.isNotEmpty &&
          isUuid(creditoRef)) {
        final byId = await SupabaseHelper.withTimeout(
          supabase.from('creditos').select('id').eq('id', creditoRef).maybeSingle(),
          operation: 'creditos lookup uuid',
        );
        if (byId?['id'] != null) return byId!['id'].toString();
      }

      if (clienteId == null || clienteId.isEmpty) return null;

      try {
        final rows = await SupabaseHelper.withTimeout(
          supabase
              .from('creditos')
              .select('id')
              .eq('cliente_id', clienteId)
              .order('dias_mora', ascending: false)
              .order('created_at', ascending: false)
              .limit(1),
          operation: 'creditos lookup cliente ordered',
        );
        if (rows.isNotEmpty && rows.first['id'] != null) {
          return rows.first['id'].toString();
        }
      } catch (_) {
        SupabaseHelper.log(
          'creditos lookup con created_at falló, reintentando sin created_at',
        );
        final rows = await SupabaseHelper.withTimeout(
          supabase
              .from('creditos')
              .select('id')
              .eq('cliente_id', clienteId)
              .order('dias_mora', ascending: false)
              .limit(1),
          operation: 'creditos lookup cliente dias_mora',
        );
        if (rows.isNotEmpty && rows.first['id'] != null) {
          return rows.first['id'].toString();
        }
      }
    } catch (error, stackTrace) {
      SupabaseHelper.log('resolveCreditoIdForCobranza falló');
      SupabaseHelper.logError(error, stackTrace);
    }
    return null;
  }

  static String _extractDocumentDigits(String? documento) {
    if (documento == null || documento.isEmpty) return '';
    final digits = documento.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 8) return digits;
    if (digits.length >= 4) return digits.substring(digits.length - 4);
    return digits;
  }

  static String? _demoDocumentoPorNombre(String? clienteNombre) {
    if (clienteNombre == null) return null;
    final name = clienteNombre.toLowerCase();
    if (name.contains('carmen flores')) return '40123456';
    if (name.contains('josé ramos') || name.contains('jose ramos')) {
      return '10876543';
    }
    if (name.contains('rosa quispe')) return '45678912';
    if (name.contains('miguel huamán') || name.contains('miguel huaman')) {
      return '72345618';
    }
    if (name.contains('ana torres')) return '71234567';
    return null;
  }

  static Future<String?> _fetchClienteIdById(String id) async {
    final row = await SupabaseHelper.withTimeout(
      supabase.from('clientes').select('id').eq('id', id).maybeSingle(),
      operation: 'clientes lookup id',
    );
    return row?['id']?.toString();
  }

  static Future<String?> _fetchClienteIdByDocumento(String documento) async {
    final row = await SupabaseHelper.withTimeout(
      supabase
          .from('clientes')
          .select('id')
          .eq('numero_documento', documento)
          .maybeSingle(),
      operation: 'clientes lookup numero_documento',
    );
    return row?['id']?.toString();
  }

  static Future<String?> _fetchClienteIdByDocumentoSuffix(String suffix) async {
    final rows = await SupabaseHelper.withTimeout(
      supabase
          .from('clientes')
          .select('id')
          .like('numero_documento', '%$suffix')
          .limit(1),
      operation: 'clientes lookup numero_documento suffix',
    );
    if (rows.isEmpty) return null;
    return rows.first['id']?.toString();
  }

  static Future<String?> _fetchClienteIdByNombre(String clienteNombre) async {
    final parts =
        clienteNombre.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final tokens = parts.toList();
    if (tokens.isEmpty) return null;

    final nombres = tokens.first;
    final apellidos = tokens.length > 1 ? tokens.sublist(1).join(' ') : '';

    var query = supabase.from('clientes').select('id').ilike('nombres', '%$nombres%');
    if (apellidos.isNotEmpty) {
      query = query.ilike('apellidos', '%$apellidos%');
    }

    final rows = await SupabaseHelper.withTimeout(
      query.limit(1),
      operation: 'clientes lookup nombre',
    );
    if (rows.isEmpty) return null;
    return rows.first['id']?.toString();
  }
}
