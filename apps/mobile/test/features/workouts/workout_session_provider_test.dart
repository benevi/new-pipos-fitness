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
      expect(state.isStarting, false);
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

    test('totalExercises falls back to session exercises when no planSession', () {
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
              sets: [],
            ),
            WorkoutExercise(
              id: 'we2',
              workoutSessionId: 'w1',
              exerciseId: 'squat',
              order: 1,
              sets: [],
            ),
            WorkoutExercise(
              id: 'we3',
              workoutSessionId: 'w1',
              exerciseId: 'deadlift',
              order: 2,
              sets: [],
            ),
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

    test('resumedSession flag works in copyWith', () {
      const state = WorkoutSessionState();
      expect(state.resumedSession, false);

      final resumed = state.copyWith(resumedSession: true);
      expect(resumed.resumedSession, true);
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

  group('Atomic workout start (state transitions)', () {
    test('starting status prevents double start', () {
      const state = WorkoutSessionState(status: WorkoutStatus.starting);
      expect(state.isStarting, true);
      expect(state.isActive, false);
    });

    test('error status with exercises-add failure preserves session', () {
      final state = WorkoutSessionState(
        status: WorkoutStatus.error,
        error: 'Failed to add exercises: No internet connection.',
        session: WorkoutSession(
          id: 'w1',
          userId: 'u1',
          startedAt: '2026-03-09T10:00:00Z',
          exercises: [],
        ),
      );
      expect(state.status, WorkoutStatus.error);
      expect(state.error, contains('Failed to add exercises'));
      expect(state.session, isNotNull);
    });
  });

  group('Resume workout (state)', () {
    test('resumed workout sets active with resumedSession flag', () {
      final resumed = WorkoutSessionState(
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
              ],
            ),
          ],
        ),
      );
      expect(resumed.isActive, true);
      expect(resumed.resumedSession, true);
      expect(resumed.session!.exercises.first.sets.length, 1);
    });
  });
}
