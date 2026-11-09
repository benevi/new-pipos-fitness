# Phase 10.1 — Flutter Hardening

No new product features. Architectural robustness, safety, and UI foundation improvements.

## Files Modified

- `lib/features/auth/auth_provider.dart` — explicit 5-state AuthState model
- `lib/features/auth/login_screen.dart` — use `isLoading` getter
- `lib/features/auth/register_screen.dart` — use `isLoading` getter
- `lib/core/api/auth_interceptor.dart` — Completer-based refresh lock, no recursive refresh
- `lib/core/api/api_client.dart` — doc comments on responsibility
- `lib/app/router.dart` — handles `unknown` state, doc comments
- `lib/app/theme.dart` — design token foundation
- `lib/main.dart` — uses AppTheme, dark mode default
- `lib/features/dashboard/progress_provider.dart` — keepAlive
- `lib/features/workouts/training_plan_provider.dart` — keepAlive
- `lib/features/nutrition/nutrition_plan_provider.dart` — keepAlive

## New Files

- `lib/core/api/api_failure.dart` — unified error model
- `lib/core/api/dio_error_mapper.dart` — Dio-to-ApiFailure mapper
- `lib/core/api/refresh_lock.dart` — Completer-based concurrency lock
- `lib/app/theme.dart` — AppTheme, AppColors, AppSpacing, AppRadius
- `test/core/api/refresh_lock_test.dart` — 6 tests for lock behavior
- `test/core/api/dio_error_mapper_test.dart` — 10 tests for error mapping
- `test/features/auth/auth_state_test.dart` — 5 tests for state model

## Auth State Model

```
unknown → (check storage) → authenticated | unauthenticated
unauthenticated → (login/register) → loading → authenticated | error
error → (retry) → loading → authenticated | error
authenticated → (logout / refresh fail) → unauthenticated
```

| Status           | Router behavior             | UI behavior          |
|------------------|-----------------------------|----------------------|
| unknown          | No redirect (splash)        | Wait                 |
| unauthenticated  | Redirect to /login          | Show login form      |
| loading          | No redirect                 | Show spinner         |
| authenticated    | Redirect from auth to /dash | Show protected tabs  |
| error            | Redirect to /login          | Show error + form    |

## Refresh Concurrency Strategy

`RefreshLock` uses a `Completer<String?>`:

1. First 401 caller creates a Completer and executes the refresh action
2. Concurrent 401 callers receive the same Completer future (wait, don't duplicate)
3. On completion, Completer is cleared; next 401 starts a new cycle
4. `/auth/refresh` path is excluded from interception to prevent recursion
5. On refresh failure: tokens cleared, `onForceLogout` callback invoked

## Error Handling Layer

`ApiFailure` types: `network`, `timeout`, `unauthorized`, `badRequest`, `server`, `parse`, `unknown`.

`mapDioException()` maps every `DioException` variant to exactly one `ApiFailure`. Server messages are preserved when available. Raw Dio exceptions never reach UI code.

## Theme Foundation

- Dark mode as default (`ThemeMode.dark`)
- Orange accent: `#FF6D00`
- Dark surface palette: `#1A1A2E`, `#16213E`, `#0F0F23`
- Material 3 with custom `ColorScheme.fromSeed`
- Design tokens: `AppSpacing` (xs–xxl), `AppRadius` (sm–xl), `AppColors`
- Styled: NavigationBar, FilledButton, OutlinedButton, InputDecoration, AppBar

## Provider Caching Strategy

All main-tab providers use `ref.keepAlive()` in `build()`:

- `progressProvider` — stays alive across tab switches
- `trainingPlanProvider` — stays alive across tab switches
- `nutritionPlanProvider` — stays alive across tab switches

Data is fetched once on first access. Manual `refresh()` available. Provider is disposed only when the ProviderScope is disposed (app restart or logout).

## Known Limitations

- No automatic token expiry timer; relies on 401-based refresh
- No offline caching; providers return null on network failure
- Theme does not include custom fonts
- `onForceLogout` callback on the interceptor is not wired to authProvider yet (requires circular dependency resolution via a global key or event bus; deferred to next phase)
- Tests require `flutter test` (not `dart test`) due to `flutter_test` dependency

## Commands

```bash
cd apps/mobile
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```
