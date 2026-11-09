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
    final f = NumberFormat.decimalPatternDigits(
      locale: localeName,
      decimalDigits: maxDecimals,
    );
    final rounded = value is int
        ? value
        : double.parse(value.toStringAsFixed(maxDecimals));
    if (rounded == rounded.roundToDouble()) {
      return NumberFormat.decimalPatternDigits(
        locale: localeName,
        decimalDigits: 0,
      ).format(rounded);
    }
    return f.format(rounded);
  }

  String kg(num value) => loadKgValue(number(value));

  /// Con hasta 2 decimales (discos de 1,25 kg, cargas de 62,25 kg).
  String kgPrecise(num value) {
    final f = NumberFormat.decimalPattern(localeName)
      ..minimumFractionDigits = 0
      ..maximumFractionDigits = 2;
    return loadKgValue(f.format(value));
  }

  String shortDate(DateTime d) =>
      DateFormat.yMMMd(localeName).format(d.toLocal());

  String dateTime(DateTime d) =>
      DateFormat.yMMMd(localeName).add_Hm().format(d.toLocal());
}
