import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Se muestra mientras se valida la sesión guardada (estado `unknown`).
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Semantics(
          label: AppLocalizations.of(context).splashLoading,
          child: const CircularProgressIndicator(),
        ),
      ),
    );
  }
}
