// #26: entrar sin red con solo el id del usuario guardado (sesiones
// antiguas) ya no deja el correo vacío en Ajustes: se marca «sin conexión».
// Con el usuario completo guardado junto a los tokens, se ve el correo.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipos_fitness/core/auth/token_storage.dart';
import 'package:pipos_fitness/features/auth/auth_provider.dart';
import 'package:pipos_fitness/models/user.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_http_adapter.dart';
import '../../helpers/ui.dart';

Future<AppHarness> _openOffline(
  WidgetTester tester,
  InMemoryTokenStorage storage,
) async {
  usePhoneSize(tester);
  final harness = AppHarness(storage: storage, online: false);
  harness.setOnline(false);
  harness.adapter.on('GET', '/me', (_) => const FakeResponse.offline());
  await harness.pump(tester);
  await tester.pumpAndSettle();
  await tapKey(tester, 'nav-settings');
  return harness;
}

void main() {
  testWidgets('solo el id guardado: Ajustes marca «sin conexión» en vez de '
      'un correo vacío', (tester) async {
    final harness = await _openOffline(
      tester,
      InMemoryTokenStorage(
        accessToken: 'a',
        refreshToken: 'r',
        userId: 'user-1',
      ),
    );
    final auth = harness.container(tester).read(authProvider);
    expect(auth.isOffline, isTrue);
    expect(auth.user?.id, 'user-1');
    expect(find.byKey(const Key('settings-email-offline')), findsOneWidget);
    expect(
      find.text('Sin conexión: tu correo aparecerá al recuperar la red.'),
      findsOneWidget,
    );
    await harness.drainAndUnmount(tester);
  });

  testWidgets('usuario completo guardado con los tokens (sin su clave '
      'propia): sin red se ve el correo', (tester) async {
    final harness = await _openOffline(
      tester,
      InMemoryTokenStorage(
        accessToken: 'a',
        refreshToken: 'r',
        userId: 'user-1',
        userEmail: 'ana@pipos.app',
      ),
    );
    expect(find.text('ana@pipos.app'), findsOneWidget);
    expect(find.byKey(const Key('settings-email-offline')), findsNothing);
    await harness.drainAndUnmount(tester);
  });

  test(
    'login/validación guardan el usuario completo junto a los tokens',
    () async {
      final storage = InMemoryTokenStorage();
      await storage.saveTokens(
        accessToken: 'a',
        refreshToken: 'r',
        userId: 'user-1',
      );
      await storage.saveCachedUser(
        const AuthUser(id: 'user-1', email: 'ana@pipos.app'),
      );
      storage.cachedUser = null;
      expect(
        await storage.readCachedUser(),
        const AuthUser(id: 'user-1', email: 'ana@pipos.app'),
      );
    },
  );
}
