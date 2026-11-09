// Músculos visibles en cada ejercicio (ADR-0014, Fase 1): «Trabaja: …» y el
// desplegable «También: …» en la tarjeta de Hoy, chips en Plan y principales
// de cada alternativa al cambiar ejercicio. TalkBack lee «Trabaja: …»; con
// texto al 200 % no hay desbordes; una respuesta anterior sin `muscles` no
// pinta nada.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/ui.dart';

const squat = '00000000-0000-4000-8000-000000000030';

/// Flexiones: hueco 032 en Hoy y 031 en Plan (fixtures).
const todayPushup = '00000000-0000-4000-8000-000000000032';
const planPushup = '00000000-0000-4000-8000-000000000031';
const legPress = '00000000-0000-4000-8000-000000000044';
const bulgarian = '00000000-0000-4000-8000-000000000045';

String? _text(WidgetTester tester, String key) => tester
    .widget<Text>(
      find.descendant(of: find.byKey(Key(key)), matching: find.byType(Text)),
    )
    .data;

/// Plan: baja hasta la sesión (lista perezosa) y la despliega.
Future<void> _openPlanSession(WidgetTester tester, String name) async {
  await tester.scrollUntilVisible(
    find.text(name),
    200,
    scrollable: verticalScrollable(),
  );
  await tapText(tester, name);
  await tester.scrollUntilVisible(
    find.byKey(const Key('muscle-chips-$squat')),
    200,
    scrollable: verticalScrollable(),
  );
}

Future<void> _checkA11y(WidgetTester tester) async {
  expect(tester.takeException(), isNull);
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
}

void main() {
  testWidgets('Hoy: «Trabaja: …» con los principales y «También: …» al '
      'desplegar; TalkBack lee «Trabaja: …»', (tester) async {
    usePhoneSize(tester);
    final semantics = tester.ensureSemantics();
    final harness = AppHarness.signedIn();
    await harness.pump(tester);
    await tester.pumpAndSettle();

    // Principales en el orden de la API; los secundarios, plegados.
    expect(find.byKey(const Key('muscles-primary-$squat')), findsOneWidget);
    expect(find.text('Trabaja: Glúteos, Cuádriceps'), findsOneWidget);
    expect(find.byKey(const Key('muscles-secondary-$squat')), findsNothing);
    expect(
      find.bySemanticsLabel(RegExp(r'^Trabaja: Glúteos, Cuádriceps')),
      findsOneWidget,
    );
    final toggle = find.byKey(const Key('muscles-toggle-$squat'));
    expect(
      tester.getSemantics(toggle),
      matchesSemantics(
        label: 'Trabaja: Glúteos, Cuádriceps',
        hint: 'Muestra los músculos que el ejercicio trabaja en segundo plano',
        isButton: true,
        hasExpandedState: true,
        isExpanded: false,
        hasTapAction: true,
        hasFocusAction: true,
        isFocusable: true,
      ),
    );

    await tapKey(tester, 'muscles-toggle-$squat');
    expect(find.text('También: Lumbares, Aductores'), findsOneWidget);
    expect(
      tester.getSemantics(toggle),
      matchesSemantics(
        label: 'Trabaja: Glúteos, Cuádriceps',
        hint: 'Ocultar secundarios',
        isButton: true,
        hasExpandedState: true,
        isExpanded: true,
        hasTapAction: true,
        hasFocusAction: true,
        isFocusable: true,
      ),
    );
    await tapKey(tester, 'muscles-toggle-$squat');
    expect(find.text('También: Lumbares, Aductores'), findsNothing);

    // Cada ejercicio muestra los suyos.
    await tester.scrollUntilVisible(
      find.byKey(const Key('muscles-primary-$todayPushup')),
      200,
      scrollable: verticalScrollable(),
    );
    expect(find.text('Trabaja: Pecho'), findsOneWidget);
    semantics.dispose();
    await harness.drainAndUnmount(tester);
  });

  testWidgets('respuesta anterior sin `muscles`: la tarjeta no pinta la línea '
      'ni deja hueco', (tester) async {
    usePhoneSize(tester);
    final harness = AppHarness.signedIn();
    for (final e in harness.backend.todayJson['exercises'] as List) {
      (e as Map).remove('muscles');
    }
    await harness.pump(tester);
    await tester.pumpAndSettle();
    expect(find.text('Sentadilla trasera'), findsOneWidget);
    expect(find.byKey(const Key('muscles-$squat')), findsNothing);
    expect(find.textContaining('Trabaja:'), findsNothing);
    expect(tester.takeException(), isNull);
    await harness.drainAndUnmount(tester);
  });

  testWidgets('Plan: chips de principales y, tras «También:», los secundarios; '
      'TalkBack lee el grupo', (tester) async {
    usePhoneSize(tester);
    final semantics = tester.ensureSemantics();
    final harness = AppHarness.signedIn();
    await harness.pump(tester);
    await tester.pumpAndSettle();
    await tapKey(tester, 'nav-plan');
    await _openPlanSession(tester, 'Cuerpo completo A');

    for (final m in ['glutes', 'quads', 'lower_back', 'adductors']) {
      expect(find.byKey(Key('muscle-chip-$squat-$m')), findsOneWidget);
    }
    expect(find.byKey(const Key('muscle-chip-$squat-chest')), findsNothing);
    expect(find.byKey(const Key('muscle-chip-$planPushup-chest')), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        'Trabaja: Glúteos, Cuádriceps. También: Lumbares, Aductores',
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        'Trabaja: Pecho. También: Deltoides anterior, Tríceps',
      ),
      findsOneWidget,
    );
    semantics.dispose();
    await harness.drainAndUnmount(tester);
  });

  testWidgets('cambiar ejercicio: cada alternativa dice qué trabaja', (
    tester,
  ) async {
    usePhoneSize(tester);
    final harness = AppHarness.signedIn();
    await harness.pump(tester);
    await tester.pumpAndSettle();

    await tapKey(tester, 'swap-$squat');
    expect(_text(tester, 'swap-muscles-$legPress'), 'Trabaja: Cuádriceps');
    expect(
      _text(tester, 'swap-muscles-$bulgarian'),
      'Trabaja: Glúteos, Cuádriceps',
    );
    await harness.drainAndUnmount(tester);
  });

  for (final brightness in Brightness.values) {
    testWidgets('texto ×2.0 en tema ${brightness.name}: tarjeta desplegada, '
        'Plan y hoja de cambio sin desbordes y con objetivos ≥ 48 dp', (
      tester,
    ) async {
      usePhoneSize(tester);
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      tester.platformDispatcher.platformBrightnessTestValue = brightness;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      final semantics = tester.ensureSemantics();
      final harness = AppHarness.signedIn();
      await harness.pump(tester);
      await tester.pumpAndSettle();

      await tapKey(tester, 'muscles-toggle-$squat');
      expect(find.text('También: Lumbares, Aductores'), findsOneWidget);
      await _checkA11y(tester);

      await tapKey(tester, 'swap-$squat');
      expect(find.byKey(const Key('swap-muscles-$legPress')), findsOneWidget);
      await _checkA11y(tester);
      Navigator.of(
        tester.element(find.byKey(const Key('swap-muscles-$legPress'))),
      ).pop();
      await tester.pumpAndSettle();

      await tapKey(tester, 'nav-plan');
      await _openPlanSession(tester, 'Cuerpo completo A');
      expect(find.byKey(const Key('muscle-chip-$squat-quads')), findsOneWidget);
      await _checkA11y(tester);
      semantics.dispose();
      await harness.drainAndUnmount(tester);
    });
  }
}
