/// Base de datos local (drift) para el modo offline-first (ADR-0007).
///
/// - [LocalWorkouts]: entrenamientos empezados en el dispositivo (con su
///   `clientId`); `serverId` se rellena cuando la API confirma el inicio.
/// - [LocalSetLogs]: cada serie registrada, con su estado de sincronización.
///   Las sincronizadas se conservan (estado `synced`) para pintar la sesión
///   sin red y se purgan pasados unos días.
/// - [CachedPayloads]: última respuesta JSON de lecturas clave (sesión de
///   hoy, plan actual) para abrir la app en modo avión.
/// - [PendingMutations]: otras escrituras offline (ADR-0013): nota fija por
///   ejercicio y medidas corporales. Una fila por clave lógica (la última
///   edición local sustituye a la anterior); se borra al confirmarse.
///
/// El código generado (`app_database.g.dart`) se versiona; para regenerarlo:
///
/// ```
/// dart run build_runner build --delete-conflicting-outputs
/// ```
library;

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// Estado de sincronización de una serie.
enum SetSyncStatus {
  /// Esperando a enviarse (o a su próximo reintento, ver `nextAttemptAt`).
  pending,

  /// Envío en curso. Si la app muere en este estado, al arrancar vuelve a
  /// `pending` (ver `SyncService.recoverInterrupted`).
  syncing,

  /// Confirmada por la API (201 o 200 por `clientId` repetido).
  synced,

  /// Error permanente (4xx de validación) o agotó los reintentos. Solo se
  /// reintenta a petición del usuario.
  failed,
}

@DataClassName('LocalWorkout')
class LocalWorkouts extends Table {
  /// UUID v4 del dispositivo: clave de idempotencia de `POST /workouts`.
  TextColumn get clientId => text()();
  TextColumn get userId => text()();
  TextColumn get planSessionId => text()();

  /// Id de la API; null hasta que el inicio se sincroniza.
  TextColumn get serverId => text().nullable()();
  DateTimeColumn get startedAt => dateTime()();

  /// Momento en que el usuario terminó (reloj del cliente).
  DateTimeColumn get finishedAt => dateTime().nullable()();
  BoolColumn get finishSynced => boolean().withDefault(const Constant(false))();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get nextAttemptAt => dateTime().nullable()();

  /// Ajuste de hoy elegido antes de empezar (JSON de `WorkoutAdjustment`;
  /// null = sesión completa). Se envía en `POST /workouts`.
  TextColumn get adjustmentJson => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {clientId};
}

@DataClassName('LocalSetLog')
class LocalSetLogs extends Table {
  /// UUID v4 del dispositivo: clave de idempotencia de la serie.
  TextColumn get clientId => text()();
  TextColumn get userId => text()();
  TextColumn get workoutClientId => text()();
  TextColumn get planExerciseId => text().nullable()();

  /// Ejercicio realmente hecho (puede ser un sustituto).
  TextColumn get exerciseId => text()();
  IntColumn get setIndex => integer()();
  IntColumn get reps => integer()();
  RealColumn get loadKg => real()();
  IntColumn get rir => integer().nullable()();
  BoolColumn get isWarmup => boolean().withDefault(const Constant(false))();
  DateTimeColumn get completedAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  TextColumn get status => textEnum<SetSyncStatus>().withDefault(
    Constant(SetSyncStatus.pending.name),
  )();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();

  /// Momento a partir del cual se puede reintentar (backoff exponencial).
  DateTimeColumn get nextAttemptAt => dateTime().nullable()();

  /// La API confirmó la serie al menos una vez (existe en el servidor).
  BoolColumn get confirmed => boolean().withDefault(const Constant(false))();

  /// Borrada en local: la fila queda como «lápida» `pending` hasta que la
  /// API confirme el `DELETE` (la UI no la pinta y oculta la copia de la
  /// API). Si nunca llegó al servidor, se borra la fila sin más.
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {clientId};
}

@DataClassName('CachedPayload')
class CachedPayloads extends Table {
  TextColumn get userId => text()();

  /// Clave lógica (`CacheKeys`).
  TextColumn get cacheKey => text()();
  TextColumn get json => text()();
  DateTimeColumn get savedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {userId, cacheKey};
}

/// Tipo de escritura offline de [PendingMutations].
enum MutationKind { notePut, noteDelete, measurementPut, measurementDelete }

@DataClassName('PendingMutation')
class PendingMutations extends Table {
  TextColumn get userId => text()();

  /// Clave lógica: `note:<exerciseId>` o `measurement:<YYYY-MM-DD>`.
  TextColumn get mutationKey => text()();
  TextColumn get kind => textEnum<MutationKind>()();

  /// Cuerpo de la petición (JSON) o datos para construirla.
  TextColumn get payload => text()();

  /// Momento de la edición local (para la nota: `clientUpdatedAt`).
  DateTimeColumn get updatedAt => dateTime()();

  /// `pending`, `syncing` o `failed` (al confirmarse la fila se borra).
  TextColumn get status => textEnum<SetSyncStatus>().withDefault(
    Constant(SetSyncStatus.pending.name),
  )();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get nextAttemptAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {userId, mutationKey};
}

@DriftDatabase(
  tables: [LocalWorkouts, LocalSetLogs, CachedPayloads, PendingMutations],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'pipos_fitness'));

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // v1 (Fase 4a) guardaba series para la API antigua (rutas por
        // WorkoutExercise), incompatibles con la API v1. No hay usuarios
        // reales todavía (ADR-0009): se descarta la tabla.
        await m.deleteTable('pending_set_logs');
        await m.createAll();
        return;
      }
      if (from < 3) {
        // ADR-0013: ajuste de hoy y cola de otras escrituras offline.
        await m.addColumn(localWorkouts, localWorkouts.adjustmentJson);
        await m.createTable(pendingMutations);
      }
      if (from < 4) {
        // Descartar, editar y borrar series (issues #21 y #22).
        await m.addColumn(localSetLogs, localSetLogs.confirmed);
        await m.addColumn(localSetLogs, localSetLogs.deleted);
        await customStatement(
          "UPDATE local_set_logs SET confirmed = 1 WHERE status = 'synced'",
        );
      }
    },
  );
}
