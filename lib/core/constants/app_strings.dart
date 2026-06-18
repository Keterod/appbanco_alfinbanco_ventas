abstract final class AppStrings {
  // ── Marca ─────────────────────────────────
  static const String bankName = 'Banco Alfin';
  static const String appName = 'App Fuerza de Ventas';
  static const String appTitle = '$bankName · $appName';

  // ── Roles ─────────────────────────────────
  static const String officerRole = 'Oficial de Crédito';
  static const String officerPortal = 'Portal Oficial de Crédito';

  // ── Login ─────────────────────────────────
  static const String loginTitle = 'Acceso de oficial';
  static const String loginSubtitle =
      'Ingrese sus credenciales institucionales.';
  static const String loginEmployeeCode = 'Código de empleado';
  static const String loginPassword = 'Contraseña';
  static const String loginButton = 'Ingresar';
  static const String loginDemoCode = 'Demo: OFI001';
  static const String loginDemoPassword = 'Demo / Supabase: alfin123';
  static const String loginDemoMode =
      'Modo demostración — acceso institucional';

  // ── Drawer ────────────────────────────────
  static const String drawerHome = 'Inicio';
  static const String drawerCartera = 'Cartera diaria';
  static const String drawerRuta = 'Planificar ruta';
  static const String drawerBuro = 'Consulta de buró';
  static const String drawerSolicitud = 'Nueva solicitud';
  static const String drawerEstado = 'Estado de solicitudes';
  static const String drawerCobranza = 'Cartera vencida';
  static const String drawerReportes = 'Reportes';
  static const String drawerLogout = 'Cerrar sesión';

  // ── Home / Dashboard ──────────────────────
  static const String homeWelcomePrefix = 'Hola,';
  static const String homeSummaryTitle = 'Resumen del día';
  static const String homeQuickAccess = 'Accesos rápidos';
  static const String homeRecentActivity = 'Actividad reciente';
  static const String homeLogout = 'Cerrar sesión';
  static const String demoBadge = 'Modo demostración';

  // ── Cartera ───────────────────────────────
  static const String carteraTitle = 'Cartera diaria';
  static const String carteraVisits = 'Visitas del día';
  static const String carteraPending = 'Pendientes';
  static const String carteraVisited = 'Visitados';

  // ── Buró ──────────────────────────────────
  static const String buroTitle = 'Consulta de buró';
  static const String buroClient = 'Cliente';
  static const String buroDniLabel = 'DNI a consultar *';
  static const String buroDniHint = '8 dígitos';
  static const String buroConsentTitle = 'Consentimiento informado';
  static const String buroConsentText =
      'El cliente autoriza a $bankName a consultar su historial '
      'crediticio en centrales de riesgo y listas de restricción, '
      'exclusivamente para evaluación de una solicitud de crédito.';
  static const String buroConsentCheckbox = 'Cliente autoriza la consulta';
  static const String buroButtonConsult = 'Consultar buró y listas';
  static const String buroButtonContinue = 'Continuar solicitud';
  static const String buroButtonNewQuery = 'Nueva consulta';
  static const String buroResultTitle = 'Resultado de consulta';
  static const String buroRestrictionList = 'Lista de restricción';
  static const String buroFieldVerification = 'Verificación en campo';

  // ── Ficha cliente ─────────────────────────
  static const String fichaNoClientData =
      'Cliente no encontrado. Seleccione desde cartera.';

  // ── Solicitud de crédito ──────────────────
  static const String solicitudStep1Title = 'Datos del solicitante';
  static const String solicitudStep2Title = 'Datos del negocio';
  static const String solicitudStep3Title = 'Condiciones del crédito';
  static const String solicitudStep4Title = 'Confirmación';

  // ── Estado solicitudes ────────────────────
  static const String estadoTitle = 'Estado de solicitudes';

  // ── Transmisión ───────────────────────────
  static const String transmisionTitle = 'Transmisión electrónica';

  // ── Documentos ────────────────────────────
  static const String documentosTitle = 'Documentos';

  // ── Cobranza ──────────────────────────────
  static const String cobranzaTitle = 'Cartera vencida';
  static const String cobranzaAccionTitle = 'Registrar gestión';

  // ── Ruta de visitas ───────────────────────
  static const String rutaTitle = 'Ruta de visitas';

  // ── Reportes ──────────────────────────────
  static const String reportesTitle = 'Reportes';

  // ── Splash / Sesión ───────────────────────
  static const String splashChecking = 'Verificando sesión…';
  static const String splashLoading = 'Cargando sesión…';

  // ── Placeholders ──────────────────────────
  static const String placeholderPdfExport =
      'Exportación PDF — función en siguiente fase';
  static const String placeholderReportExport =
      'Exportación de reportes disponible en siguiente fase';
  static const String placeholderNavigation =
      'Navegación externa — función en siguiente fase';
  static const String placeholderMap =
      'Mapa simulado — integración de mapas en siguiente fase';
}
