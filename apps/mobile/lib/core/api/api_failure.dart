/// Unified failure model for the API layer.
///
/// All Dio/network/backend errors are mapped to an [ApiFailure] before
/// reaching providers or UI. Raw DioExceptions never leak beyond the API layer.
class ApiFailure {
  final ApiFailureType type;
  final String message;
  final int? statusCode;

  const ApiFailure({
    required this.type,
    required this.message,
    this.statusCode,
  });

  @override
  String toString() => 'ApiFailure($type, $statusCode, $message)';
}

enum ApiFailureType {
  /// Network unreachable / DNS failure / socket error.
  network,

  /// Request or response timed out.
  timeout,

  /// Server returned 401 and refresh failed.
  unauthorized,

  /// Server returned 4xx (not 401).
  badRequest,

  /// Server returned 5xx.
  server,

  /// Response could not be parsed.
  parse,

  /// Catch-all for unexpected errors.
  unknown,
}
