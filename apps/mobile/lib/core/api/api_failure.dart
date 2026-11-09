import 'package:dio/dio.dart';
import 'package:json_annotation/json_annotation.dart';

import 'dio_error_mapper.dart';

/// Unified failure model for the API layer.
///
/// All Dio/network/backend errors are mapped to an [ApiFailure] before
/// reaching providers or UI. Raw DioExceptions never leak beyond the API layer.
///
/// Los `message` son textos técnicos de respaldo; la UI migrada a i18n
/// traduce por [type]/[statusCode] (ver `l10n/failure_messages.dart`).
class ApiFailure {
  final ApiFailureType type;
  final String message;
  final int? statusCode;

  const ApiFailure({
    required this.type,
    required this.message,
    this.statusCode,
  });

  /// Convierte cualquier error capturado en un [ApiFailure].
  ///
  /// - [DioException] → [mapDioException].
  /// - Errores de parseo/forma del JSON ([FormatException], [TypeError] como
  ///   un `as Map<String, dynamic>` fallido, `CheckedFromJsonException`, ...)
  ///   → [ApiFailureType.parse].
  /// - Cualquier otra cosa → [ApiFailureType.unknown].
  factory ApiFailure.from(Object error) {
    if (error is ApiFailure) return error;
    if (error is DioException) return mapDioException(error);
    if (error is FormatException || error is TypeError) {
      return const ApiFailure(
        type: ApiFailureType.parse,
        message: 'Unexpected response format.',
      );
    }
    if (error is CheckedFromJsonException || error is ArgumentError) {
      return const ApiFailure(
        type: ApiFailureType.parse,
        message: 'Unexpected response format.',
      );
    }
    return const ApiFailure(
      type: ApiFailureType.unknown,
      message: 'An unexpected error occurred.',
    );
  }

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
