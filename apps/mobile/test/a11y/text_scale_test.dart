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
