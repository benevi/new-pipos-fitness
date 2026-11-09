import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_failure.dart';
import '../../core/offline/app_database.dart';
import '../../core/offline/offline_providers.dart';
import '../../core/offline/sync_service.dart';
import '../../models/training_plan.dart';
import '../../models/workout_session.dart';

enum WorkoutStatus { idle, starting, active, finishing, completed, error }

class WorkoutSessionState {
  final WorkoutStatus status;
  final WorkoutSession? session;
  final TrainingSession? planSession;
  final int currentExerciseIndex;
  final String? error;
  final bool resumedSession;

  const WorkoutSessionState({
    this.status = WorkoutStatus.idle,
    this.session,
    this.planSession,
    this.currentExerciseIndex = 0,
    this.error,
    this.resumedSession = false,
  });

  bool get isActive => status == WorkoutStatus.active;
  bool get isStarting => status == WorkoutStatus.starting;
  bool get isCompleted => status == WorkoutStatus.completed;

  String? get sessionId => session?.id;
  String? get startedAt => session?.startedAt;

  int get totalExercises =>
      planSession?.exercises.length ?? session?.exercises.length ?? 0;

  List<WorkoutSet> setsForExercise(String workoutExerciseId) {
    final ex = session?.exercises
        .where((e) => e.id == workoutExerciseId)
        .firstOrNull;
    return ex?.sets ?? [];
  }

  WorkoutSessionState copyWith({
    WorkoutStatus? status,
    WorkoutSession? session,
    TrainingSession? planSession,
    int? currentExerciseIndex,
    String? error,
    bool? resumedSession,
  }) {
    return WorkoutSessionState(
      status: status ?? this.status,
      session: session ?? this.session,
      planSession: planSession ?? this.planSession,
      currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
      error: error,
      resumedSession: resumedSession ?? this.resumedSession,
    );
  }
}

final workoutSessionProvider =
    StateNotifierProvider<WorkoutSessionNotifier, WorkoutSessionState>(
      (ref) =>
          WorkoutSessionNotifier(ref, sync: ref.watch(syncServiceProvider)),
    );

/// Registro de entrenos.
///
/// Las series se registran offline-first: [logSet] las escribe en la cola
/// local (drift) a través del [SyncService], las muestra al instante
/// (UI optimista) y el servicio las envía cuando hay red. Cuando la API
/// confirma una serie, la sesión del servidor reemplaza a la local y se
/// vuelven a aplicar encima las series que siguen pendientes.
class WorkoutSessionNotifier extends StateNotifier<WorkoutSessionState> {
  final Ref _ref;
  final SyncService? _sync;
  final Uuid _uuid;
  StreamSubscription<SyncedSetLog>? _syncedSub;

  /// Series mostradas de forma optimista, aún sin confirmar (por clientId).
  final Map<String, WorkoutSet> _optimistic = {};

  WorkoutSessionNotifier(this._ref, {SyncService? sync, Uuid? uuid})
    : _sync = sync,
      _uuid = uuid ?? const Uuid(),
      super(const WorkoutSessionState()) {
    _syncedSub = _sync?.synced.listen(_onSynced);
  }

  ApiClient get _api => _ref.read(apiClientProvider);

  @override
  void dispose() {
    _syncedSub?.cancel();
    super.dispose();
  }

  /// Ids de las series que aún no ha confirmado la API.
  Set<String> get pendingSetIds => Set.unmodifiable(_optimistic.keys);

  /// Atomic start: creates session + adds all exercises.
  /// State becomes active only after both steps succeed.
  Future<bool> startWorkout(TrainingSession planSession) async {
    if (state.isActive || state.isStarting) return false;

    state = WorkoutSessionState(
      status: WorkoutStatus.starting,
      planSession: planSession,
    );

    WorkoutSession session;
    try {
      final response = await _api.post(
        '/workouts/start',
        data: {'planSessionId': planSession.id},
      );
      session = WorkoutSession.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      final failure = ApiFailure.from(e);
      state = WorkoutSessionState(
        status: WorkoutStatus.error,
        planSession: planSession,
        error: failure.message,
      );
      return false;
    }

    // Add all exercises; each call returns the full updated session
    try {
      for (final planExercise in planSession.exercises) {
        final resp = await _api.post(
          '/workouts/${session.id}/exercises',
          data: {'exerciseId': planExercise.exerciseId},
        );
        session = WorkoutSession.fromJson(resp.data as Map<String, dynamic>);
      }
    } catch (e) {
      final failure = ApiFailure.from(e);
      state = WorkoutSessionState(
        status: WorkoutStatus.error,
        planSession: planSession,
        session: session,
        error: 'Failed to add exercises: ${failure.message}',
      );
      return false;
    }

    state = WorkoutSessionState(
      status: WorkoutStatus.active,
      session: session,
      planSession: planSession,
    );
    return true;
  }

