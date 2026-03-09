import 'package:flutter_test/flutter_test.dart';
import 'package:pipos_fitness/core/auth/auth_session_coordinator.dart';

void main() {
  group('AuthSessionCoordinator', () {
    late AuthSessionCoordinator coordinator;

    setUp(() {
      coordinator = AuthSessionCoordinator();
    });

    test('onSessionExpired calls forceLogout handler', () {
      var called = false;
      coordinator.setForceLogoutHandler(() => called = true);

      coordinator.onSessionExpired();

      expect(called, isTrue);
    });

    test('onSessionExpired invalidates all registered providers', () {
      final invalidated = <String>[];
      coordinator.registerInvalidation(() => invalidated.add('progress'));
      coordinator.registerInvalidation(() => invalidated.add('training'));
      coordinator.registerInvalidation(() => invalidated.add('nutrition'));

      coordinator.onSessionExpired();

      expect(invalidated, ['progress', 'training', 'nutrition']);
    });

    test('onSessionExpired executes only once per event (re-entry guard)', () async {
      var callCount = 0;
      coordinator.setForceLogoutHandler(() => callCount++);

      coordinator.onSessionExpired();
      coordinator.onSessionExpired();
      coordinator.onSessionExpired();

      expect(callCount, 1);

      // After microtask, guard resets
      await Future.delayed(Duration.zero);
      coordinator.onSessionExpired();
      expect(callCount, 2);
    });

    test('onSessionStarted resets the guard', () {
      var callCount = 0;
      coordinator.setForceLogoutHandler(() => callCount++);

      coordinator.onSessionExpired();
      expect(callCount, 1);

      coordinator.onSessionStarted();
      coordinator.onSessionExpired();
      expect(callCount, 2);
    });

    test('works without forceLogout handler set', () {
      // Should not throw
      coordinator.onSessionExpired();
    });

    test('works without invalidation callbacks', () {
      coordinator.setForceLogoutHandler(() {});
      // Should not throw
      coordinator.onSessionExpired();
    });
  });
}
