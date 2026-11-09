import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'tokens.dart';

export 'tokens.dart';

/// Temas claro y oscuro construidos a partir de los mismos [AppColorTokens].
/// La app sigue el modo del sistema (`ThemeMode.system`).
class AppTheme {
  AppTheme._();

  static ThemeData get dark => _build(AppColorTokens.dark);
  static ThemeData get light => _build(AppColorTokens.light);

  static ThemeData _build(AppColorTokens t) {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: t.accent,
          brightness: t.brightness,
        ).copyWith(
          primary: t.accent,
          onPrimary: t.onAccent,
          primaryContainer: t.accentContainer,
          secondary: t.accent,
          onSecondary: t.onAccent,
          surface: t.surface,
          onSurface: t.onSurface,
          onSurfaceVariant: t.onSurfaceVariant,
          surfaceContainerHighest: t.surfaceVariant,
          outline: t.outline,
          error: t.error,
          onError: t.onError,
        );
    // Tipografía: la fuente del sistema de cada plataforma (Roboto en
    // Android, San Francisco en iOS) según `Typography.material2021`. La
    // escala de AppTypography se fusiona SOBRE esa base para que cada estilo
    // lleve `fontFamily`; los estilos de componentes (botones, AppBar,
    // pestañas, barra de navegación) salen de este TextTheme ya fusionado y
    // no de AppTypography en crudo, que no tiene familia y en iOS caía en
    // otra fuente que el resto de la app (docs/UX_MOVIL.md §3).
    final typography = Typography.material2021(
      platform: defaultTargetPlatform,
      colorScheme: colorScheme,
    );
    final base = t.brightness == Brightness.dark
        ? typography.white
        : typography.black;
    final textTheme = base.merge(AppTypography.textTheme(t));
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: t.brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: t.background,
      typography: typography,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: t.onSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge,
      ),
      // Interruptores: en apagado el borde y el pulgar usan onSurfaceVariant
      // (≥ 3:1 sobre las superficies) y la pista es la propia superficie,
      // para que «apagado» se vea claramente en claro y en oscuro (el
      // `outline` por defecto daba ~1,5:1 en oscuro). Encendido: pista del
      // acento y pulgar onAccent. Ver test/app/tokens_contrast_test.dart.
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return t.onSurface.withValues(alpha: 0.38);
          }
          return states.contains(WidgetState.selected)
              ? t.onAccent
              : t.onSurfaceVariant;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return t.surfaceVariant;
          }
          return states.contains(WidgetState.selected) ? t.accent : t.surface;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.transparent;
          if (states.contains(WidgetState.disabled)) {
            return t.onSurface.withValues(alpha: 0.12);
          }
          return t.onSurfaceVariant;
        }),
      ),
      tabBarTheme: TabBarThemeData(
        labelStyle: textTheme.titleSmall,
        unselectedLabelStyle: textTheme.titleSmall,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: t.surfaceVariant,
        indicatorColor: t.accent.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelMedium?.copyWith(
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? t.accent : t.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? t.accent
                : t.onSurfaceVariant,
          );
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: t.accent,
          foregroundColor: t.onAccent,
          minimumSize: const Size(double.infinity, AppSpacing.xxl),
          textStyle: textTheme.labelLarge,
          shape: shape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: t.accent,
          side: BorderSide(color: t.accent),
          textStyle: textTheme.labelLarge,
          shape: shape,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: t.accent,
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: t.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: t.accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: t.error),
        ),
      ),
    );
  }
}
