// Idea 4 / CUJ-9 (ADR-0013): «¿Poco tiempo hoy?». Vista previa antes de
// empezar (ejercicios quitados y explicación), la sesión ajustada queda en
// caché (sirve sin red) y el ajuste viaja en POST /workouts.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipos_fitness/features/today/today_providers.dart';
import 'package:pipos_fitness/models/workout.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/ui.dart';

const squat = '00000000-0000-4000-8000-000000000030';
const row = '00000000-0000-4000-8000-000000000031';

/// Huecos de la sesión de hoy que se están mostrando.
List<String> _slots(AppHarness harness, WidgetTester tester) => harness
    .container(tester)
    .read(todaySessionProvider)
    .value!
    .value
    .exercises
    .map((e) => e.planExerciseId)
    .toList();

void main() {
  testWidgets(
    'elegir 30 min → vista previa → empezar sin red → el ajuste llega a la API',
    (tester) async {
      usePhoneSize(tester);
      final harness = AppHarness.signedIn();
      await harness.pump(tester);
      await tester.pumpAndSettle();
      expect(_slots(harness, tester), contains(row));

      await tapKey(tester, 'adjust-open');
      await tapKey(tester, 'adjust-preview');
      expect(
        find.text('Elige un tiempo o activa el volumen reducido.'),
        findsOneWidget,
      );
      expect(harness.backend.todayQueries, isEmpty);

      await tapKey(tester, 'adjust-minutes-30');
      await tapKey(tester, 'adjust-preview');
      expect(harness.backend.todayQueries, [
        const WorkoutAdjustment(availableMinutes: 30),
      ]);
      expect(find.text('Duración estimada: 28 min'), findsOneWidget);
      expect(find.byKey(const Key('adjust-dropped-$row')), findsOneWidget);
      expect(find.text('• Remo con mancuerna'), findsOneWidget);
      await tapKey(tester, 'adjust-apply');

      // Hoy muestra la sesión ajustada, con lo quitado y su porqué.
      expect(find.text('Sesión ajustada a 30 min'), findsOneWidget);
      expect(find.text('Hoy sin: Remo con mancuerna'), findsOneWidget);
      expect(_slots(harness, tester), isNot(contains(row)));
      expect(find.byKey(const Key('adjust-open')), findsNothing);

      // Sin red, la sesión ajustada sale de la caché.
      harness.setOnline(false);
      harness.container(tester).invalidate(todaySessionProvider);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('today-cached')), findsOneWidget);
      expect(find.text('Sesión ajustada a 30 min'), findsOneWidget);

      await tapKey(tester, 'confirm-$squat', settle: false);
      await pumpFrames(tester);
      expect(harness.backend.startRequests, isEmpty);

      harness.setOnline(true);
      await pumpFrames(tester, frames: 20);
      expect(
        harness.backend.startRequests.single.adjustment,
        const WorkoutAdjustment(availableMinutes: 30),
      );
      await tapKey(tester, 'rest-skip', settle: false);
      await harness.drainAndUnmount(tester);
    },
  );

  testWidgets('volumen reducido y vuelta a la sesión completa', (tester) async {
    usePhoneSize(tester);
    final harness = AppHarness.signedIn();
    await harness.pump(tester);
    await tester.pumpAndSettle();

    await tapKey(tester, 'adjust-open');
    await tapKey(tester, 'adjust-reduced');
    await tapKey(tester, 'adjust-preview');
    expect(harness.backend.todayQueries.single.reducedVolume, isTrue);
    await tapKey(tester, 'adjust-apply');
    expect(find.text('Sesión con volumen reducido'), findsOneWidget);

    await tapKey(tester, 'adjust-remove');
    expect(find.byKey(const Key('adjust-banner')), findsNothing);
    expect(_slots(harness, tester), contains(row));
    await harness.drainAndUnmount(tester);
  });

  testWidgets('sin red la vista previa explica que hace falta conexión', (
    tester,
  ) async {
    usePhoneSize(tester);
    final harness = AppHarness.signedIn();
    await harness.pump(tester);
    await tester.pumpAndSettle();
    harness.setOnline(false);
    await tapKey(tester, 'adjust-open');
    await tapKey(tester, 'adjust-minutes-20');
    await tapKey(tester, 'adjust-preview');
    expect(find.text('Necesitas conexión para hacer esto.'), findsOneWidget);
    expect(find.byKey(const Key('adjust-apply')), findsNothing);
    await harness.drainAndUnmount(tester);
  });
}
