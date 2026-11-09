import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipos_fitness/core/api/api_client.dart';
import 'package:pipos_fitness/core/api/auth_interceptor.dart';
import 'package:pipos_fitness/core/auth/auth_session_coordinator.dart';
import 'package:pipos_fitness/core/auth/session_providers.dart';
import 'package:pipos_fitness/core/auth/token_storage.dart';

import '../../helpers/fake_http_adapter.dart';

void main() {
  late FakeHttpAdapter adapter;
  late InMemoryTokenStorage storage;
  late List<SessionEndReason> ended;
  late ProviderContainer container;

  setUp(() {
    adapter = FakeHttpAdapter();
    storage = InMemoryTokenStorage(accessToken: 'old', refreshToken: 'r1');
    ended = [];
    container = ProviderContainer(
      overrides: [
        apiBaseUrlProvider.overrideWithValue('http://api.test'),
        httpClientAdapterProvider.overrideWithValue(adapter),
        tokenStorageProvider.overrideWithValue(storage),
        sessionEndCallbackProvider.overrideWithValue(ended.add),
      ],
    );
  });

  tearDown(() => container.dispose());

  Dio dio() => container.read(dioProvider);

  void refreshReturns(String access, String refresh) {
    adapter.reply('POST', '/auth/refresh', 200, {
      'accessToken': access,
      'refreshToken': refresh,
    });
  }

  test('adjunta el Bearer token guardado', () async {
    adapter.reply('GET', '/me', 200, meJson());
    await dio().get<dynamic>('/me');
    expect(adapter.requests.single.headers['Authorization'], 'Bearer old');
  });

  test('401 → refresh → reintento único con el token nuevo', () async {
    refreshReturns('new', 'r2');
    adapter.on('GET', '/me', (o) async {
      return o.headers['Authorization'] == 'Bearer new'
          ? FakeResponse(200, meJson())
          : const FakeResponse(401);
    });

    final res = await dio().get<dynamic>('/me');

    expect(res.statusCode, 200);
    expect(adapter.count('GET', '/me'), 2);
    expect(adapter.count('POST', '/auth/refresh'), 1);
    expect(storage.accessToken, 'new');
    expect(storage.refreshToken, 'r2');
    expect(ended, isEmpty);
    // El refresh no lleva Authorization (va por el Dio público).
    final refresh = adapter.requests.firstWhere(
      (r) => r.path == '/auth/refresh',
    );
    expect(refresh.headers.containsKey('Authorization'), isFalse);
  });

  test('(b) una petición se reintenta como mucho UNA vez; 2º 401 = sesión '
      'expirada', () async {
    refreshReturns('new', 'r2');
    adapter.reply('GET', '/me', 401);

    await expectLater(
      dio().get<dynamic>('/me'),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.statusCode,
          'status',
          401,
        ),
      ),
    );

    expect(adapter.count('GET', '/me'), 2, reason: 'original + 1 reintento');
    expect(adapter.count('POST', '/auth/refresh'), 1);
    expect(ended, [SessionEndReason.expired]);
    expect(storage.accessToken, isNull);
    final retried = adapter.requests.where((r) => r.path == '/me').last;
    expect(retried.extra[AuthExtra.retried], isTrue);
  });

  test('si el token cambió mientras la petición volaba, reintenta con el '
      'actual SIN refrescar', () async {
    var calls = 0;
    adapter.on('GET', '/me', (o) async {
      calls++;
      if (calls == 1) {
        // Otro request refrescó en paralelo.
        storage.accessToken = 'fresh';
        return const FakeResponse(401);
      }
      return o.headers['Authorization'] == 'Bearer fresh'
          ? FakeResponse(200, meJson())
          : const FakeResponse(401);
    });

    final res = await dio().get<dynamic>('/me');

    expect(res.statusCode, 200);
    expect(adapter.count('POST', '/auth/refresh'), 0);
    expect(ended, isEmpty);
  });

  test('401 concurrentes comparten un único refresh (no se reusa el refresh '
      'token rotado)', () async {
    final gate = Completer<void>();
    adapter.on('POST', '/auth/refresh', (_) async {
      await gate.future;
      return const FakeResponse(200, {
        'accessToken': 'new',
        'refreshToken': 'r2',
      });
    });
    for (final path in ['/a', '/b', '/c']) {
      adapter.on('GET', path, (o) async {
        return o.headers['Authorization'] == 'Bearer new'
            ? const FakeResponse(200, {'ok': true})
            : const FakeResponse(401);
      });
    }

    final futures = [
      dio().get<dynamic>('/a'),
      dio().get<dynamic>('/b'),
      dio().get<dynamic>('/c'),
    ];
    await Future<void>.delayed(const Duration(milliseconds: 20));
    gate.complete();
    final results = await Future.wait(futures);

    expect(results.map((r) => r.statusCode), everyElement(200));
    expect(adapter.count('POST', '/auth/refresh'), 1);
  });

  test(
    'refresh rechazado (401) → borra tokens y notifica sesión expirada',
    () async {
      adapter.reply('POST', '/auth/refresh', 401);
      adapter.reply('GET', '/me', 401);

      await expectLater(
        dio().get<dynamic>('/me'),
        throwsA(isA<DioException>()),
      );

      expect(adapter.count('GET', '/me'), 1);
      expect(ended, [SessionEndReason.expired]);
      expect(storage.accessToken, isNull);
      expect(storage.refreshToken, isNull);
    },
  );

  test('refresh sin red NO cierra la sesión (offline)', () async {
    adapter.on(
      'POST',
      '/auth/refresh',
      (_) async => const FakeResponse.offline(),
    );
    adapter.reply('GET', '/me', 401);

    await expectLater(dio().get<dynamic>('/me'), throwsA(isA<DioException>()));

    expect(ended, isEmpty);
    expect(storage.accessToken, 'old');
    expect(storage.refreshToken, 'r1');
  });

  for (final relogin in [false, true]) {
    test('401 de una petición de la sesión anterior NO borra los tokens '
        'nuevos (relogin en el mismo scope: $relogin)', () async {
      final coordinator = container.read(authSessionCoordinatorProvider);
      adapter.reply('POST', '/auth/refresh', 401);
      adapter.on('GET', '/me', (o) async {
        // Mientras volaba: logout de A y login de B.
        coordinator.onLoggedOut();
        if (relogin) coordinator.onSessionStarted();
        storage.accessToken = 'b-access';
        storage.refreshToken = 'b-refresh';
        return const FakeResponse(401);
      });

      await expectLater(
        dio().get<dynamic>('/me'),
        throwsA(isA<DioException>()),
      );

      expect(storage.accessToken, 'b-access');
      expect(storage.refreshToken, 'b-refresh');
      expect(ended, [SessionEndReason.logout]);
    });
  }

  test('peticiones con skipAuth: sin token y sin refresh ante 401', () async {
    adapter.reply('POST', '/auth/login', 401, {'message': 'Invalid'});

    await expectLater(
      dio().post<dynamic>(
        '/auth/login',
        options: Options(extra: AuthExtra.public),
      ),
      throwsA(isA<DioException>()),
    );

    expect(
      adapter.requests.single.headers.containsKey('Authorization'),
      isFalse,
    );
    expect(adapter.count('POST', '/auth/refresh'), 0);
    expect(ended, isEmpty);
  });

  test('aplica los timeouts configurados a ambos Dio', () {
    for (final d in [
      container.read(dioProvider),
      container.read(publicDioProvider),
    ]) {
      expect(d.options.connectTimeout, isNotNull);
      expect(d.options.receiveTimeout, isNotNull);
      expect(d.options.sendTimeout, isNotNull);
    }
    expect(
      container
          .read(publicDioProvider)
          .interceptors
          .whereType<AuthInterceptor>(),
      isEmpty,
    );
  });

  group('401 AUTH_REFRESH_RACE (otro refresh concurrente ganó)', () {
    test(
      'NO cierra sesión y reintenta con el token que guardó el ganador',
      () async {
        adapter.on('POST', '/auth/refresh', (_) async {
          // Mientras tanto, el refresh ganador guardó tokens nuevos.
          storage.accessToken = 'winner';
          storage.refreshToken = 'r-winner';
          return const FakeResponse(401, {
            'statusCode': 401,
            'code': 'AUTH_REFRESH_RACE',
            'message': 'Refresh in progress',
          });
        });
        adapter.on('GET', '/me', (o) async {
          return o.headers['Authorization'] == 'Bearer winner'
              ? FakeResponse(200, meJson())
              : const FakeResponse(401);
        });

        final res = await dio().get<dynamic>('/me');

        expect(res.statusCode, 200);
        expect(ended, isEmpty);
        expect(storage.accessToken, 'winner');
        expect(storage.refreshToken, 'r-winner');
      },
    );

    test(
      'sin token nuevo guardado: propaga el 401 pero mantiene la sesión',
      () async {
        adapter.reply('POST', '/auth/refresh', 401, {
          'statusCode': 401,
          'code': 'AUTH_REFRESH_RACE',
          'message': 'Refresh in progress',
        });
        adapter.reply('GET', '/me', 401);

        await expectLater(
          dio().get<dynamic>('/me'),
          throwsA(isA<DioException>()),
        );
        expect(ended, isEmpty);
        expect(storage.accessToken, 'old');
        expect(storage.refreshToken, 'r1');
      },
    );
  });
}
