import '../domain/collection_model.dart';

/// Repositorio local en memoria para cobranza (mock).
/// Preparado para reemplazar por Supabase/SQLite.
class CobranzaLocalRepository {
  CobranzaLocalRepository._();
  static final CobranzaLocalRepository instance = CobranzaLocalRepository._();

  bool _initialized = false;
  final List<OverdueClientModel> _clients = [];
  int _actionSequence = 1;

  List<OverdueClientModel> get clients => List.unmodifiable(_clients);

  void ensureInitialized() {
    if (_initialized) return;
    _clients.addAll(_buildSeedClients());
    _initialized = true;
  }

  void resetForDemo() {
    _clients.clear();
    _initialized = false;
    _actionSequence = 1;
    ensureInitialized();
  }

  OverdueClientModel? getById(String id) {
    try {
      return _clients.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  OverdueClientModel? getByClientId(String clientId) {
    try {
      return _clients.firstWhere((c) => c.clientId == clientId);
    } catch (_) {
      return null;
    }
  }

  void registerAction(String overdueClientId, CollectionActionModel action) {
    final index = _clients.indexWhere((c) => c.id == overdueClientId);
    if (index < 0) return;

    final client = _clients[index];
    final newStatus = switch (action.resultado) {
      CollectionResult.compromisoPago => CollectionStatus.compromisoVigente,
      _ => CollectionStatus.gestionado,
    };

    _clients[index] = client.copyWith(
      estadoGestion: newStatus,
      fechaUltimoContacto: action.timestampGestion,
      acciones: [...client.acciones, action],
    );
  }

  String nextActionId() {
    final id = 'COB-ACT-${_actionSequence.toString().padLeft(4, '0')}';
    _actionSequence++;
    return id;
  }

  static List<OverdueClientModel> _buildSeedClients() {
    return [
      _seed(
        id: 'mor-001',
        clientId: 'cli-003',
        nombre: 'Carmen Flores',
        doc: '40123456',
        tel: '956112233',
        dir: 'Mz. B Lt. 8 Urb. Santa Rosa, Callao',
        credito: 'CR-3301',
        monto: 1850.50,
        dias: 18,
        ultimoContacto: DateTime(2026, 5, 28),
        vencimiento: DateTime(2026, 5, 15),
        estado: CollectionStatus.pendiente,
      ),
      _seed(
        id: 'mor-002',
        clientId: 'cli-006',
        nombre: 'Luis Mendoza',
        doc: '44556677',
        tel: '934111222',
        dir: 'Av. Argentina 450, Lima',
        credito: 'CR-3302',
        monto: 920.00,
        dias: 12,
        ultimoContacto: DateTime(2026, 5, 30),
        vencimiento: DateTime(2026, 5, 22),
        estado: CollectionStatus.gestionado,
      ),
      _seed(
        id: 'mor-003',
        clientId: 'cli-007',
        nombre: 'Elena Rojas',
        doc: '33445566',
        tel: '987222333',
        dir: 'Calle Los Pinos 88, SMP',
        credito: 'CR-3303',
        monto: 2400.00,
        dias: 25,
        ultimoContacto: DateTime(2026, 5, 20),
        vencimiento: DateTime(2026, 5, 8),
        estado: CollectionStatus.pendiente,
      ),
      _seed(
        id: 'mor-004',
        clientId: 'cli-004',
        nombre: 'José Ramos',
        doc: '10876543',
        tel: '934567890',
        dir: 'Av. Universitaria 890, SMP',
        credito: 'CR-3304',
        monto: 3100.00,
        dias: 42,
        ultimoContacto: DateTime(2026, 5, 10),
        vencimiento: DateTime(2026, 4, 22),
        estado: CollectionStatus.compromisoVigente,
      ),
      _seed(
        id: 'mor-005',
        clientId: 'cli-008',
        nombre: 'Carlos Vega',
        doc: '22334455',
        tel: '912888999',
        dir: 'Jr. Cusco 210, Breña',
        credito: 'CR-3305',
        monto: 4500.00,
        dias: 55,
        ultimoContacto: DateTime(2026, 4, 28),
        vencimiento: DateTime(2026, 4, 8),
        estado: CollectionStatus.pendiente,
      ),
      _seed(
        id: 'mor-006',
        clientId: 'cli-009',
        nombre: 'Patricia Salas',
        doc: '55667788',
        tel: '998111444',
        dir: 'Av. Primavera 1200, Surco',
        credito: 'CR-3306',
        monto: 7800.00,
        dias: 78,
        ultimoContacto: DateTime(2026, 4, 5),
        vencimiento: DateTime(2026, 3, 15),
        estado: CollectionStatus.pendiente,
      ),
      _seed(
        id: 'mor-007',
        clientId: 'cli-010',
        nombre: 'Roberto Díaz',
        doc: '66778899',
        tel: '945666777',
        dir: 'Mz. D Lt. 3 Villa El Salvador',
        credito: 'CR-3307',
        monto: 12500.00,
        dias: 95,
        ultimoContacto: DateTime(2026, 3, 20),
        vencimiento: DateTime(2026, 2, 28),
        estado: CollectionStatus.pendiente,
      ),
    ];
  }

  static OverdueClientModel _seed({
    required String id,
    required String clientId,
    required String nombre,
    required String doc,
    required String tel,
    required String dir,
    required String credito,
    required double monto,
    required int dias,
    required DateTime ultimoContacto,
    required DateTime vencimiento,
    required CollectionStatus estado,
  }) {
    return OverdueClientModel(
      id: id,
      clientId: clientId,
      clienteNombre: nombre,
      documento: doc,
      telefono: tel,
      direccion: dir,
      creditoId: credito,
      montoVencido: monto,
      diasMora: dias,
      fechaUltimoContacto: ultimoContacto,
      fechaVencimientoCuota: vencimiento,
      estadoGestion: estado,
      prioridad: OverduePriority.fromDiasMora(dias),
    );
  }
}
