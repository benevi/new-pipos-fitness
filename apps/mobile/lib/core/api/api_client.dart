/// API Client Responsibility
///
/// - Single Dio instance shared across the app via [dioProvider].
/// - [AuthInterceptor] handles token attachment and refresh.
///   On refresh failure, it delegates to [AuthSessionCoordinator].
/// - [ApiClient] is a thin typed wrapper; it does NOT catch errors.
///   Providers catch DioExceptions and map them via [mapDioException].
library;
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../app/constants.dart';
import '../auth/auth_session_coordinator.dart';
import 'auth_interceptor.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (_) => const FlutterSecureStorage(),
);

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: AppConstants.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Content-Type': 'application/json'},
  ));

  final storage = ref.read(secureStorageProvider);
  final interceptor = AuthInterceptor(
    dio: dio,
    storage: storage,
    coordinator: authSessionCoordinator,
  );
  dio.interceptors.add(interceptor);

  return dio;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.read(dioProvider));
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
