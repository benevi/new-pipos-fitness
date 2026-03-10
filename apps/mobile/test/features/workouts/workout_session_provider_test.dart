import 'package:flutter_test/flutter_test.dart';
import 'package:pipos_fitness/features/workouts/workout_session_provider.dart';
import 'package:pipos_fitness/models/training_plan.dart';
import 'package:pipos_fitness/models/workout_session.dart';

void main() {
  group('WorkoutSessionState', () {
    test('default state is idle', () {
      const state = WorkoutSessionState();
      expect(state.status, WorkoutStatus.idle);
      expect(state.isActive, false);
      expect(state.isStarting, false);
      expect(state.isCompleted, false);
      expect(state.session, isNull);
      expect(state.sessionId, isNull);
      expect(state.startedAt, isNull);
      expect(state.currentExerciseIndex, 0);
      expect(state.resumedSession, false);
    });

    test('isStarting returns true when status is starting', () {
      const state = WorkoutSessionState(status: WorkoutStatus.starting);
      expect(state.isStarting, true);
      expect(state.isActive, false);
    });

    test('isActive returns true when status is active', () {
      const state = WorkoutSessionState(status: WorkoutStatus.active);
      expect(state.isActive, true);
    });

    test('isCompleted returns true when status is completed', () {
      const state = WorkoutSessionState(status: WorkoutStatus.completed);
      expect(state.isCompleted, true);
    });

    test('sessionId and startedAt derive from session', () {
      final state = WorkoutSessionState(
        session: WorkoutSession(
          id: 'w1',
          userId: 'u1',
          startedAt: '2026-03-09T10:00:00Z',
          exercises: [],
        ),
      );
      expect(state.sessionId, 'w1');
      expect(state.startedAt, '2026-03-09T10:00:00Z');
    });

    test('totalExercises uses planSession when available', () {
      const session = TrainingSession(
        id: 's1',
        planVersionId: 'v1',
        sessionIndex: 0,
        name: 'Day 1',
        targetDurationMinutes: 60,
        exercises: [
          TrainingSessionExercise(
            id: 'e1',
            sessionId: 's1',
            exerciseId: 'bench-press',
            sets: 3,
            repRangeMin: 8,
            repRangeMax: 12,
            restSeconds: 90,
            rirTarget: 2,
          ),
          TrainingSessionExercise(
            id: 'e2',
            sessionId: 's1',
            exerciseId: 'squat',
            sets: 4,
            repRangeMin: 6,
            repRangeMax: 10,
            restSeconds: 120,
            rirTarget: 2,
          ),
        ],
      );
      const state = WorkoutSessionState(planSession: session);
      expect(state.totalExercises, 2);
    });

    test('totalExercises falls back to session exercises when no planSession',
        () {
      final state = WorkoutSessionState(
        session: WorkoutSession(
          id: 'w1',
          userId: 'u1',
          startedAt: '2026-03-09T10:00:00Z',
          exercises: [
            WorkoutExercise(
                id: 'we1',
                workoutSessionId: 'w1',
                exerciseId: 'bench-press',
                order: 0,
                sets: []),
            WorkoutExercise(
                id: 'we2',
                workoutSessionId: 'w1',
                exerciseId: 'squat',
                order: 1,
                sets: []),
            WorkoutExercise(
                id: 'we3',
                workoutSessionId: 'w1',
                exerciseId: 'deadlift',
                order: 2,
                sets: []),
          ],
        ),
      );
      expect(state.totalExercises, 3);
    });

    test('setsForExercise returns sets for matching workout exercise', () {
      final state = WorkoutSessionState(
        session: WorkoutSession(
          id: 'w1',
          userId: 'u1',
          startedAt: '2026-03-09T10:00:00Z',
          exercises: [
            WorkoutExercise(
              id: 'we1',
              workoutSessionId: 'w1',
              exerciseId: 'bench-press',
              order: 0,
              sets: [
                WorkoutSet(
                  id: 'ws1',
                  workoutExerciseId: 'we1',
                  setIndex: 0,
                  weightKg: 80,
                  reps: 10,
                  completed: true,
                ),
              ],
            ),
          ],
        ),
      );
      expect(state.setsForExercise('we1').length, 1);
      expect(state.setsForExercise('nonexistent'), isEmpty);
    });

    test('copyWith preserves unchanged fields', () {
      const state = WorkoutSessionState(
        status: WorkoutStatus.active,
        currentExerciseIndex: 2,
        resumedSession: true,
      );
      final updated = state.copyWith(currentExerciseIndex: 3);
      expect(updated.status, WorkoutStatus.active);
      expect(updated.currentExerciseIndex, 3);
      expect(updated.resumedSession, true);
    });

    test('copyWith with error sets and clears error', () {
      const state = WorkoutSessionState();
      final withError = state.copyWith(error: 'Network error');
      expect(withError.error, 'Network error');

      final cleared = withError.copyWith(error: null);
      expect(cleared.error, isNull);
    });
  });

  group('WorkoutStatus', () {
    test('all values exist', () {
      expect(
        WorkoutStatus.values,
        containsAll([
          WorkoutStatus.idle,
          WorkoutStatus.starting,
          WorkoutStatus.active,
          WorkoutStatus.finishing,
          WorkoutStatus.completed,
          WorkoutStatus.error,
        ]),
      );
    });
  });

  group('Atomic start (state transitions)', () {
    test('starting status prevents double start', () {
      const state = WorkoutSessionState(status: WorkoutStatus.starting);
      expect(state.isStarting, true);
      expect(state.isActive, false);
    });

    test('error state with partial exercises preserves session for retry', () {
      final state = WorkoutSessionState(
        status: WorkoutStatus.error,
        error: 'Failed to add exercises: No internet connection.',
        session: WorkoutSession(
          id: 'w1',
          userId: 'u1',
          startedAt: '2026-03-09T10:00:00Z',
          exercises: [
            WorkoutExercise(
              id: 'we1',
              workoutSessionId: 'w1',
              exerciseId: 'bench-press',
              order: 0,
              sets: [],
            ),
          ],
        ),
        planSession: const TrainingSession(
          id: 's1',
          planVersionId: 'v1',
          sessionIndex: 0,
          name: 'Day 1',
          targetDurationMinutes: 60,
          exercises: [
            TrainingSessionExercise(
              id: 'e1',
              sessionId: 's1',
              exerciseId: 'bench-press',
              sets: 3,
              repRangeMin: 8,
              repRangeMax: 12,
              restSeconds: 90,
              rirTarget: 2,
            ),
            TrainingSessionExercise(
              id: 'e2',
              sessionId: 's1',
              exerciseId: 'squat',
              sets: 4,
              repRangeMin: 6,
              repRangeMax: 10,
              restSeconds: 120,
              rirTarget: 2,
            ),
          ],
        ),
      );
      expect(state.status, WorkoutStatus.error);
      expect(state.session, isNotNull);
      expect(state.session!.exercises.length, 1);
      expect(state.planSession, isNotNull);
      expect(state.planSession!.exercises.length, 2);
    });
  });

  group('Resume workout (state restoration)', () {
    test('resumed state includes exercises with logged sets', () {
      final state = WorkoutSessionState(
        status: WorkoutStatus.active,
        resumedSession: true,
        currentExerciseIndex: 1,
        session: WorkoutSession(
          id: 'w1',
          userId: 'u1',
          startedAt: '2026-03-09T10:00:00Z',
          exercises: [
            WorkoutExercise(
              id: 'we1',
              workoutSessionId: 'w1',
              exerciseId: 'bench-press',
              order: 0,
              sets: [
                WorkoutSet(
                  id: 'ws1',
                  workoutExerciseId: 'we1',
                  setIndex: 0,
                  weightKg: 60,
                  reps: 8,
                  completed: true,
                ),
                WorkoutSet(
                  id: 'ws2',
                  workoutExerciseId: 'we1',
                  setIndex: 1,
                  weightKg: 65,
                  reps: 7,
                  completed: true,
                ),
              ],
            ),
            WorkoutExercise(
              id: 'we2',
              workoutSessionId: 'w1',
              exerciseId: 'squat',
              order: 1,
              sets: [],
            ),
          ],
        ),
      );
      expect(state.isActive, true);
      expect(state.resumedSession, true);
      expect(state.currentExerciseIndex, 1);
      expect(state.session!.exercises[0].sets.length, 2);
      expect(state.session!.exercises[1].sets.length, 0);
    });

    test('resumed state totalExercises uses session exercises count', () {
      final state = WorkoutSessionState(
        status: WorkoutStatus.active,
        resumedSession: true,
        session: WorkoutSession(
          id: 'w1',
          userId: 'u1',
          startedAt: '2026-03-09T10:00:00Z',
          exercises: [
            WorkoutExercise(
                id: 'we1',
                workoutSessionId: 'w1',
                exerciseId: 'bench',
                order: 0,
                sets: []),
            WorkoutExercise(
                id: 'we2',
                workoutSessionId: 'w1',
                exerciseId: 'squat',
                order: 1,
                sets: []),
          ],
        ),
      );
      expect(state.totalExercises, 2);
    });
  });

  group('Multiple active sessions guard', () {
    test('most recent incomplete session is selected (mock scenario)', () {
      // Simulates the logic: history ordered by startedAt desc,
      // incomplete sessions filtered, first (most recent) chosen
      final sessions = [
        WorkoutSession(
          id: 'w2',
          userId: 'u1',
          startedAt: '2026-03-09T12:00:00Z',
          exercises: [],
        ),
        WorkoutSession(
          id: 'w1',
          userId: 'u1',
          startedAt: '2026-03-09T10:00:00Z',
          exercises: [],
        ),
        WorkoutSession(
          id: 'w0',
          userId: 'u1',
          startedAt: '2026-03-08T10:00:00Z',
          completedAt: '2026-03-08T11:00:00Z',
          exercises: [],
        ),
      ];

      final incomplete =
          sessions.where((w) => w.completedAt == null).toList();
      expect(incomplete.length, 2);

      final mostRecent = incomplete.first;
      expect(mostRecent.id, 'w2');
    });
  });

  group('Duplicate set prevention', () {
    test('setIndex equals plannedSets marks exercise as complete', () {
      // This mirrors the UI logic in _SetInputForm
      const plannedSets = 3;
      const setIndex = 3; // 3 sets logged, planned 3
      final allDone = plannedSets > 0 && setIndex >= plannedSets;
      expect(allDone, true);
    });

    test('allows unlimited sets when plannedSets is 0 (resumed without plan)',
        () {
      const plannedSets = 0;
      const setIndex = 5;
      final allDone = plannedSets > 0 && setIndex >= plannedSets;
      expect(allDone, false);
    });

    test('allows more sets when under planned count', () {
      const plannedSets = 4;
      const setIndex = 2;
      final allDone = plannedSets > 0 && setIndex >= plannedSets;
      expect(allDone, false);
    });
  });
}
