import 'package:flutter/foundation.dart';

import '../../../core/supabase/supabase_helper.dart';
import '../data/ficha_cliente_repository.dart';
import '../domain/client_detail_model.dart';

/// ViewModel de ficha del cliente (HU-V03). Datos mock por clientId.
class FichaClienteViewModel extends ChangeNotifier {
  final FichaClienteRepository _repo = FichaClienteRepository.instance;

  bool _isLoading = false;
  String? _errorMessage;
  ClientDetailModel? _client;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ClientDetailModel? get client => _client;

  Future<void> loadClientDetail(String clientId) async {
    _isLoading = true;
    _errorMessage = null;
    _client = null;
    notifyListeners();

    if (SupabaseHelper.hasSession) {
      try {
        SupabaseHelper.log('FichaClienteViewModel load Supabase id=$clientId');
        final remote = await _repo.loadClientDetail(clientId);
        if (remote != null) {
          _client = remote;
          _isLoading = false;
          notifyListeners();
          return;
        }
        SupabaseHelper.log('ficha no encontrada en Supabase, fallback mock');
      } catch (error, stackTrace) {
        SupabaseHelper.log('ficha falló, usando fallback mock');
        SupabaseHelper.logError(error, stackTrace);
      }
    }

    await Future<void>.delayed(const Duration(milliseconds: 300));

    final detail = _mockDetails[clientId];
    if (detail == null) {
      _errorMessage = 'No se encontró información del cliente.';
      _isLoading = false;
      notifyListeners();
      return;
    }

    _client = detail;
    _isLoading = false;
    notifyListeners();
  }

