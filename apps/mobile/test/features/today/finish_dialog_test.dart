// Fin del entrenamiento con series sin enviar: el diálogo lo avisa y ofrece
// reintentar; el finish no se envía mientras quede alguna `failed`.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipos_fitness/core/api/api_failure.dart';
import 'package:pipos_fitness/core/offline/offline_providers.dart';
import 'package:pipos_fitness/features/today/today_screen.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/ui.dart';

void main() {
  const squat = '00000000-0000-4000-8000-000000000030';

  testWidgets('serie failed: el diálogo avisa «Hay 1 serie sin enviar», '
      'reintentar la envía y el finish espera', (tester) async {
    usePhoneSize(tester);
    var reject = true;
    final backend = FakeBackend()
      ..setFailure = (_) => reject
          ? const ApiFailure(
              type: ApiFailureType.badRequest,
              message: 'bad',
              statusCode: 422,
              code: ApiErrorCode.validationFailed,
            )
          : null;
    final harness = AppHarness.signedIn(backend: backend);
    await harness.pump(tester);
    await tester.pumpAndSettle();
    expect(find.byType(TodayScreen), findsOneWidget);

    await tapKey(tester, 'confirm-$squat', settle: false);
    await pumpFrames(tester);
    await tapKey(tester, 'rest-skip', settle: false);

    await tapKey(tester, 'finish-workout');
    expect(find.byKey(const Key('finish-unsynced')), findsOneWidget);
    expect(find.textContaining('Hay 1 serie sin enviar.'), findsOneWidget);

    // Reintentar (sigue fallando) cierra el diálogo sin terminar.
    await tester.tap(find.byKey(const Key('finish-retry')));
    await pumpFrames(tester);
    expect(find.byType(TodayScreen), findsOneWidget);
    expect(backend.finishCalls, 0);

    // Terminar con la serie aún fallida: no se envía el finish.
    await tapKey(tester, 'finish-workout');
    await tester.tap(find.byKey(const Key('finish-confirm')));
    await pumpFrames(tester);
    expect(backend.finishCalls, 0);
    expect(backend.sets, isEmpty);

    // La API vuelve a aceptarla: «Reintentar» la envía y después el finish.
    reject = false;
    await harness.container(tester).read(syncServiceProvider).retryFailed();
    await pumpFrames(tester);
    expect(backend.sets, hasLength(1));
    expect(backend.finishes, 1);
    await harness.drainAndUnmount(tester);
  });

  testWidgets('409 WORKOUT_IN_PROGRESS de otra sesión: aviso accionable y '
      '«Descartar» borra el entrenamiento local', (tester) async {
    usePhoneSize(tester);
    final backend = FakeBackend();
    final harness = AppHarness.signedIn(backend: backend);
    await harness.pump(tester);
    await tester.pumpAndSettle();

    harness.setOnline(false);
    await tapKey(tester, 'confirm-$squat', settle: false);
    await pumpFrames(tester);
    await tapKey(tester, 'rest-skip', settle: false);

    // Mientras, otro dispositivo empezó otra sesión del plan.
    backend.seedInProgress(
      clientId: 'other-device',
      planSessionId: '00000000-0000-4000-8000-000000000099',
      startedAt: DateTime.utc(2026, 11, 9, 7),
    );
    harness.setOnline(true);
    await pumpFrames(tester);
    await scrollToTop(tester);

    final banner = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('workout-conflict-'),
    );
    expect(banner, findsOneWidget);
    expect(find.textContaining('ya hay otro en curso'), findsOneWidget);

    await tapKey(tester, 'conflict-discard', settle: false);
    await pumpFrames(tester);
    await tester.tap(find.byKey(const Key('conflict-discard-confirm')));
    await pumpFrames(tester);
    expect(banner, findsNothing);
    final db = harness.database;
    expect(
      await tester.runAsync(() => db.select(db.localWorkouts).get()),
      isEmpty,
    );
    await harness.drainAndUnmount(tester);
  });
}
