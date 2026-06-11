import 'package:flutter/foundation.dart';

import '../../home/presentation/home_oficial_viewmodel.dart';
import '../domain/report_model.dart';

/// ViewModel del módulo Reportes del Oficial.
class ReportesViewModel extends ChangeNotifier {
  static const String periodoHoy = 'Hoy';
  static const String periodoSemana = 'Semana';
  static const String periodoMes = 'Mes';

  static const List<String> periodos = [
    periodoHoy,
    periodoSemana,
    periodoMes,
  ];

  bool _isLoading = false;
  String? _errorMessage;
  String _selectedPeriod = periodoHoy;
  OfficerReportModel? _report;
  List<ReportActivityItem> _activities = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedPeriod => _selectedPeriod;
  OfficerReportModel? get report => _report;
  List<ReportActivityItem> get activities =>
      List.unmodifiable(_activities);

  Future<void> loadReport() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 400));

    try {
      _report = _buildReportForPeriod(_selectedPeriod);
      _activities = _buildActivitiesForPeriod(_selectedPeriod);
    } catch (e) {
      _errorMessage = 'No se pudo cargar el reporte.';
      _report = null;
      _activities = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> changePeriod(String period) async {
    if (!periodos.contains(period) || period == _selectedPeriod) return;
    _selectedPeriod = period;
    await loadReport();
  }

  double getCoveragePercentage() {
    final report = _report;
    if (report == null) return 0;
    return (report.coberturaVisitas * 100).clamp(0, 100);
  }

  double getApprovalPercentage() {
    final report = _report;
    if (report == null) return 0;
    return (report.tasaAprobacion * 100).clamp(0, 100);
  }

  String getProductivityLabel() {
    final report = _report;
    if (report == null) return 'Sin datos';

    final score =
        (report.coberturaVisitas + report.tasaAprobacion) / 2;

    if (score >= 0.75) return 'Productividad alta';
    if (score >= 0.55) return 'Productividad media';
    return 'Productividad en mejora';
  }

  OfficerReportModel _buildReportForPeriod(String period) {
    final officer = HomeOficialViewModel.officerName;

    return switch (period) {
      periodoSemana => OfficerReportModel(
          asesorNombre: officer,
          periodo: periodoSemana,
          visitasAsignadas: 35,
          visitasRealizadas: 28,
          visitasPendientes: 7,
          solicitudesEnviadas: 9,
          solicitudesAprobadas: 6,
          solicitudesDesembolsadas: 3,
          montoSolicitado: 85000,
          montoAprobado: 62000,
          clientesEnMora: 4,
          montoVencido: 12500,
          gestionesCobranza: 8,
          tasaAprobacion: 6 / 9,
          coberturaVisitas: 28 / 35,
        ),
      periodoMes => OfficerReportModel(
          asesorNombre: officer,
          periodo: periodoMes,
          visitasAsignadas: 140,
          visitasRealizadas: 118,
          visitasPendientes: 22,
          solicitudesEnviadas: 32,
          solicitudesAprobadas: 24,
          solicitudesDesembolsadas: 18,
          montoSolicitado: 320000,
          montoAprobado: 245000,
          clientesEnMora: 4,
          montoVencido: 12500,
          gestionesCobranza: 22,
          tasaAprobacion: 24 / 32,
          coberturaVisitas: 118 / 140,
        ),
      _ => OfficerReportModel(
          asesorNombre: officer,
          periodo: periodoHoy,
          visitasAsignadas: 8,
          visitasRealizadas: 5,
          visitasPendientes: 3,
          solicitudesEnviadas: 2,
          solicitudesAprobadas: 1,
          solicitudesDesembolsadas: 0,
          montoSolicitado: 15000,
          montoAprobado: 8000,
          clientesEnMora: 4,
          montoVencido: 12500,
          gestionesCobranza: 2,
          tasaAprobacion: 0.5,
          coberturaVisitas: 5 / 8,
        ),
    };
  }

  List<ReportActivityItem> _buildActivitiesForPeriod(String period) {
    final now = DateTime.now();

    return switch (period) {
      periodoSemana => [
          ReportActivityItem(
            id: 'w1',
            titulo: 'Desembolso confirmado',
            descripcion: 'María Huamán — S/ 12,000',
            fecha: now.subtract(const Duration(days: 1)),
            tipo: ReportActivityType.desembolso,
          ),
          ReportActivityItem(
            id: 'w2',
            titulo: 'Solicitud aprobada',
            descripcion: 'Pedro Quispe — crédito grupal',
            fecha: now.subtract(const Duration(days: 2)),
            tipo: ReportActivityType.solicitud,
          ),
          ReportActivityItem(
            id: 'w3',
            titulo: 'Visita completada',
            descripcion: 'Carmen Flores — renovación',
            fecha: now.subtract(const Duration(days: 3)),
            tipo: ReportActivityType.visita,
          ),
          ReportActivityItem(
            id: 'w4',
            titulo: 'Gestión de cobranza',
            descripcion: 'José Ramos — compromiso de pago',
            fecha: now.subtract(const Duration(days: 4)),
            tipo: ReportActivityType.cobranza,
          ),
        ],
      periodoMes => [
          ReportActivityItem(
            id: 'm1',
            titulo: 'Meta mensual de visitas',
            descripcion: '118 de 140 visitas completadas',
            fecha: now.subtract(const Duration(days: 2)),
            tipo: ReportActivityType.alerta,
          ),
          ReportActivityItem(
            id: 'm2',
            titulo: 'Desembolso grupal',
            descripcion: 'Comité San Juan — S/ 45,000',
            fecha: now.subtract(const Duration(days: 5)),
            tipo: ReportActivityType.desembolso,
          ),
          ReportActivityItem(
            id: 'm3',
            titulo: 'Solicitud enviada',
            descripcion: 'Rosa Quispe — EXP-ALF-2026-0001',
            fecha: now.subtract(const Duration(days: 8)),
            tipo: ReportActivityType.solicitud,
          ),
          ReportActivityItem(
            id: 'm4',
            titulo: 'Visita en campo',
            descripcion: 'Lucía Mendoza — seguimiento cartera',
            fecha: now.subtract(const Duration(days: 12)),
            tipo: ReportActivityType.visita,
          ),
          ReportActivityItem(
            id: 'm5',
            titulo: 'Gestión de cobranza',
            descripcion: 'Ana Torres — contacto telefónico',
            fecha: now.subtract(const Duration(days: 15)),
            tipo: ReportActivityType.cobranza,
          ),
        ],
      _ => [
          ReportActivityItem(
            id: 'd1',
            titulo: 'Visita registrada',
            descripcion: 'Carmen Flores — gestión en campo',
            fecha: now.subtract(const Duration(hours: 2)),
            tipo: ReportActivityType.visita,
          ),
          ReportActivityItem(
            id: 'd2',
            titulo: 'Solicitud enviada',
            descripcion: 'Rosa Quispe — EXP-ALF-2026-0001',
            fecha: now.subtract(const Duration(hours: 4)),
            tipo: ReportActivityType.solicitud,
          ),
          ReportActivityItem(
            id: 'd3',
            titulo: 'Gestión de cobranza',
            descripcion: 'José Ramos — compromiso de pago',
            fecha: now.subtract(const Duration(hours: 6)),
            tipo: ReportActivityType.cobranza,
          ),
          ReportActivityItem(
            id: 'd4',
            titulo: 'Visita pendiente',
            descripcion: '3 clientes por visitar hoy',
            fecha: now.subtract(const Duration(hours: 1)),
            tipo: ReportActivityType.alerta,
          ),
        ],
    };
  }
}
