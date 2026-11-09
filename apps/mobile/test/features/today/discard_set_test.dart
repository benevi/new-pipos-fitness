// #21: una serie rechazada de forma permanente por la API muestra el motivo
// y se puede descartar (con confirmación); después el finish sale.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipos_fitness/core/api/api_failure.dart';
import 'package:pipos_fitness/features/today/today_screen.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/ui.dart';

Finder byKeyPrefix(String prefix, {bool skipOffstage = true}) =>
    find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith(prefix),
      skipOffstage: skipOffstage,
    );

void main() {
  const squat = '00000000-0000-4000-8000-000000000030';

  testWidgets('serie rechazada (400): motivo visible, «Descartar» pide '
      'confirmación, la quita y desbloquea el fin', (tester) async {
    usePhoneSize(tester);
    final backend = FakeBackend()
      ..setFailure = (_) => const ApiFailure(
        type: ApiFailureType.badRequest,
        message: 'bad',
        statusCode: 400,
        code: ApiErrorCode.validationFailed,
      );
    final harness = AppHarness.signedIn(backend: backend);
    await harness.pump(tester);
    await tester.pumpAndSettle();

    await tapKey(tester, 'confirm-$squat', settle: false);
    await pumpFrames(tester);
    await tapKey(tester, 'rest-skip', settle: false);
    await tester.scrollUntilVisible(
      byKeyPrefix('set-failed-'),
      -200,
      scrollable: verticalScrollable(),
    );
    await tester.pumpAndSettle();

    expect(byKeyPrefix('set-failed-'), findsOneWidget);
    expect(
      find.text(
        'La API no la acepta: el ejercicio o los datos no valen para este hueco.',
      ),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Descartar la serie 1'), findsOneWidget);

    // Cancelar no borra nada.
    final discard = byKeyPrefix('set-discard-');
    await tester.ensureVisible(discard);
    await tester.tap(discard);
    await tester.pumpAndSettle();
    expect(find.text('¿Descartar la serie 1?'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(byKeyPrefix('set-failed-'), findsOneWidget);

    await tester.tap(discard);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('set-discard-confirm')));
    await pumpFrames(tester);
    expect(byKeyPrefix('set-failed-'), findsNothing);
    expect(backend.calls.where((c) => c.startsWith('DELETE')), isEmpty);

    // Otra serie buena y terminar: el finish ya no espera a la descartada.
    backend.setFailure = null;
    await tapKey(tester, 'confirm-$squat', settle: false);
    await pumpFrames(tester);
    await tapKey(tester, 'rest-skip', settle: false);
    await tapKey(tester, 'finish-workout');
    expect(find.byKey(const Key('finish-unsynced')), findsNothing);
    await tester.tap(find.byKey(const Key('finish-confirm')));
    await pumpFrames(tester);
    expect(backend.finishes, 1);
    expect(backend.sets, hasLength(1));
    expect(find.byType(TodayScreen), findsNothing);
    await harness.drainAndUnmount(tester);
  });
}
