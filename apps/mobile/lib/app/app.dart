/// Raíz de la app y ciclo de vida de la sesión.
///
/// [PiposRoot] posee las dependencias que sobreviven a la sesión (config,
/// almacenamiento de tokens, base de datos local, conectividad) y monta la
/// app dentro de un `ProviderScope` con una clave propia. Cuando la sesión
/// termina (logout o sesión expirada), el [AuthSessionCoordinator] llama a
/// [_PiposRootState._onSessionEnded], que cambia la clave: Flutter descarta
/// el `ProviderScope` anterior (y con él TODOS los providers, el router y
/// sus cachés) y crea uno nuevo, limpio.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api_client.dart';
import '../core/auth/auth_session_coordinator.dart';
import '../core/auth/session_providers.dart';
import '../core/auth/token_storage.dart';
import '../core/offline/app_database.dart';
import '../core/offline/connectivity.dart';
import '../core/offline/offline_providers.dart';
import '../l10n/app_localizations.dart';
import 'config.dart';
import 'router.dart';
import 'theme.dart';

class PiposRoot extends StatefulWidget {
  const PiposRoot({
    super.key,
    required this.config,
    required this.tokenStorage,
    required this.database,
    this.connectivity,
    this.overrides = const [],
  });

  final AppConfig config;
  final TokenStorage tokenStorage;
  final AppDatabase database;
  final ConnectivitySource? connectivity;

  /// Overrides adicionales (tests: adaptador HTTP falso, etc.).
  final List<Override> overrides;

  @override
  State<PiposRoot> createState() => _PiposRootState();
}

class _PiposRootState extends State<PiposRoot> {
  Key _scopeKey = UniqueKey();
  SessionEndReason? _lastSessionEnd;

  void _onSessionEnded(SessionEndReason reason) {
    if (!mounted) return;
    setState(() {
      _lastSessionEnd = reason;
      _scopeKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    final connectivity = widget.connectivity;
    return ProviderScope(
      key: _scopeKey,
      overrides: [
        apiBaseUrlProvider.overrideWithValue(widget.config.apiBaseUrl),
        tokenStorageProvider.overrideWithValue(widget.tokenStorage),
        appDatabaseProvider.overrideWithValue(widget.database),
        if (connectivity != null)
          connectivitySourceProvider.overrideWithValue(connectivity),
        sessionEndCallbackProvider.overrideWithValue(_onSessionEnded),
        previousSessionEndProvider.overrideWithValue(_lastSessionEnd),
        ...widget.overrides,
      ],
      child: const PiposApp(),
    );
  }
}

class PiposApp extends ConsumerWidget {
  const PiposApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    // Mantiene vivo el servicio de sincronización durante la sesión.
    ref.listen(syncServiceProvider, (_, _) {});

    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }
}

/// Se muestra en builds no-debug compilados sin `API_BASE_URL`.
class ConfigErrorApp extends StatelessWidget {
  const ConfigErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const _ConfigErrorScreen(),
    );
  }
}

class _ConfigErrorScreen extends StatelessWidget {
  const _ConfigErrorScreen();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.settings_suggest_outlined,
                size: AppSpacing.xxl,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(l10n.configErrorTitle, style: theme.textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.sm),
              Text(l10n.configErrorBody, style: theme.textTheme.bodyLarge),
            ],
          ),
        ),
      ),
    );
  }
}
