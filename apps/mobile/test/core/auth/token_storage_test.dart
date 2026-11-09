import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipos_fitness/core/auth/token_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const raw = FlutterSecureStorage();

  test('access y refresh se escriben juntos en UN solo valor', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final storage = SecureTokenStorage();
    await storage.saveTokens(
      accessToken: 'a1',
      refreshToken: 'r1',
      userId: 'user-1',
    );
    expect((await raw.readAll()).keys, ['session']);
    expect(await storage.readAccessToken(), 'a1');
    expect(await storage.readRefreshToken(), 'r1');
    expect(await storage.readUserId(), 'user-1');

    // Un refresh (sin userId) conserva el dueño.
    await storage.saveTokens(accessToken: 'a2', refreshToken: 'r2');
    expect(await storage.readAccessToken(), 'a2');
    expect(await storage.readUserId(), 'user-1');

    await storage.clear();
    expect(await raw.readAll(), isEmpty);
  });

  test('migra las claves sueltas antiguas al leer', () async {
    FlutterSecureStorage.setMockInitialValues({
      'access_token': 'old-a',
      'refresh_token': 'old-r',
    });
    final storage = SecureTokenStorage();
    expect(await storage.readAccessToken(), 'old-a');
    expect(await storage.readRefreshToken(), 'old-r');
    expect((await raw.readAll()).keys, ['session']);
  });
}
