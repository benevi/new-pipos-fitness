import 'package:flutter_test/flutter_test.dart';
import 'package:pipos_fitness/features/dashboard/dashboard_provider.dart';
import 'package:pipos_fitness/features/dashboard/muscle_catalog_provider.dart';
import 'package:pipos_fitness/models/exercise.dart';
import 'package:pipos_fitness/models/muscle.dart';
import 'package:pipos_fitness/models/progress_metrics.dart';
import 'package:pipos_fitness/models/volume_metrics.dart';
import 'package:pipos_fitness/features/workouts/exercise_catalog_provider.dart';

void main() {
  group('DashboardViewModel empty-state logic', () {
    test('isEmpty when no progress, no volume, no adherence', () {
      const vm = DashboardViewModel();
      expect(vm.isEmpty, true);
    });

    test('not empty when adherence exists but exercises empty', () {
      const progress = ProgressMetrics(
        exercises: [],
        adherenceScore: 0.9,
        fatigueDetected: false,
      );
      final vm = _build(progress: progress);
      expect(vm.isEmpty, false);
      expect(vm.adherenceScore, 0.9);
    });

    test('not empty when volume exists but progress null', () {
      const volume = VolumeMetrics(
        byExercise: [VolumeByExercise(exerciseId: 'a', volume: 100)],
        byMuscle: [],
      );
      final vm = _build(volume: volume);
      expect(vm.isEmpty, false);
      expect(vm.totalVolume, 100);
    });

    test('not empty when exercises exist', () {
      const progress = ProgressMetrics(
        exercises: [
          ExerciseProgressItem(exerciseId: 'bench', estimated1RM: 100),
        ],
        adherenceScore: null,
        fatigueDetected: false,
      );
      final vm = _build(progress: progress);
      expect(vm.isEmpty, false);
      expect(vm.exercises.length, 1);
    });

    test('empty when progress is null and volume is null', () {
      final vm = _build();
      expect(vm.isEmpty, true);
    });

    test('empty when progress has empty exercises, null adherence, no volume',
        () {
      const progress = ProgressMetrics(
        exercises: [],
        adherenceScore: null,
        fatigueDetected: false,
      );
      final vm = _build(progress: progress);
      expect(vm.isEmpty, true);
    });
  });

  group('DashboardViewModel data composition', () {
    test('resolves exercise names from catalog', () {
      const progress = ProgressMetrics(
        exercises: [
          ExerciseProgressItem(exerciseId: 'bench-press'),
        ],
        adherenceScore: 0.8,
        fatigueDetected: false,
      );
      final catalog = {
        'bench-press': const Exercise(
          id: 'bench-press',
          slug: 'bench-press',
          name: 'Bench Press',
          difficulty: 3,
          place: 'gym',
        ),
      };

      final vm = _build(progress: progress, exerciseCatalog: catalog);
      expect(vm.exercises.first.displayName, 'Bench Press');
    });

    test('falls back to exerciseId when catalog missing', () {
      const progress = ProgressMetrics(
        exercises: [
          ExerciseProgressItem(exerciseId: 'unknown-exercise'),
        ],
        adherenceScore: null,
        fatigueDetected: false,
      );

      final vm = _build(progress: progress);
      expect(vm.exercises.first.displayName, 'unknown-exercise');
    });

    test('resolves muscle names from catalog', () {
      const volume = VolumeMetrics(
        byExercise: [],
        byMuscle: [VolumeByMuscle(muscleId: 'chest-1', volume: 2400)],
      );
      final muscleCat = {
        'chest-1': const Muscle(id: 'chest-1', name: 'Chest', region: 'upper'),
      };

      final vm = _build(volume: volume, muscleCatalog: muscleCat);
      expect(vm.volumeByMuscle.first.displayName, 'Chest');
    });

    test('falls back to muscleId when muscle catalog missing', () {
      const volume = VolumeMetrics(
        byExercise: [],
        byMuscle: [VolumeByMuscle(muscleId: 'chest-1', volume: 2400)],
      );

      final vm = _build(volume: volume);
      expect(vm.volumeByMuscle.first.displayName, 'chest-1');
    });

    test('totalVolume sums byExercise', () {
      const volume = VolumeMetrics(
        byExercise: [
          VolumeByExercise(exerciseId: 'a', volume: 1000),
          VolumeByExercise(exerciseId: 'b', volume: 2500),
        ],
        byMuscle: [],
      );

      final vm = _build(volume: volume);
      expect(vm.totalVolume, 3500);
    });

    test('fatigueDetected propagated from progress', () {
      const progress = ProgressMetrics(
        exercises: [ExerciseProgressItem(exerciseId: 'a')],
        adherenceScore: 0.5,
        fatigueDetected: true,
      );

      final vm = _build(progress: progress);
      expect(vm.fatigueDetected, true);
    });
  });

  group('muscleName helper', () {
    test('returns name from catalog', () {
      final catalog = {
        'quads': const Muscle(id: 'quads', name: 'Quadriceps', region: 'lower'),
      };
      expect(muscleName(catalog, 'quads'), 'Quadriceps');
    });

    test('returns muscleId when not in catalog', () {
      expect(muscleName({}, 'unknown'), 'unknown');
    });

    test('returns muscleId when catalog is null', () {
      expect(muscleName(null, 'some-id'), 'some-id');
    });
  });

  group('exerciseName helper', () {
    test('returns name from catalog', () {
      final catalog = {
        'bench': const Exercise(
            id: 'bench', slug: 'bench', name: 'Bench', difficulty: 3, place: 'gym'),
      };
      expect(exerciseName(catalog, 'bench'), 'Bench');
    });

    test('returns exerciseId when catalog null', () {
      expect(exerciseName(null, 'abc'), 'abc');
    });
  });

  group('Partial data rendering', () {
    test('progress loads but volume fails', () {
      const progress = ProgressMetrics(
        exercises: [ExerciseProgressItem(exerciseId: 'a', estimated1RM: 80)],
        adherenceScore: 0.7,
        fatigueDetected: false,
      );
      final vm = _build(progress: progress, volume: null);
      expect(vm.isEmpty, false);
      expect(vm.exercises.length, 1);
      expect(vm.totalVolume, 0);
      expect(vm.volumeByMuscle, isEmpty);
    });

    test('volume loads but progress fails', () {
      const volume = VolumeMetrics(
        byExercise: [VolumeByExercise(exerciseId: 'x', volume: 500)],
        byMuscle: [VolumeByMuscle(muscleId: 'm1', volume: 500)],
      );
      final vm = _build(progress: null, volume: volume);
      expect(vm.isEmpty, false);
      expect(vm.exercises, isEmpty);
      expect(vm.totalVolume, 500);
      expect(vm.volumeByMuscle.length, 1);
    });
  });

  group('Model parsing', () {
    test('ProgressMetrics fromJson', () {
      final json = {
        'exercises': [
          {
            'exerciseId': 'bench',
            'estimated1RM': 100.0,
            'volumeLastWeek': 2400.0,
            'volumeTrend': 'up',
            'fatigueScore': 0.3,
            'lastUpdated': '2026-03-09T12:00:00Z',
          }
        ],
        'adherenceScore': 0.85,
        'fatigueDetected': false,
      };
      final m = ProgressMetrics.fromJson(json);
      expect(m.exercises.length, 1);
      expect(m.adherenceScore, 0.85);
    });

    test('VolumeMetrics fromJson', () {
      final json = {
        'byExercise': [
          {'exerciseId': 'a', 'volume': 1000.0}
        ],
        'byMuscle': [
          {'muscleId': 'chest', 'volume': 1000.0}
        ],
        'weekStart': '2026-03-03T00:00:00Z',
      };
      final v = VolumeMetrics.fromJson(json);
      expect(v.byExercise.length, 1);
      expect(v.byMuscle.length, 1);
      expect(v.weekStart, '2026-03-03T00:00:00Z');
    });

    test('Muscle fromJson', () {
      final json = {'id': 'm1', 'name': 'Chest', 'region': 'upper'};
      final m = Muscle.fromJson(json);
      expect(m.id, 'm1');
      expect(m.name, 'Chest');
    });
  });
}

