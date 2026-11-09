// Integration test «completar una sesión» (CUJ-2).
//
// Arranca la app completa (PiposRoot, router, drift en memoria, SyncService)
// con la capa de datos sustituida por un backend en memoria
// (test/helpers/fake_backend.dart) que implementa las interfaces de
// lib/data/pipos_api.dart con la semántica de la API v1. Recorre la sesión de
// hoy, registra todas las series, termina y comprueba la pantalla final y lo
// que recibió la «API».
//
// Corre sin dispositivo (headless) con el binding de flutter_test:
//   flutter test -d flutter-tester integration_test
// (`flutter test integration_test` a secas pide un dispositivo; con
// `-d flutter-tester` usa el mismo motor que `flutter test`). En CI se lanza
// así en el job móvil.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipos_fitness/features/today/today_screen.dart';
import 'package:pipos_fitness/features/today/workout_complete_screen.dart';

import '../test/helpers/app_harness.dart';
import '../test/helpers/ui.dart';

const squat = '00000000-0000-4000-8000-000000000030';
const row = '00000000-0000-4000-8000-000000000031';
const pushups = '00000000-0000-4000-8000-000000000032';

Future<void> confirmSet(WidgetTester tester, String planExerciseId) async {
  await tapKey(tester, 'confirm-$planExerciseId', settle: false);
  await pumpFrames(tester);
  // El descanso arranca solo; en el test lo saltamos.
  expect(find.byKey(const Key('rest-timer')), findsOneWidget);
  await tapKey(tester, 'rest-skip', settle: false);
  await pumpFrames(tester, frames: 3);
}

void main() {
  testWidgets('completar una sesión: registrar todas las series y terminar', (
    tester,
  ) async {
    usePhoneSize(tester);
    final harness = AppHarness.signedIn();
    await harness.pump(tester);
    await tester.pumpAndSettle();
    expect(find.byType(TodayScreen), findsOneWidget);
    expect(find.text('Cuerpo completo A'), findsOneWidget);
    expect(find.textContaining('Calentamiento general: 5 min'), findsOneWidget);
    expect(find.text('Series de aproximación'), findsOneWidget);

    // Sentadilla: carga sugerida precargada → 1 toque por serie.
    await confirmSet(tester, squat);
    await confirmSet(tester, squat);

    // Remo: «estimación inicial» → se elige el peso una vez; la 2.ª serie
    // ya viene precargada con lo de la 1.ª.
    await tester.scrollUntilVisible(
      find.byKey(const Key('estimate-$row')),
      200,
      scrollable: verticalScrollable(),
    );
    final load = find.byKey(const Key('load-$row'));
    await tester.ensureVisible(load);
    await tester.enterText(load, '20');
    await tapKey(tester, 'rir-$row');
    await tapKey(tester, 'rir-option-3');
    await confirmSet(tester, row);
    await confirmSet(tester, row);

    // Flexiones (peso corporal).
    await confirmSet(tester, pushups);
    await confirmSet(tester, pushups);

    await tapKey(tester, 'finish-workout');
    expect(find.text('¿Terminar el entrenamiento?'), findsOneWidget);
    expect(
      find.text(
        'Has completado todas las series. Lo registrado se guarda igualmente.',
      ),
      findsOneWidget,
    );
    await tapKey(tester, 'finish-confirm', settle: false);
    await pumpFrames(tester, frames: 20);

    expect(find.byType(WorkoutCompleteScreen), findsOneWidget);
    expect(find.byKey(const Key('complete-title')), findsOneWidget);
    expect(find.textContaining('6 series registradas'), findsOneWidget);
    expect(find.byKey(const Key('complete-synced')), findsOneWidget);

    final api = harness.backend;
    expect(api.workouts, hasLength(1));
    expect(api.sets, hasLength(6));
    expect(api.setsReplayed, 0);
    expect(api.finishes, 1);
    final rowSets = api.sets.values
        .where((s) => s.planExerciseId == row)
        .toList();
    expect(rowSets.map((s) => s.loadKg), [20, 20]);
    expect(rowSets.map((s) => s.rir), [3, 3]);
    expect(rowSets.map((s) => s.setIndex), [0, 1]);

    await harness.drainAndUnmount(tester);
  });
}
