import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/config.dart';
import 'core/auth/token_storage.dart';
import 'core/offline/app_database.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final config = AppConfig.resolve();
  if (config == null) {
    runApp(const ConfigErrorApp());
    return;
  }

  runApp(
    PiposRoot(
      config: config,
      tokenStorage: SecureTokenStorage(),
      database: AppDatabase(),
    ),
  );
}
