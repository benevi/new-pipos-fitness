import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pipos_fitness/app/router.dart';
import 'package:pipos_fitness/features/auth/auth_provider.dart';

import '../helpers/app_harness.dart';
import '../helpers/fake_http_adapter.dart';

String _path(GoRouter r) => r.routerDelegate.currentConfiguration.uri.path;

void main() {
  group('authRedirect (función pura)', () {
    const unknown = AuthState();
    const signedOut = AuthState(status: AuthStatus.unauthenticated);
    const loading = AuthState(status: AuthStatus.loading);
    const signedIn = AuthState(status: AuthStatus.authenticated);

    test('sin resolver → splash', () {
      expect(authRedirect(unknown, '/dashboard'), AppRoutes.splash);
      expect(authRedirect(unknown, AppRoutes.splash), isNull);
    });

    test('no autenticado → login (salvo rutas de auth)', () {
      expect(authRedirect(signedOut, '/dashboard'), AppRoutes.login);
      expect(authRedirect(signedOut, AppRoutes.splash), AppRoutes.login);
      expect(authRedirect(signedOut, AppRoutes.login), isNull);
      expect(authRedirect(signedOut, AppRoutes.register), isNull);
      expect(authRedirect(loading, AppRoutes.login), isNull);
    });

    test('autenticado → home desde auth/splash; resto sin cambios', () {
      expect(authRedirect(signedIn, AppRoutes.login), AppRoutes.home);
      expect(authRedirect(signedIn, AppRoutes.splash), AppRoutes.home);
      expect(authRedirect(signedIn, '/workouts'), isNull);
    });
  });

  testWidgets('(d) unauth → /login y auth → /dashboard con el MISMO router', (
    tester,
  ) async {
    final harness = AppHarness();
    harness.adapter.reply('POST', '/auth/login', 200, authResponseJson());
    await harness.pump(tester);
    await tester.pumpAndSettle();

    final container = harness.container(tester);
    final router = container.read(routerProvider);
    expect(_path(router), AppRoutes.login);

    // Un intento con error (loading → error) no recrea ni mueve el router.
    harness.adapter.reply('POST', '/auth/login', 401);
    // Sin await: el reloj falso lo avanza pumpAndSettle (Dio usa timers).
    unawaited(container.read(authProvider.notifier).login('a@b.c', 'x'));
    await tester.pumpAndSettle();
    expect(identical(container.read(routerProvider), router), isTrue);
    expect(_path(router), AppRoutes.login);

    harness.adapter.reply('POST', '/auth/login', 200, authResponseJson());
    unawaited(container.read(authProvider.notifier).login('a@b.c', 'ok'));
    await tester.pumpAndSettle();

    expect(identical(container.read(routerProvider), router), isTrue);
    expect(_path(router), AppRoutes.home);
    await harness.drainAndUnmount(tester);
  });
}
