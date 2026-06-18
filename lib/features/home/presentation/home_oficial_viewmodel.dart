import 'package:flutter/foundation.dart';

import '../../../core/supabase/supabase_helper.dart';
import '../../../core/sync/sync_manager.dart';
import '../../auth/data/asesor_repository.dart';
import '../../cobranza/data/cobranza_local_repository.dart';
import '../../estado_solicitudes/data/estado_solicitudes_repository.dart';
import '../../estado_solicitudes/domain/request_status_mock_data.dart';
import '../../estado_solicitudes/domain/request_status_model.dart';
import '../../reportes/data/reportes_repository.dart';
import '../../reportes/domain/report_model.dart';

/// Evento reciente en el panel del oficial.
class RecentActivityItem {
  const RecentActivityItem({
    required this.titulo,
    required this.descripcion,
    required this.fechaHora,
    required this.iconName,
  });

  final String titulo;
  final String descripcion;
  final DateTime fechaHora;
  final String iconName;
}

/// ViewModel del dashboard del oficial de crédito.
class HomeOficialViewModel extends ChangeNotifier {
  static String get officerName =>
      AsesorRepository.instance.current?.nombreCompleto ?? 'Oficial Alfin';

  bool _isLoading = false;
  bool _usandoDatosReales = false;
  int _visitasDelDia = 0;
  int _pendientes = 0;
  int _solicitudesEnEvaluacion = 0;
  int _clientesEnMora = 0;
  List<RecentActivityItem> _actividadReciente = [];

  bool get isLoading => _isLoading;
  bool get usandoDatosReales => _usandoDatosReales;
  int get visitasDelDia => _visitasDelDia;
  int get pendientes => _pendientes;
  int get solicitudesEnEvaluacion => _solicitudesEnEvaluacion;
  int get clientesEnMora => _clientesEnMora;
  List<RecentActivityItem> get actividadReciente =>
      List.unmodifiable(_actividadReciente);

  Future<void> loadDashboard() async {
    _isLoading = true;
    _usandoDatosReales = false;
    notifyListeners();

    // Procesar pendientes de sincronización al abrir Dashboard
    try {
      await SyncManager.instance.processPending();
    } catch (_) {}

    try {
      await _tryLoadReal();
      _usandoDatosReales = _visitasDelDia > 0 || _solicitudesEnEvaluacion > 0;
    } catch (_) {
      // fallback a mock
    }

    if (!_usandoDatosReales) {
      _loadMock();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _tryLoadReal() async {
    if (!SupabaseHelper.hasSession) return;

    final now = DateTime.now();
    final hoyInicio = DateTime(now.year, now.month, now.day);
    final hoyFin = hoyInicio.add(const Duration(days: 1));

    final repo = ReportesRepository.instance;
    final asesor = await AsesorRepository.instance.requireCurrentAsesor();

    final reporte = await repo.loadReport(
      asesorNombre: officerName,
      periodo: 'Hoy',
      inicio: hoyInicio,
      fin: hoyFin,
    );

    if (reporte != null) {
      _visitasDelDia = reporte.visitasAsignadas;
      _pendientes = reporte.visitasPendientes;
      _clientesEnMora = reporte.clientesEnMora;
    }

    try {
      final solicitudes = await EstadoSolicitudesRepository.instance
          .loadSolicitudes();
      final anyReal =
          solicitudes.any((s) => !s.id.startsWith('req-'));
      if (anyReal) {
        _solicitudesEnEvaluacion = solicitudes
            .where((s) =>
                s.estado == RequestStatus.enEvaluacion ||
                s.estado == RequestStatus.enComite)
            .length;
      } else {
        final mock = RequestStatusMockData.all();
        _solicitudesEnEvaluacion = mock
            .where((s) =>
                s.estado == RequestStatus.enEvaluacion ||
                s.estado == RequestStatus.enComite)
            .length;
      }
    } catch (_) {
      final mock = RequestStatusMockData.all();
      _solicitudesEnEvaluacion = mock
          .where((s) =>
              s.estado == RequestStatus.enEvaluacion ||
              s.estado == RequestStatus.enComite)
          .length;
    }

    final activities = await repo.loadActivities(
      asesorId: asesor.id,
      inicio: hoyInicio,
      fin: hoyFin,
    );

    if (activities.isNotEmpty) {
      _actividadReciente = activities.map((a) {
        return RecentActivityItem(
          titulo: a.titulo,
          descripcion: a.descripcion,
          fechaHora: a.fecha,
          iconName: _mapActivityType(a.tipo),
        );
      }).toList();
    }
  }

  String _mapActivityType(ReportActivityType type) {
    return switch (type) {
      ReportActivityType.visita => 'visit',
      ReportActivityType.solicitud => 'send',
      ReportActivityType.cobranza => 'collection',
      ReportActivityType.desembolso => 'send',
      ReportActivityType.alerta => 'visit',
    };
  }

  void _loadMock() {
    _visitasDelDia = 5;
    _pendientes = 3;

    final solicitudes = RequestStatusMockData.all();
    _solicitudesEnEvaluacion = solicitudes
        .where((s) =>
            s.estado == RequestStatus.enEvaluacion ||
            s.estado == RequestStatus.enComite)
        .length;

    CobranzaLocalRepository.instance.ensureInitialized();
    _clientesEnMora = CobranzaLocalRepository.instance.clients.length;

    final now = DateTime.now();
    _actividadReciente = [
      RecentActivityItem(
        titulo: 'Solicitud enviada al comité',
        descripcion: 'Rosa Quispe — EXP-ALF-2026-0001',
        fechaHora: now.subtract(const Duration(hours: 2)),
        iconName: 'send',
      ),
      RecentActivityItem(
        titulo: 'Cliente marcado como visitado',
        descripcion: 'Carmen Flores — gestión en campo',
        fechaHora: now.subtract(const Duration(hours: 5)),
        iconName: 'visit',
      ),
      RecentActivityItem(
        titulo: 'Gestión de cobranza registrada',
        descripcion: 'José Ramos — compromiso de pago',
        fechaHora: now.subtract(const Duration(hours: 8)),
        iconName: 'collection',
      ),
    ];
  }
}
