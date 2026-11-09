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
    final textTheme = AppTypography.textTheme(t);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: t.brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: t.background,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: t.onSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge,
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
