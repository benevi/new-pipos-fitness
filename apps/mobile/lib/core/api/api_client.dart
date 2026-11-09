/// API Client Responsibility
///
/// - [publicDioProvider]: Dio SIN [AuthInterceptor]. Lo usan login, registro,
///   refresh y logout: un 401 ahí (p. ej. contraseña incorrecta) es un error
///   de formulario, nunca un motivo para refrescar o cerrar sesión.
/// - [dioProvider]: Dio autenticado con [AuthInterceptor].
/// - Ambos comparten base URL, timeouts ([ApiTimeouts]) y, en tests, el
///   adaptador HTTP ([httpClientAdapterProvider]).
/// - [ApiClient] es un wrapper fino; NO captura errores. Los providers
///   capturan y convierten con `ApiFailure.from`.
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/constants.dart';
import '../auth/session_providers.dart';
import 'auth_interceptor.dart';

/// Base URL de la API. `PiposRoot` lo sobreescribe con `AppConfig`.
final apiBaseUrlProvider = Provider<String>(
  (_) => throw StateError(
    'API_BASE_URL no configurada. Sobrescribe apiBaseUrlProvider '
    '(PiposRoot lo hace a partir de --dart-define=API_BASE_URL=...).',
  ),
);

/// Adaptador HTTP opcional (solo tests). `null` = adaptador por defecto.
final httpClientAdapterProvider = Provider<HttpClientAdapter?>((_) => null);

Dio _buildDio(Ref ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ref.watch(apiBaseUrlProvider),
      connectTimeout: ApiTimeouts.connect,
      receiveTimeout: ApiTimeouts.receive,
      sendTimeout: ApiTimeouts.send,
      headers: {'Content-Type': 'application/json'},
    ),
  );
  final adapter = ref.watch(httpClientAdapterProvider);
  if (adapter != null) dio.httpClientAdapter = adapter;
  return dio;
}

final publicDioProvider = Provider<Dio>((ref) {
  final dio = _buildDio(ref);
  ref.onDispose(dio.close);
  return dio;
});

final tokenRefresherProvider = Provider<TokenRefresher>(
  (ref) => DioTokenRefresher(
    publicDio: ref.watch(publicDioProvider),
    storage: ref.watch(tokenStorageProvider),
  ),
);

final dioProvider = Provider<Dio>((ref) {
  final dio = _buildDio(ref);
  dio.interceptors.add(
    AuthInterceptor(
      dio: dio,
      storage: ref.watch(tokenStorageProvider),
      refresher: ref.watch(tokenRefresherProvider),
      coordinator: ref.watch(authSessionCoordinatorProvider),
    ),
  );
  ref.onDispose(dio.close);
  return dio;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.watch(dioProvider));
});

class ApiClient {
  final Dio _dio;

  ApiClient(this._dio);

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.get<T>(path, queryParameters: queryParameters);
  }

  Future<Response<T>> post<T>(String path, {Object? data}) {
    return _dio.post<T>(path, data: data);
  }

  Future<Response<T>> put<T>(String path, {Object? data}) {
    return _dio.put<T>(path, data: data);
  }

  Future<Response<T>> delete<T>(String path) {
    return _dio.delete<T>(path);
  }
}
