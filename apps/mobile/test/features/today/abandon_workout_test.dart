// «Abandonar entrenamiento» en Hoy (issue #13 de la API): con confirmación,
// también sin red (la cola envía el abandono al volver la conexión).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipos_fitness/features/today/today_providers.dart';
import 'package:pipos_fitness/models/enums.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/ui.dart';

void main() {
  const squat = '00000000-0000-4000-8000-000000000030';

  testWidgets('sin red: confirmar «Abandonar» limpia Hoy y el abandono se '
      'envía al volver la red', (tester) async {
    usePhoneSize(tester);
    final harness = AppHarness.signedIn();
    await harness.pump(tester);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('abandon-workout')), findsNothing);

    await tapKey(tester, 'confirm-$squat', settle: false);
    await pumpFrames(tester);
    harness.container(tester).read(restTimerProvider.notifier).skip();
    final clientId = harness.backend.workouts.keys.single;
    harness.setOnline(false);

    // Cancelar no hace nada.
    await tapKey(tester, 'abandon-workout');
    expect(find.text('¿Abandonar el entrenamiento?'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    await tapKey(tester, 'abandon-workout');
    await tester.tap(find.byKey(const Key('abandon-confirm')));
    await pumpFrames(tester);
    expect(find.text('Entrenamiento abandonado.'), findsOneWidget);
    expect(find.byKey(const Key('abandon-workout')), findsNothing);
    expect(harness.backend.abandons, 0);

    harness.setOnline(true);
    await pumpFrames(tester, frames: 20);
    expect(harness.backend.abandons, 1);
    expect(harness.backend.workouts[clientId]!.status, WorkoutStatus.abandoned);
    expect(harness.backend.finishCalls, 0);
    await harness.drainAndUnmount(tester);
  });
}
