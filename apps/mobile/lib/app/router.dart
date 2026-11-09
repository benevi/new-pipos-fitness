/// Routing Responsibility
///
/// GoRouter es la única fuente de verdad de la navegación y se crea UNA sola
/// vez por `ProviderScope` (por sesión): los cambios de auth no lo recrean,
/// sino que notifican a [AuthRouterListenable] (`refreshListenable`) y
/// GoRouter vuelve a evaluar [authRedirect]:
/// - `unknown`: /splash mientras se valida la sesión.
/// - no autenticado: /login (o /register).
/// - autenticado: fuera de las rutas de auth → /dashboard.
///
/// Al cerrar sesión no hace falta navegar: `PiposRoot` recrea el scope y con
/// él un router nuevo que arranca en /splash.
///
/// Protected routes live inside a ShellRoute that provides bottom navigation.
/// Full-screen flows (workout player, workout complete) are top-level routes
/// outside the ShellRoute so they don't show the bottom nav bar.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/auth_provider.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/workouts/workouts_screen.dart';
import '../features/workouts/workout_player_screen.dart';
import '../features/workouts/workout_complete_screen.dart';
import '../features/nutrition/nutrition_screen.dart';
import '../features/ai_coach/ai_coach_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/exercises/exercises_screen.dart';
import '../features/exercises/exercise_detail_screen.dart';
import '../core/offline/offline_providers.dart';
import '../l10n/app_localizations.dart';
import 'splash_screen.dart';
import 'tokens.dart';

class AppRoutes {
  AppRoutes._();

  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const home = '/dashboard';
}

/// Decide la redirección a partir del estado de auth. Función pura (testable).
String? authRedirect(AuthState auth, String location) {
  final isAuthRoute =
      location == AppRoutes.login || location == AppRoutes.register;
  final isSplash = location == AppRoutes.splash;

  if (!auth.isResolved) return isSplash ? null : AppRoutes.splash;
  if (auth.isAuthenticated) {
    return (isAuthRoute || isSplash) ? AppRoutes.home : null;
  }
  return isAuthRoute ? null : AppRoutes.login;
}

/// Puente entre el estado de Riverpod y `GoRouter.refreshListenable`.
///
/// Solo notifica cuando cambia algo relevante para la navegación
/// (resuelto / autenticado), no en cada `loading` del formulario.
class AuthRouterListenable extends ChangeNotifier {
  AuthRouterListenable(this._state);

  AuthState _state;
  AuthState get state => _state;

  set state(AuthState next) {
    final changed =
        next.isResolved != _state.isResolved ||
        next.isAuthenticated != _state.isAuthenticated;
    _state = next;
    if (changed) notifyListeners();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final listenable = AuthRouterListenable(ref.read(authProvider));
  ref.listen<AuthState>(authProvider, (_, next) => listenable.state = next);

  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: listenable,
    redirect: (context, state) =>
        authRedirect(listenable.state, state.matchedLocation),
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      // Full-screen workout flows (no bottom nav)
      GoRoute(
        path: '/workout-player',
        builder: (_, __) => const WorkoutPlayerScreen(),
      ),
      GoRoute(
        path: '/workout-complete',
        builder: (_, __) => const WorkoutCompleteScreen(),
      ),
      ShellRoute(
        builder: (_, __, child) => _ScaffoldWithNav(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: DashboardScreen()),
          ),
          GoRoute(
            path: '/workouts',
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: WorkoutsScreen()),
          ),
          GoRoute(
            path: '/nutrition',
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: NutritionScreen()),
          ),
          GoRoute(
            path: '/ai-coach',
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: AiCoachScreen()),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: ProfileScreen()),
          ),
          GoRoute(
            path: '/exercises',
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: ExercisesScreen()),
          ),
          GoRoute(
            path: '/exercises/:id',
            builder: (_, state) {
              final id = state.pathParameters['id'] ?? '';
              return ExerciseDetailScreen(exerciseId: id);
            },
          ),
        ],
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    listenable.dispose();
  });
  return router;
});

class _ScaffoldWithNav extends ConsumerWidget {
  final Widget child;
  const _ScaffoldWithNav({required this.child});

  static const _tabs = [
    '/dashboard',
    '/workouts',
    '/nutrition',
    '/ai-coach',
    '/profile',
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final idx = _tabs.indexOf(location);
    return idx >= 0 ? idx : 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isOffline = ref.watch(authProvider.select((s) => s.isOffline));
    final pending = ref.watch(pendingSetLogsProvider).valueOrNull?.length ?? 0;
    return Scaffold(
      body: child,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isOffline || pending > 0)
            _SyncStatusBar(
              message: pending > 0
                  ? l10n.pendingSyncCount(pending)
                  : l10n.offlineBanner,
              offline: isOffline,
            ),
          _buildNavigationBar(context, l10n),
        ],
      ),
    );
  }

  Widget _buildNavigationBar(BuildContext context, AppLocalizations l10n) {
    return NavigationBar(
      selectedIndex: _currentIndex(context),
      onDestinationSelected: (i) => context.go(_tabs[i]),
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home),
          label: l10n.navHome,
        ),
        NavigationDestination(
          icon: const Icon(Icons.fitness_center_outlined),
          selectedIcon: const Icon(Icons.fitness_center),
          label: l10n.navWorkouts,
        ),
        NavigationDestination(
          icon: const Icon(Icons.restaurant_outlined),
          selectedIcon: const Icon(Icons.restaurant),
          label: l10n.navNutrition,
        ),
        NavigationDestination(
          icon: const Icon(Icons.smart_toy_outlined),
          selectedIcon: const Icon(Icons.smart_toy),
          label: l10n.navCoach,
        ),
        NavigationDestination(
          icon: const Icon(Icons.person_outline),
          selectedIcon: const Icon(Icons.person),
          label: l10n.navProfile,
        ),
      ],
    );
  }
}

class _SyncStatusBar extends StatelessWidget {
  const _SyncStatusBar({required this.message, required this.offline});

  final String message;
  final bool offline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        color: theme.colorScheme.surfaceContainerHighest,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(
              offline ? Icons.cloud_off_outlined : Icons.cloud_upload_outlined,
              size: AppSpacing.md,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(message, style: theme.textTheme.bodySmall)),
          ],
        ),
      ),
    );
  }
}
