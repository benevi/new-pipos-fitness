import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/pipos_api.dart';
import '../../features/auth/auth_provider.dart';
import 'app_database.dart';
import 'connectivity.dart';
import 'mutation_sender.dart';
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

/// Reloj de la app (sustituible en tests).
final clockProvider = Provider<DateTime Function()>((_) => DateTime.now);

/// Servicio de sincronización de la sesión actual. Se recrea cuando cambia
/// el usuario (login) y se descarta con el scope (logout).
final syncServiceProvider = Provider<SyncService>((ref) {
  final userId = ref.watch(authProvider.select((s) => s.user?.id));
  final service = SyncService(
    database: ref.watch(appDatabaseProvider),
    api: ref.watch(workoutApiProvider),
    connectivity: ref.watch(connectivitySourceProvider),
    userId: userId,
    clock: ref.watch(clockProvider),
    mutations: ApiMutationSender(
      notes: ref.watch(notesApiProvider),
      body: ref.watch(bodyApiProvider),
    ),
  );
  service.start();
  ref.onDispose(service.dispose);
  return service;
});

/// Series pendientes/fallidas del usuario (barra de estado de sync).
final syncSummaryProvider = StreamProvider<SyncSummary>(
  (ref) => ref.watch(syncServiceProvider).watchSummary(),
);

/// Claves de [CacheStore].
class CacheKeys {
  CacheKeys._();
  static const today = 'sessions/today';
  static const currentPlan = 'plans/current';

  /// Pausas planificadas (para «hoy toca» y el recordatorio sin red).
  static const breaks = 'me/breaks';

  /// Medidas corporales (lista del último año).
  static const measurements = 'me/measurements';

  /// Evolución corporal (`GET /progress/body`).
  static const bodyProgress = 'progress/body';
}

/// Última respuesta JSON de lecturas clave, por usuario (modo avión).
class CacheStore {
  CacheStore(this._db, this._userId, this._clock);

  final AppDatabase _db;
  final String? _userId;
  final DateTime Function() _clock;

  Future<void> write(String key, Map<String, dynamic> json) async {
    final userId = _userId;
    if (userId == null) return;
    await _db
        .into(_db.cachedPayloads)
        .insertOnConflictUpdate(
          CachedPayloadsCompanion.insert(
            userId: userId,
            cacheKey: key,
            json: jsonEncode(json),
            savedAt: _clock(),
          ),
        );
  }

  Future<({Map<String, dynamic> json, DateTime savedAt})?> read(
    String key,
  ) async {
    final userId = _userId;
    if (userId == null) return null;
    final row =
        await (_db.select(_db.cachedPayloads)
              ..where((t) => t.userId.equals(userId) & t.cacheKey.equals(key)))
            .getSingleOrNull();
    if (row == null) return null;
    try {
      final decoded = jsonDecode(row.json);
      if (decoded is Map<String, dynamic>) {
        return (json: decoded, savedAt: row.savedAt);
      }
    } catch (_) {}
    return null;
  }

  Future<void> remove(String key) async {
    final userId = _userId;
    if (userId == null) return;
    await (_db.delete(
      _db.cachedPayloads,
    )..where((t) => t.userId.equals(userId) & t.cacheKey.equals(key))).go();
  }

  /// Borra todo lo local del usuario (cuenta eliminada o logout confirmado).
  Future<void> wipeUser() async {
    final userId = _userId;
    if (userId == null) return;
    await (_db.delete(
      _db.cachedPayloads,
    )..where((t) => t.userId.equals(userId))).go();
    await (_db.delete(
      _db.localSetLogs,
    )..where((t) => t.userId.equals(userId))).go();
    await (_db.delete(
      _db.localWorkouts,
    )..where((t) => t.userId.equals(userId))).go();
    await (_db.delete(
      _db.pendingMutations,
    )..where((t) => t.userId.equals(userId))).go();
  }
}

final cacheStoreProvider = Provider<CacheStore>(
  (ref) => CacheStore(
    ref.watch(appDatabaseProvider),
    ref.watch(authProvider.select((s) => s.user?.id)),
    ref.watch(clockProvider),
  ),
);

/// Resultado de una lectura con respaldo en caché.
class Cached<T> {
  const Cached(
    this.value, {
    this.savedAt,
    this.fromCache = false,
    this.isStale = false,
  });

  final T value;

  /// Cuándo se obtuvo de la API (fetchedAt de la copia en caché).
  final DateTime? savedAt;

  /// `true` si viene de la caché porque no había red.
  final bool fromCache;

  /// `true` si la copia es de otro día local: la UI no debe presentarla
  /// como «la sesión de hoy».
  final bool isStale;
}

/// `true` si [a] y [b] caen en el mismo día del calendario local.
bool isSameLocalDay(DateTime a, DateTime b) {
  final la = a.toLocal();
  final lb = b.toLocal();
  return la.year == lb.year && la.month == lb.month && la.day == lb.day;
}
