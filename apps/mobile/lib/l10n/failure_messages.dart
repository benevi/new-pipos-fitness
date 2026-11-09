import 'package:intl/intl.dart';

import '../core/api/api_failure.dart';
import '../features/auth/auth_provider.dart';
import 'app_localizations.dart';

/// Traducción de errores de la capa de datos a textos de UI. Se decide por
/// `code` estable de la API cuando lo hay, y si no por el tipo de fallo.
extension ApiFailureL10n on ApiFailure {
  String localized(AppLocalizations l10n) {
    switch (code) {
      case ApiErrorCode.rateLimited:
        return l10n.errorRateLimited;
      case ApiErrorCode.planGenerationFailed:
        return l10n.errorPlanGeneration;
      case ApiErrorCode.healthConsentRequired:
      case ApiErrorCode.healthConsentVersionMismatch:
        return l10n.errorConsentRequired;
      case ApiErrorCode.validationFailed:
        return l10n.validationFixErrors;
    }
    return switch (type) {
      ApiFailureType.network => l10n.errorNetwork,
      ApiFailureType.timeout => l10n.errorTimeout,
      ApiFailureType.unauthorized => l10n.errorUnauthorized,
      ApiFailureType.badRequest => l10n.errorBadRequest,
      ApiFailureType.server => l10n.errorServer,
      ApiFailureType.parse => l10n.errorParse,
      ApiFailureType.unknown => l10n.errorUnknown,
    };
  }
}

/// Motivo legible de una serie que no se pudo enviar (`lastError` de la
/// cola: código estable de la API o `HTTP nnn`).
String setRejectionReason(AppLocalizations l10n, String? code) =>
    switch (code) {
      ApiErrorCode.validationFailed ||
      ApiErrorCode.unknownExercise ||
      'HTTP 400' ||
      'HTTP 422' => l10n.setRejectedInvalid,
      ApiErrorCode.workoutFinished => l10n.setRejectedFinished,
      ApiErrorCode.notFound ||
      ApiErrorCode.workoutInProgress ||
      'WORKOUT_NOT_STARTED' => l10n.setRejectedNotStarted,
      null => l10n.syncStatusFailed,
      _ => l10n.setRejectedOther(code),
    };

extension AuthErrorCodeL10n on AuthErrorCode {
  String localized(AppLocalizations l10n) => switch (this) {
    AuthErrorCode.invalidCredentials => l10n.authErrorInvalidCredentials,
    AuthErrorCode.emailAlreadyRegistered =>
      l10n.authErrorEmailAlreadyRegistered,
    AuthErrorCode.invalidInput => l10n.authErrorInvalidInput,
    AuthErrorCode.network => l10n.errorNetwork,
    AuthErrorCode.timeout => l10n.errorTimeout,
    AuthErrorCode.server => l10n.errorServer,
    AuthErrorCode.sessionExpired => l10n.authErrorSessionExpired,
    AuthErrorCode.unknown => l10n.errorUnknown,
  };
}

/// Formato de números y fechas según el idioma de la UI.
extension L10nFormat on AppLocalizations {
  /// `62,5` (es) / `62.5` (en); sin decimales si es entero.
  String number(num value, {int maxDecimals = 1}) {
    // Hasta [maxDecimals] decimales, sin ceros sobrantes (0,5 y no 0,50).
    final f = NumberFormat.decimalPattern(localeName)
      ..minimumFractionDigits = 0
      ..maximumFractionDigits = maxDecimals;
    return f.format(value);
  }

  String kg(num value) => loadKgValue(number(value));

  /// Con hasta 2 decimales (discos de 1,25 kg, cargas de 62,25 kg).
  String kgPrecise(num value) => loadKgValue(number(value, maxDecimals: 2));

  /// Día y mes («12 oct.»), para los ejes de las gráficas.
  String dayMonth(DateTime d) => DateFormat.MMMd(localeName).format(d);

  /// Periodo entre dos fechas: en semanas desde 14 días, si no en días.
  String period(DateTime from, DateTime to) {
    final days = to.difference(from).inDays.abs();
    return days >= 14
        ? chartPeriodWeeks((days / 7).round())
        : chartPeriodDays(days);
  }

  String shortDate(DateTime d) =>
      DateFormat.yMMMd(localeName).format(d.toLocal());

  String dateTime(DateTime d) =>
      DateFormat.yMMMd(localeName).add_Hm().format(d.toLocal());
}
