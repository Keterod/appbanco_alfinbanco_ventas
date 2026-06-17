/// Perfil del asesor de negocio vinculado al usuario Auth.
class AsesorModel {
  const AsesorModel({
    required this.id,
    required this.userId,
    required this.codigoEmpleado,
    required this.nombres,
    required this.apellidos,
    this.agenciaId,
  });

  final String id;
  final String userId;
  final String codigoEmpleado;
  final String nombres;
  final String apellidos;
  final String? agenciaId;

  String get nombreCompleto {
    final full = '$nombres $apellidos'.trim();
    return full.isEmpty ? codigoEmpleado : full;
  }
}
