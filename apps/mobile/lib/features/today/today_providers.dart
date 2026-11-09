/// Datos de la sesión de hoy (CUJ-2/3/4).
///
/// La sesión se lee de `GET /sessions/today` y se guarda en caché local:
/// sin red, la pantalla abre con la última copia. Las series se pintan desde
/// drift (cola del [SyncService]) fusionadas con las que la API ya tenía.
library;

import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_failure.dart';
import '../../core/offline/app_database.dart';
import '../../core/offline/offline_providers.dart';
import '../../core/offline/sync_service.dart';
import '../../core/reminders/reminders.dart';
import '../../data/pipos_api.dart';
import '../../models/workout.dart';
import '../exercise/exercise_providers.dart';

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
    // Fichas de los ejercicios de hoy, para verlas sin red (CUJ-11).
    unawaited(
      prefetchExerciseDetails(
        ref.read(catalogApiProvider),
        cache,
        session.exercises.map((e) => e.exercise.id),
        ref.read(clockProvider)(),
      ),
    );
    if (adjustment == null) {
      unawaited(
        prefetchSubstitutes(
          ref.read(workoutApiProvider),
          cache,
          session,
          ref.read(clockProvider)(),
        ),
      );
    }
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

/// Guarda en caché las alternativas de cada ejercicio de la sesión (las
/// que falten o sean de otro día) para poder cambiar de ejercicio sin red
/// (#23). Nunca falla: es una mejora oportunista.
Future<void> prefetchSubstitutes(
  WorkoutApi api,
  CacheStore cache,
  TodaySession session,
  DateTime now,
) async {
  try {
    for (final e in session.exercises) {
      final key = CacheKeys.substitutes(e.exercise.id);
      final saved = await cache.read(key);
      if (saved != null && isSameLocalDay(saved.savedAt, now)) continue;
      final options = await api.getSubstitutes(e.exercise.id);
      await cache.write(key, options.toJson());
    }
  } catch (_) {}
}

/// Alternativas de un ejercicio: de la API (y a la caché) o, sin red, la
/// última copia guardada.
final substitutesProvider = FutureProvider.autoDispose
    .family<Cached<SubstitutesResponse>, String>((ref, exerciseId) async {
      final cache = ref.read(cacheStoreProvider);
      final key = CacheKeys.substitutes(exerciseId);
      try {
        final r = await ref
            .watch(workoutApiProvider)
            .getSubstitutes(exerciseId);
        await cache.write(key, r.toJson());
        return Cached(r);
      } on ApiFailure catch (f) {
        if (!f.isConnectivity && f.type != ApiFailureType.server) rethrow;
        final saved = await cache.read(key);
        if (saved == null) rethrow;
        return Cached(
          SubstitutesResponse.fromJson(saved.json),
          savedAt: saved.savedAt,
          fromCache: true,
        );
      }
    });

/// Cambios de ejercicio en la cola (#23), del más antiguo al más reciente.
final pendingSwapsProvider = StreamProvider.autoDispose<List<PendingSwap>>(
  (ref) => ref.watch(syncServiceProvider).watchSwaps(),
);

/// Aplica a la sesión los cambios de ejercicio aún sin confirmar del
/// entrenamiento [workoutClientId] (el último de cada hueco manda; los
/// fallidos no se aplican).
List<TodayExercise> applyPendingSwaps(
  List<TodayExercise> exercises,
  List<PendingSwap> swaps,
  String? workoutClientId,
) {
  if (workoutClientId == null || swaps.isEmpty) return exercises;
  final bySlot = <String, PendingSwap>{
    for (final s in swaps)
      if (!s.failed && s.workoutClientId == workoutClientId)
        s.planExerciseId: s,
  };
  return [
    for (final e in exercises)
      if (bySlot[e.planExerciseId] case final s?)
        e.withPendingSwap(s.exercise, s.substitutedFrom)
      else
        e,
  ];
}

/// Entrenamiento local abierto para la sesión de hoy (o null si aún no se
/// ha registrado ninguna serie).
final openWorkoutProvider = StreamProvider.autoDispose
    .family<LocalWorkout?, String>(
      (ref, planSessionId) =>
          ref.watch(syncServiceProvider).watchOpenWorkout(planSessionId),
    );

/// Entrenamientos que el servidor cerró sin que la persona los terminara
/// (p. ej. abandonados solos tras 12 h sin actividad).
final closedRemotelyProvider = StreamProvider.autoDispose<List<LocalWorkout>>(
  (ref) => ref.watch(syncServiceProvider).watchClosedRemotely(),
);

/// La API avisó de que el plan cambió (`409 PLAN_SESSION_OUTDATED`).
final planOutdatedProvider = StreamProvider.autoDispose<void>(
  (ref) => ref.watch(syncServiceProvider).planOutdated,
);

/// Entrenamientos locales bloqueados por otro en curso en la cuenta
/// (`409 WORKOUT_IN_PROGRESS` de otra sesión del plan) o por un cambio de
/// plan con series ya hechas (`409 PLAN_SESSION_OUTDATED`).
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
///
/// Con la app en segundo plano el fin del descanso avisa con una
/// notificación local programada para `endsAt` ([onBackground], #24), solo
/// si ya hay permiso (no se pide aquí). Se cancela al volver a primer plano
/// ([onForeground]), al saltar el descanso o al empezar otro.
class RestTimerController extends StateNotifier<RestTimerState?> {
  RestTimerController({
    DateTime Function()? clock,
    NotificationScheduler? notifications,
  }) : _clock = clock ?? DateTime.now,
       _notifications = notifications,
       super(null);

  final DateTime Function() _clock;
  final NotificationScheduler? _notifications;
  Timer? _ticker;

  /// Id del aviso de fin de descanso (los recordatorios usan 0..13).
  static const notificationId = 1000;

  bool _backgrounded = false;
  bool _notificationScheduled = false;

  /// La app pasa a segundo plano: si hay un descanso en marcha, programa el
  /// aviso de su fin.
  Future<void> onBackground({
    required String title,
    required String body,
  }) async {
    _backgrounded = true;
    final s = state;
    final n = _notifications;
    if (s == null || s.done || n == null) return;
    try {
      if (!await n.hasPermission()) return;
      if (!_backgrounded || state?.endsAt != s.endsAt) return;
      await n.schedule(
        id: notificationId,
        when: s.endsAt.toLocal(),
        title: title,
        body: body,
        channel: NotificationChannel.restTimer,
      );
      _notificationScheduled = true;
      // Volvió a primer plano mientras se programaba.
      if (!_backgrounded) await _cancelNotification();
    } catch (e) {
      debugPrint('RestTimer: no se pudo programar el aviso: $e');
    }
  }

  /// La app vuelve a primer plano: cancela el aviso y recalcula.
  Future<void> onForeground() async {
    _backgrounded = false;
    await _cancelNotification();
    refresh();
  }

  Future<void> _cancelNotification() async {
    if (!_notificationScheduled) return;
    _notificationScheduled = false;
    try {
      await _notifications?.cancel(notificationId);
    } catch (e) {
      debugPrint('RestTimer: no se pudo cancelar el aviso: $e');
    }
  }

  void start(int seconds) {
    unawaited(_cancelNotification());
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
    unawaited(_cancelNotification());
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
      (ref) => RestTimerController(
        clock: ref.watch(clockProvider),
        notifications: ref.watch(notificationSchedulerProvider),
      ),
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
