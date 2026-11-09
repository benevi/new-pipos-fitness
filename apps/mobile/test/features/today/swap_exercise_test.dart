import 'package:flutter_test/flutter_test.dart';

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

  testWidgets('sin red, cambiar ejercicio explica que hace falta conexión', (
    tester,
  ) async {
    usePhoneSize(tester);
    final harness = AppHarness.signedIn();
    await harness.pump(tester);
    await tester.pumpAndSettle();
    harness.setOnline(false);

    await tapKey(tester, 'swap-$squatSlot');
    expect(find.text('Necesitas conexión para hacer esto.'), findsOneWidget);
    expect(harness.backend.substitutions, isEmpty);
    await tester.tapAt(const Offset(10, 10));
    await harness.drainAndUnmount(tester);
  });
}
