import 'package:flutter/material.dart';

/// Paleta de colores oficial de Banco Alfin.
/// Reemplazará al archivo existente en lib/app/ui/theme/app_colors.dart
/// una vez completada la migración.
class AppColors {
  // Marca Alfin
  static const Color primaryPurple = Color(0xFF73058A);
  static const Color primaryPurpleLight = Color(0xFF8F1A95);
  static const Color accentOrange = Color(0xFFFA4616);

  // Estados de visita
  static const Color statusPending = Color(0xFFFFA726);
  static const Color statusVisited = Color(0xFF66BB6A);
  static const Color statusNotFound = Color(0xFFEF5350);
  static const Color statusRescheduled = Color(0xFF42A5F5);
  static const Color statusClosed = Color(0xFF78909C);

  // Tipos de gestión (cartera)
  static const Color gestionRenovacion = Color(0xFF1565C0);
  static const Color gestionAmpliacion = Color(0xFF2E7D32);
  static const Color gestionNuevaSolicitud = Color(0xFFE65100);
  static const Color gestionSeguimiento = Color(0xFF546E7A);
  static const Color gestionRecuperacionMora = Color(0xFFC62828);
  static const Color gestionDesertor = Color(0xFF6A1B9A);

  // Semáforo SBS
  static const Color semaforoNormal = Color(0xFF43A047);
  static const Color semaforoCpp = Color(0xFFFDD835);
  static const Color semaforoDeficiente = Color(0xFFFF7043);
  static const Color semaforoDudoso = Color(0xFFE53935);
  static const Color semaforoPerdida = Color(0xFF37474F);

  // Mora
  static const Color mora30 = Color(0xFFFDD835);
  static const Color mora60 = Color(0xFFFF7043);
  static const Color mora60plus = Color(0xFFC62828);

  // UI general
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color divider = Color(0xFFBDBDBD);

  // ── Aliases de compatibilidad (legacy) ──────────────────────
  // Estos nombres los usan los screens actuales.
  // Se eliminarán cuando los screens migren a los nombres nuevos.
  static const Color primary = primaryPurple;
  static const Color secondary = primaryPurpleLight;
  static const Color purpleSupport = Color(0xFF6A1B9A);
  static const Color lightBackground = background;
  static const Color white = Colors.white;
  static const Color darkText = textPrimary;
  static const Color lightGraySecondary = textSecondary;
  static const Color softOrange = accentOrange;
}
