// Entrada offline sin usuario cacheado: el id guardado con los tokens
// identifica al dueño de la cola offline (antes `user` quedaba null y
// registrar una serie lanzaba StateError).
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipos_fitness/core/api/api_client.dart';
import 'package:pipos_fitness/core/auth/session_providers.dart';
import 'package:pipos_fitness/core/auth/token_storage.dart';
import 'package:pipos_fitness/core/offline/connectivity.dart';
import 'package:pipos_fitness/core/offline/offline_providers.dart';
import 'package:pipos_fitness/features/auth/auth_provider.dart';

import '../../helpers/fake_http_adapter.dart';

void main() {
  test('sin red y sin usuario cacheado: entra offline con el id guardado '
      'junto a los tokens', () async {
    final adapter = FakeHttpAdapter()
      ..on('GET', '/me', (_) => const FakeResponse.offline());
    final connectivity = ManualConnectivitySource(online: false);
    final container = ProviderContainer(
      overrides: [
        apiBaseUrlProvider.overrideWithValue('http://api.test'),
        httpClientAdapterProvider.overrideWithValue(adapter),
        tokenStorageProvider.overrideWithValue(
          InMemoryTokenStorage(
            accessToken: 'a',
            refreshToken: 'r',
            userId: 'user-1',
          ),
        ),
        sessionEndCallbackProvider.overrideWithValue((_) {}),
        connectivitySourceProvider.overrideWithValue(connectivity),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await connectivity.dispose();
    });
    container.read(authProvider);
    for (var i = 0; i < 20 && !container.read(authProvider).isResolved; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    final state = container.read(authProvider);
    expect(state.isAuthenticated, isTrue);
    expect(state.isOffline, isTrue);
    expect(state.user?.id, 'user-1');
  });

  test('login guarda el id del usuario junto a los tokens', () async {
    final storage = InMemoryTokenStorage();
    await storage.saveTokens(
      accessToken: 'a',
      refreshToken: 'r',
      userId: 'user-1',
    );
    await storage.saveTokens(accessToken: 'a2', refreshToken: 'r2');
    expect(await storage.readUserId(), 'user-1');
  });
}
