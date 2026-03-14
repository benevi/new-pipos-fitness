/// Routing Responsibility
///
/// GoRouter is the single source of navigation truth. It watches [authProvider]
/// and redirects based on [AuthStatus]:
/// - `unknown`: stay on current route (app is checking storage)
/// - `unauthenticated` / `error`: redirect to /login
/// - `loading`: no redirect (screens show inline spinners)
/// - `authenticated`: redirect away from auth routes to /dashboard
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

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    redirect: (context, state) {
      if (!authState.isResolved) return null;

      final isAuth = authState.isAuthenticated;
      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!isAuth && !isAuthRoute) return '/login';
      if (isAuth && isAuthRoute) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegisterScreen(),
      ),
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
        navigatorKey: _shellNavigatorKey,
        builder: (_, __, child) => _ScaffoldWithNav(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (_, __) => const NoTransitionPage(
              child: DashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/workouts',
            pageBuilder: (_, __) => const NoTransitionPage(
              child: WorkoutsScreen(),
            ),
          ),
          GoRoute(
            path: '/nutrition',
            pageBuilder: (_, __) => const NoTransitionPage(
              child: NutritionScreen(),
            ),
          ),
          GoRoute(
            path: '/ai-coach',
            pageBuilder: (_, __) => const NoTransitionPage(
              child: AiCoachScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (_, __) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
        ],
      ),
    ],
  );
});

class _ScaffoldWithNav extends StatelessWidget {
  final Widget child;
  const _ScaffoldWithNav({required this.child});

  static const _tabs = ['/dashboard', '/workouts', '/nutrition', '/ai-coach', '/profile'];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final idx = _tabs.indexOf(location);
    return idx >= 0 ? idx : 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex(context),
        onDestinationSelected: (i) => context.go(_tabs[i]),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.fitness_center_outlined), selectedIcon: Icon(Icons.fitness_center), label: 'Workouts'),
          NavigationDestination(icon: Icon(Icons.restaurant_outlined), selectedIcon: Icon(Icons.restaurant), label: 'Nutrition'),
          NavigationDestination(icon: Icon(Icons.smart_toy_outlined), selectedIcon: Icon(Icons.smart_toy), label: 'AI Coach'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
