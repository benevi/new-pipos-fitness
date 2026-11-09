// Idea 6 (ADR-0013): días de entreno (como mucho los del plan), pausas
// (añadir con selector de fechas y borrar), recordatorio LOCAL que se salta
// los días de pausa y estados de Hoy en pausa / día de descanso.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipos_fitness/core/reminders/reminders.dart';
import 'package:pipos_fitness/features/settings/schedule_providers.dart';
import 'package:pipos_fitness/models/notes_breaks.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fixtures.dart';
import '../../helpers/ui.dart';

/// Lunes 9 de noviembre de 2026, 10:00 (hora local).
final monday = DateTime(2026, 11, 9, 10);

TrainingBreak _break(String start, String end) => TrainingBreak(
  id: 'b',
  clientId: 'c',
  startsOn: start,
  endsOn: end,
  createdAt: DateTime.utc(2026, 11, 1),
);

Override _pickRange(DateTime start, DateTime end) =>
    dateRangePickerProvider.overrideWithValue(
      (_, _, _) async => DateTimeRange(start: start, end: end),
    );

Future<void> _openSchedule(WidgetTester tester, AppHarness harness) async {
  await harness.pump(
    tester,
    overrides: [_pickRange(DateTime(2026, 11, 11), DateTime(2026, 11, 13))],
  );
  await tester.pumpAndSettle();
  await tapKey(tester, 'nav-settings');
  await tapKey(tester, 'settings-schedule');
}

