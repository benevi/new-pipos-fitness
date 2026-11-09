# Phase 10.2 — Auth / Session Consistency Hardening

No new product features. Guarantees consistent authentication state, logout behavior, and protected-provider invalidation.

## Files Modified

- `lib/features/auth/auth_provider.dart` — registers with coordinator, invalidates providers on logout/forced-logout, session-expired error message
- `lib/core/api/auth_interceptor.dart` — uses coordinator instead of `onForceLogout` callback
- `lib/core/api/api_client.dart` — passes coordinator to interceptor
- `lib/features/profile/profile_screen.dart` — removed manual `context.go('/login')`, relies on router redirect
- `test/features/auth/auth_state_test.dart` — expanded with forced-logout and loading tests

## New Files

- `lib/core/auth/auth_session_coordinator.dart` — session coordination bridge
- `test/core/auth/auth_session_coordinator_test.dart` — 6 tests for coordinator

## Auth/Session Coordination Pattern

`AuthSessionCoordinator` is a singleton that bridges the Dio interceptor (which lives outside Riverpod) with the Riverpod-managed auth state and data providers.

Dependency direction (no cycles):

```
AuthInterceptor ──calls──> AuthSessionCoordinator ──calls──> AuthNotifier
                                                  ──invalidates──> data providers
```

The coordinator is instantiated once as a top-level singleton. The interceptor receives it via constructor. The AuthNotifier registers its `_onForceLogout` handler with the coordinator during initialization.

## How Forced Logout Works

1. Interceptor detects 401 + refresh failure in `_doRefresh()`
2. Interceptor clears tokens from secure storage
3. Interceptor calls `coordinator.onSessionExpired()`
4. Coordinator's re-entry guard prevents duplicate execution
5. Coordinator calls `AuthNotifier._onForceLogout()`:
   - Invalidates `progressProvider`, `trainingPlanProvider`, `nutritionPlanProvider`
   - Sets state to `unauthenticated` with error: "Your session has expired..."
6. Router watches auth state → redirects to `/login`
7. Login screen shows the session-expired message
8. Original 401 error propagates to the API caller (fails safely)

User-initiated logout follows the same invalidation path via `AuthNotifier.logout()` directly.

## Providers Invalidated on Logout

| Provider               | Invalidated on logout | Invalidated on forced logout |
|------------------------|-----------------------|------------------------------|
| progressProvider       | Yes                   | Yes                          |
| trainingPlanProvider   | Yes                   | Yes                          |
| nutritionPlanProvider  | Yes                   | Yes                          |

After invalidation, providers return to their initial (unresolved) state. Next authenticated session triggers fresh fetches.

## Router Consistency

| Transition                          | Behavior                              |
|-------------------------------------|---------------------------------------|
| unknown → unauthenticated           | Redirect to /login                    |
| unknown → authenticated             | Stay on current / redirect from auth  |
| authenticated → unauthenticated     | Redirect to /login                    |
| authenticated → unauthenticated (forced) | Redirect to /login + show error  |
| unauthenticated → authenticated     | Redirect from /login to /dashboard    |

Router uses `authState.isResolved` (blocks during `unknown`) and `authState.isAuthenticated`. Profile screen no longer calls `context.go('/login')` — it calls `logout()` and the router redirect handles navigation.

## Deterministic Refresh Failure

Guarantees:
- `RefreshLock` ensures only one refresh executes for concurrent 401s
- `AuthSessionCoordinator._isProcessingLogout` guard prevents duplicate logout handling
- Token clearing happens once in the interceptor, before coordinator notification
- Auth state is set once by the coordinator's handler
- Guard resets via `scheduleMicrotask` (same event loop) or `onSessionStarted` (new login)

## Known Limitations

- Coordinator is a top-level singleton (acceptable for mobile app lifecycle)
- No automatic token expiry timer; relies on 401-based detection
- Provider invalidation uses `ref.invalidate()` which re-triggers `build()` — providers with `keepAlive` will immediately attempt to re-fetch (this is acceptable because auth state is already unauthenticated so requests will fail cleanly)
- `onForceLogout` is registered once; if AuthNotifier is recreated the handler must be re-registered (handled by the provider factory)

## Commands

```bash
cd apps/mobile
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```