  /// Retry adding remaining exercises after a partial start failure.
  /// Fetches current session state, determines missing exercises, adds them.
  Future<bool> retryAddExercises() async {
    if (state.session == null || state.planSession == null) return false;
    if (state.status != WorkoutStatus.error) return false;

    final sessionId = state.session!.id;
    final planSession = state.planSession!;

    state = state.copyWith(status: WorkoutStatus.starting, error: null);

    WorkoutSession current;
    try {
      final resp = await _api.get('/workouts/$sessionId');
      current = WorkoutSession.fromJson(resp.data as Map<String, dynamic>);
    } catch (e) {
      final failure = ApiFailure.from(e);
      state = state.copyWith(
        status: WorkoutStatus.error,
        error: 'Failed to load session: ${failure.message}',
      );
      return false;
    }

    final existingExerciseIds = current.exercises
        .map((e) => e.exerciseId)
        .toSet();
    final missing = planSession.exercises
        .where((pe) => !existingExerciseIds.contains(pe.exerciseId))
        .toList();

    try {
      for (final planExercise in missing) {
        final resp = await _api.post(
          '/workouts/$sessionId/exercises',
          data: {'exerciseId': planExercise.exerciseId},
        );
        current = WorkoutSession.fromJson(resp.data as Map<String, dynamic>);
      }
    } catch (e) {
      final failure = ApiFailure.from(e);
      state = WorkoutSessionState(
        status: WorkoutStatus.error,
        planSession: planSession,
        session: current,
        error: 'Failed to add exercises: ${failure.message}',
      );
      return false;
    }

    state = WorkoutSessionState(
      status: WorkoutStatus.active,
      session: current,
      planSession: planSession,
    );
    return true;
  }

  /// Resume an incomplete workout by fetching its full state from the server.
  Future<bool> resumeWorkout(String sessionId) async {
    try {
      final resp = await _api.get('/workouts/$sessionId');
      await _restorePendingFor(sessionId);
      final session = _applyOptimistic(
        WorkoutSession.fromJson(resp.data as Map<String, dynamic>),
      );

      // Restore currentExerciseIndex: first exercise with fewer completed sets
      // than expected, or the last exercise
      final exerciseIndex = _computeResumeIndex(session);

      state = WorkoutSessionState(
        status: WorkoutStatus.active,
        session: session,
        resumedSession: true,
        currentExerciseIndex: exerciseIndex,
      );
      return true;
    } catch (e) {
      final failure = ApiFailure.from(e);
      state = state.copyWith(error: 'Failed to resume: ${failure.message}');
      return false;
    }
  }

  /// Find the first exercise that has no sets, or the last one if all have sets.
  int _computeResumeIndex(WorkoutSession session) {
    if (session.exercises.isEmpty) return 0;
    for (int i = 0; i < session.exercises.length; i++) {
      if (session.exercises[i].sets.isEmpty) return i;
    }
    return session.exercises.length - 1;
  }

  /// Check for incomplete workouts via GET /workouts/history.
  /// Returns the most recent incomplete session, warns in debug if multiple.
  Future<WorkoutSession?> checkForActiveWorkout() async {
    try {
      final response = await _api.get('/workouts/history');
      final list = (response.data as List<dynamic>)
          .map((e) => WorkoutSession.fromJson(e as Map<String, dynamic>))
          .toList();

      final incomplete = list.where((w) => w.completedAt == null).toList();
      if (incomplete.isEmpty) return null;

      if (incomplete.length > 1) {
        debugPrint(
          'WARNING: ${incomplete.length} incomplete workout sessions found. '
          'Resuming most recent.',
        );
      }

      // History is ordered by startedAt desc, so first is most recent
      return incomplete.first;
    } catch (_) {
      return null;
    }
  }

  Future<bool> logSet({
    required String workoutExerciseId,
    double? weightKg,
    int? reps,
    int? rir,
  }) async {
    final session = state.session;
    final sync = _sync;
    if (session == null || sync == null) return false;

    final exercise = session.exercises
        .where((e) => e.id == workoutExerciseId)
        .firstOrNull;
    if (exercise == null) return false;

    final clientId = _uuid.v4();
    final setIndex = exercise.sets.length;
    try {
      await sync.enqueue(
        clientId: clientId,
        workoutSessionId: session.id,
        workoutExerciseId: workoutExerciseId,
        exerciseId: exercise.exerciseId,
        setIndex: setIndex,
        reps: reps,
        loadKg: weightKg,
        rir: rir,
      );
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(error: ApiFailure.from(e).message);
      return false;
    }
    if (!mounted) return true;

    final optimistic = WorkoutSet(
      id: clientId,
      workoutExerciseId: workoutExerciseId,
      setIndex: setIndex,
      weightKg: weightKg,
      reps: reps,
      rir: rir,
      completed: true,
    );
    _optimistic[clientId] = optimistic;
    // Leemos el estado de nuevo: pudo cambiar mientras se escribía en disco.
    final current = state.session;
    if (current != null) {
      state = state.copyWith(session: _applyOptimistic(current));
    }
    return true;
  }

