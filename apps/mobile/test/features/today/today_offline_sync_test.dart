// CUJ-2: registrar una serie en modo avión → queda en la cola drift →
// al volver la red se sincroniza una sola vez. La API se simula a nivel
// HTTP (Dio real + FakeHttpAdapter) con idempotencia por clientId: 201 la
// primera vez, 200 al reenviar.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipos_fitness/core/auth/token_storage.dart';
import 'package:pipos_fitness/features/today/today_screen.dart';
import 'package:pipos_fitness/models/user.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_http_adapter.dart';
import '../../helpers/fixtures.dart';
import '../../helpers/ui.dart';

/// API de entrenamientos simulada por HTTP.
class _HttpWorkoutServer {
  _HttpWorkoutServer(this.adapter) {
    adapter.on(
      'GET',
      '/sessions/today',
      (_) => _maybe(FakeResponse(200, fixture('today_session'))),
    );
    adapter.on('POST', '/workouts', (o) {
      if (offline) return const FakeResponse.offline();
      final body = _body(o);
      final created = workoutClientId == null;
      workoutClientId ??= body['clientId'] as String;
      return FakeResponse(created ? 201 : 200, _workout());
    });
    adapter.on('POST', '/workouts/srv-w1/sets', (o) {
      if (offline) return const FakeResponse.offline();
      final body = _body(o);
      final clientId = body['clientId'] as String;
      final created = !sets.containsKey(clientId);
      sets.putIfAbsent(clientId, () => body);
      if (loseNextResponse) {
        // La API guardó la serie pero la respuesta no llega al móvil.
        loseNextResponse = false;
        return const FakeResponse.offline();
      }
      statuses.add(created ? 201 : 200);
      return FakeResponse(created ? 201 : 200, _setLog(body));
    });
  }

  final FakeHttpAdapter adapter;
  bool offline = false;
  bool loseNextResponse = false;
  String? workoutClientId;
  final Map<String, Map<String, dynamic>> sets = {};
  final List<int> statuses = [];

  FakeResponse _maybe(FakeResponse r) =>
      offline ? const FakeResponse.offline() : r;

  static Map<String, dynamic> _body(dynamic o) {
    final data = o.data;
    return data is String
        ? jsonDecode(data) as Map<String, dynamic>
        : (data as Map).cast<String, dynamic>();
  }

  Map<String, dynamic> _workout() => {
    ...fixture('workout'),
    'id': 'srv-w1',
    'clientId': workoutClientId,
    'sets': <Object>[],
    'substitutions': <Object>[],
  };

  Map<String, dynamic> _setLog(Map<String, dynamic> body) => {
    ...fixture('set_log'),
    'clientId': body['clientId'],
    'workoutId': 'srv-w1',
    'planExerciseId': body['planExerciseId'],
    'exerciseId': body['exerciseId'],
    'setIndex': body['setIndex'],
    'reps': body['reps'],
    'loadKg': body['loadKg'],
    'rir': body['rir'],
  };
}

Finder _syncIcon(String status) => find.byWidgetPredicate(
  (w) =>
      w is Icon &&
      w.key is ValueKey<String> &&
      (w.key! as ValueKey<String>).value.endsWith('-$status'),
);

void main() {
  testWidgets(
    'serie offline → en cola → online → sincronizada sin duplicar (201 y luego 200)',
    (tester) async {
      usePhoneSize(tester);
      var now = DateTime.utc(2026, 11, 9, 8);
      final backend = FakeBackend()..useHttpWorkoutApi = true;
      final harness = AppHarness(
        storage: InMemoryTokenStorage(
          accessToken: 'access-1',
          refreshToken: 'refresh-1',
          cachedUser: const AuthUser(id: 'user-1', email: 'ana@pipos.app'),
        ),
        backend: backend,
        clock: () => now,
      );
      harness.adapter.reply('GET', '/me', 200, meJson());
      final server = _HttpWorkoutServer(harness.adapter);

      await harness.pump(tester);
      await tester.pumpAndSettle();
      expect(find.byType(TodayScreen), findsOneWidget);
      expect(find.text('Sentadilla trasera'), findsOneWidget);
      expect(find.text('Carga sugerida: 62,5 kg'), findsOneWidget);

      // Modo avión.
      server.offline = true;
      harness.connectivity.online = false;

      const squat = '00000000-0000-4000-8000-000000000030';
      // Valores precargados (8 reps, 62,5 kg, RIR 2): confirmar = 1 toque.
      expect(find.text('62.5'), findsOneWidget);
      await tapKey(tester, 'confirm-$squat', settle: false);
      await pumpFrames(tester);
      await scrollToTop(tester);
      expect(_syncIcon('pending'), findsOneWidget);
      expect(find.text('1 serie pendiente de sincronizar'), findsOneWidget);
      expect(find.byKey(const Key('rest-timer')), findsOneWidget);
      expect(server.sets, isEmpty);
      await tapKey(tester, 'rest-skip', settle: false);

      // Vuelve la red, pero la primera respuesta de la serie se pierde.
      server.offline = false;
      server.loseNextResponse = true;
      harness.connectivity.online = true;
      await pumpFrames(tester);
      expect(server.sets, hasLength(1), reason: 'la API ya la guardó');
      expect(
        _syncIcon('pending'),
        findsOneWidget,
        reason: 'el móvil no recibió confirmación',
      );

      // Reintento con backoff: mismo clientId → 200, sin duplicar.
      now = now.add(const Duration(minutes: 1));
      await tester.pump(const Duration(seconds: 3));
      await pumpFrames(tester);
      expect(server.sets, hasLength(1));
      expect(server.statuses, [200]);
      expect(harness.adapter.count('POST', '/workouts/srv-w1/sets'), 2);
      expect(_syncIcon('synced'), findsOneWidget);
      expect(find.text('1 serie pendiente de sincronizar'), findsNothing);

      final body = server.sets.values.single;
      expect(body['setIndex'], 0);
      expect(body['reps'], 8);
      expect(body['loadKg'], 62.5);
      expect(body['rir'], 2);
      expect(body['planExerciseId'], squat);

      await harness.drainAndUnmount(tester);
    },
  );

  testWidgets('sin red y con la sesión en caché, Hoy abre en modo avión', (
    tester,
  ) async {
    usePhoneSize(tester);
    final harness = AppHarness.signedIn();
    await harness.pump(tester);
    await tester.pumpAndSettle();
    expect(find.text('Sentadilla trasera'), findsOneWidget);

    // Se reabre la app sin red: mismo almacenamiento y misma BD.
    harness.setOnline(false);
    harness.adapter.on('GET', '/me', (_) => const FakeResponse.offline());
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpWidget(harness.build());
    await tester.pumpAndSettle();

    expect(find.byType(TodayScreen), findsOneWidget);
    expect(find.text('Sentadilla trasera'), findsOneWidget);
    expect(find.byKey(const Key('today-cached')), findsOneWidget);
    await harness.drainAndUnmount(tester);
  });
}
