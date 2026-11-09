import '../core/api/api_failure.dart';
import '../features/auth/auth_provider.dart';
import 'app_localizations.dart';

/// Traducción de errores de la capa de datos a textos de UI.
extension ApiFailureL10n on ApiFailure {
  String localized(AppLocalizations l10n) => switch (type) {
    ApiFailureType.network => l10n.errorNetwork,
    ApiFailureType.timeout => l10n.errorTimeout,
    ApiFailureType.unauthorized => l10n.errorUnauthorized,
    ApiFailureType.badRequest => l10n.errorBadRequest,
    ApiFailureType.server => l10n.errorServer,
    ApiFailureType.parse => l10n.errorParse,
    ApiFailureType.unknown => l10n.errorUnknown,
  };
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
