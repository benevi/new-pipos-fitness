/// Datos de la sesión de hoy (CUJ-2/3/4).
///
/// La sesión se lee de `GET /sessions/today` y se guarda en caché local:
/// sin red, la pantalla abre con la última copia. Las series se pintan desde
/// drift (cola del [SyncService]) fusionadas con las que la API ya tenía.
library;

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_failure.dart';
import '../../core/offline/app_database.dart';
import '../../core/offline/offline_providers.dart';
import '../../data/pipos_api.dart';
import '../../models/workout.dart';

/// Ajuste de hoy elegido antes de empezar (idea 4); null = sesión completa.
/// Una vez empezado el entrenamiento, la API aplica el ajuste guardado.
final todayAdjustmentProvider = StateProvider<WorkoutAdjustment?>((_) => null);

/// Sesión de hoy con respaldo en caché. `null` = no hay plan/perfil.
final todaySessionProvider = FutureProvider.autoDispose<Cached<TodaySession>?>((
  ref,
) async {
  final cache = ref.read(cacheStoreProvider);
  final adjustment = ref.watch(todayAdjustmentProvider);
  try {
    final session = await ref
        .watch(workoutApiProvider)
        .getToday(adjustment: adjustment);

    await cache.write(CacheKeys.today, session.toJson());
    return Cached(session);
  } on ApiFailure catch (f) {
    if (f.code == ApiErrorCode.planRequired ||
        f.code == ApiErrorCode.profileRequired) {
      return null;
    }
    if (!f.isConnectivity && f.type != ApiFailureType.server) rethrow;
    final cached = await cache.read(CacheKeys.today);
    if (cached == null) rethrow;
    return Cached(
      TodaySession.fromJson(cached.json),
      savedAt: cached.savedAt,
      fromCache: true,
      isStale: !isSameLocalDay(cached.savedAt, ref.read(clockProvider)()),
    );
  }
});

/// Entrenamiento local abierto para la sesión de hoy (o null si aún no se
/// ha registrado ninguna serie).
final openWorkoutProvider = StreamProvider.autoDispose
    .family<LocalWorkout?, String>(
      (ref, planSessionId) =>
          ref.watch(syncServiceProvider).watchOpenWorkout(planSessionId),
    );

/// Entrenamientos locales bloqueados por otro en curso en la cuenta
/// (`409 WORKOUT_IN_PROGRESS` de otra sesión del plan).
final conflictingWorkoutsProvider =
    StreamProvider.autoDispose<List<LocalWorkout>>(
      (ref) => ref.watch(syncServiceProvider).watchConflictingWorkouts(),
    );

/// Series locales del entrenamiento.
final localSetsProvider = StreamProvider.autoDispose
    .family<List<LocalSetLog>, String>(
      (ref, workoutClientId) =>
          ref.watch(syncServiceProvider).watchSets(workoutClientId),
    );

/// Series locales visibles (sin las lápidas de las borradas).
List<LocalSetLog> visibleSets(List<LocalSetLog> local) =>
    local.where((s) => !s.deleted).toList();

/// Serie registrada tal como se pinta (local o ya en la API).
class LoggedSetView {
  const LoggedSetView({
    required this.clientId,
    required this.setIndex,
    required this.reps,
    required this.loadKg,
    required this.rir,
    required this.status,
    this.lastError,
    this.server,
  });

  final String clientId;
  final int setIndex;
  final int reps;
  final double loadKg;
  final int? rir;
  final SetSyncStatus status;

  /// Motivo del último fallo de envío (código de la API o `HTTP nnn`).
  final String? lastError;

  /// La serie de la API si no hay copia local (p. ej. registrada en otro
  /// dispositivo): para editarla o borrarla se adopta antes en drift.
  final SetLog? server;
}

