import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipos_fitness/app/app.dart';
import 'package:pipos_fitness/app/config.dart';
import 'package:pipos_fitness/core/api/api_client.dart';
import 'package:pipos_fitness/core/auth/token_storage.dart';
import 'package:pipos_fitness/core/offline/app_database.dart';
import 'package:pipos_fitness/core/offline/connectivity.dart';

import 'package:pipos_fitness/core/offline/offline_providers.dart';
import 'package:pipos_fitness/core/reminders/reminders.dart';
import 'package:pipos_fitness/features/onboarding/onboarding_controller.dart';
import 'package:pipos_fitness/features/settings/settings_providers.dart';
import 'package:pipos_fitness/models/user.dart';

import 'fake_backend.dart';
import 'fake_http_adapter.dart';

export 'fake_backend.dart';

/// Guarda la exportación en memoria (en vez de la hoja de compartir).
class RecordingExportSaver implements ExportSaver {
  final List<String> saved = [];

  @override
  Future<void> save(String fileName, Map<String, dynamic> json) async {
    saved.add(fileName);
  }
}

/// Notificaciones locales en memoria (sin plugin).
class FakeNotificationScheduler implements NotificationScheduler {
  bool grant = true;
  int permissionRequests = 0;
  final Map<int, DateTime> scheduled = {};

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return grant;
  }

  @override
  Future<void> cancelAll() async => scheduled.clear();

  @override
  Future<void> schedule({
    required int id,
    required DateTime when,
    required String title,
    required String body,
  }) async {
    scheduled[id] = when;
  }
}

/// Dependencias falsas para montar [PiposRoot] en tests: sin secure storage,
/// sin red real, sin plugins y con base de datos en memoria.
class AppHarness {
  AppHarness({
    InMemoryTokenStorage? storage,
    bool online = true,
    FakeBackend? backend,
    this.clock,
  }) : storage = storage ?? InMemoryTokenStorage(),
       adapter = FakeHttpAdapter(),
       backend = backend ?? FakeBackend(),
       connectivity = ManualConnectivitySource(online: online),
       database = AppDatabase(NativeDatabase.memory());

  /// Usuario autenticado con sesión válida (GET /me responde 200).
  factory AppHarness.signedIn({
    FakeBackend? backend,
    bool online = true,
    DateTime Function()? clock,
  }) {
    final h = AppHarness(
      storage: InMemoryTokenStorage(
        accessToken: 'access-1',
        refreshToken: 'refresh-1',
        cachedUser: const AuthUser(id: 'user-1', email: 'ana@pipos.app'),
      ),
      backend: backend,
      online: online,
      clock: clock,
    );
    h.adapter.reply('GET', '/me', 200, meJson());
    return h;
  }

  final InMemoryTokenStorage storage;
  final FakeHttpAdapter adapter;

  /// Capa de datos de la API v1 en memoria (auth sigue yendo por [adapter]).
  final FakeBackend backend;
  final ManualConnectivitySource connectivity;
  final AppDatabase database;
  final DateTime Function()? clock;

  /// Simula modo avión: sin conectividad y sin respuesta de la API.
  void setOnline(bool value) {
    backend.online = value;
    connectivity.online = value;
  }

  Widget build({List<Override> overrides = const []}) => PiposRoot(
    config: const AppConfig(apiBaseUrl: 'http://api.test'),
    tokenStorage: storage,
    database: database,
    connectivity: connectivity,
    overrides: [
      httpClientAdapterProvider.overrideWithValue(adapter),
      ...backend.overrides,
      deviceTimezoneProvider.overrideWith((_) async => 'Europe/Madrid'),
      exportSaverProvider.overrideWithValue(exportSaver),
      notificationSchedulerProvider.overrideWithValue(notifications),
      if (clock != null) clockProvider.overrideWithValue(clock!),
      ...overrides,
    ],
  );

  final RecordingExportSaver exportSaver = RecordingExportSaver();
  final FakeNotificationScheduler notifications = FakeNotificationScheduler();

  /// Monta la app en español y registra la limpieza.
  Future<void> pump(
    WidgetTester tester, {
    List<Override> overrides = const [],
  }) async {
    tester.platformDispatcher.localesTestValue = const [Locale('es', 'ES')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      // Deja terminar peticiones/timers pendientes del scope desmontado.
      await tester.pump(const Duration(seconds: 1));
      await tester.runAsync(() async {
        await database.close();
        await connectivity.dispose();
      });
    });
    await tester.pumpWidget(build(overrides: overrides));
  }

  /// Deja avanzar el reloj falso para que terminen las peticiones y timers
  /// que lanzan las pantallas reales (p. ej. el dashboard) y después
  /// desmonta la app. Llamar al final de tests que navegan a pantallas con
  /// datos.
  Future<void> drainAndUnmount(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    await tester.pumpWidget(const SizedBox.shrink());
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  /// Contenedor del `ProviderScope` montado actualmente por [PiposRoot].
  ProviderContainer container(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(PiposApp)));
}
