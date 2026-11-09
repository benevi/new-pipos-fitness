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

/// Sesión de hoy con respaldo en caché. `null` = no hay plan/perfil.
final todaySessionProvider = FutureProvider.autoDispose<Cached<TodaySession>?>((
  ref,
) async {
  final cache = ref.read(cacheStoreProvider);
  try {
    final session = await ref.watch(workoutApiProvider).getToday();
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

/// Series locales del entrenamiento.
final localSetsProvider = StreamProvider.autoDispose
    .family<List<LocalSetLog>, String>(
      (ref, workoutClientId) =>
          ref.watch(syncServiceProvider).watchSets(workoutClientId),
    );

/// Serie registrada tal como se pinta (local o ya en la API).
class LoggedSetView {
  const LoggedSetView({
    required this.clientId,
    required this.setIndex,
    required this.reps,
    required this.loadKg,
    required this.rir,
    required this.status,
  });

  final String clientId;
  final int setIndex;
  final int reps;
  final double loadKg;
  final int? rir;
  final SetSyncStatus status;
}

/// Fusiona las series de la API (`loggedSets`) con las locales, sin
/// duplicar por `clientId`. Las de calentamiento no cuentan.
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
    );
  }
  for (final s in local) {
    if (s.isWarmup || s.planExerciseId != exercise.planExerciseId) continue;
    byClient[s.clientId] = LoggedSetView(
      clientId: s.clientId,
      setIndex: s.setIndex,
      reps: s.reps,
      loadKg: s.loadKg,
      rir: s.rir,
      status: s.status,
    );
  }
  final list = byClient.values.toList()
    ..sort((a, b) => a.setIndex.compareTo(b.setIndex));
  return list;
}

// ── Temporizador de descanso ──

class RestTimerState {
  const RestTimerState({required this.total, required this.remaining});

  final int total;
  final int remaining;

  bool get done => remaining <= 0;
}

/// Cuenta atrás de descanso que arranca sola tras confirmar una serie.
/// Al terminar vibra (si el dispositivo lo permite). Un `Timer` por
/// segundo; se cancela al saltar o al salir de la pantalla.
class RestTimerController extends StateNotifier<RestTimerState?> {
  RestTimerController() : super(null);

  Timer? _ticker;

  void start(int seconds) {
    _ticker?.cancel();
    if (seconds <= 0) {
      state = null;
      return;
    }
    state = RestTimerState(total: seconds, remaining: seconds);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final s = state;
    if (s == null) return;
    final remaining = s.remaining - 1;
    if (remaining <= 0) {
      _ticker?.cancel();
      state = RestTimerState(total: s.total, remaining: 0);
      HapticFeedback.heavyImpact();
      return;
    }
    state = RestTimerState(total: s.total, remaining: remaining);
  }

  void add(int seconds) {
    final s = state;
    if (s == null) return;
    if (s.done) {
      start(seconds);
      return;
    }
    state = RestTimerState(
      total: s.total + seconds,
      remaining: s.remaining + seconds,
    );
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
      (ref) => RestTimerController(),
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
