import '../../../core/supabase/supabase_client.dart';
import '../../../core/supabase/supabase_helper.dart';
import '../../auth/data/asesor_repository.dart';
import '../domain/report_model.dart';

class ReportesRepository {
  ReportesRepository._();
  static final ReportesRepository instance = ReportesRepository._();

  Future<OfficerReportModel?> loadReport({
    required String asesorNombre,
    required String periodo,
    required DateTime inicio,
    required DateTime fin,
  }) async {
    SupabaseHelper.log('reportes load iniciado periodo=$periodo');

    if (!SupabaseHelper.hasSession) return null;

    try {
      final asesor = await AsesorRepository.instance.requireCurrentAsesor();

      final inicioStr = inicio.toIso8601String();
      final finStr = fin.toIso8601String();

      final solicitudes = await _countSolicitudes(asesor.id, inicioStr, finStr);
      final cartera = await _countCartera(asesor.id, inicioStr, finStr);
      final cobranza = await _countCobranza(asesor.id, inicioStr, finStr);

      final visitasAsignadas =
          (cartera['total'] as int?) ?? 0;
      final visitasRealizadas =
          (cartera['realizadas'] as int?) ?? 0;
      final visitasPendientes = visitasAsignadas - visitasRealizadas;

      final solicitudesEnviadas =
          (solicitudes['total'] as int?) ?? 0;
      final solicitudesAprobadas =
          (solicitudes['aprobadas'] as int?) ?? 0;
      final solicitudesDesembolsadas =
          (solicitudes['desembolsadas'] as int?) ?? 0;
      final montoSolicitado =
          ((solicitudes['monto_solicitado'] as num?) ?? 0).toDouble();
      final montoAprobado =
          ((solicitudes['monto_aprobado'] as num?) ?? 0).toDouble();

      final clientesEnMora =
          (cobranza['clientes_mora'] as int?) ?? 0;
      final montoVencido =
          ((cobranza['monto_vencido'] as num?) ?? 0).toDouble();
      final gestionesCobranza =
          (cobranza['gestiones'] as int?) ?? 0;

      final double tasaAprobacion = solicitudesEnviadas > 0
          ? solicitudesAprobadas / solicitudesEnviadas
          : 0.0;
      final double coberturaVisitas = visitasAsignadas > 0
          ? visitasRealizadas / visitasAsignadas
          : 0.0;

      return OfficerReportModel(
        asesorNombre: asesorNombre,
        periodo: periodo,
        visitasAsignadas: visitasAsignadas,
        visitasRealizadas: visitasRealizadas,
        visitasPendientes: visitasPendientes,
        solicitudesEnviadas: solicitudesEnviadas,
        solicitudesAprobadas: solicitudesAprobadas,
        solicitudesDesembolsadas: solicitudesDesembolsadas,
        montoSolicitado: montoSolicitado,
        montoAprobado: montoAprobado,
        clientesEnMora: clientesEnMora,
        montoVencido: montoVencido,
        gestionesCobranza: gestionesCobranza,
        tasaAprobacion: tasaAprobacion,
        coberturaVisitas: coberturaVisitas,
      );
    } catch (error, stackTrace) {
      SupabaseHelper.log('reportes load falló, retornando null');
      SupabaseHelper.logError(error, stackTrace);
      return null;
    }
  }

  Future<Map<String, dynamic>> _countSolicitudes(
    String asesorId,
    String inicio,
    String fin,
  ) async {
    try {
      final rows = await SupabaseHelper.withTimeout(
        supabase
            .from('solicitudes_credito')
            .select()
            .eq('asesor_id', asesorId)
            .gte('created_at', inicio)
            .lte('created_at', fin),
        operation: 'reportes solicitudes',
      );

      int total = 0;
      int aprobadas = 0;
      int desembolsadas = 0;
      double montoSolicitado = 0;
      double montoAprobado = 0;

      for (final row in rows) {
        total++;
        final estado = row['estado']?.toString() ?? '';
        final ms = _toDouble(row['monto_solicitado']) ?? 0;
        final ma = _toDouble(row['monto_aprobado']) ?? 0;
        montoSolicitado += ms;
        if (estado == 'aprobada' ||
            estado == 'condicionada' ||
            estado == 'desembolsada') {
          aprobadas++;
          montoAprobado += ma > 0 ? ma : ms;
        }
        if (estado == 'desembolsada') {
          desembolsadas++;
        }
      }

      return {
        'total': total,
        'aprobadas': aprobadas,
        'desembolsadas': desembolsadas,
        'monto_solicitado': montoSolicitado,
        'monto_aprobado': montoAprobado,
      };
    } catch (_) {
      return {};
    }
  }

