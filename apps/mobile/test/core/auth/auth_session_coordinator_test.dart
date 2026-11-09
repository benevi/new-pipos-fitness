import 'package:flutter_test/flutter_test.dart';
import 'package:pipos_fitness/core/auth/auth_session_coordinator.dart';

void main() {
  group('AuthSessionCoordinator', () {
    late List<SessionEndReason> ended;
    late AuthSessionCoordinator coordinator;

    setUp(() {
      ended = [];
      coordinator = AuthSessionCoordinator(onSessionEnded: ended.add);
    });

    test('onSessionExpired notifica el fin de sesión con motivo expired', () {
      coordinator.onSessionExpired();
      expect(ended, [SessionEndReason.expired]);
      expect(coordinator.hasEnded, isTrue);
    });

    test('onLoggedOut notifica con motivo logout', () {
      coordinator.onLoggedOut();
      expect(ended, [SessionEndReason.logout]);
    });

    test('es idempotente: varios 401 a la vez solo provocan un reset', () {
      coordinator.onSessionExpired();
      coordinator.onSessionExpired();
      coordinator.onLoggedOut();
      expect(ended, [SessionEndReason.expired]);
    });

    test('onSessionStarted rearma la guarda', () {
      coordinator.onSessionExpired();
      coordinator.onSessionStarted();
      expect(coordinator.hasEnded, isFalse);
      coordinator.onLoggedOut();
      expect(ended, [SessionEndReason.expired, SessionEndReason.logout]);
    });
  });
}
