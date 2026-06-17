import '../../../core/supabase/supabase_client.dart';
import '../../../core/supabase/supabase_helper.dart';
import '../domain/asesor_model.dart';

/// Carga y cache del perfil del asesor autenticado.
class AsesorRepository {
  AsesorRepository._();
  static final AsesorRepository instance = AsesorRepository._();

  AsesorModel? _current;

  AsesorModel? get current => _current;

  void clear() => _current = null;

  Future<AsesorModel?> loadCurrentAsesor() async {
    if (!SupabaseHelper.hasSession) {
      _current = null;
      return null;
    }

    final userId = supabase.auth.currentUser!.id;
    SupabaseHelper.log('loadCurrentAsesor userId=$userId');

    final row = await SupabaseHelper.withTimeout(
      supabase
          .from('asesores_negocio')
          .select()
          .eq('user_id', userId)
          .maybeSingle(),
      operation: 'asesores_negocio',
    );

    if (row == null) {
      SupabaseHelper.log('asesor no encontrado para user_id=$userId');
      _current = null;
      return null;
    }

    _current = _mapRow(row);
    SupabaseHelper.log('asesor cargado id=${_current!.id}');
    return _current;
  }

  Future<AsesorModel> requireCurrentAsesor() async {
    final asesor = _current ?? await loadCurrentAsesor();
    if (asesor == null || asesor.id.isEmpty) {
      throw StateError(
        'No se encontró asesor Supabase para el usuario autenticado',
      );
    }
    return asesor;
  }

  AsesorModel _mapRow(Map<String, dynamic> row) {
    return AsesorModel(
      id: row['id']?.toString() ?? '',
      userId: row['user_id']?.toString() ?? '',
      codigoEmpleado:
          row['codigo_empleado']?.toString() ?? row['codigo']?.toString() ?? '',
      nombres: row['nombres']?.toString() ?? '',
      apellidos: row['apellidos']?.toString() ?? '',
      agenciaId: row['agencia_id']?.toString(),
    );
  }
}
