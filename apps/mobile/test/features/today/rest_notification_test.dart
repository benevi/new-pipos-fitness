// #24: con la app en segundo plano, el fin del descanso avisa con una
// notificación local programada (planificador inyectado); se cancela al
// volver, al saltar el descanso o sin permiso no se programa.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipos_fitness/core/offline/offline_providers.dart';
import 'package:pipos_fitness/core/reminders/reminders.dart';
import 'package:pipos_fitness/features/today/today_providers.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/ui.dart';

const _id = RestTimerController.notificationId;

void main() {
  late DateTime now;
  late FakeNotificationScheduler notifications;
  late ProviderContainer container;
  late RestTimerController timer;

  setUp(() {
    now = DateTime.utc(2026, 11, 9, 8);
    notifications = FakeNotificationScheduler();
    container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(() => now),
        notificationSchedulerProvider.overrideWithValue(notifications),
      ],
    );
    container.listen(restTimerProvider, (_, _) {});
    timer = container.read(restTimerProvider.notifier);
  });

  tearDown(() {
    timer.skip();
    container.dispose();
  });

  Future<void> background() =>
      timer.onBackground(title: 'Descanso terminado', body: 'Sigue');

  test('en segundo plano se programa al final del descanso; al volver se '
      'cancela', () async {
    timer.start(90);
    await background();
    expect(
      notifications.scheduled[_id]!.isAtSameMomentAs(
        now.add(const Duration(seconds: 90)),
      ),
      isTrue,
    );
    expect(notifications.titles[_id], 'Descanso terminado');

    await timer.onForeground();
    expect(notifications.scheduled, isEmpty);
    expect(notifications.cancelled, [_id]);
  });

  test('«Saltar» cancela el aviso programado', () async {
    timer.start(60);
    await background();
    expect(notifications.scheduled, contains(_id));
    timer.skip();
    await Future<void>.delayed(Duration.zero);
    expect(notifications.scheduled, isEmpty);
  });

  test('sin permiso de notificaciones no se programa (ni se pide)', () async {
    notifications.grant = false;
    timer.start(60);
    await background();
    expect(notifications.scheduled, isEmpty);
    expect(notifications.permissionRequests, 0);
  });

  test('sin descanso en marcha (o ya terminado) no se programa nada', () async {
    await background();
    expect(notifications.scheduled, isEmpty);
    timer.start(30);
    now = now.add(const Duration(seconds: 31));
    timer.refresh();
    await background();
    expect(notifications.scheduled, isEmpty);
  });

  test('si vuelve a primer plano mientras se programaba, se cancela', () async {
    timer.start(60);
    final pending = background();
    await timer.onForeground();
    await pending;
    expect(notifications.scheduled, isEmpty);
  });

  testWidgets('ciclo de vida real: la app se oculta tras confirmar una serie '
      '→ aviso programado; vuelve → cancelado', (tester) async {
    usePhoneSize(tester);
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

    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await pumpFrames(tester, frames: 2);
    expect(harness.notifications.scheduled, contains(_id));
    expect(harness.notifications.titles[_id], 'Descanso terminado');

    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await pumpFrames(tester, frames: 2);
    expect(harness.notifications.scheduled, isNot(contains(_id)));
    await tapKey(tester, 'rest-skip', settle: false);
    await harness.drainAndUnmount(tester);
  });
}
