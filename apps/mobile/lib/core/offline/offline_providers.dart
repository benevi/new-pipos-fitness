import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/auth_provider.dart';
import '../api/api_client.dart';
import 'app_database.dart';
import 'connectivity.dart';
import 'set_log_uploader.dart';
import 'sync_service.dart';

/// Base de datos local. Vive FUERA del ciclo de sesión: `PiposRoot` la abre
/// una vez y la inyecta en cada `ProviderScope` (así la cola sobrevive a un
/// logout/login y no se abren dos conexiones al mismo fichero).
final appDatabaseProvider = Provider<AppDatabase>(
  (_) => throw StateError(
    'appDatabaseProvider debe sobrescribirse (PiposRoot o tests).',
  ),
);

final connectivitySourceProvider = Provider<ConnectivitySource>(
  (_) => PluginConnectivitySource(),
);

final setLogUploaderProvider = Provider<SetLogUploader>(
  (ref) => ApiSetLogUploader(ref.watch(dioProvider)),
);

/// Servicio de sincronización de la sesión actual. Se recrea cuando cambia
/// el usuario (login) y se descarta con el scope (logout).
final syncServiceProvider = Provider<SyncService>((ref) {
  final userId = ref.watch(authProvider.select((s) => s.user?.id));
  final service = SyncService(
    database: ref.watch(appDatabaseProvider),
    uploader: ref.watch(setLogUploaderProvider),
    connectivity: ref.watch(connectivitySourceProvider),
    userId: userId,
  );
  service.start();
  ref.onDispose(service.dispose);
  return service;
});

/// Series del usuario pendientes de confirmar por la API.
final pendingSetLogsProvider = StreamProvider<List<PendingSetLog>>(
  (ref) => ref.watch(syncServiceProvider).watchQueue(),
);
