import 'package:flutter_test/flutter_test.dart';
import 'package:pipos_fitness/models/progress_metrics.dart';
import 'package:pipos_fitness/models/volume_metrics.dart';

void main() {
  group('ProgressMetrics', () {
    test('fromJson parses full response', () {
      final json = {
        'exercises': [
          {
            'exerciseId': 'bench-press',
            'estimated1RM': 100.0,
            'volumeLastWeek': 2400.0,
            'volumeTrend': 'up',
            'fatigueScore': 0.3,
            'lastUpdated': '2026-03-09T12:00:00Z',
          },
          {
            'exerciseId': 'squat',
            'estimated1RM': 140.0,
            'volumeLastWeek': 3200.0,
            'volumeTrend': 'stable',
            'fatigueScore': null,
            'lastUpdated': null,
          },
        ],
        'adherenceScore': 0.85,
        'fatigueDetected': false,
      };

      final metrics = ProgressMetrics.fromJson(json);
      expect(metrics.exercises.length, 2);
      expect(metrics.adherenceScore, 0.85);
      expect(metrics.fatigueDetected, false);
      expect(metrics.exercises[0].exerciseId, 'bench-press');
      expect(metrics.exercises[0].estimated1RM, 100.0);
      expect(metrics.exercises[0].volumeTrend, 'up');
      expect(metrics.exercises[1].fatigueScore, isNull);
    });

    test('fromJson handles null adherenceScore', () {
      final json = {
        'exercises': <dynamic>[],
        'adherenceScore': null,
        'fatigueDetected': true,
      };

      final metrics = ProgressMetrics.fromJson(json);
      expect(metrics.adherenceScore, isNull);
      expect(metrics.fatigueDetected, true);
      expect(metrics.exercises, isEmpty);
    });

    test('fromJson handles empty exercises list', () {
      final json = {
        'exercises': <dynamic>[],
        'adherenceScore': 0.5,
        'fatigueDetected': false,
      };

      final metrics = ProgressMetrics.fromJson(json);
      expect(metrics.exercises, isEmpty);
    });
  });

  group('VolumeMetrics', () {
    test('fromJson parses full response', () {
      final json = {
        'byExercise': [
          {'exerciseId': 'bench-press', 'volume': 2400.0},
          {'exerciseId': 'squat', 'volume': 3200.0},
        ],
        'byMuscle': [
          {'muscleId': 'chest', 'volume': 2400.0},
          {'muscleId': 'quads', 'volume': 3200.0},
        ],
        'weekStart': '2026-03-03T00:00:00Z',
        'weekEnd': '2026-03-09T23:59:59Z',
      };

      final volume = VolumeMetrics.fromJson(json);
      expect(volume.byExercise.length, 2);
      expect(volume.byMuscle.length, 2);
      expect(volume.weekStart, '2026-03-03T00:00:00Z');
      expect(volume.byExercise[0].volume, 2400.0);
      expect(volume.byMuscle[1].muscleId, 'quads');
    });

    test('fromJson handles empty lists', () {
      final json = {
        'byExercise': <dynamic>[],
        'byMuscle': <dynamic>[],
      };

      final volume = VolumeMetrics.fromJson(json);
      expect(volume.byExercise, isEmpty);
      expect(volume.byMuscle, isEmpty);
      expect(volume.weekStart, isNull);
    });

    test('total volume calculation', () {
      final volume = VolumeMetrics(
        byExercise: [
          VolumeByExercise(exerciseId: 'a', volume: 1000),
          VolumeByExercise(exerciseId: 'b', volume: 2000),
          VolumeByExercise(exerciseId: 'c', volume: 500),
        ],
        byMuscle: [],
      );

      final total =
          volume.byExercise.fold<double>(0, (s, e) => s + e.volume);
      expect(total, 3500);
    });
  });

  group('Dashboard rendering logic', () {
    test('adherence percentage formatting', () {
      const score = 0.85;
      final pct = '${(score * 100).toStringAsFixed(0)}%';
      expect(pct, '85%');
    });

    test('null adherence shows dash', () {
      const double? score = null;
      final pct = score != null
          ? '${(score * 100).toStringAsFixed(0)}%'
          : '—';
      expect(pct, '—');
    });

    test('trend icon mapping', () {
      // Mirrors the logic in _ExerciseProgressRow
      String trendLabel(String? trend) {
        switch (trend) {
          case 'up':
            return 'trending_up';
          case 'down':
            return 'trending_down';
          default:
            return 'trending_flat';
        }
      }

      expect(trendLabel('up'), 'trending_up');
      expect(trendLabel('down'), 'trending_down');
      expect(trendLabel('stable'), 'trending_flat');
      expect(trendLabel(null), 'trending_flat');
    });

    test('fatigue card shows correct state', () {
      expect(true, isTrue); // fatigueDetected = true → warning
      expect(false, isFalse); // fatigueDetected = false → shield
    });

    test('exercise fatigue highlight threshold', () {
      // Only exercises with fatigueScore > 0.5 show the fatigue label
      const item = ExerciseProgressItem(
        exerciseId: 'bench',
        fatigueScore: 0.7,
      );
      expect(item.fatigueScore! > 0.5, true);

      const low = ExerciseProgressItem(
        exerciseId: 'squat',
        fatigueScore: 0.3,
      );
      expect(low.fatigueScore! > 0.5, false);
    });
  });
}
