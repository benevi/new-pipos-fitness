// A11y: las pantallas principales soportan texto al 200 % en un móvil de
// 390 dp sin desbordamientos (un overflow de RenderFlex hace fallar el test),
// todos los botones de icono tienen tooltip y los objetivos táctiles miden
// al menos 48 dp.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';
import '../helpers/ui.dart';

Future<void> _checkScreen(WidgetTester tester) async {
  expect(tester.takeException(), isNull);
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  for (final b in tester.widgetList<IconButton>(find.byType(IconButton))) {
    expect(b.tooltip, isNotNull, reason: 'IconButton sin tooltip');
  }
}

void main() {
  testWidgets(
    'texto ×2.0: Hoy, Plan, Progreso y Ajustes sin overflow y con objetivos ≥ 48 dp',
    (tester) async {
      usePhoneSize(tester);
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final semantics = tester.ensureSemantics();

      final harness = AppHarness.signedIn();
      await harness.pump(tester);
      await tester.pumpAndSettle();
      expect(find.text('Cuerpo completo A'), findsOneWidget);
      await _checkScreen(tester);

      for (final tab in ['nav-plan', 'nav-progress', 'nav-settings']) {
        await tapKey(tester, tab);
        await _checkScreen(tester);
      }
      semantics.dispose();
      await harness.drainAndUnmount(tester);
    },
  );

  testWidgets(
    'texto ×2.0: pantallas y hojas de ADR-0013 sin overflow y accesibles',
    (tester) async {
      usePhoneSize(tester);
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final semantics = tester.ensureSemantics();
      const squat = '00000000-0000-4000-8000-000000000030';

      final harness = AppHarness.signedIn();
      await harness.pump(tester);
      await tester.pumpAndSettle();

      // Hoy: hojas de discos, nota y ajuste de hoy.
      for (final (open, sheet) in [
        ('plates-$squat', 'plates-sheet'),
        ('note-edit-$squat', 'note-field'),
        ('adjust-open', 'adjust-sheet'),
      ]) {
        await tapKey(tester, open);
        expect(find.byKey(Key(sheet)), findsOneWidget);
        await _checkScreen(tester);
        Navigator.of(tester.element(find.byKey(Key(sheet)))).pop();
        await tester.pumpAndSettle();
      }

      // Ajustes → días, pausas y recordatorio.
      await tapKey(tester, 'nav-settings');
      await tapKey(tester, 'settings-schedule');
      await _checkScreen(tester);
      await tester.scrollUntilVisible(
        find.byKey(const Key('reminder-toggle')),
        200,
        scrollable: verticalScrollable(),
      );
      await _checkScreen(tester);

      // Progreso → Cuerpo y formulario de medidas.
      await tapKey(tester, 'nav-progress');
      await tapKey(tester, 'progress-tab-body');
      await _checkScreen(tester);
      await tapKey(tester, 'body-add');
      await _checkScreen(tester);
      semantics.dispose();
      await harness.drainAndUnmount(tester);
    },
  );

  testWidgets(
    'texto ×2.0: biblioteca por músculo, ficha con preferencias y mapa de '
    'calor (ADR-0014, Fase 3) sin overflow y accesibles',
    (tester) async {
      usePhoneSize(tester);
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final semantics = tester.ensureSemantics();
      final harness = AppHarness.signedIn();
      await harness.pump(tester);
      await tester.pumpAndSettle();

      // Plan → Ejercicios (cuerpo y lista) → glúteos → ficha.
      await tapKey(tester, 'nav-plan');
      await tapKey(tester, 'plan-exercises-by-muscle');
      await _checkScreen(tester);
      await tester.scrollUntilVisible(
        find.byKey(const Key('body-figure-back')),
        200,
        scrollable: verticalScrollable(),
      );
      await _checkScreen(tester);
      await tapKey(tester, 'exercises-tab-list');
      await _checkScreen(tester);
      await tapKey(tester, 'muscle-list-glutes');
      await _checkScreen(tester);
      await tapKey(tester, 'library-exercise-puente-gluteos');
      await tester.scrollUntilVisible(
        find.byKey(const Key('exercise-preferences')),
        200,
        scrollable: verticalScrollable(),
      );
      await _checkScreen(tester);
      await tapKey(tester, 'exercise-add-favourite');
      await _checkScreen(tester);

      // Progreso: mapa de calor con su leyenda.
      await tapKey(tester, 'nav-progress');
      await tester.scrollUntilVisible(
        find.byKey(const Key('heatmap-figure-front')),
        200,
        scrollable: verticalScrollable(),
      );
      await _checkScreen(tester);
      semantics.dispose();
      await harness.drainAndUnmount(tester);
    },
  );

  testWidgets('texto ×2.0: cuestionario sin overflow', (tester) async {
    usePhoneSize(tester);
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final harness = AppHarness.signedIn(
      backend: FakeBackend(hasPlan: false, hasProfile: false),
    );
    await harness.pump(tester);
    await tester.pumpAndSettle();
    await tapKey(tester, 'onboarding-next');
    expect(find.text('Elige una opción'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
    await harness.drainAndUnmount(tester);
  });

  testWidgets(
    'animaciones reducidas: el descanso no pinta barra de progreso animada',
    (tester) async {
      usePhoneSize(tester);
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final harness = AppHarness.signedIn();
      await harness.pump(tester);
      await tester.pumpAndSettle();
      await tapKey(
        tester,
        'confirm-00000000-0000-4000-8000-000000000030',
        settle: false,
      );
      await pumpFrames(tester);
      expect(find.byKey(const Key('rest-timer')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('rest-timer')),
          matching: find.byType(LinearProgressIndicator),
        ),
        findsNothing,
      );
      expect(find.textContaining('Descanso: quedan 1:'), findsOneWidget);
      await tapKey(tester, 'rest-skip', settle: false);
      await harness.drainAndUnmount(tester);
    },
  );
}
