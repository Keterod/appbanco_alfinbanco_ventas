import 'package:flutter/foundation.dart';

import '../../cobranza/data/cobranza_local_repository.dart';
import '../../estado_solicitudes/domain/request_status_mock_data.dart';
import '../../estado_solicitudes/domain/request_status_model.dart';

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
  static const String officerName = 'Oficial Alfin';

  bool _isLoading = false;
  int _visitasDelDia = 0;
  int _pendientes = 0;
  int _solicitudesEnEvaluacion = 0;
  int _clientesEnMora = 0;
  List<RecentActivityItem> _actividadReciente = [];

  bool get isLoading => _isLoading;
  int get visitasDelDia => _visitasDelDia;
  int get pendientes => _pendientes;
  int get solicitudesEnEvaluacion => _solicitudesEnEvaluacion;
  int get clientesEnMora => _clientesEnMora;
  List<RecentActivityItem> get actividadReciente =>
      List.unmodifiable(_actividadReciente);

  Future<void> loadDashboard() async {
    _isLoading = true;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 350));

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

    _isLoading = false;
    notifyListeners();
  }
}
