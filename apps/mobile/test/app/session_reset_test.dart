import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pipos_fitness/app/router.dart';
import 'package:pipos_fitness/core/auth/token_storage.dart';
import 'package:pipos_fitness/features/auth/auth_provider.dart';
import 'package:pipos_fitness/models/user.dart';

import '../helpers/app_harness.dart';
import '../helpers/fake_http_adapter.dart';

/// Provider con "datos de usuario" cualquiera, para comprobar que el reset
/// del scope los descarta sin tener que registrarlo en ninguna lista.
final _userNotesProvider = StateProvider<String?>((_) => null);

/// Router mínimo (sin pantallas que hagan peticiones) para aislar el test
/// del mecanismo de reset.
final _testRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => Consumer(
          builder: (context, ref, _) {
            final user = ref.watch(currentUserProvider);
            final notes = ref.watch(_userNotesProvider);
            return Scaffold(
              body: Column(
                children: [
                  Text('user:${user?.email ?? '-'}'),
                  Text('notes:${notes ?? '-'}'),
                  TextButton(
                    onPressed: () => ref.read(authProvider.notifier).logout(),
                    child: const Text('logout'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

void main() {
  testWidgets('(c) logout resetea TODO el estado (nuevo ProviderScope)', (
    tester,
  ) async {
    final harness = AppHarness(
      storage: InMemoryTokenStorage(accessToken: 'a', refreshToken: 'r'),
    );
    harness.adapter.reply('GET', '/me', 200, meJson(email: 'ana@pipos.app'));
    harness.adapter.reply('POST', '/auth/logout', 200, {'ok': true});

    await harness.pump(
      tester,
      overrides: [
        routerProvider.overrideWith((ref) => ref.watch(_testRouterProvider)),
      ],
    );
    await tester.pumpAndSettle();

    final before = harness.container(tester);
    before.read(_userNotesProvider.notifier).state = 'datos privados';
    await tester.pump();
    expect(find.text('user:ana@pipos.app'), findsOneWidget);
    expect(find.text('notes:datos privados'), findsOneWidget);

    await tester.tap(find.text('logout'));
    await tester.pumpAndSettle();

    final after = harness.container(tester);
    expect(identical(after, before), isFalse, reason: 'scope recreado');
    expect(after.read(currentUserProvider), isNull);
    expect(after.read(_userNotesProvider), isNull);
    expect(after.read(authProvider).status, AuthStatus.unauthenticated);
    expect(
      after.read(authProvider).error,
      isNull,
      reason: 'logout no es expiración',
    );
    expect(find.text('notes:-'), findsOneWidget);
    expect(harness.storage.accessToken, isNull);
    expect(harness.storage.cachedUser, isNull);
    expect(harness.adapter.count('POST', '/auth/logout'), 1);
  });

  testWidgets('arranque con token: GET /me valida la sesión', (tester) async {
    final harness = AppHarness(
      storage: InMemoryTokenStorage(accessToken: 'a', refreshToken: 'r'),
    );
    harness.adapter.reply('GET', '/me', 200, meJson(id: 'u-9', email: 'x@y.z'));
    await harness.pump(
      tester,
      overrides: [
        routerProvider.overrideWith((ref) => ref.watch(_testRouterProvider)),
      ],
    );
    await tester.pumpAndSettle();

    final auth = harness.container(tester).read(authProvider);
    expect(auth.isAuthenticated, isTrue);
    expect(auth.isOffline, isFalse);
    expect(auth.user?.id, 'u-9');
    expect(harness.storage.cachedUser?.email, 'x@y.z');
  });

  testWidgets('arranque con token sin red: entra en modo offline con el '
      'usuario cacheado y revalida al volver la red', (tester) async {
    final harness = AppHarness(
      online: false,
      storage: InMemoryTokenStorage(
        accessToken: 'a',
        refreshToken: 'r',
        cachedUser: const AuthUser(id: 'u-1', email: 'a@b.c'),
      ),
    );
    var online = false;
    harness.adapter.on('GET', '/me', (_) async {
      return online
          ? FakeResponse(200, meJson(id: 'u-1'))
          : const FakeResponse.offline();
    });
    await harness.pump(
      tester,
      overrides: [
        routerProvider.overrideWith((ref) => ref.watch(_testRouterProvider)),
      ],
    );
    await tester.pumpAndSettle();

    final container = harness.container(tester);
    expect(container.read(authProvider).isAuthenticated, isTrue);
    expect(container.read(authProvider).isOffline, isTrue);
    expect(container.read(currentUserProvider)?.id, 'u-1');

    online = true;
    harness.connectivity.online = true;
    await tester.pumpAndSettle();
    expect(container.read(authProvider).isOffline, isFalse);
  });
}
