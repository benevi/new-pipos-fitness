/// Interceptor Responsibility
///
/// 1. Adjunta el Bearer token a cada petición, salvo las marcadas con
///    `extra: {'skipAuth': true}` (login/registro/refresh/logout también van
///    por un Dio público sin este interceptor; el flag es una segunda red).
/// 2. Ante un 401:
///    a. `skipAuth` → se propaga tal cual (p. ej. contraseña incorrecta).
///    b. Petición ya reintentada (`extra['retried'] == true`) → la sesión no
///       es válida: se notifica [AuthSessionCoordinator.onSessionExpired] y se
///       propaga el error. Cada petición se reintenta como mucho UNA vez.
///    c. El token con el que se envió difiere del token guardado ahora
///       (otro request ya refrescó) → se reintenta con el token actual sin
///       volver a refrescar.
///    d. En otro caso se refresca vía [RefreshLock] (los 401 concurrentes
///       comparten el mismo refresh) y se reintenta una vez.
/// 3. Refresh rechazado por el servidor (400/401/403) → se borran tokens y se
///    notifica sesión expirada. Excepción: `401 AUTH_REFRESH_RACE` (otro
///    refresh concurrente ganó) NO cierra sesión: se reintenta con el token
///    guardado si cambió; si no, se propaga el error original. Un fallo de red durante el refresh NO cierra
///    la sesión (modo offline): se propaga el error original.
library;

import 'package:dio/dio.dart';

import '../auth/auth_session_coordinator.dart';
import '../auth/token_storage.dart';
import 'api_failure.dart';
import 'refresh_lock.dart';

/// Claves de `RequestOptions.extra` que entiende el interceptor.
class AuthExtra {
  AuthExtra._();

  static const String skipAuth = 'skipAuth';
  static const String retried = 'retried';

  static const Map<String, dynamic> public = {skipAuth: true};
}

/// El servidor rechazó el refresh token: la sesión no se puede recuperar.
class RefreshRejectedException implements Exception {
  const RefreshRejectedException();
}

/// El servidor respondió `401 AUTH_REFRESH_RACE`: otro refresh concurrente
/// rotó el token. NO es motivo para cerrar sesión: se reintenta con el token
/// guardado si cambió, y si no, se propaga el error original.
class RefreshRaceException implements Exception {
  const RefreshRaceException();
}

/// Obtiene un access token nuevo a partir del refresh token.
abstract class TokenRefresher {
  /// Devuelve el nuevo access token (y lo persiste), lanza
  /// [RefreshRejectedException] si el servidor rechaza el refresh, o
  /// cualquier otro error si fue un fallo transitorio (red, timeout, 5xx).
  Future<String> refresh();
}

class DioTokenRefresher implements TokenRefresher {
  DioTokenRefresher({required Dio publicDio, required TokenStorage storage})
    : _dio = publicDio,
      _storage = storage;

  final Dio _dio;
  final TokenStorage _storage;

  @override
  Future<String> refresh() async {
    final refreshToken = await _storage.readRefreshToken();
    if (refreshToken == null) throw const RefreshRejectedException();

    final Response<dynamic> response;
    try {
      response = await _dio.post<dynamic>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
        options: Options(extra: AuthExtra.public),
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final body = e.response?.data;
      if (status == 401 &&
          body is Map &&
          body['code'] == ApiErrorCode.authRefreshRace) {
        // Otro refresh concurrente con el mismo token ganó: la sesión sigue
        // siendo válida y el token nuevo lo guardó quien ganó.
        throw const RefreshRaceException();
      }
      if (status == 400 || status == 401 || status == 403) {
        throw const RefreshRejectedException();
      }
      rethrow;
    }

    final data = response.data;
    if (data is! Map ||
        data['accessToken'] is! String ||
        data['refreshToken'] is! String) {
      throw const RefreshRejectedException();
    }
    final access = data['accessToken'] as String;
    await _storage.saveTokens(
      accessToken: access,
      refreshToken: data['refreshToken'] as String,
    );
    return access;
  }
}

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required Dio dio,
    required TokenStorage storage,
    required TokenRefresher refresher,
    required AuthSessionCoordinator coordinator,
    RefreshLock? refreshLock,
  }) : _dio = dio,
       _storage = storage,
       _refresher = refresher,
       _coordinator = coordinator,
       _refreshLock = refreshLock ?? RefreshLock();

  final Dio _dio;
  final TokenStorage _storage;
  final TokenRefresher _refresher;
  final AuthSessionCoordinator _coordinator;
  final RefreshLock _refreshLock;

  static bool _isSkipAuth(RequestOptions o) =>
      o.extra[AuthExtra.skipAuth] == true;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isSkipAuth(options)) {
      final token = await _storage.readAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      } else {
        options.headers.remove('Authorization');
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    if (err.response?.statusCode != 401 || _isSkipAuth(options)) {
      return handler.next(err);
    }

    if (options.extra[AuthExtra.retried] == true) {
      // Ya se reintentó con un token fresco y sigue siendo 401.
      await _expireSession();
      return handler.next(err);
    }

    final sentToken = _bearer(options.headers['Authorization']);
    final currentToken = await _storage.readAccessToken();

    String? tokenForRetry;
    if (currentToken != null && currentToken != sentToken) {
      // Otro request ya refrescó mientras este estaba en vuelo.
      tokenForRetry = currentToken;
    } else {
      try {
        tokenForRetry = await _refreshLock.execute(_refresher.refresh);
      } on RefreshRejectedException {
        await _expireSession();
        return handler.next(err);
      } on RefreshRaceException {
        final stored = await _storage.readAccessToken();
        if (stored == null || stored == sentToken) return handler.next(err);
        tokenForRetry = stored;
      } catch (_) {
        // Fallo transitorio (red/timeout/5xx): no cerramos la sesión.
        return handler.next(err);
      }
    }

    if (tokenForRetry == null) return handler.next(err);

    try {
      final retryOptions = options.copyWith(
        extra: {...options.extra, AuthExtra.retried: true},
        headers: {...options.headers, 'Authorization': 'Bearer $tokenForRetry'},
      );
      final response = await _dio.fetch<dynamic>(retryOptions);
      return handler.resolve(response);
    } on DioException catch (retryError) {
      return handler.next(retryError);
    }
  }

  Future<void> _expireSession() async {
    await _storage.clear();
    _coordinator.onSessionExpired();
  }

  static String? _bearer(Object? header) {
    if (header is! String) return null;
    const prefix = 'Bearer ';
    return header.startsWith(prefix) ? header.substring(prefix.length) : null;
  }
}
