import 'package:dio/dio.dart';

import 'dio_error_mapper.dart';

/// Códigos de error estables de la API v1 (`ERROR_CODES` en
/// contracts/src/schemas/common.ts). El móvil decide por `code`, nunca por
/// `message`.
class ApiErrorCode {
  ApiErrorCode._();

  static const validationFailed = 'VALIDATION_FAILED';
  static const unauthorized = 'UNAUTHORIZED';
  static const forbidden = 'FORBIDDEN';
  static const notFound = 'NOT_FOUND';
  static const conflict = 'CONFLICT';
  static const rateLimited = 'RATE_LIMITED';
  static const authInvalidCredentials = 'AUTH_INVALID_CREDENTIALS';
  static const authEmailTaken = 'AUTH_EMAIL_TAKEN';
  static const authRefreshInvalid = 'AUTH_REFRESH_INVALID';
  static const authRefreshReused = 'AUTH_REFRESH_REUSED';
  static const authRefreshRace = 'AUTH_REFRESH_RACE';
  static const healthConsentRequired = 'HEALTH_CONSENT_REQUIRED';
  static const healthConsentVersionMismatch = 'HEALTH_CONSENT_VERSION_MISMATCH';
  static const profileRequired = 'PROFILE_REQUIRED';
  static const planRequired = 'PLAN_REQUIRED';
  static const planGenerationFailed = 'PLAN_GENERATION_FAILED';
  static const planVersionConflict = 'PLAN_VERSION_CONFLICT';
  static const unknownExercise = 'UNKNOWN_EXERCISE';
  static const workoutInProgress = 'WORKOUT_IN_PROGRESS';
  static const workoutFinished = 'WORKOUT_FINISHED';
  static const clientIdConflict = 'CLIENT_ID_CONFLICT';
  static const nutritionInputIncomplete = 'NUTRITION_INPUT_INCOMPLETE';
}

/// Error de un campo (`FieldIssue`: `path` con puntos, p. ej. `daysPerWeek`
/// o `equipment.2`).
class FieldIssue {
  const FieldIssue({required this.path, required this.message});

  final String path;
  final String message;

  /// Primer segmento del `path` (el campo de primer nivel).
  String get field => path.split('.').first;
}

/// Unified failure model for the API layer.
///
/// All Dio/network/backend errors are mapped to an [ApiFailure] before
/// reaching providers or UI. Raw DioExceptions never leak beyond the API layer.
///
/// Los `message` son textos técnicos de respaldo; la UI traduce por
/// [code]/[type] (ver `l10n/failure_messages.dart`).
class ApiFailure implements Exception {
  final ApiFailureType type;
  final String message;
  final int? statusCode;

  /// `code` estable de la API ([ApiErrorCode]), si la respuesta lo trae.
  final String? code;

  /// Errores por campo (422/400 de validación).
  final List<FieldIssue> issues;

  const ApiFailure({
    required this.type,
    required this.message,
    this.statusCode,
    this.code,
    this.issues = const [],
  });

  /// Fallo por falta de red o por servidor inalcanzable: se puede tirar de
  /// la caché local.
  bool get isConnectivity =>
      type == ApiFailureType.network || type == ApiFailureType.timeout;

  /// Merece la pena reintentar más tarde (cola offline).
  bool get isTransient =>
      isConnectivity ||
      type == ApiFailureType.server ||
      type == ApiFailureType.unauthorized ||
      statusCode == 408 ||
      statusCode == 429;

  /// Convierte cualquier error capturado en un [ApiFailure].
  factory ApiFailure.from(Object error) {
    if (error is ApiFailure) return error;
    if (error is DioException) return mapDioException(error);
    if (error is FormatException ||
        error is TypeError ||
        error is ArgumentError) {
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
  String toString() => 'ApiFailure($type, $statusCode, $code, $message)';
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
