/// Routing Responsibility
///
/// GoRouter es la única fuente de verdad de la navegación y se crea UNA sola
/// vez por `ProviderScope` (por sesión): los cambios de auth o de la puerta
/// de onboarding no lo recrean, sino que notifican a [RouterRefresh]
/// (`refreshListenable`) y GoRouter vuelve a evaluar [appRedirect]:
/// - auth `unknown`: /splash mientras se valida la sesión.
/// - no autenticado: /login (o /register).
/// - autenticado y comprobando si hay plan: /splash.
/// - autenticado sin plan: /onboarding (cuestionario, CUJ-1).
/// - autenticado con plan: fuera de auth/splash/onboarding → /today.
///
/// Mapa (docs/UX_MOVIL.md):
/// ```
/// StatefulShellRoute (barra inferior; cada pestaña conserva su pila)
/// ├── /today ─────────────── Hoy
/// ├── /plan ──────────────── Plan
/// │   ├── history ─ :id ──── Historial → versión
/// │   └── exercises ─ :muscle  Ejercicios por músculo → lista del músculo
/// ├── /progress ──────────── Progreso
/// └── /settings ──────────── Ajustes
///     └── profile ────────── Editar perfil
/// /onboarding, /workout-complete: pantalla completa, sin barra.
/// /exercise/:id: ficha del ejercicio (id o slug), pantalla completa; se abre
/// desde Hoy, Plan, el cambio de ejercicio y el onboarding (CUJ-11).
/// ```
///
/// Al cerrar sesión no hace falta navegar: `PiposRoot` recrea el scope y con
/// él un router nuevo que arranca en /splash.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/offline/offline_providers.dart';
import '../features/auth/auth_provider.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/exercise/exercise_detail_screen.dart';
import '../features/exercises/exercises_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/onboarding/profile_draft.dart' show ProfilePick;
import '../features/plan/plan_screen.dart';
import '../features/progress/progress_screen.dart';
import '../features/settings/schedule_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/setup/setup_provider.dart';
import '../features/today/today_providers.dart';
import '../features/today/today_screen.dart';
import '../features/today/workout_complete_screen.dart';
import '../l10n/app_localizations.dart';
import 'splash_screen.dart';
import 'tokens.dart';

class AppRoutes {
  AppRoutes._();

  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const onboarding = '/onboarding';
  static const home = '/today';
  static const plan = '/plan';
  static const progress = '/progress';
  static const settings = '/settings';
  static const workoutComplete = '/workout-complete';
  static const exercise = '/exercise';
}

/// Redirección por estado de auth (compatibilidad con tests de 4a).
String? authRedirect(AuthState auth, String location) =>
    appRedirect(auth, SetupStatus.ready, location);

/// Decide la redirección a partir de auth y de la puerta de onboarding.
/// Función pura (testable).
String? appRedirect(AuthState auth, SetupStatus setup, String location) {
  final isAuthRoute =
      location == AppRoutes.login || location == AppRoutes.register;
  final isSplash = location == AppRoutes.splash;
  final isOnboarding = location == AppRoutes.onboarding;
  // La ficha se puede abrir también durante el onboarding (favoritos/vetados).
  final isExercise = location.startsWith('${AppRoutes.exercise}/');

  if (!auth.isResolved) return isSplash ? null : AppRoutes.splash;
  if (!auth.isAuthenticated) return isAuthRoute ? null : AppRoutes.login;

  switch (setup) {
    case SetupStatus.checking:
      return isSplash ? null : AppRoutes.splash;
    case SetupStatus.needsOnboarding:
      return (isOnboarding || isExercise) ? null : AppRoutes.onboarding;
    case SetupStatus.ready:
      return (isAuthRoute || isSplash) ? AppRoutes.home : null;
  }
}

/// Puente entre Riverpod y `GoRouter.refreshListenable`. Solo notifica
/// cuando cambia algo relevante para la navegación.
class RouterRefresh extends ChangeNotifier {
  RouterRefresh(this._auth, this._setup);

  AuthState _auth;
  SetupStatus _setup;
  AuthState get auth => _auth;
  SetupStatus get setup => _setup;

  set auth(AuthState next) {
    final changed =
        next.isResolved != _auth.isResolved ||
        next.isAuthenticated != _auth.isAuthenticated;
    _auth = next;
    if (changed) notifyListeners();
  }

