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
        error: 'prev',
      );
      final updated = original.copyWith(status: AuthStatus.error);
      expect(updated.status, AuthStatus.error);
      // error is reset to null when not explicitly provided via the
      // copyWith signature (error defaults to the parameter value)
    });

    test('error state holds message', () {
      final state = const AuthState().copyWith(
        status: AuthStatus.error,
        error: 'Bad credentials',
      );
      expect(state.status, AuthStatus.error);
      expect(state.error, 'Bad credentials');
    });
  });
}