void main() {
  group('planReminders', () {
    const on = ReminderSettings(enabled: true, hour: 18);

    test('días de entreno de las próximas 2 semanas, sin los de pausa', () {
      final times = planReminders(
        settings: on,
        weekdays: const [1, 3, 5],
        breaks: [_break('2026-11-11', '2026-11-13')],
        now: monday,
      );
      expect(times, [
        DateTime(2026, 11, 9, 18),
        DateTime(2026, 11, 16, 18),
        DateTime(2026, 11, 18, 18),
        DateTime(2026, 11, 20, 18),
      ]);
    });

    test('si ya pasó la hora de hoy, empieza el siguiente día', () {
      final times = planReminders(
        settings: on,
        weekdays: const [1],
        breaks: const [],
        now: DateTime(2026, 11, 9, 19),
      );
      expect(times, [DateTime(2026, 11, 16, 18)]);
    });

    test('desactivado o sin días: nada', () {
      expect(
        planReminders(
          settings: const ReminderSettings(),
          weekdays: const [1, 3],
          breaks: const [],
          now: monday,
        ),
        isEmpty,
      );
      expect(
        planReminders(
          settings: on,
          weekdays: const [],
          breaks: const [],
          now: monday,
        ),
        isEmpty,
      );
    });
  });

  testWidgets('días de entreno: como mucho los del plan', (tester) async {
    usePhoneSize(tester);
    final harness = AppHarness.signedIn(clock: () => monday);
    await _openSchedule(tester, harness);

    expect(find.text('3 de 3 días elegidos'), findsOneWidget);
    await tapKey(tester, 'weekday-2');
    expect(
      find.text('Tu plan tiene 3 días por semana: elige 3 como mucho.'),
      findsOneWidget,
    );
    final save = find.byKey(const Key('weekdays-save'));
    expect(tester.widget<FilledButton>(save).onPressed, isNull);

    await tapKey(tester, 'weekday-1');
    await tapKey(tester, 'weekday-6');
    await tapKey(tester, 'weekday-6');
    expect(find.text('3 de 3 días elegidos'), findsOneWidget);
    await tapKey(tester, 'weekdays-save');
    expect(harness.backend.scheduleRequests.single, [2, 3, 5]);
    expect(find.text('Días de entreno guardados.'), findsOneWidget);
    await harness.drainAndUnmount(tester);
  });

  testWidgets('pausas: añadir con el selector de fechas y borrar', (
    tester,
  ) async {
    usePhoneSize(tester);
    final harness = AppHarness.signedIn(clock: () => monday);
    await _openSchedule(tester, harness);
    expect(find.byKey(const Key('breaks-empty')), findsOneWidget);

    await tapKey(tester, 'break-add');
    final created = harness.backend.breaks.values.single;
    expect((created.startsOn, created.endsOn), ('2026-11-11', '2026-11-13'));
    expect(find.text('3 días'), findsOneWidget);

    await tapKey(tester, 'break-delete-${created.id}');
    await tapKey(tester, 'break-delete-confirm');
    expect(harness.backend.breaks, isEmpty);
    expect(find.byKey(const Key('breaks-empty')), findsOneWidget);
    await harness.drainAndUnmount(tester);
  });

  testWidgets('una pausa de más de 60 días no se envía', (tester) async {
    usePhoneSize(tester);
    final harness = AppHarness.signedIn(clock: () => monday);
    await harness.pump(
      tester,
      overrides: [_pickRange(DateTime(2026, 11, 10), DateTime(2027, 1, 20))],
    );
    await tester.pumpAndSettle();
    await tapKey(tester, 'nav-settings');
    await tapKey(tester, 'settings-schedule');
    await tapKey(tester, 'break-add');
    expect(find.text('Una pausa dura como mucho 60 días.'), findsOneWidget);
    expect(harness.backend.breaks, isEmpty);
    await harness.drainAndUnmount(tester);
  });

  testWidgets('recordatorio: explica el permiso y se salta los días de pausa', (
    tester,
  ) async {
    usePhoneSize(tester);
    final harness = AppHarness.signedIn(clock: () => monday);
    await _openSchedule(tester, harness);
    await tapKey(tester, 'break-add'); // pausa del 11 al 13

    await tapKey(tester, 'reminder-toggle');
    expect(find.text('¿Te avisamos?'), findsOneWidget);
    expect(harness.notifications.permissionRequests, 0);
    await tapKey(tester, 'reminder-permission-continue');
    expect(harness.notifications.permissionRequests, 1);
    expect(harness.notifications.scheduled.values.toList()..sort(), [
      DateTime(2026, 11, 9, 18),
      DateTime(2026, 11, 16, 18),
      DateTime(2026, 11, 18, 18),
      DateTime(2026, 11, 20, 18),
    ]);
    expect(find.byKey(const Key('reminder-time')), findsOneWidget);

    // Al apagarlo se cancela todo.
    await tapKey(tester, 'reminder-toggle');
    expect(harness.notifications.scheduled, isEmpty);
    await harness.drainAndUnmount(tester);
  });

  testWidgets('recordatorio sin permiso: no se activa y lo explica', (
    tester,
  ) async {
    usePhoneSize(tester);
    final harness = AppHarness.signedIn(clock: () => monday);
    harness.notifications.grant = false;
    await _openSchedule(tester, harness);
    await tapKey(tester, 'reminder-toggle');
    await tapKey(tester, 'reminder-permission-continue');
    expect(
      find.textContaining('Sin permiso no podemos avisarte'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('reminder-time')), findsNothing);
    expect(harness.notifications.scheduled, isEmpty);
    await harness.drainAndUnmount(tester);
  });

  testWidgets('Hoy: en pausa y en día de descanso', (tester) async {
    usePhoneSize(tester);
    final backend = FakeBackend()..todayJson = fixture('today_session_break');
    final harness = AppHarness.signedIn(backend: backend);
    await harness.pump(tester);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('today-break')), findsOneWidget);
    expect(find.textContaining('Estás en pausa hasta el'), findsOneWidget);
    await harness.drainAndUnmount(tester);

    final rest = FakeBackend()
      ..todayJson = (fixture('today_session')..['scheduledToday'] = false);
    final h2 = AppHarness.signedIn(backend: rest);
    await h2.pump(tester);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('today-rest-day')), findsOneWidget);
    expect(find.byKey(const Key('today-break')), findsNothing);
    await h2.drainAndUnmount(tester);
  });
}
