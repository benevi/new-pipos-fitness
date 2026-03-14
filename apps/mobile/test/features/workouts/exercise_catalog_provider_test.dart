import 'package:flutter_test/flutter_test.dart';
import 'package:pipos_fitness/features/workouts/exercise_catalog_provider.dart';
import 'package:pipos_fitness/models/exercise.dart';

void main() {
  group('exerciseName', () {
    test('returns name from catalog when present', () {
      final catalog = {
        'bench-press': const Exercise(
          id: 'bench-press',
          slug: 'bench-press',
          name: 'Bench Press',
          difficulty: 3,
          place: 'gym',
        ),
      };
      expect(exerciseName(catalog, 'bench-press'), 'Bench Press');
    });

    test('returns exerciseId when not in catalog', () {
      final catalog = <String, Exercise>{};
      expect(exerciseName(catalog, 'unknown-exercise'), 'unknown-exercise');
    });

    test('returns exerciseId when catalog is null', () {
      expect(exerciseName(null, 'some-id'), 'some-id');
    });
  });
}
