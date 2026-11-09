// Idea 3 (ADR-0013): «Usar siempre este cambio» fija el cambio en el plan
// (PUT …/override) en vez de cambiarlo solo hoy; Hoy y Plan lo marcan, Plan
// permite volver al original y avisa si una versión nueva lo descartó.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/ui.dart';

const squatSlot = '00000000-0000-4000-8000-000000000030';
const legPress = '00000000-0000-4000-8000-000000000044';

void main() {
  testWidgets('fijar el cambio → marca en Hoy y en Plan → volver al original', (
    tester,
  ) async {
    usePhoneSize(tester);
    final harness = AppHarness.signedIn();
    await harness.pump(tester);
    await tester.pumpAndSettle();

    await tapKey(tester, 'swap-$squatSlot');
    expect(find.text('Usar siempre este cambio'), findsOneWidget);
    await tapKey(tester, 'swap-pin');
    await tapKey(tester, 'swap-choose-$legPress');

    // Fijado en el plan, sin crear un entrenamiento ni un cambio puntual.
    expect(harness.backend.pins, {squatSlot: legPress});
    expect(harness.backend.substitutions, isEmpty);
    expect(harness.backend.workouts, isEmpty);
    expect(
      find.text('A partir de ahora harás Prensa de piernas en este plan'),
      findsOneWidget,
    );
    await scrollToTop(tester);
    expect(find.byKey(const Key('pinned-$squatSlot')), findsOneWidget);
    // La chincheta es solo del cambio fijado (la nota usa otro icono).
    expect(
      find.descendant(
        of: find.byKey(const Key('pinned-$squatSlot')),
        matching: find.byIcon(Icons.push_pin),
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.push_pin_outlined), findsNothing);
    expect(
      find.text('Cambio fijado: en lugar de Sentadilla trasera'),
      findsOneWidget,
    );

    await tapKey(tester, 'nav-plan');
    await tester.scrollUntilVisible(
      find.byKey(const Key('plan-pinned-$squatSlot')),
      200,
      scrollable: verticalScrollable(),
    );
    await tapKey(tester, 'unpin-$squatSlot');
    expect(harness.backend.pins, isEmpty);
    expect(find.text('Has vuelto a Sentadilla trasera'), findsOneWidget);
    expect(find.byKey(const Key('plan-pinned-$squatSlot')), findsNothing);
    await harness.drainAndUnmount(tester);
  });

  testWidgets('Plan avisa si una versión nueva descartó un cambio fijado', (
    tester,
  ) async {
    usePhoneSize(tester);
    final backend = FakeBackend();
    backend.planJson['warnings'] = [
      {
        'code': 'PINNED_SUBSTITUTION_DROPPED',
        'message':
            'Prensa de piernas ya no es válido con tu material: vuelves a Sentadilla trasera.',
      },
    ];
    final harness = AppHarness.signedIn(backend: backend);
    await harness.pump(tester);
    await tester.pumpAndSettle();
    await tapKey(tester, 'nav-plan');
    expect(find.byKey(const Key('warning-pin-dropped')), findsOneWidget);
    expect(
      find.textContaining('Un cambio fijado ya no se puede aplicar.'),
      findsOneWidget,
    );
    await harness.drainAndUnmount(tester);
  });
}