  static final Map<String, ClientDetailModel> _mockDetails = {
    'cli-001': ClientDetailModel(
      id: 'cli-001',
      nombres: 'Rosa',
      apellidos: 'Quispe',
      documento: '45678912',
      telefono: '+51 987 654 321',
      direccion: 'Av. Los Olivos 234, Los Olivos, Lima',
      tipoNegocio: 'Comercio minorista',
      nombreNegocio: 'Bodega Quispe',
      antiguedadNegocio: '4 años',
      deudaTotal: 3200.00,
      cuotasAlDia: 8,
      cuotasEnMora: 0,
      ultimoPago: DateTime(2026, 5, 28),
      calificacionSbs: CalificacionSbs.normal,
      montoPreaprobado: 12000,
      plazoSugerido: 18,
      teaReferencial: 38.5,
      fechaVencimientoOferta: DateTime(2026, 7, 15),
      historialCreditos: const [
        CreditHistoryItem(
          producto: 'Microcrédito Emprendedor',
          monto: 8500,
          plazoMeses: 12,
          tasa: 36.0,
          estado: 'Vigente',
          porcentajePagosPuntuales: 94.5,
        ),
        CreditHistoryItem(
          producto: 'Capital de Trabajo',
          monto: 5000,
          plazoMeses: 9,
          tasa: 34.0,
          estado: 'Cancelado',
          porcentajePagosPuntuales: 100,
        ),
      ],
    ),
    'cli-002': ClientDetailModel(
      id: 'cli-002',
      nombres: 'Miguel',
      apellidos: 'Huamán',
      documento: '72345618',
      telefono: '+51 912 345 678',
      direccion: 'Jr. Huascar 120, Huancayo',
      tipoNegocio: 'Servicios',
      nombreNegocio: 'Taller Huamán',
      antiguedadNegocio: '2 años',
      deudaTotal: 0,
      cuotasAlDia: 0,
      cuotasEnMora: 0,
      ultimoPago: DateTime(2025, 11, 10),
      calificacionSbs: CalificacionSbs.normal,
      montoPreaprobado: 18000,
      plazoSugerido: 24,
      teaReferencial: 37.0,
      fechaVencimientoOferta: DateTime(2026, 8, 1),
      historialCreditos: const [
        CreditHistoryItem(
          producto: 'Crédito Nuevo Emprendedor',
          monto: 10000,
          plazoMeses: 18,
          tasa: 35.5,
          estado: 'Cancelado',
          porcentajePagosPuntuales: 98.2,
        ),
      ],
    ),
    'cli-003': ClientDetailModel(
      id: 'cli-003',
      nombres: 'Carmen',
      apellidos: 'Flores',
      documento: '40123456',
      telefono: '+51 956 112 233',
      direccion: 'Mz. B Lt. 8 Urb. Santa Rosa, Callao',
      tipoNegocio: 'Alimentos',
      nombreNegocio: 'Pollería Flores',
      antiguedadNegocio: '6 años',
      deudaTotal: 1850.50,
      cuotasAlDia: 2,
      cuotasEnMora: 3,
      ultimoPago: DateTime(2026, 4, 5),
      calificacionSbs: CalificacionSbs.cpp,
      historialCreditos: const [
        CreditHistoryItem(
          producto: 'Recuperación Mora',
          monto: 3500,
          plazoMeses: 6,
          tasa: 42.0,
          estado: 'Vigente',
          porcentajePagosPuntuales: 62.0,
        ),
        CreditHistoryItem(
          producto: 'Microcrédito',
          monto: 2800,
          plazoMeses: 8,
          tasa: 38.0,
          estado: 'Refinanciado',
          porcentajePagosPuntuales: 71.5,
        ),
      ],
    ),
    'cli-004': ClientDetailModel(
      id: 'cli-004',
      nombres: 'José',
      apellidos: 'Ramos',
      documento: '10876543',
      telefono: '+51 934 567 890',
      direccion: 'Av. Universitaria 890, San Martín de Porres',
      tipoNegocio: 'Transporte',
      nombreNegocio: 'Transportes Ramos EIRL',
      antiguedadNegocio: '8 años',
      deudaTotal: 12400.00,
      cuotasAlDia: 5,
      cuotasEnMora: 2,
      ultimoPago: DateTime(2026, 5, 12),
      calificacionSbs: CalificacionSbs.deficiente,
      montoPreaprobado: 8000,
      plazoSugerido: 12,
      teaReferencial: 45.0,
      fechaVencimientoOferta: DateTime(2026, 6, 30),
      historialCreditos: const [
        CreditHistoryItem(
          producto: 'Renovación Plus',
          monto: 15000,
          plazoMeses: 24,
          tasa: 40.0,
          estado: 'Vigente',
          porcentajePagosPuntuales: 78.0,
        ),
        CreditHistoryItem(
          producto: 'Vehículo productivo',
          monto: 22000,
          plazoMeses: 36,
          tasa: 39.5,
          estado: 'Vigente',
          porcentajePagosPuntuales: 81.3,
        ),
      ],
    ),
    'cli-005': ClientDetailModel(
      id: 'cli-005',
      nombres: 'Ana',
      apellidos: 'Torres',
      documento: '71234567',
      telefono: '+51 998 776 554',
      direccion: 'Calle Las Flores 45, San Juan de Lurigancho, Lima',
      tipoNegocio: 'Textil',
      nombreNegocio: 'Confecciones Torres',
      antiguedadNegocio: '5 años',
      deudaTotal: 0,
      cuotasAlDia: 0,
      cuotasEnMora: 0,
      ultimoPago: DateTime(2026, 5, 20),
      calificacionSbs: CalificacionSbs.normal,
      montoPreaprobado: 25000,
      plazoSugerido: 30,
      teaReferencial: 36.8,
      fechaVencimientoOferta: DateTime(2026, 9, 10),
      historialCreditos: const [
        CreditHistoryItem(
          producto: 'Capital de Trabajo Plus',
          monto: 15000,
          plazoMeses: 18,
          tasa: 35.0,
          estado: 'Cancelado',
          porcentajePagosPuntuales: 100,
        ),
        CreditHistoryItem(
          producto: 'Ampliación Negocio',
          monto: 12000,
          plazoMeses: 15,
          tasa: 36.5,
          estado: 'Cancelado',
          porcentajePagosPuntuales: 99.1,
        ),
        CreditHistoryItem(
          producto: 'Microcrédito Mujer',
          monto: 8000,
          plazoMeses: 12,
          tasa: 34.5,
          estado: 'Cancelado',
          porcentajePagosPuntuales: 100,
        ),
      ],
    ),
  };
}