/// Helper to call the same logic as [dashboardProvider] without Riverpod.
DashboardViewModel _build({
  ProgressMetrics? progress,
  VolumeMetrics? volume,
  Map<String, Exercise>? exerciseCatalog,
  Map<String, Muscle>? muscleCatalog,
}) {
  final hasExercises = progress != null && progress.exercises.isNotEmpty;
  final hasVolume = volume != null &&
      (volume.byExercise.isNotEmpty || volume.byMuscle.isNotEmpty);
  final hasAdherence = progress?.adherenceScore != null;

  if (!hasExercises && !hasVolume && !hasAdherence) {
    return const DashboardViewModel();
  }

  final exercises = (progress?.exercises ?? []).map((e) {
    return ExerciseProgressVM(
      exerciseId: e.exerciseId,
      displayName: exerciseName(exerciseCatalog, e.exerciseId),
      estimated1RM: e.estimated1RM,
      volumeLastWeek: e.volumeLastWeek,
      volumeTrend: e.volumeTrend,
      fatigueScore: e.fatigueScore,
    );
  }).toList();

  final totalVolume =
      volume?.byExercise.fold<double>(0, (s, e) => s + e.volume) ?? 0;

  final muscleVolumes = (volume?.byMuscle ?? []).map((m) {
    return MuscleVolumeVM(
      muscleId: m.muscleId,
      displayName: muscleName(muscleCatalog, m.muscleId),
      volume: m.volume,
    );
  }).toList();

  return DashboardViewModel(
    adherenceScore: progress?.adherenceScore,
    fatigueDetected: progress?.fatigueDetected ?? false,
    exercises: exercises,
    totalVolume: totalVolume,
    volumeByMuscle: muscleVolumes,
    exerciseCount: volume?.byExercise.length ?? exercises.length,
    muscleCount: volume?.byMuscle.length ?? 0,
    isEmpty: false,
  );
}
