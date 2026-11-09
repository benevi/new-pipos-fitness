/// Design tokens de Pipos Fitness.
///
/// Identidad: superficies azul marino oscuro + acento naranja.
///
/// Contraste (WCAG 2.1, texto normal ≥ 4.5:1). Calculado con la fórmula de
/// luminancia relativa y verificado en `test/app/tokens_contrast_test.dart`:
///
/// Tema oscuro
/// - accent #FF6D00 sobre background #0F0F23 ........ 6.68:1 ✓
/// - accent #FF6D00 sobre surface #1A1A2E ........... 6.04:1 ✓
/// - accent #FF6D00 sobre surfaceVariant #16213E .... 5.63:1 ✓
/// - onSurface #E8E8E8 sobre surface ............... 13.92:1 ✓
/// - onSurfaceVariant #AAAAAA sobre surface ......... 7.34:1 ✓
/// - onSurfaceVariant #AAAAAA sobre surfaceVariant .. 6.84:1 ✓
/// - error #CF6679 sobre surface .................... 4.74:1 ✓
/// - success #4CAF50 sobre surface .................. 6.14:1 ✓
/// - blanco sobre accent ............................ 2.82:1 ✗ → por eso el
///   texto sobre el acento (onAccent) es navy #0F0F23: 6.68:1 ✓
///
/// Tema claro (derivado de los mismos tokens)
/// - #FF6D00 sobre blanco daría 2.82:1 ✗ → en claro el acento es #B34700:
///   sobre surface #FFFFFF 5.50:1 ✓, background #F4F4F8 5.01:1 ✓,
///   surfaceVariant #ECECF2 4.67:1 ✓; blanco sobre #B34700 5.50:1 ✓
/// - onSurface #0F0F23 sobre blanco ................ 18.87:1 ✓
/// - onSurfaceVariant #4A4A5E sobre #ECECF2 ......... 7.34:1 ✓
/// - error #B3261E sobre blanco ..................... 6.54:1 ✓
/// - success #2E7D32 sobre blanco ................... 5.13:1 ✓
library;

import 'package:flutter/material.dart';

/// Escala de espaciado: 4 / 8 / 12 / 16 / 24 / 32 (+48 para secciones).
class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double ms = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

class AppRadius {
  AppRadius._();
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
}

/// Paleta de un tema (claro u oscuro).
@immutable
class AppColorTokens {
  const AppColorTokens({
    required this.brightness,
    required this.accent,
    required this.onAccent,
    required this.accentContainer,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.outline,
    required this.error,
    required this.onError,
    required this.success,
  });

  final Brightness brightness;
  final Color accent;
  final Color onAccent;
  final Color accentContainer;
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color outline;
  final Color error;
  final Color onError;
  final Color success;

  static const dark = AppColorTokens(
    brightness: Brightness.dark,
    accent: Color(0xFFFF6D00),
    onAccent: Color(0xFF0F0F23),
    accentContainer: Color(0xFF4A2200),
    background: Color(0xFF0F0F23),
    surface: Color(0xFF1A1A2E),
    surfaceVariant: Color(0xFF16213E),
    onSurface: Color(0xFFE8E8E8),
    onSurfaceVariant: Color(0xFFAAAAAA),
    outline: Color(0xFF3A3A55),
    error: Color(0xFFCF6679),
    onError: Color(0xFF0F0F23),
    success: Color(0xFF4CAF50),
  );

  static const light = AppColorTokens(
    brightness: Brightness.light,
    accent: Color(0xFFB34700),
    onAccent: Color(0xFFFFFFFF),
    accentContainer: Color(0xFFFFE0CC),
    background: Color(0xFFF4F4F8),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFECECF2),
    onSurface: Color(0xFF0F0F23),
    onSurfaceVariant: Color(0xFF4A4A5E),
    outline: Color(0xFFC4C4D0),
    error: Color(0xFFB3261E),
    onError: Color(0xFFFFFFFF),
    success: Color(0xFF2E7D32),
  );
}

/// Accesos directos a la paleta oscura (identidad original).
///
/// Las pantallas aún no migradas (Fase 4b) los usan directamente; las
/// nuevas deben leer `Theme.of(context).colorScheme` para respetar el modo
/// claro/oscuro del sistema.
class AppColors {
  AppColors._();
  static const Color accent = Color(0xFFFF6D00);
  static const Color accentLight = Color(0xFFFF9E40);
  static const Color onAccent = Color(0xFF0F0F23);
  static const Color surface = Color(0xFF1A1A2E);
  static const Color surfaceVariant = Color(0xFF16213E);
  static const Color background = Color(0xFF0F0F23);
  static const Color onSurface = Color(0xFFE8E8E8);
  static const Color onSurfaceVariant = Color(0xFFAAAAAA);
  static const Color error = Color(0xFFCF6679);
  static const Color success = Color(0xFF4CAF50);
}

/// Escala tipográfica (Material 3). Los widgets usan `textTheme.*`, nunca
/// tamaños literales.
class AppTypography {
  AppTypography._();

  static TextTheme textTheme(AppColorTokens c) {
    TextStyle s(
      double size,
      FontWeight weight, {
      double? spacing,
      Color? color,
    }) => TextStyle(
      fontSize: size,
      fontWeight: weight,
      letterSpacing: spacing,
      color: color ?? c.onSurface,
    );

    return TextTheme(
      displayLarge: s(57, FontWeight.w700, spacing: -0.5),
      displayMedium: s(45, FontWeight.w700, spacing: -0.5),
      displaySmall: s(36, FontWeight.w700, spacing: -0.5),
      headlineLarge: s(32, FontWeight.w700, spacing: -0.5),
      headlineMedium: s(28, FontWeight.w700, spacing: -0.5),
      headlineSmall: s(24, FontWeight.w700),
      titleLarge: s(22, FontWeight.w600),
      titleMedium: s(16, FontWeight.w600),
      titleSmall: s(14, FontWeight.w600),
      bodyLarge: s(16, FontWeight.w400),
      bodyMedium: s(14, FontWeight.w400),
      bodySmall: s(12, FontWeight.w400, color: c.onSurfaceVariant),
      labelLarge: s(14, FontWeight.w600),
      labelMedium: s(12, FontWeight.w600),
      labelSmall: s(11, FontWeight.w500),
    );
  }
}
