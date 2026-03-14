/// Auth Session Coordinator
///
/// Bridges the gap between the Dio [AuthInterceptor] (which lives outside
/// Riverpod) and the Riverpod-managed [AuthNotifier] + protected providers.
///
/// Why this exists:
/// - The interceptor detects refresh failure but cannot access Riverpod Ref.
/// - AuthNotifier manages auth state but doesn't know about data providers.
/// - This coordinator owns the single "session lost" code path so that
///   logout (user-initiated) and forced logout (refresh failure) both
///   follow the exact same invalidation sequence.
///
/// Dependency direction (no cycles):
///   AuthInterceptor â”€â”€callsâ”€â”€> AuthSessionCoordinator â”€â”€callsâ”€â”€> AuthNotifier
///                                                     â”€â”€invalidatesâ”€â”€> data providers
///
/// The coordinator is created once and injected into both the interceptor
/// and the auth provider setup. It holds a weak reference to the Ref via
/// a callback list, not a direct Ref, so it can be instantiated before the
/// provider tree is fully built.
library;
import 'dart:async';

typedef _InvalidateCallback = void Function();

class AuthSessionCoordinator {
  void Function()? _onForceLogout;
  final List<_InvalidateCallback> _invalidateCallbacks = [];
  bool _isProcessingLogout = false;

  /// Register the callback that sets auth state to unauthenticated.
  /// Called once during auth provider initialization.
  void setForceLogoutHandler(void Function() handler) {
    _onForceLogout = handler;
  }

  /// Register a provider invalidation callback.
  /// Each protected provider registers itself here via its build method.
  void registerInvalidation(_InvalidateCallback cb) {
    _invalidateCallbacks.add(cb);
  }

  /// Single entry point for session loss (forced or voluntary).
  ///
  /// Guarantees:
  /// - Executes at most once per session-loss event (guard via [_isProcessingLogout])
  /// - Sets auth state to unauthenticated
  /// - Invalidates all registered protected providers
  /// - Pending API requests that triggered this will fail with the original 401
  void onSessionExpired() {
    if (_isProcessingLogout) return;
    _isProcessingLogout = true;

    _onForceLogout?.call();

    for (final cb in _invalidateCallbacks) {
      cb();
    }

    // Allow re-entry for the next session (after login + logout cycle)
    scheduleMicrotask(() {
      _isProcessingLogout = false;
    });
  }

  /// Reset the guard. Called when a new authenticated session begins.
  void onSessionStarted() {
    _isProcessingLogout = false;
  }
}

/// Singleton coordinator shared between interceptor and providers.
/// Created outside of Riverpod so the interceptor can access it without Ref.
final authSessionCoordinator = AuthSessionCoordinator();
