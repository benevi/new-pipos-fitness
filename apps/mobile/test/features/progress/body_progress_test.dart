// Idea 7 / CUJ-10 (ADR-0013): medidas corporales con consentimiento por
// ámbitos, tendencia de peso, IMC y % de grasa siempre como «Estimación — no
// es un diagnóstico» y con sus límites, y registro offline.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipos_fitness/models/enums.dart';
import 'package:pipos_fitness/models/body.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fixtures.dart';
import '../../helpers/ui.dart';

Future<void> _openBody(WidgetTester tester, AppHarness harness) async {
  await harness.pump(tester);
  await tester.pumpAndSettle();
  await tapKey(tester, 'nav-progress');
  await tapKey(tester, 'progress-tab-body');
}

Future<void> _scrollTo(WidgetTester tester, Finder finder) =>
    tester.scrollUntilVisible(finder, 200, scrollable: verticalScrollable());

/// Escribe en un campo de la lista aunque esté fuera de pantalla.
Future<void> _enter(WidgetTester tester, String key, String text) async {
  final finder = find.byKey(Key(key));
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      -200,
      scrollable: verticalScrollable(),
    );
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.enterText(finder, text);
  await tester.pump();
}

void main() {
  testWidgets('Cuerpo: estado del ritmo, IMC y % de grasa con sus límites', (
    tester,
  ) async {
    usePhoneSize(tester);
    final harness = AppHarness.signedIn();
    await _openBody(tester, harness);

    // Consintió la versión anterior: peso sí, perímetros y estimaciones no.
    expect(find.byKey(const Key('body-consent-upgrade')), findsOneWidget);
    expect(find.text('Vas más lento de lo previsto'), findsOneWidget);
    expect(find.text('-0,46 % por semana'), findsOneWidget);
    expect(
      find.text('Objetivo: perder entre el 0,5 y el 1 % por semana'),
      findsOneWidget,
    );

    // Gráfica del peso: título honesto, ejes y resumen para el lector.
    expect(
      find.text('Peso (kg): media móvil de 7 días en cada pesada'),
      findsOneWidget,
    );
    Finder inWeight(String key) => find.descendant(
      of: find.byKey(const Key('weight-chart')),
      matching: find.byKey(Key(key)),
    );
    expect(tester.widget<Text>(inWeight('chart-min')).data, '80,5 kg');
    expect(tester.widget<Text>(inWeight('chart-max')).data, '82 kg');
    expect(tester.widget<Text>(inWeight('chart-first')).data, '12 oct');
    expect(tester.widget<Text>(inWeight('chart-last')).data, '9 nov');
    expect(
      find.bySemanticsLabel('Peso: de 82 a 80,5 kg en 4 semanas'),
      findsOneWidget,
    );

    await _scrollTo(tester, find.byKey(const Key('bmi-value')));
    expect(find.text('24,8'), findsOneWidget);
    expect(find.text('Peso normal'), findsOneWidget);
    expect(
      find.textContaining('El IMC no distingue músculo de grasa'),
      findsOneWidget,
    );
    await _scrollTo(tester, find.byKey(const Key('body-fat-value')));
    expect(find.text('17,9 %'), findsOneWidget);
    expect(
      find.textContaining(
        'Estimación por circunferencias (método de la Marina',
      ),
      findsOneWidget,
    );
    expect(find.text('Estimación — no es un diagnóstico'), findsNWidgets(2));

    await _scrollTo(tester, find.byKey(const Key('circ-waistCm')));
    expect(find.text('Δ 4 sem: -1,5 cm'), findsOneWidget);
    expect(find.text('Δ 12 sem: -3 cm'), findsOneWidget);
    await _scrollTo(tester, find.byKey(const Key('body-disclaimer')));
    expect(
      find.text(
        'Es una estimación orientativa, no un diagnóstico. Para valorar tu salud, consulta a un profesional sanitario.',
      ),
      findsWidgets,
    );
    await harness.drainAndUnmount(tester);
  });

  testWidgets('% de grasa que no aplica: lo dice y explica por qué', (
    tester,
  ) async {
    usePhoneSize(tester);
    final backend = FakeBackend()
      ..bodyProgressJson = fixture('body_progress_not_applicable');
    final harness = AppHarness.signedIn(backend: backend);
    await _openBody(tester, harness);
    await _scrollTo(tester, find.byKey(const Key('body-fat-not-applicable')));
    expect(find.text('No aplica'), findsOneWidget);
    expect(
      find.text(
        'La fórmula solo está validada para hombres y para mujeres por separado.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('body-fat-value')), findsNothing);
    await harness.drainAndUnmount(tester);
  });

  testWidgets(
    'peso en sentido contrario al objetivo: estado propio, no «más lento»',
    (tester) async {
      usePhoneSize(tester);
      final base = fixture('body_progress');
      final weight = Map<String, dynamic>.from(base['weight'] as Map);
      weight['trend'] = {
        ...(weight['trend'] as Map<String, dynamic>),
        'status': 'wrong_direction',
        'weeklyRatePct': -0.5,
        'target': {'direction': 'gain', 'minPct': 0.25, 'maxPct': 0.5},
        'rationale': [
          'Estás perdiendo peso (−0,5 %/semana) y tu objetivo es ganar entre 0,25 y 0,5 % por semana.',
        ],
      };
      final backend = FakeBackend()
        ..bodyProgressJson = {...base, 'weight': weight};
      final harness = AppHarness.signedIn(backend: backend);
      await _openBody(tester, harness);
      expect(
        find.text('Vas en sentido contrario a tu objetivo'),
        findsOneWidget,
      );
      expect(find.text('Vas más lento de lo previsto'), findsNothing);
      expect(
        find.text('Objetivo: ganar entre el 0,25 y el 0,5 % por semana'),
        findsOneWidget,
      );
      await harness.drainAndUnmount(tester);
    },
  );

  testWidgets('sin consentimiento: pide el texto nuevo antes de mostrar nada', (
    tester,
  ) async {
    usePhoneSize(tester);
    final backend = FakeBackend();
    backend.profileJson = {
      ...backend.profileJson,
      'healthConsent': {
        'granted': false,
        'version': null,
        'grantedAt': null,
        'currentVersion': 'health-2026-11-v2',
        'scopes': <String>[],
      },
    };
    final harness = AppHarness.signedIn(backend: backend);
    await _openBody(tester, harness);
    expect(find.byKey(const Key('body-consent-gate')), findsOneWidget);
    expect(harness.backend.calls, isNot(contains('GET /progress/body')));

    await tapText(tester, 'Leer y aceptar');
    expect(
      find.textContaining('perímetros de cintura, cuello'),
      findsOneWidget,
    );
    await tapKey(tester, 'consent-accept');
    expect(harness.backend.consentGrants.single.version, 'health-2026-11-v2');
    expect(find.byKey(const Key('body-consent-gate')), findsNothing);
    expect(find.byKey(const Key('body-add')), findsOneWidget);
    await harness.drainAndUnmount(tester);
  });

  testWidgets(
    'formulario: al menos una medida, rangos, perímetros tras reconsentir y '
    'guardado sin red',
    (tester) async {
      usePhoneSize(tester);
      final harness = AppHarness.signedIn();
      await _openBody(tester, harness);
      await tapKey(tester, 'body-add');

      // Con la versión anterior del consentimiento, solo el peso.
      final waist = find.byKey(const Key('measure-waistCm'));
      expect(tester.widget<TextField>(waist).enabled, isFalse);
      expect(find.byKey(const Key('measure-consent-locked')), findsOneWidget);
      await _scrollTo(tester, find.byKey(const Key('measure-armCm')));
      expect(
        find.textContaining('punto medio entre el hombro y el codo'),
        findsOneWidget,
      );

      await tapKey(tester, 'measure-save');
      expect(find.text('Introduce al menos una medida.'), findsOneWidget);

      await _enter(tester, 'measure-weightKg', '500');
      await tapKey(tester, 'measure-save');
      await tester.scrollUntilVisible(
        find.text('Debe estar entre 25 y 400'),
        -200,
        scrollable: verticalScrollable(),
      );
      expect(find.text('Debe estar entre 25 y 400'), findsOneWidget);

      // Reconsentir con el texto nuevo habilita los perímetros.
      await tapKey(tester, 'measure-consent');
      expect(
        find.textContaining('perímetros de cintura, cuello'),
        findsOneWidget,
      );
      await tapKey(tester, 'consent-accept');
      await _scrollTo(tester, waist);
      expect(tester.widget<TextField>(waist).enabled, isTrue);
      expect(find.byKey(const Key('measure-consent-locked')), findsNothing);

      harness.setOnline(false);
      await _enter(tester, 'measure-weightKg', '80,4');
      await _enter(tester, 'measure-waistCm', '86');
      await tapKey(tester, 'measure-save', settle: false);
      await pumpFrames(tester);
      expect(find.text('Medidas guardadas.'), findsOneWidget);
      expect(harness.backend.measurements, isEmpty);

      harness.setOnline(true);
      await pumpFrames(tester, frames: 20);
      final saved = harness.backend.measurements.values.single;
      expect(saved[BodyField.weightKg], 80.4);
      expect(saved[BodyField.waistCm], 86);
      expect(saved[BodyField.neckCm], isNull);
      await harness.drainAndUnmount(tester);
    },
  );

  testWidgets('borrar las medidas de un día va por la cola', (tester) async {
    usePhoneSize(tester);
    final backend = FakeBackend();
    backend.profileJson = {
      ...backend.profileJson,
      'healthConsent': fixture('health_consent_v2'),
    };
    final harness = AppHarness.signedIn(backend: backend);
    await harness.pump(tester);
    await tester.pumpAndSettle();
    await harness.backend.putMeasurement(
      const BodyMeasurement(
        measuredOn: '2026-11-08',
        values: {BodyField.weightKg: 80.9},
      ),
    );
    await tapKey(tester, 'nav-progress');
    await tapKey(tester, 'progress-tab-body');
    await _scrollTo(
      tester,
      find.byKey(const Key('measurement-delete-2026-11-08')),
    );
    await tapKey(tester, 'measurement-delete-2026-11-08', settle: false);
    await pumpFrames(tester, frames: 20);
    expect(harness.backend.measurements, isEmpty);
    expect(
      harness.backend.calls,
      contains('DELETE /me/measurements/2026-11-08'),
    );
    await harness.drainAndUnmount(tester);
  });
}
