import '../../../core/storage/session_local_datasource.dart';
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

    try {
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
      _saveToCache(_current!);
      SupabaseHelper.log('asesor cargado id=${_current!.id}');
      return _current;
    } catch (e) {
      SupabaseHelper.log('loadCurrentAsesor falló, intentando cache local: $e');
      final restored = await _tryRestoreFromCache();
      if (restored != null) {
        _current = restored;
        SupabaseHelper.log('asesor restaurado desde cache local id=${_current!.id}');
      }
      return _current;
    }
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

  Future<AsesorModel?> _tryRestoreFromCache() async {
    final cache = await SessionLocalDataSource.instance.loadAsesorSession();
    if (cache.isEmpty) return null;
    final id = cache['id'];
    final userId = cache['user_id'];
    if (id == null || userId == null || id.isEmpty) return null;
    return AsesorModel(
      id: id,
      userId: userId,
      codigoEmpleado: cache['codigo_empleado'] ?? '',
      nombres: cache['nombres'] ?? '',
      apellidos: cache['apellidos'] ?? '',
      agenciaId: cache['agencia_id'],
    );
  }

  Future<void> _saveToCache(AsesorModel asesor) async {
    try {
      await SessionLocalDataSource.instance.saveAsesorSession({
        'id': asesor.id,
        'user_id': asesor.userId,
        'codigo_empleado': asesor.codigoEmpleado,
        'nombres': asesor.nombres,
        'apellidos': asesor.apellidos,
        if (asesor.agenciaId != null) 'agencia_id': asesor.agenciaId!,
      });
    } catch (_) {}
  }

  Future<void> clearCache() async {
    try {
      await SessionLocalDataSource.instance.clearAsesorSession();
    } catch (_) {}
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
