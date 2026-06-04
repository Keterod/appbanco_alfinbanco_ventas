import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../domain/document_model.dart';

/// ViewModel de captura/revisión de documentos (HU-V05). Datos mock.
class DocumentosViewModel extends ChangeNotifier {
  static const String solicitudDemoDefault = 'SOL-DEMO-001';
  static final math.Random _random = math.Random();

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  String _solicitudId = solicitudDemoDefault;
  List<DocumentModel> _documentos = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  String get solicitudId => _solicitudId;
  List<DocumentModel> get documentos => List.unmodifiable(_documentos);

  int requiredCount() =>
      _documentos.where((d) => d.obligatorio).length;

  int readyCount() => _documentos
      .where((d) => d.obligatorio && d.estado == EstadoDocumento.listo)
      .length;

  bool allRequiredReady() => readyCount() == requiredCount() && requiredCount() > 0;

  double get progressRequired {
    final total = requiredCount();
    if (total == 0) return 0;
    return readyCount() / total;
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
  }

  Future<void> loadDocuments(String solicitudId) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    _solicitudId = solicitudId.isNotEmpty ? solicitudId : solicitudDemoDefault;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 400));

    _documentos = _buildDocumentList(_solicitudId);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> captureDocument(String documentId) async {
    await _simulateCapture(documentId);
  }

  Future<void> retakeDocument(String documentId) async {
    await _simulateCapture(documentId);
  }

  Future<void> deleteDocument(String documentId) async {
    final index = _documentos.indexWhere((d) => d.id == documentId);
    if (index < 0) {
      _errorMessage = 'Documento no encontrado.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 250));

    _documentos[index] = _documentos[index].copyWith(clearCapture: true);
    _successMessage = 'Documento eliminado. Puede capturarlo nuevamente.';
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _simulateCapture(String documentId) async {
    final index = _documentos.indexWhere((d) => d.id == documentId);
    if (index < 0) {
      _errorMessage = 'Documento no encontrado.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 650));

    final doc = _documentos[index];
    final tamanioKb = 300 + _random.nextInt(501);
    final nitidez = 70 + _random.nextDouble() * 28;
    final path =
        'mock_${doc.tipoDocumento.name}_${_solicitudId.replaceAll('-', '_').toLowerCase()}.jpg';

    _documentos[index] = doc.copyWith(
      estado: EstadoDocumento.listo,
      imagePathSimulado: path,
      tamanioKb: tamanioKb,
      nitidezScore: double.parse(nitidez.toStringAsFixed(1)),
      fechaCaptura: DateTime.now(),
    );

    _successMessage = '${doc.nombreVisible} capturado correctamente.';
    _isLoading = false;
    notifyListeners();
  }

  static List<DocumentModel> _buildDocumentList(String solicitudId) {
    DocumentModel template(TipoDocumento tipo) {
      return DocumentModel(
        id: 'doc-${tipo.name}',
        solicitudId: solicitudId,
        tipoDocumento: tipo,
        nombreVisible: tipo.nombreVisible,
        obligatorio: tipo.esObligatorio,
        estado: EstadoDocumento.pendiente,
      );
    }

    return [
      template(TipoDocumento.dniAnverso),
      template(TipoDocumento.dniReverso),
      template(TipoDocumento.fotoNegocio),
      template(TipoDocumento.fotoAsesorCliente),
      template(TipoDocumento.ruc),
      template(TipoDocumento.reciboServicios),
      template(TipoDocumento.contratoArrendamiento),
    ];
  }
}
