/// Interceptor Responsibility
///
/// 1. Attach Bearer token to every outgoing request.
/// 2. On 401: attempt ONE token refresh. If multiple requests fail with 401
///    concurrently, only the first triggers a refresh; others wait for the
///    result via a shared Completer.
/// 3. The refresh call itself uses a separate Dio instance to avoid recursion.
/// 4. On refresh success: retry the original request once.
/// 5. On refresh failure: clear tokens and propagate the error.
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../app/constants.dart';
import 'refresh_lock.dart';

class AuthInterceptor extends Interceptor {
  final Dio dio;
  final FlutterSecureStorage storage;
  final RefreshLock _refreshLock;

  AuthInterceptor({
    required this.dio,
    required this.storage,
    RefreshLock? refreshLock,
  }) : _refreshLock = refreshLock ?? RefreshLock();

  /// Called by auth provider when refresh fails and UI must react.
  void Function()? onForceLogout;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await storage.read(key: AppConstants.accessTokenKey);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    // Prevent the refresh endpoint itself from triggering recursive refresh
    if (err.requestOptions.path == '/auth/refresh') {
      return handler.next(err);
    }

    try {
      final newAccessToken = await _refreshLock.execute(() => _doRefresh());
      if (newAccessToken == null) {
        return handler.next(err);
      }

      final retryOptions = err.requestOptions;
      retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';
      final retryResponse = await dio.fetch(retryOptions);
      return handler.resolve(retryResponse);
    } catch (_) {
      return handler.next(err);
    }
  }

  /// Performs the actual refresh network call. Only called by the lock winner.
  Future<String?> _doRefresh() async {
    final refreshToken =
        await storage.read(key: AppConstants.refreshTokenKey);
    if (refreshToken == null) {
      await _clearTokens();
      onForceLogout?.call();
      return null;
    }

    try {
      final freshDio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl));
      final response = await freshDio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      final newAccess = response.data['accessToken'] as String;
      final newRefresh = response.data['refreshToken'] as String;
      await storage.write(key: AppConstants.accessTokenKey, value: newAccess);
      await storage.write(
        key: AppConstants.refreshTokenKey,
        value: newRefresh,
      );
      return newAccess;
    } catch (_) {
      await _clearTokens();
      onForceLogout?.call();
      return null;
    }
  }

  Future<void> _clearTokens() async {
    await storage.delete(key: AppConstants.accessTokenKey);
    await storage.delete(key: AppConstants.refreshTokenKey);
  }
}