  Future<Map<String, dynamic>> _countCartera(
    String asesorId,
    String inicio,
    String fin,
  ) async {
    try {
      final rows = await SupabaseHelper.withTimeout(
        supabase
            .from('cartera_diaria')
            .select()
            .eq('asesor_id', asesorId)
            .gte('fecha_asignacion', inicio)
            .lte('fecha_asignacion', fin),
        operation: 'reportes cartera',
      );

      int total = rows.length;
      int realizadas = 0;

      for (final row in rows) {
        final estado = row['estado_visita']?.toString() ?? '';
        if (estado.toLowerCase() == 'visitado' ||
            estado.toLowerCase() == 'realizada') {
          realizadas++;
        }
      }

      return {
        'total': total,
        'realizadas': realizadas,
      };
    } catch (_) {
      return {};
    }
  }

  Future<Map<String, dynamic>> _countCobranza(
    String asesorId,
    String inicio,
    String fin,
  ) async {
    try {
      final rows = await SupabaseHelper.withTimeout(
        supabase
            .from('acciones_cobranza')
            .select()
            .eq('asesor_id', asesorId)
            .gte('created_at', inicio)
            .lte('created_at', fin),
        operation: 'reportes cobranza',
      );

      final clientesMoraSet = <String>{};
      double montoVencido = 0;

      for (final row in rows) {
        final cid = row['cliente_id']?.toString();
        if (cid != null) clientesMoraSet.add(cid);
        montoVencido += _toDouble(row['monto_gestionado']) ?? 0;
      }

      return {
        'clientes_mora': clientesMoraSet.length,
        'monto_vencido': montoVencido,
        'gestiones': rows.length,
      };
    } catch (_) {
      return {};
    }
  }

  Future<List<ReportActivityItem>> loadActivities({
    required String asesorId,
    required DateTime inicio,
    required DateTime fin,
  }) async {
    final activities = <ReportActivityItem>[];

    try {
      final solicitudes = await SupabaseHelper.withTimeout(
        supabase
            .from('solicitudes_credito')
            .select(
                'created_at, estado, monto_solicitado, clientes!inner(nombres, apellidos)')
            .eq('asesor_id', asesorId)
            .gte('created_at', inicio)
            .lte('created_at', fin)
            .order('created_at', ascending: false)
            .limit(5),
        operation: 'actividades solicitudes',
      );

      for (final row in solicitudes) {
        final clientes = row['clientes'] as Map<String, dynamic>?;
        final nom = clientes?['nombres']?.toString() ?? '';
        final ape = clientes?['apellidos']?.toString() ?? '';
        final nombre = '$nom $ape'.trim();
        final estado = row['estado']?.toString() ?? '';
        final monto = _toDouble(row['monto_solicitado']) ?? 0;
        final fecha = _parseDateTime(row['created_at']) ?? DateTime.now();

        activities.add(ReportActivityItem(
          id: 'act-sol-${activities.length}',
          titulo: 'Solicitud $estado',
          descripcion:
              '$nombre — S/ ${monto.toStringAsFixed(0)}',
          fecha: fecha,
          tipo: ReportActivityType.solicitud,
        ));
      }
    } catch (_) {}

    try {
      final cobranzas = await SupabaseHelper.withTimeout(
        supabase
            .from('acciones_cobranza')
            .select('created_at, resultado, monto_pagado')
            .eq('asesor_id', asesorId)
            .gte('created_at', inicio)
            .lte('created_at', fin)
            .order('created_at', ascending: false)
            .limit(5),
        operation: 'actividades cobranza',
      );

      for (final row in cobranzas) {
        final fecha = _parseDateTime(row['created_at']) ?? DateTime.now();
        activities.add(ReportActivityItem(
          id: 'act-cob-${activities.length}',
          titulo: 'Gestión de cobranza',
          descripcion:
              'Resultado: ${row['resultado']?.toString() ?? '—'}',
          fecha: fecha,
          tipo: ReportActivityType.cobranza,
        ));
      }
    } catch (_) {}

    activities.sort((a, b) => b.fecha.compareTo(a.fecha));
    return activities.take(10).toList();
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
