import 'package:flutter/material.dart';

import '../../features/auth/presentation/login_oficial_screen.dart';
import '../../features/home/presentation/home_oficial_screen.dart';
import '../../features/cartera/presentation/cartera_diaria_screen.dart';
import '../../features/ficha_cliente/presentation/ficha_cliente_screen.dart';
import '../../features/solicitud/presentation/solicitud_credito_screen.dart';
import '../../features/documentos/presentation/documentos_screen.dart';
import '../../features/transmision/presentation/transmision_screen.dart';
import '../../features/estado_solicitudes/presentation/estado_solicitudes_screen.dart';
import '../../features/estado_solicitudes/presentation/estado_solicitud_detalle_screen.dart';
import '../../features/buro/presentation/buro_screen.dart';
import '../../features/ruta/presentation/ruta_screen.dart';
import '../../features/cobranza/presentation/cobranza_screen.dart';
import '../../features/cobranza/presentation/cobranza_accion_screen.dart';
import '../../features/reportes/presentation/reportes_screen.dart';
import '../../core/constants/app_theme.dart';
import '../../core/constants/app_routes.dart';

class AppNavigation extends StatelessWidget {
  const AppNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alfin Banco — Ventas',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.login,
      routes: {
        AppRoutes.login: (_) => const LoginOficialScreen(),
        AppRoutes.homeOficial: (_) => const HomeOficialScreen(),
        AppRoutes.cartera: (_) => const CarteraDiariaScreen(),
        AppRoutes.fichaCliente: (context) {
          final clientId =
              ModalRoute.of(context)!.settings.arguments as String;
          return FichaClienteScreen(clientId: clientId);
        },
        AppRoutes.solicitudCredito: (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          final clientId = args is String ? args : null;
          return SolicitudCreditoScreen(clientId: clientId);
        },
        AppRoutes.documentos: (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          final solicitudId = args is String ? args : null;
          return DocumentosScreen(solicitudId: solicitudId);
        },
        AppRoutes.transmision: (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          final solicitudId = args is String ? args : null;
          return TransmisionScreen(solicitudId: solicitudId);
        },
        AppRoutes.estadoSolicitudes: (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          final highlight = args is String ? args : null;
          return EstadoSolicitudesScreen(highlightReference: highlight);
        },
        AppRoutes.estadoSolicitudDetalle: (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          if (args is String) {
            if (args.startsWith('EXP-')) {
              return EstadoSolicitudDetalleScreen(numeroExpediente: args);
            }
            return EstadoSolicitudDetalleScreen(requestId: args);
          }
          return const EstadoSolicitudDetalleScreen();
        },
        AppRoutes.buro: (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          final clientId = args is String ? args : null;
          return BuroScreen(clientId: clientId);
        },
        AppRoutes.ruta: (_) => const RutaScreen(),
        AppRoutes.cobranza: (_) => const CobranzaScreen(),
        AppRoutes.cobranzaAccion: (context) {
          final overdueClientId =
              ModalRoute.of(context)!.settings.arguments as String;
          return CobranzaAccionScreen(overdueClientId: overdueClientId);
        },
        AppRoutes.reportes: (_) => const ReportesScreen(),
      },
    );
  }
}
