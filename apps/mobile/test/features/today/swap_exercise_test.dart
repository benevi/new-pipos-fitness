import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipos_fitness/features/today/today_providers.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/ui.dart';

const squatSlot = '00000000-0000-4000-8000-000000000030';
const legPress = '00000000-0000-4000-8000-000000000044';

void main() {
  testWidgets(
    'cambiar ejercicio: 3 alternativas explicadas → sustitución en la API → la sesión lo refleja',
    (tester) async {
      usePhoneSize(tester);
      final harness = AppHarness.signedIn();
      await harness.pump(tester);
      await tester.pumpAndSettle();

      await tapKey(tester, 'swap-$squatSlot');
      expect(find.text('Alternativas a Sentadilla trasera'), findsOneWidget);
      expect(find.text('Prensa de piernas'), findsOneWidget);
      expect(find.text('Sentadilla goblet'), findsOneWidget);
      expect(find.text('Sentadilla búlgara'), findsOneWidget);
      expect(find.textContaining('Mismo patrón (sentadilla)'), findsOneWidget);

      await tapKey(tester, 'swap-choose-$legPress');

      final sub = harness.backend.substitutions.single;
      expect(sub.planExerciseId, squatSlot);
      expect(sub.exerciseId, legPress);
      // La sustitución necesita el entrenamiento en la API: se creó antes.
      expect(harness.backend.workouts, hasLength(1));
      expect(
        find.text('Ejercicio cambiado por Prensa de piernas'),
        findsOneWidget,
      );

      await scrollToTop(tester);
      expect(find.text('Prensa de piernas'), findsOneWidget);
      expect(find.text('Sustituye a Sentadilla trasera'), findsOneWidget);
      await harness.drainAndUnmount(tester);
    },
  );

  testWidgets('#23 sin red: alternativas en caché, el cambio de hoy va a la '
      'cola y se ve al momento; al volver la red sale ANTES que la serie del '
      'sustituto', (tester) async {
    usePhoneSize(tester);
    final harness = AppHarness.signedIn();
    harness.backend.enforceSlotExercise = true;
    await harness.pump(tester);
    await tester.pumpAndSettle();
    // Las alternativas se guardaron con la sesión de hoy.
    expect(
      harness.backend.calls,
      contains(
        'GET /exercises/00000000-0000-4000-8000-000000000040/substitutes',
      ),
    );
    harness.setOnline(false);

    await tapKey(tester, 'swap-$squatSlot');
    expect(find.byKey(const Key('swap-offline')), findsOneWidget);
    expect(find.text('Prensa de piernas'), findsOneWidget);

    await tapKey(tester, 'swap-choose-$legPress');
    expect(harness.backend.substitutions, isEmpty);
    expect(
      find.text(
        'Cambio a Prensa de piernas guardado. Se enviará al recuperar la conexión.',
      ),
      findsOneWidget,
    );
    await scrollToTop(tester);
    expect(find.text('Prensa de piernas'), findsOneWidget);
    expect(find.text('Sustituye a Sentadilla trasera'), findsOneWidget);
    expect(find.byKey(const Key('swap-pending-$squatSlot')), findsOneWidget);

    // Serie del sustituto sin red (sin carga sugerida: la del original no
    // vale para él).
    await tester.enterText(find.byKey(const Key('load-$squatSlot')), '100');
    await tapKey(tester, 'confirm-$squatSlot', settle: false);
    await pumpFrames(tester);
    harness.container(tester).read(restTimerProvider.notifier).skip();

    harness.setOnline(true);
    await pumpFrames(tester, frames: 20);
    final writes = [
      for (final c in harness.backend.calls)
        if (c.endsWith('/substitute'))
          'swap'
        else if (c.startsWith('POST /workouts/') && c.endsWith('/sets'))
          'set',
    ];
    expect(writes, ['swap', 'set']);
    expect(harness.backend.substitutions.single.exerciseId, legPress);
    expect(harness.backend.sets.values.single.exerciseId, legPress);
    await scrollToTop(tester);
    expect(find.byKey(const Key('swap-pending-$squatSlot')), findsNothing);
    expect(find.text('Sustituye a Sentadilla trasera'), findsOneWidget);
    await harness.drainAndUnmount(tester);
  });

  testWidgets('#23 fijar el cambio en el plan sigue necesitando red', (
    tester,
  ) async {
    usePhoneSize(tester);
    final harness = AppHarness.signedIn();
    await harness.pump(tester);
    await tester.pumpAndSettle();
    harness.setOnline(false);

    await tapKey(tester, 'swap-$squatSlot');
    await tapKey(tester, 'swap-pin');
    await tapKey(tester, 'swap-choose-$legPress');
    expect(
      find.text(
        'Fijar el cambio en el plan necesita conexión. Sin red puedes cambiarlo solo para hoy.',
      ),
      findsOneWidget,
    );
    expect(harness.backend.pins, isEmpty);
    expect(harness.backend.substitutions, isEmpty);
    await tester.tapAt(const Offset(10, 10));
    await harness.drainAndUnmount(tester);
  });
}
