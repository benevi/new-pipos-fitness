# Phase 10 — Flutter App Foundation

Foundation-only phase. No full UI design, no complex widgets, no offline sync.

## Project Structure

```
apps/mobile/
  lib/
    main.dart
    app/
      constants.dart          # API URL, storage keys
      router.dart             # GoRouter config + bottom nav shell
    core/
      api/
        api_client.dart       # Dio wrapper + providers
        auth_interceptor.dart # Token attachment + 401 refresh
    models/
      user.dart               # User, AuthResponse, AuthUser (Freezed)
      training_plan.dart      # TrainingPlan, Version, Session, Exercise (Freezed)
      nutrition_plan.dart     # NutritionPlan, Version, Day, Meal, Item (Freezed)
      progress_metrics.dart   # ProgressMetrics, ExerciseProgressItem (Freezed)
      ai_response.dart        # AIResponse (Freezed)
    features/
      auth/
        auth_provider.dart    # AuthNotifier (login, register, logout, token persistence)
        login_screen.dart     # Email + password form
        register_screen.dart  # Email + password + confirm form
      dashboard/
        dashboard_screen.dart # Placeholder
        progress_provider.dart# AsyncNotifier for GET /analytics/progress
      workouts/
        workouts_screen.dart  # Placeholder
        training_plan_provider.dart # AsyncNotifier for training plans
      nutrition/
        nutrition_screen.dart # Placeholder
        nutrition_plan_provider.dart # AsyncNotifier for nutrition plans
      ai_coach/
        ai_coach_screen.dart  # Placeholder
      profile/
        profile_screen.dart   # Placeholder + logout button
  pubspec.yaml
  analysis_options.yaml
```

## Dependencies

| Package                  | Purpose                              |
|--------------------------|--------------------------------------|
| dio                      | HTTP client                          |
| flutter_riverpod         | State management                     |
| riverpod_annotation      | Code-gen annotations                 |
| go_router                | Declarative routing                  |
| flutter_secure_storage   | Secure token persistence             |
| freezed_annotation       | Immutable model annotations          |
| json_annotation          | JSON serialization annotations       |
| build_runner (dev)       | Code generation runner               |
| freezed (dev)            | Freezed code generator               |
| json_serializable (dev)  | JSON code generator                  |
| riverpod_generator (dev) | Riverpod code generator              |

## Routing

GoRouter with auth redirect guard:

| Route        | Screen           | Auth required |
|-------------|------------------|---------------|
| /login      | LoginScreen      | No            |
| /register   | RegisterScreen   | No            |
| /dashboard  | DashboardScreen  | Yes           |
| /workouts   | WorkoutsScreen   | Yes           |
| /nutrition  | NutritionScreen  | Yes           |
| /ai-coach   | AiCoachScreen    | Yes           |
| /profile    | ProfileScreen    | Yes           |

Authenticated routes use a ShellRoute with Material 3 NavigationBar (5 tabs).

## API Integration

- `ApiClient` wraps Dio with typed `get`, `post`, `put`, `delete` methods
- `AuthInterceptor` attaches Bearer token on every request
- On 401: intercepts, calls `POST /auth/refresh`, retries original request
- On refresh failure: clears tokens → user redirected to `/login`
- Base URL configurable via `--dart-define=API_BASE_URL=...`

### Example API call

```dart
final api = ref.read(apiClientProvider);
final response = await api.get('/training-plans/current');
final plan = TrainingPlan.fromJson(response.data);
```

## State Management

Four Riverpod providers:

| Provider               | Type                        | API Endpoint             |
|------------------------|-----------------------------|--------------------------|
| authProvider           | StateNotifier<AuthState>    | /auth/login, /register   |
| trainingPlanProvider   | AsyncNotifier<TrainingPlan?>| /training-plans/current  |
| nutritionPlanProvider  | AsyncNotifier<NutritionPlan?>| /nutrition-plans/current|
| progressProvider       | AsyncNotifier<ProgressMetrics?>| /analytics/progress   |

## Authentication Flow

1. App starts → `AuthNotifier` checks secure storage for access token
2. No token → redirect to `/login`
3. User submits credentials → `POST /auth/login` or `/auth/register`
4. On success: tokens stored in `FlutterSecureStorage`, state → `authenticated`, redirect to `/dashboard`
5. On API 401: interceptor attempts token refresh → on failure clears storage → redirect to `/login`
6. Logout: `POST /auth/logout` + clear storage + state → `unauthenticated`

## Code Generation

After `flutter pub get`, run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

This generates `*.freezed.dart` and `*.g.dart` files for all models.
