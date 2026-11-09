import 'package:flutter/material.dart';

import '../../../app/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/failure_messages.dart';
import '../auth_provider.dart';

/// Mensaje de error del formulario de auth (accesible: se anuncia).
class AuthErrorText extends StatelessWidget {
  const AuthErrorText({super.key, required this.error});

  final AuthErrorCode error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.ms),
      child: Semantics(
        liveRegion: true,
        child: Text(
          error.localized(AppLocalizations.of(context)),
          key: const Key('auth-error'),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
      ),
    );
  }
}

/// Botón principal con indicador de carga.
class AuthSubmitButton extends StatelessWidget {
  const AuthSubmitButton({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox.square(
              dimension: AppSpacing.lg - AppSpacing.xs,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label),
    );
  }
}

/// Validadores compartidos.
class AuthValidators {
  AuthValidators._();

  static const int minPasswordLength = 8;

  static String? email(AppLocalizations l10n, String? v) {
    final value = v?.trim() ?? '';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
    return ok ? null : l10n.validationEmailInvalid;
  }
}
