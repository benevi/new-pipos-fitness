import 'package:flutter_test/flutter_test.dart';
import 'package:pipos_fitness/features/auth/auth_provider.dart';

void main() {
  group('AuthState', () {
    test('default status is unknown', () {
      const state = AuthState();
      expect(state.status, AuthStatus.unknown);
      expect(state.isResolved, isFalse);
      expect(state.isAuthenticated, isFalse);
      expect(state.isLoading, isFalse);
    });

    test('isResolved is true for all non-unknown statuses', () {
      for (final status in AuthStatus.values) {
        final state = AuthState(status: status);
        expect(state.isResolved, status != AuthStatus.unknown);
      }
    });

    test('isAuthenticated only true for authenticated', () {
      expect(
        const AuthState(status: AuthStatus.authenticated).isAuthenticated,
        isTrue,
      );
      expect(
        const AuthState(status: AuthStatus.unauthenticated).isAuthenticated,
        isFalse,
      );
      expect(
        const AuthState(status: AuthStatus.error).isAuthenticated,
        isFalse,
      );
    });

    test('copyWith preserves unspecified fields', () {
      const original = AuthState(
        status: AuthStatus.authenticated,
        error: AuthErrorCode.network,
        isOffline: true,
      );
      final updated = original.copyWith(status: AuthStatus.error);
      expect(updated.status, AuthStatus.error);
      expect(updated.isOffline, isTrue);
      expect(updated.error, isNull, reason: 'copyWith limpia el error');
    });

    test('error state holds message', () {
      final state = const AuthState().copyWith(
        status: AuthStatus.error,
        error: AuthErrorCode.invalidCredentials,
      );
      expect(state.status, AuthStatus.error);
      expect(state.error, AuthErrorCode.invalidCredentials);
    });

    test(
      'forced logout produces unauthenticated with session-expired message',
      () {
        const state = AuthState(
          status: AuthStatus.unauthenticated,
          error: AuthErrorCode.sessionExpired,
        );
        expect(state.isAuthenticated, isFalse);
        expect(state.isResolved, isTrue);
        expect(state.error, AuthErrorCode.sessionExpired);
      },
    );

    test('unauthenticated state clears user', () {
      const state = AuthState(status: AuthStatus.unauthenticated);
      expect(state.user, isNull);
      expect(state.error, isNull);
    });

    test('loading state is not authenticated and is resolved', () {
      const state = AuthState(status: AuthStatus.loading);
      expect(state.isAuthenticated, isFalse);
      expect(state.isLoading, isTrue);
      expect(state.isResolved, isTrue);
    });
  });
}
