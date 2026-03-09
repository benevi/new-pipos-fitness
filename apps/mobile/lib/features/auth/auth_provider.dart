/// Auth State Lifecycle
///
/// ```
/// unknown ──(check storage)──> authenticated | unauthenticated
/// unauthenticated ──(login/register)──> loading ──> authenticated | error
/// error ──(retry login/register)──> loading ──> authenticated | error
/// authenticated ──(logout)──> unauthenticated
/// authenticated ──(token refresh fail)──> unauthenticated (via coordinator)
/// ```
///
/// Session coordination:
/// - On login/register success: coordinator.onSessionStarted()
/// - On logout: coordinator.onSessionExpired() invalidates protected providers
/// - On forced logout (interceptor refresh failure): coordinator calls
///   forceUnauthenticated() on this notifier AND invalidates providers
///
/// The coordinator prevents duplicate logout execution via a re-entry guard.
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../app/constants.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_failure.dart';
import '../../core/api/dio_error_mapper.dart';
import '../../core/auth/auth_session_coordinator.dart';
import '../../models/user.dart';
import '../dashboard/progress_provider.dart';
import '../nutrition/nutrition_plan_provider.dart';
import '../workouts/training_plan_provider.dart';

enum AuthStatus { unknown, unauthenticated, loading, authenticated, error }

class AuthState {
  final AuthStatus status;
  final AuthUser? user;
  final String? error;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.error,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;
  bool get isResolved => status != AuthStatus.unknown;

  AuthState copyWith({AuthStatus? status, AuthUser? user, String? error}) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Dio _dio;
  final FlutterSecureStorage _storage;
  final Ref _ref;

  AuthNotifier(this._dio, this._storage, this._ref) : super(const AuthState()) {
    // Register with coordinator so forced logout can update this notifier
    authSessionCoordinator.setForceLogoutHandler(_onForceLogout);
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final token = await _storage.read(key: AppConstants.accessTokenKey);
    state = token != null
        ? state.copyWith(status: AuthStatus.authenticated)
        : state.copyWith(status: AuthStatus.unauthenticated);
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      final authResponse = AuthResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
      await _persistTokens(authResponse);
      authSessionCoordinator.onSessionStarted();
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: authResponse.user,
      );
    } on DioException catch (e) {
      final failure = mapDioException(e);
      state = state.copyWith(status: AuthStatus.error, error: failure.message);
    }
  }

  Future<void> register(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      final response = await _dio.post('/auth/register', data: {
        'email': email,
        'password': password,
      });
      final authResponse = AuthResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
      await _persistTokens(authResponse);
      authSessionCoordinator.onSessionStarted();
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: authResponse.user,
      );
    } on DioException catch (e) {
      final failure = mapDioException(e);
      state = state.copyWith(status: AuthStatus.error, error: failure.message);
    }
  }

  /// User-initiated logout. Clears tokens, invalidates providers, sets state.
  Future<void> logout() async {
    final refreshToken = await _storage.read(key: AppConstants.refreshTokenKey);
    if (refreshToken != null) {
      try {
        await _dio.post('/auth/logout', data: {'refreshToken': refreshToken});
      } catch (_) {}
    }
    await _clearTokens();
    _invalidateProtectedProviders();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Called by the coordinator when the interceptor detects an expired session.
  void _onForceLogout() {
    _invalidateProtectedProviders();
    state = const AuthState(
      status: AuthStatus.unauthenticated,
      error: 'Your session has expired. Please log in again.',
    );
  }

  void _invalidateProtectedProviders() {
    _ref.invalidate(progressProvider);
    _ref.invalidate(trainingPlanProvider);
    _ref.invalidate(nutritionPlanProvider);
  }

  Future<void> _persistTokens(AuthResponse auth) async {
    await _storage.write(
      key: AppConstants.accessTokenKey,
      value: auth.accessToken,
    );
    await _storage.write(
      key: AppConstants.refreshTokenKey,
      value: auth.refreshToken,
    );
  }

  Future<void> _clearTokens() async {
    await _storage.delete(key: AppConstants.accessTokenKey);
    await _storage.delete(key: AppConstants.refreshTokenKey);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final dio = ref.read(dioProvider);
  final storage = ref.read(secureStorageProvider);
  return AuthNotifier(dio, storage, ref);
});
