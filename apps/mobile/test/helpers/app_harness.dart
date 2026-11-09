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

import 'fake_http_adapter.dart';

/// Dependencias falsas para montar [PiposRoot] en tests: sin secure storage,
/// sin red real, sin plugins y con base de datos en memoria.
class AppHarness {
  AppHarness({InMemoryTokenStorage? storage, bool online = true})
    : storage = storage ?? InMemoryTokenStorage(),
      adapter = FakeHttpAdapter(),
      connectivity = ManualConnectivitySource(online: online),
      database = AppDatabase(NativeDatabase.memory());

  final InMemoryTokenStorage storage;
  final FakeHttpAdapter adapter;
  final ManualConnectivitySource connectivity;
  final AppDatabase database;

  Widget build({List<Override> overrides = const []}) => PiposRoot(
    config: const AppConfig(apiBaseUrl: 'http://api.test'),
    tokenStorage: storage,
    database: database,
    connectivity: connectivity,
    overrides: [
      httpClientAdapterProvider.overrideWithValue(adapter),
      ...overrides,
    ],
  );

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
