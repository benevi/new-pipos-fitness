/// Auth State Lifecycle
///
/// ```
/// unknown ──(sin token)──────────────> unauthenticated
/// unknown ──(token + GET /me OK)─────> authenticated
/// unknown ──(token + /me sin red)────> authenticated (isOffline = true)
/// unknown ──(token + refresh inválido)> [reset del scope] → unauthenticated
/// unauthenticated ──(login/register)──> loading ──> authenticated | error
/// authenticated ──(logout | sesión expirada)──> [reset del scope]
/// ```
///
/// - Login/registro/logout usan el Dio público (sin AuthInterceptor): una
///   contraseña incorrecta (401) es [AuthErrorCode.invalidCredentials] y
///   nunca dispara refresh ni cierre de sesión.
/// - Cerrar sesión NO invalida providers a mano: el [AuthSessionCoordinator]
///   pide a `PiposRoot` que recree el `ProviderScope`, lo que descarta todo
///   el estado de la app.
library;

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_failure.dart';
import '../../core/api/auth_interceptor.dart';
import '../../core/auth/auth_session_coordinator.dart';
import '../../core/auth/session_providers.dart';
import '../../core/auth/token_storage.dart';
import '../../core/offline/connectivity.dart';
import '../../core/offline/offline_providers.dart';
import '../../models/user.dart';

enum AuthStatus { unknown, unauthenticated, loading, authenticated, error }

/// Errores de autenticación; la UI los traduce con `AppLocalizations`.
enum AuthErrorCode {
  invalidCredentials,
  emailAlreadyRegistered,
  invalidInput,
  network,
  timeout,
  server,
  sessionExpired,
  unknown,
}

class AuthState {
  final AuthStatus status;
  final AuthUser? user;
  final AuthErrorCode? error;

  /// Autenticado con datos cacheados porque no se pudo validar la sesión
  /// contra el servidor (sin red al arrancar).
  final bool isOffline;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.error,
    this.isOffline = false,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;
  bool get isResolved => status != AuthStatus.unknown;