  set setup(SetupStatus next) {
    if (next == _setup) return;
    _setup = next;
    notifyListeners();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = RouterRefresh(
    ref.read(authProvider),
    ref.read(setupStatusProvider),
  );
  ref.listen<AuthState>(authProvider, (_, next) => refresh.auth = next);
  ref.listen<SetupStatus>(
    setupStatusProvider,
    (_, next) => refresh.setup = next,
  );

  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) =>
        appRedirect(refresh.auth, refresh.setup, state.matchedLocation),
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.exercise}/:id',
        builder: (_, state) =>
            ExerciseDetailScreen(idOrSlug: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: AppRoutes.workoutComplete,
        builder: (_, state) =>
            WorkoutCompleteScreen(summary: state.extra as WorkoutSummary?),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => ScaffoldWithNav(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (_, __) => const TodayScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.plan,
                builder: (_, __) => const PlanScreen(),
                routes: [
                  GoRoute(
                    path: 'exercises',
                    builder: (_, __) => const ExercisesScreen(),
                    routes: [
                      GoRoute(
                        path: ':muscle',
                        redirect: (_, state) =>
                            MuscleExercisesScreen.parse(
                                  state.pathParameters['muscle'],
                                ) ==
                                null
                            ? exercisesLocation
                            : null,
                        builder: (_, state) => MuscleExercisesScreen(
                          muscle: MuscleExercisesScreen.parse(
                            state.pathParameters['muscle'],
                          )!,
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'history',
                    builder: (_, __) => const PlanHistoryScreen(),
                    routes: [
                      GoRoute(
                        path: ':id',
                        builder: (_, state) => PlanVersionScreen(
                          versionId: state.pathParameters['id'] ?? '',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.progress,
                builder: (_, __) => const ProgressScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                builder: (_, __) => const SettingsScreen(),
                routes: [
                  GoRoute(
                    path: 'profile',
                    builder: (_, state) => ProfileEditScreen(
                      pick: state.extra is ProfilePick
                          ? state.extra! as ProfilePick
                          : null,
                    ),
                  ),
                  GoRoute(
                    path: 'schedule',
                    builder: (_, __) => const ScheduleScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});

class ScaffoldWithNav extends ConsumerWidget {
  const ScaffoldWithNav({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isOffline = ref.watch(authProvider.select((s) => s.isOffline));
    final sync = ref.watch(syncSummaryProvider).valueOrNull;
    final showBar = isOffline || (sync != null && !sync.isClean);
    return Scaffold(
      body: ReminderRefresher(child: shell),

      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showBar)
            SyncStatusBar(
              offline: isOffline,
              pending: sync?.pending ?? 0,
              failed: sync?.failed ?? 0,
              pendingChanges: sync?.pendingChanges ?? 0,
              failedChanges: sync?.failedChanges ?? 0,
              onRetry: () => ref.read(syncServiceProvider).retryFailed(),
            ),
          NavigationBar(
            selectedIndex: shell.currentIndex,
            onDestinationSelected: (i) {
              if (i == 0) ref.invalidate(todaySessionProvider);
              shell.goBranch(i, initialLocation: i == shell.currentIndex);
            },
            destinations: [
              NavigationDestination(
                key: const Key('nav-today'),
                icon: const Icon(Icons.today_outlined),
                selectedIcon: const Icon(Icons.today),
                label: l10n.navToday,
              ),
              NavigationDestination(
                key: const Key('nav-plan'),
                icon: const Icon(Icons.event_note_outlined),
                selectedIcon: const Icon(Icons.event_note),
                label: l10n.navPlan,
              ),
              NavigationDestination(
                key: const Key('nav-progress'),
                icon: const Icon(Icons.insights_outlined),
                selectedIcon: const Icon(Icons.insights),
                label: l10n.navProgress,
              ),
              NavigationDestination(
                key: const Key('nav-settings'),
                icon: const Icon(Icons.settings_outlined),
                selectedIcon: const Icon(Icons.settings),
                label: l10n.navSettings,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Estado de la cola offline: pendientes, fallidas (con reintento) o sin red.
class SyncStatusBar extends StatelessWidget {
  const SyncStatusBar({
    super.key,
    required this.offline,
    required this.pending,
    required this.failed,
    required this.onRetry,
    this.pendingChanges = 0,
    this.failedChanges = 0,
  });

  final bool offline;
  final int pending;
  final int failed;

  /// Otras escrituras offline (notas, medidas).
  final int pendingChanges;
  final int failedChanges;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final anyFailed = failed > 0 || failedChanges > 0;
    final message = failed > 0
        ? l10n.failedSyncCount(failed)
        : failedChanges > 0
        ? l10n.failedChangesCount(failedChanges)
        : pending > 0
        ? l10n.pendingSyncCount(pending)
        : pendingChanges > 0
        ? l10n.pendingChangesCount(pendingChanges)
        : l10n.offlineBanner;
    return Semantics(
      liveRegion: true,
      child: Container(
        key: const Key('sync-status-bar'),
        width: double.infinity,
        color: theme.colorScheme.surfaceContainerHighest,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            Icon(
              anyFailed
                  ? Icons.error_outline
                  : offline
                  ? Icons.cloud_off_outlined
                  : Icons.cloud_upload_outlined,
              color: anyFailed
                  ? theme.colorScheme.error
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(message, style: theme.textTheme.bodyMedium)),
            if (anyFailed)
              TextButton(
                key: const Key('sync-retry'),
                onPressed: onRetry,
                child: Text(l10n.syncRetry),
              ),
          ],
        ),
      ),
    );
  }
}