  void _onSynced(SyncedSetLog event) {
    _optimistic.remove(event.clientId);
    if (!mounted) return;
    final current = state.session;
    if (current == null || current.id != event.workoutSessionId) return;

    final data = event.responseData;
    WorkoutSession? server;
    if (data is Map<String, dynamic>) {
      try {
        server = WorkoutSession.fromJson(data);
      } catch (_) {
        server = null; // Respuesta inesperada: mantenemos la vista local.
      }
    }
    if (server == null) return;
    state = state.copyWith(session: _applyOptimistic(server));
  }

  /// Añade a [base] las series optimistas que aún no contiene.
  WorkoutSession _applyOptimistic(WorkoutSession base) {
    if (_optimistic.isEmpty) return base;
    final byExercise = <String, List<WorkoutSet>>{};
    for (final set in _optimistic.values) {
      byExercise.putIfAbsent(set.workoutExerciseId, () => []).add(set);
    }
    return base.copyWith(
      exercises: [
        for (final ex in base.exercises)
          if (!byExercise.containsKey(ex.id))
            ex
          else
            _withPending(ex, byExercise[ex.id]!),
      ],
    );
  }

  WorkoutExercise _withPending(WorkoutExercise ex, List<WorkoutSet> pending) {
    final existingIds = ex.sets.map((s) => s.id).toSet();
    final sets = [...ex.sets];
    final toAdd = pending.where((p) => !existingIds.contains(p.id)).toList()
      ..sort((a, b) => a.setIndex.compareTo(b.setIndex));
    for (final p in toAdd) {
      sets.add(p.copyWith(setIndex: sets.length));
    }
    return ex.copyWith(sets: sets);
  }

  /// Recupera de la cola local las series pendientes de [sessionId] (p. ej.
  /// tras reiniciar la app) para seguir mostrándolas.
  Future<void> _restorePendingFor(String sessionId) async {
    final sync = _sync;
    if (sync == null) return;
    final List<PendingSetLog> queue;
    try {
      queue = await sync.queue();
    } catch (_) {
      return;
    }
    for (final item in queue.where((q) => q.workoutSessionId == sessionId)) {
      _optimistic[item.clientId] = WorkoutSet(
        id: item.clientId,
        workoutExerciseId: item.workoutExerciseId,
        setIndex: item.setIndex,
        weightKg: item.loadKg,
        reps: item.reps,
        rir: item.rir,
        completed: true,
      );
    }
  }

  void nextExercise() {
    if (state.currentExerciseIndex < state.totalExercises - 1) {
      state = state.copyWith(
        currentExerciseIndex: state.currentExerciseIndex + 1,
      );
    }
  }

  void previousExercise() {
    if (state.currentExerciseIndex > 0) {
      state = state.copyWith(
        currentExerciseIndex: state.currentExerciseIndex - 1,
      );
    }
  }

  Future<bool> finishWorkout({int? durationMinutes, String? notes}) async {
    if (state.session == null) return false;

    state = state.copyWith(status: WorkoutStatus.finishing);

    // Best effort: intenta vaciar la cola antes de cerrar la sesión.
    try {
      await _sync?.syncNow();
    } catch (_) {}

    try {
      await _api.post(
        '/workouts/${state.session!.id}/finish',
        data: {
          if (durationMinutes != null) 'durationMinutes': durationMinutes,
          if (notes != null) 'notes': notes,
        },
      );

      state = state.copyWith(status: WorkoutStatus.completed);
      return true;
    } catch (e) {
      final failure = ApiFailure.from(e);
      // 409: la sesión ya estaba terminada (p. ej. reintento tras perder la
      // respuesta). Para el usuario el resultado es el mismo.
      if (failure.statusCode == 409) {
        state = state.copyWith(status: WorkoutStatus.completed);
        return true;
      }
      state = state.copyWith(
        status: WorkoutStatus.active,
        error: failure.message,
      );
      return false;
    }
  }

  void reset() {
    _optimistic.clear();
    state = const WorkoutSessionState();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}
