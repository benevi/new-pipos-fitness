import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipos_fitness/app/config.dart';
import 'package:pipos_fitness/app/theme.dart';
import 'package:pipos_fitness/core/api/api_failure.dart';

/// Ratio de contraste WCAG 2.1.
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  group('contraste de tokens ≥ 4.5:1', () {
    for (final t in [AppColorTokens.dark, AppColorTokens.light]) {
      final name = t.brightness.name;
      final pairs = <String, (Color, Color)>{
        'accent/background': (t.accent, t.background),
        'accent/surface': (t.accent, t.surface),
        'accent/surfaceVariant': (t.accent, t.surfaceVariant),
        'onAccent/accent': (t.onAccent, t.accent),
        'onSurface/surface': (t.onSurface, t.surface),
        'onSurface/background': (t.onSurface, t.background),
        'onSurfaceVariant/surface': (t.onSurfaceVariant, t.surface),
        'onSurfaceVariant/surfaceVariant': (
          t.onSurfaceVariant,
          t.surfaceVariant,
        ),
        'error/surface': (t.error, t.surface),
        'onError/error': (t.onError, t.error),
        'success/surface': (t.success, t.surface),
      };
      pairs.forEach((label, pair) {
        test('$name $label', () {
          expect(contrast(pair.$1, pair.$2), greaterThanOrEqualTo(4.5));
        });
      });
    }

    test('el tema aplica onAccent al texto de los botones rellenos', () {
      final fg = AppTheme.dark.filledButtonTheme.style!.foregroundColor!
          .resolve({});
      expect(fg, AppColorTokens.dark.onAccent);
    });
  });

  group('AppConfig', () {
    test('usa API_BASE_URL si está definida', () {
      final c = AppConfig.resolve(fromEnvironment: 'https://api.pipos.app');
      expect(c?.apiBaseUrl, 'https://api.pipos.app');
    });

    test('debug sin API_BASE_URL → fallback del emulador', () {
      final c = AppConfig.resolve(fromEnvironment: '', isDebug: true);
      expect(c?.apiBaseUrl, AppConfig.debugFallbackBaseUrl);
    });

    test('release sin API_BASE_URL → null (pantalla de error)', () {
      expect(AppConfig.resolve(fromEnvironment: '', isDebug: false), isNull);
    });
  });

  group('ApiFailure.from', () {
    test('errores de cast/parseo → parse', () {
      Object err;
      try {
        const Object data = 'no-es-un-mapa';
        data as Map<String, dynamic>;
        err = StateError('unreachable');
      } catch (e) {
        err = e;
      }
      expect(ApiFailure.from(err).type, ApiFailureType.parse);
      expect(
        ApiFailure.from(const FormatException('x')).type,
        ApiFailureType.parse,
      );
    });

    test('cualquier otra cosa → unknown', () {
      expect(ApiFailure.from(StateError('x')).type, ApiFailureType.unknown);
    });
  });
}
