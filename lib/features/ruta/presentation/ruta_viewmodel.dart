import 'package:flutter/foundation.dart';

import '../domain/route_visit_model.dart';

/// ViewModel de planificación de ruta diaria (HU-V09).
class RutaViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  List<RouteVisitModel> _visitas = [];
  List<RouteVisitModel> _visitasIniciales = [];
  bool _modoOptimizado = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  List<RouteVisitModel> get visitas => List.unmodifiable(_visitas);
  bool get rutaOptimizada => _modoOptimizado;

  double get distanciaTotalKm =>
      _visitas.fold(0, (sum, v) => sum + v.distanciaKm);

  int get tiempoTotalMin =>
      _visitas.fold(0, (sum, v) => sum + v.tiempoEstimadoMin);

  int get totalVisitas => _visitas.length;

  int get pendientes => getPendingVisits().length;

  int get visitadas => getVisitedVisits().length;

  List<RouteVisitModel> getPendingVisits() =>
      _visitas.where((v) => v.isPendiente).toList(growable: false);

  List<RouteVisitModel> getVisitedVisits() =>
      _visitas.where((v) => v.isVisitado).toList(growable: false);

  Future<void> loadTodayRoute() async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 450));

    _visitas = _buildInitialVisits();
    _visitasIniciales = List.from(_visitas);
    _modoOptimizado = false;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> optimizeRoute() async {
    if (_visitas.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 500));

    final sorted = List<RouteVisitModel>.from(_visitas)
      ..sort((a, b) {
        final p = a.prioridad.sortOrder.compareTo(b.prioridad.sortOrder);
        if (p != 0) return p;
        return a.distanciaKm.compareTo(b.distanciaKm);
      });

    _visitas = [
      for (var i = 0; i < sorted.length; i++)
        sorted[i].copyWith(ordenSugerido: i + 1),
    ];

    _modoOptimizado = true;
    _successMessage = 'Ruta optimizada según prioridad y distancia.';
    _isLoading = false;
    notifyListeners();
  }

  void resetRoute() {
    _visitas = List.from(_visitasIniciales);
    _modoOptimizado = false;
    _successMessage = 'Ruta restablecida al orden inicial.';
    notifyListeners();
  }

  void markAsVisited(String clientId) {
    final index = _visitas.indexWhere((v) => v.clientId == clientId);
    if (index < 0) {
      _errorMessage = 'Visita no encontrada.';
      notifyListeners();
      return;
    }

    _visitas[index] = _visitas[index].copyWith(
      estadoVisita: RouteVisitStatus.visitado,
    );
    _successMessage =
        '${_visitas[index].clienteNombre} marcado como visitado.';
    notifyListeners();
  }

  String openNavigation(String clientId) {
    final index = _visitas.indexWhere((v) => v.clientId == clientId);
    if (index < 0) {
      _errorMessage = 'Visita no encontrada.';
      notifyListeners();
      return _errorMessage!;
    }

    final visita = _visitas[index];
    final msg =
        'Navegación externa — función en siguiente fase. Destino: ${visita.clienteNombre}';
    _successMessage = msg;
    notifyListeners();
    return msg;
  }

  static List<RouteVisitModel> _buildInitialVisits() {
    return [
      RouteVisitModel(
        id: 'vis-001',
        clientId: 'cli-001',
        clienteNombre: 'Rosa Quispe',
        direccion: 'Av. Los Olivos 234, Los Olivos, Lima',
        tipoGestion: RouteManagementType.renovacion,
        prioridad: RoutePriority.media,
        estadoVisita: RouteVisitStatus.pendiente,
        lat: -11.9912,
        lng: -77.0715,
        distanciaKm: 4.2,
        tiempoEstimadoMin: 18,
        ordenSugerido: 1,
      ),
      RouteVisitModel(
        id: 'vis-002',
        clientId: 'cli-002',
        clienteNombre: 'Miguel Huamán',
        direccion: 'Jr. Huascar 120, Huancayo',
        tipoGestion: RouteManagementType.nuevaSolicitud,
        prioridad: RoutePriority.normal,
        estadoVisita: RouteVisitStatus.pendiente,
        lat: -12.0650,
        lng: -75.2048,
        distanciaKm: 8.5,
        tiempoEstimadoMin: 35,
        ordenSugerido: 2,
      ),
      RouteVisitModel(
        id: 'vis-003',
        clientId: 'cli-003',
        clienteNombre: 'Carmen Flores',
        direccion: 'Mz. B Lt. 8 Urb. Santa Rosa, Callao',
        tipoGestion: RouteManagementType.cobranza,
        prioridad: RoutePriority.alta,
        estadoVisita: RouteVisitStatus.pendiente,
        lat: -12.0464,
        lng: -77.1180,
        distanciaKm: 2.8,
        tiempoEstimadoMin: 14,
        ordenSugerido: 3,
      ),
      RouteVisitModel(
        id: 'vis-004',
        clientId: 'cli-004',
        clienteNombre: 'José Ramos',
        direccion: 'Av. Universitaria 890, San Martín de Porres',
        tipoGestion: RouteManagementType.renovacion,
        prioridad: RoutePriority.media,
        estadoVisita: RouteVisitStatus.pendiente,
        lat: -11.9520,
        lng: -77.0625,
        distanciaKm: 5.1,
        tiempoEstimadoMin: 22,
        ordenSugerido: 4,
      ),
      RouteVisitModel(
        id: 'vis-005',
        clientId: 'cli-005',
        clienteNombre: 'Ana Torres',
        direccion: 'Calle Las Flores 45, San Juan de Lurigancho',
        tipoGestion: RouteManagementType.nuevaSolicitud,
        prioridad: RoutePriority.normal,
        estadoVisita: RouteVisitStatus.pendiente,
        lat: -12.0180,
        lng: -76.9850,
        distanciaKm: 6.3,
        tiempoEstimadoMin: 28,
        ordenSugerido: 5,
      ),
    ];
  }
}
