import 'package:dio/dio.dart';
import 'api_failure.dart';

/// Maps a [DioException] into a normalized [ApiFailure].
///
/// This is the single mapping point. Providers call this instead of
/// inspecting DioException fields directly.
ApiFailure mapDioException(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return const ApiFailure(
        type: ApiFailureType.timeout,
        message: 'Request timed out. Please try again.',
      );

    case DioExceptionType.connectionError:
      return const ApiFailure(
        type: ApiFailureType.network,
        message: 'No internet connection.',
      );

    case DioExceptionType.badResponse:
      return _mapBadResponse(e);

    case DioExceptionType.cancel:
      return const ApiFailure(
        type: ApiFailureType.unknown,
        message: 'Request was cancelled.',
      );

    case DioExceptionType.badCertificate:
      return const ApiFailure(
        type: ApiFailureType.network,
        message: 'Certificate error.',
      );

    case DioExceptionType.unknown:
      return ApiFailure(
        type: ApiFailureType.network,
        message: e.message ?? 'An unexpected error occurred.',
      );
  }
}

ApiFailure _mapBadResponse(DioException e) {
  final statusCode = e.response?.statusCode ?? 0;
  final data = e.response?.data;

  final serverMessage = (data is Map<String, dynamic> && data.containsKey('message'))
      ? data['message'] as String
      : null;

  if (statusCode == 401) {
    return ApiFailure(
      type: ApiFailureType.unauthorized,
      message: serverMessage ?? 'Session expired. Please log in again.',
      statusCode: statusCode,
    );
  }

  if (statusCode >= 400 && statusCode < 500) {
    return ApiFailure(
      type: ApiFailureType.badRequest,
      message: serverMessage ?? 'Invalid request.',
      statusCode: statusCode,
    );
  }

  if (statusCode >= 500) {
    return ApiFailure(
      type: ApiFailureType.server,
      message: serverMessage ?? 'Server error. Please try again later.',
      statusCode: statusCode,
    );
  }

  return ApiFailure(
    type: ApiFailureType.unknown,
    message: serverMessage ?? 'An unexpected error occurred.',
    statusCode: statusCode,
  );
}