  /// `error` se limpia salvo que se indique explícitamente.
  AuthState copyWith({
    AuthStatus? status,
    AuthUser? user,
    AuthErrorCode? error,
    bool? isOffline,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error,
      isOffline: isOffline ?? this.isOffline,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier({
    required Dio publicDio,
    required Dio authenticatedDio,
    required TokenStorage storage,
    required AuthSessionCoordinator coordinator,
    SessionEndReason? previousSessionEnd,
    ConnectivitySource? connectivity,
  }) : _publicDio = publicDio,
       _connectivity = connectivity,
       _dio = authenticatedDio,
       _storage = storage,
       _coordinator = coordinator,
       _previousSessionEnd = previousSessionEnd,
       super(const AuthState()) {
    _restoreSession();
  }

  final Dio _publicDio;
  final Dio _dio;
  final TokenStorage _storage;
  final AuthSessionCoordinator _coordinator;
  final SessionEndReason? _previousSessionEnd;
  final ConnectivitySource? _connectivity;
  StreamSubscription<bool>? _reconnectSub;

  AuthState get _signedOut => AuthState(
    status: AuthStatus.unauthenticated,
    error: _previousSessionEnd == SessionEndReason.expired
        ? AuthErrorCode.sessionExpired
        : null,
  );

  Future<void> _restoreSession() async {
    final token = await _storage.readAccessToken();
    if (!mounted) return;
    if (token == null) {
      state = _signedOut;
      return;
    }

    final cachedUser = await _storage.readCachedUser();
    try {
      final response = await _dio.get<dynamic>('/me');
      final user = AuthUser.fromJson(response.data as Map<String, dynamic>);
      await _storage.saveCachedUser(user);
      await _rememberOwner(user.id);
      if (!mounted) return;
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      // Refresh inválido → el coordinador ya está reseteando el scope.
      if (!mounted || _coordinator.hasEnded) return;
      final failure = ApiFailure.from(e);
      if (failure.type == ApiFailureType.unauthorized) {
        await _storage.clear();
        if (!mounted) return;
        state = const AuthState(
          status: AuthStatus.unauthenticated,
          error: AuthErrorCode.sessionExpired,
        );
        return;
      }
      // Sin red / servidor caído / respuesta rara: dejamos entrar con los
      // datos cacheados y marcamos la sesión como no verificada. El usuario
      // completo se guarda también junto a los tokens; si aun así solo hay
      // id (sesiones antiguas), el email queda vacío y Ajustes lo marca como
      // «sin conexión» hasta revalidar (la cola offline solo necesita el
      // id).
      final ownerId = cachedUser == null ? await _storage.readUserId() : null;
      if (!mounted) return;
      state = AuthState(
        status: AuthStatus.authenticated,
        user:
            cachedUser ??
            (ownerId == null ? null : AuthUser(id: ownerId, email: '')),
        isOffline: true,
      );
      _revalidateWhenOnline();
    }
  }

  /// Sesiones guardadas antes de que los tokens llevaran el id del dueño:
  /// se completa en cuanto /me lo confirma.
  Future<void> _rememberOwner(String userId) async {
    if (await _storage.readUserId() != null) return;
    final access = await _storage.readAccessToken();
    final refresh = await _storage.readRefreshToken();
    if (access == null || refresh == null) return;
    await _storage.saveTokens(
      accessToken: access,
      refreshToken: refresh,
      userId: userId,
    );
  }

  /// En modo offline, al recuperar la red se vuelve a validar con /me.
  void _revalidateWhenOnline() {
    final connectivity = _connectivity;
    if (connectivity == null || _reconnectSub != null) return;
    _reconnectSub = connectivity.onlineChanges.where((o) => o).listen((_) {
      _reconnectSub?.cancel();
      _reconnectSub = null;
      if (mounted && state.isOffline) _restoreSession();
    });
  }

  @override
  void dispose() {
    _reconnectSub?.cancel();
    super.dispose();
  }

  Future<void> login(String email, String password) =>
      _authenticate('/auth/login', email, password);

  Future<void> register(String email, String password) =>
      _authenticate('/auth/register', email, password);

  Future<void> _authenticate(String path, String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      final response = await _publicDio.post<dynamic>(
        path,
        data: {'email': email, 'password': password},
        options: Options(extra: AuthExtra.public),
      );
      final auth = AuthResponse.fromJson(response.data as Map<String, dynamic>);
      await _storage.saveTokens(
        accessToken: auth.accessToken,
        refreshToken: auth.refreshToken,
        userId: auth.user.id,
      );
      await _storage.saveCachedUser(auth.user);
      _coordinator.onSessionStarted();
      if (!mounted) return;
      state = AuthState(status: AuthStatus.authenticated, user: auth.user);
    } catch (e) {
      if (!mounted) return;
      state = AuthState(
        status: AuthStatus.error,
        error: _errorCodeFor(e, isRegister: path.endsWith('register')),
      );
    }
  }

  static AuthErrorCode _errorCodeFor(Object error, {required bool isRegister}) {
    final failure = ApiFailure.from(error);
    final status = failure.statusCode;
    if (!isRegister && (status == 401 || status == 403)) {
      return AuthErrorCode.invalidCredentials;
    }
    if (isRegister && status == 409) {
      return AuthErrorCode.emailAlreadyRegistered;
    }
    return switch (failure.type) {
      ApiFailureType.network => AuthErrorCode.network,
      ApiFailureType.timeout => AuthErrorCode.timeout,
      ApiFailureType.server => AuthErrorCode.server,
      ApiFailureType.badRequest => AuthErrorCode.invalidInput,
      ApiFailureType.unauthorized => AuthErrorCode.invalidCredentials,
      ApiFailureType.parse || ApiFailureType.unknown => AuthErrorCode.unknown,
    };
  }

  /// La cuenta se borró en el servidor (`DELETE /me`): sus tokens ya no
  /// sirven. Se borra la sesión local y se resetea el estado sin llamar a
  /// `/auth/logout`.
  Future<void> onAccountDeleted() async {
    await _storage.clear();
    _coordinator.onLoggedOut();
  }

  /// Logout del usuario: revoca el refresh token (best effort, sin esperar a
  /// la red), borra la sesión local y resetea TODO el estado de la app.
  Future<void> logout() async {
    final refreshToken = await _storage.readRefreshToken();
    if (refreshToken != null) {
      unawaited(
        _publicDio
            .post<dynamic>(
              '/auth/logout',
              data: {'refreshToken': refreshToken},
              options: Options(extra: AuthExtra.public),
            )
            .then<void>((_) {}, onError: (Object _) {}),
      );
    }
    await _storage.clear();
    _coordinator.onLoggedOut();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    publicDio: ref.read(publicDioProvider),
    authenticatedDio: ref.read(dioProvider),
    storage: ref.read(tokenStorageProvider),
    coordinator: ref.read(authSessionCoordinatorProvider),
    previousSessionEnd: ref.read(previousSessionEndProvider),
    connectivity: ref.read(connectivitySourceProvider),
  );
});

/// Usuario de la sesión actual (o `null`).
final currentUserProvider = Provider<AuthUser?>(
  (ref) => ref.watch(authProvider.select((s) => s.user)),
);
