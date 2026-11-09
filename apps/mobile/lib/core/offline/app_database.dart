/// Base de datos local (drift) para el modo offline-first (ADR-0007).
///
/// De momento solo guarda la cola de series registradas pendientes de
/// enviar a la API. El código generado (`app_database.g.dart`) se versiona;
/// para regenerarlo:
///
/// ```
/// dart run build_runner build --delete-conflicting-outputs
/// ```
library;

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// Estado de una serie en la cola. Las enviadas con éxito se borran.
enum PendingSetLogStatus {
  /// Esperando a enviarse (o a su próximo reintento, ver `nextAttemptAt`).
  pending,

  /// Envío en curso. Si la app muere en este estado, al arrancar vuelve a
  /// `pending` (ver `SyncService.recoverInterrupted`).
  syncing,

  /// Error permanente (4xx de validación) o agotó los reintentos. No se
  /// reintenta automáticamente.
  failed,
}

@DataClassName('PendingSetLog')
class PendingSetLogs extends Table {
  /// UUID v4 generado en el dispositivo. La API lo usará como clave de
  /// idempotencia (Fase 3): reenviar la misma serie no la duplica.
  TextColumn get clientId => text()();

  /// Dueño de la serie: solo se sincroniza con la sesión de ese usuario.
  TextColumn get userId => text()();

  TextColumn get workoutSessionId => text()();

  /// `WorkoutExercise.id` de la sesión (segmento de la ruta del endpoint).
  TextColumn get workoutExerciseId => text()();

  /// Id del ejercicio de catálogo (informativo).
  TextColumn get exerciseId => text().nullable()();

  IntColumn get setIndex => integer()();
  IntColumn get reps => integer().nullable()();
  RealColumn get loadKg => real().nullable()();
  IntColumn get rir => integer().nullable()();
  DateTimeColumn get completedAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  TextColumn get status => textEnum<PendingSetLogStatus>().withDefault(
    Constant(PendingSetLogStatus.pending.name),
  )();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();

  /// Momento a partir del cual se puede reintentar (backoff exponencial).
  DateTimeColumn get nextAttemptAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {clientId};
}

@DriftDatabase(tables: [PendingSetLogs])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'pipos_fitness'));

  @override
  int get schemaVersion => 1;
}
