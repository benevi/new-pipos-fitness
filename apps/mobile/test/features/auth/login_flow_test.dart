import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipos_fitness/app/router.dart';
import 'package:pipos_fitness/core/auth/token_storage.dart';
import 'package:pipos_fitness/features/auth/auth_provider.dart';
import 'package:pipos_fitness/features/auth/login_screen.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_http_adapter.dart';

Future<void> _submitLogin(WidgetTester tester, String password) async {
  await tester.enterText(find.byKey(const Key('login-email')), 'ana@pipos.app');
  await tester.enterText(find.byKey(const Key('login-password')), password);
  await tester.tap(find.byKey(const Key('login-submit')));
  await tester.pumpAndSettle();
}

void main() {
  group('(a) contraseña incorrecta', () {
    testWidgets(
      'muestra error en el formulario y NO refresca ni cierra sesión',
      (tester) async {
        final harness = AppHarness();
        harness.adapter.reply('POST', '/auth/login', 401, {
          'message': 'Invalid email or password',
        });
        await harness.pump(tester);
        await tester.pumpAndSettle();
        final containerBefore = harness.container(tester);

        await _submitLogin(tester, 'mala');

        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.text('Correo o contraseña incorrectos.'), findsOneWidget);
        // Ni refresh ni logout ni reset del scope.
        expect(harness.adapter.count('POST', '/auth/refresh'), 0);
        expect(harness.adapter.count('POST', '/auth/logout'), 0);
        expect(identical(harness.container(tester), containerBefore), isTrue);
        expect(
          containerBefore.read(authProvider).error,
          AuthErrorCode.invalidCredentials,
        );
        // El login fue sin cabecera Authorization (Dio público).
        final login = harness.adapter.requests.firstWhere(
          (r) => r.path == '/auth/login',
        );
        expect(login.headers.containsKey('Authorization'), isFalse);
      },
    );

    testWidgets('tras el error, un login correcto entra en la app', (
      tester,
    ) async {
      final harness = AppHarness();
      var attempts = 0;
      harness.adapter.on('POST', '/auth/login', (o) async {
        attempts++;
        return attempts == 1
            ? const FakeResponse(401, {'message': 'Invalid'})
            : FakeResponse(201, authResponseJson());
      });
      await harness.pump(tester);
      await tester.pumpAndSettle();

      await _submitLogin(tester, 'mala');
      expect(find.text('Correo o contraseña incorrectos.'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('login-password')), 'buena');
      await tester.tap(find.byKey(const Key('login-submit')));
      await tester.pumpAndSettle();

      final container = harness.container(tester);
      expect(container.read(authProvider).isAuthenticated, isTrue);
      expect(harness.storage.accessToken, 'access-1');
      expect(
        container
            .read(routerProvider)
            .routerDelegate
            .currentConfiguration
            .uri
            .path,
        AppRoutes.home,
      );
      await harness.drainAndUnmount(tester);
    });
  });

  group('sesión expirada', () {
    testWidgets('refresh rechazado al arrancar → login con aviso', (
      tester,
    ) async {
      final harness = AppHarness(
        storage: InMemoryTokenStorage(accessToken: 'old', refreshToken: 'r'),
      );
      harness.adapter.reply('GET', '/me', 401);
      harness.adapter.reply('POST', '/auth/refresh', 401);
      await harness.pump(tester);
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(
        find.text('Tu sesión ha caducado. Vuelve a iniciar sesión.'),
        findsOneWidget,
      );
      expect(harness.storage.accessToken, isNull);
    });
  });
}
