/// Estado civil del solicitante.
enum EstadoCivil {
  soltero('Soltero/a'),
  casado('Casado/a'),
  conviviente('Conviviente'),
  divorciado('Divorciado/a'),
  viudo('Viudo/a');

  const EstadoCivil(this.label);
  final String label;
}

/// Grado de instrucción.
enum GradoInstruccion {
  primaria('Primaria'),
  secundaria('Secundaria'),
  tecnico('Técnico'),
  universitario('Universitario'),
  postgrado('Postgrado');

  const GradoInstruccion(this.label);
  final String label;
}

/// Tipo de negocio.
enum TipoNegocio {
  comercioMinorista('Comercio minorista'),
  servicios('Servicios'),
  alimentos('Alimentos'),
  transporte('Transporte'),
  textil('Textil'),
  manufactura('Manufactura'),
  otro('Otro');

  const TipoNegocio(this.label);
  final String label;
}

/// Moneda del crédito.
enum Moneda {
  pen('PEN'),
  usd('USD');

  const Moneda(this.label);
  final String label;
}

/// Tipo de cuota.
enum TipoCuota {
  fija('Cuota fija'),
  decreciente('Cuota decreciente'),
  balloon('Balloon');

  const TipoCuota(this.label);
  final String label;
}

/// Garantía del crédito.
enum Garantia {
  personal('Garantía personal'),
  prendaria('Garantía prendaria'),
  hipotecaria('Garantía hipotecaria'),
  mixta('Garantía mixta');

  const Garantia(this.label);
  final String label;
}

/// Estado de la solicitud.
enum EstadoSolicitud {
  borrador('Borrador'),
  pendienteEnvio('Pendiente de envío'),
  enviadoDemo('Enviado (demo)');

  const EstadoSolicitud(this.label);
  final String label;
}

/// Plazos permitidos en meses.
const List<int> plazosPermitidosMeses = [3, 6, 12, 18, 24, 36, 48, 60];

/// Modelo de solicitud de crédito (HU-V04).
class CreditRequestModel {
  const CreditRequestModel({
    this.clientId,
    this.nombres = '',
    this.apellidos = '',
    this.documento = '',
    this.fechaNacimiento = '',
    this.estadoCivil,
    this.gradoInstruccion,
    this.telefono = '',
    this.correo = '',
    this.tipoNegocio,
    this.nombreNegocio = '',
    this.direccionNegocio = '',
    this.antiguedadNegocioMeses = 0,
    this.ingresosMensuales = 0,
    this.gastosMensuales = 0,
    this.patrimonioEstimado = 0,
    this.destinoCredito = '',
    this.actividadEconomica = '',
    this.montoSolicitado = 5000,
    this.plazoMeses = 12,
    this.moneda = Moneda.pen,
    this.tipoCuota,
    this.garantia,
    this.teaReferencial = 0.36,
    this.cuotaEstimada = 0,
    this.aceptaDeclaracion = false,
    this.firmaSimulada = false,
    this.estadoSolicitud = EstadoSolicitud.borrador,
    this.numeroExpediente,
  });

  final String? clientId;
  final String nombres;
  final String apellidos;
  final String documento;
  final String fechaNacimiento;
  final EstadoCivil? estadoCivil;
  final GradoInstruccion? gradoInstruccion;
  final String telefono;
  final String correo;
  final TipoNegocio? tipoNegocio;
  final String nombreNegocio;
  final String direccionNegocio;
  final int antiguedadNegocioMeses;
  final double ingresosMensuales;
  final double gastosMensuales;
  final double patrimonioEstimado;
  final String destinoCredito;
  final String actividadEconomica;
  final double montoSolicitado;
  final int plazoMeses;
  final Moneda moneda;
  final TipoCuota? tipoCuota;
  final Garantia? garantia;
  final double teaReferencial;
  final double cuotaEstimada;
  final bool aceptaDeclaracion;
  final bool firmaSimulada;
  final EstadoSolicitud estadoSolicitud;
  final String? numeroExpediente;

  double get totalAPagar => cuotaEstimada * plazoMeses;

  double get costoFinanciero => totalAPagar - montoSolicitado;

  String get nombreCompleto => '$nombres $apellidos'.trim();
}