/// Fusiona las series de la API (`loggedSets`) con las locales, sin
/// duplicar por `clientId`. Las de calentamiento no cuentan; las borradas
/// en local (lápidas) ocultan la copia de la API.
List<LoggedSetView> mergeSets(TodayExercise exercise, List<LocalSetLog> local) {
  final byClient = <String, LoggedSetView>{};
  for (final s in exercise.loggedSets) {
    if (s.isWarmup || s.deletedAt != null) continue;
    byClient[s.clientId] = LoggedSetView(
      clientId: s.clientId,
      setIndex: s.setIndex,
      reps: s.reps,
      loadKg: s.loadKg,
      rir: s.rir,
      status: SetSyncStatus.synced,
      server: s,
    );
  }
  for (final s in local) {
    if (s.isWarmup || s.planExerciseId != exercise.planExerciseId) continue;
    if (s.deleted) {
      byClient.remove(s.clientId);
      continue;
    }
    byClient[s.clientId] = LoggedSetView(
      clientId: s.clientId,
      setIndex: s.setIndex,
      reps: s.reps,
      loadKg: s.loadKg,
      rir: s.rir,
      status: s.status,
      lastError: s.lastError,
    );
  }
  final list = byClient.values.toList()
    ..sort((a, b) => a.setIndex.compareTo(b.setIndex));
  return list;
}

// ── Temporizador de descanso ──

class RestTimerState {
  const RestTimerState({
    required this.total,
    required this.endsAt,
    required this.remaining,
  });

  final int total;

  /// Momento (reloj de la app) en que termina el descanso.
  final DateTime endsAt;

  /// Segundos que faltan, calculados contra el reloj (no contando ticks).
  final int remaining;

  bool get done => remaining <= 0;
}

/// Cuenta atrás de descanso que arranca sola tras confirmar una serie.
/// Al terminar vibra (si el dispositivo lo permite).
///
/// Se guarda `endsAt` y lo que falta se calcula con el reloj en cada tick:
/// si la app se suspende (pantalla apagada, otra app), los ticks no llegan,
/// pero al volver el tiempo restante es el real. [refresh] lo recalcula al
/// instante (lo llama la barra al volver a primer plano).
class RestTimerController extends StateNotifier<RestTimerState?> {
  RestTimerController({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now,
      super(null);

  final DateTime Function() _clock;
  Timer? _ticker;

  void start(int seconds) {
    _ticker?.cancel();
    if (seconds <= 0) {
      state = null;
      return;
    }
    _set(seconds, _clock().add(Duration(seconds: seconds)));
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => refresh());
  }

  int _remainingUntil(DateTime endsAt) {
    final ms = endsAt.difference(_clock()).inMilliseconds;
    return ms <= 0 ? 0 : (ms / 1000).ceil();
  }

  void _set(int total, DateTime endsAt) {
    state = RestTimerState(
      total: total,
      endsAt: endsAt,
      remaining: _remainingUntil(endsAt),
    );
  }

  /// Recalcula lo que falta según el reloj.
  void refresh() {
    final s = state;
    if (s == null || s.done) return;
    _set(s.total, s.endsAt);
    if (state!.done) {
      _ticker?.cancel();
      HapticFeedback.heavyImpact();
    }
  }

  void add(int seconds) {
    final s = state;
    if (s == null) return;
    if (s.done) {
      start(seconds);
      return;
    }
    _set(s.total + seconds, s.endsAt.add(Duration(seconds: seconds)));
  }

  void skip() {
    _ticker?.cancel();
    state = null;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

final restTimerProvider =
    StateNotifierProvider.autoDispose<RestTimerController, RestTimerState?>(
      (ref) => RestTimerController(clock: ref.watch(clockProvider)),
    );

/// Resumen que recibe la pantalla de fin de entrenamiento.
class WorkoutSummary {
  const WorkoutSummary({
    required this.workoutClientId,
    required this.sets,
    required this.volumeKg,
  });

  final String workoutClientId;
  final int sets;
  final double volumeKg;
}
