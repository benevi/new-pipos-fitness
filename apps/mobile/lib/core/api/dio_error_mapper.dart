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

  final serverMessage = _extractServerMessage(data);
  final code = data is Map && data['code'] is String
      ? data['code'] as String
      : null;
  final issues = _extractIssues(data);

  final ApiFailureType type;
  final String fallback;
  if (statusCode == 401) {
    type = ApiFailureType.unauthorized;
    fallback = 'Session expired. Please log in again.';
  } else if (statusCode >= 400 && statusCode < 500) {
    type = ApiFailureType.badRequest;
    fallback = 'Invalid request.';
  } else if (statusCode >= 500) {
    type = ApiFailureType.server;
    fallback = 'Server error. Please try again later.';
  } else {
    type = ApiFailureType.unknown;
    fallback = 'An unexpected error occurred.';
  }

  return ApiFailure(
    type: type,
    message: serverMessage ?? fallback,
    statusCode: statusCode,
    code: code,
    issues: issues,
  );
}

List<FieldIssue> _extractIssues(Object? data) {
  if (data is! Map) return const [];
  final raw = data['issues'];
  if (raw is! List) return const [];
  return [
    for (final i in raw)
      if (i is Map && i['path'] is String)
        FieldIssue(
          path: i['path'] as String,
          message: i['message'] is String ? i['message'] as String : '',
        ),
  ];
}

/// `message` puede venir como String o como lista (errores de validación).
String? _extractServerMessage(Object? data) {
  if (data is! Map) return null;
  final raw = data['message'];
  if (raw is String) return raw;
  if (raw is List) return raw.whereType<String>().join('\n');
  return null;
}
