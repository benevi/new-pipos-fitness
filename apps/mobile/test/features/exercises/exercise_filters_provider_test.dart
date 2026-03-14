import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pipos_fitness/features/exercises/exercise_filters_provider.dart';

void main() {
  group('ExerciseFiltersState', () {
    test('toQueryParams includes page and limit only when no filters', () {
      const state = ExerciseFiltersState();
      final params = state.toQueryParams(1, 20);
      expect(params['page'], '1');
      expect(params['limit'], '20');
      expect(params.containsKey('search'), false);
      expect(params.containsKey('difficulty'), false);
      expect(params.containsKey('place'), false);
      expect(params.containsKey('muscleId'), false);
    });

    test('toQueryParams includes search when non-empty', () {
      const state = ExerciseFiltersState(search: 'squat');
      final params = state.toQueryParams(1, 20);
      expect(params['search'], 'squat');
    });

    test('toQueryParams omits search when empty or whitespace', () {
      expect(const ExerciseFiltersState(search: '').toQueryParams(1, 20).containsKey('search'), false);
      expect(const ExerciseFiltersState(search: '   ').toQueryParams(1, 20).containsKey('search'), false);
    });

    test('toQueryParams includes difficulty and place when set', () {
      const state = ExerciseFiltersState(difficulty: 3, place: 'gym');
      final params = state.toQueryParams(2, 10);
      expect(params['difficulty'], '3');
      expect(params['place'], 'gym');
    });

    test('toQueryParams includes muscleId when set', () {
      const state = ExerciseFiltersState(muscleId: 'chest-1');
      final params = state.toQueryParams(1, 20);
      expect(params['muscleId'], 'chest-1');
    });
  });

  group('ExerciseFiltersNotifier', () {
    test('initial state is empty defaults', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final state = container.read(exerciseFiltersProvider);
      expect(state.search, '');
      expect(state.difficulty, isNull);
      expect(state.place, isNull);
      expect(state.muscleId, isNull);
    });

    test('setSearch updates search', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(exerciseFiltersProvider.notifier).setSearch('press');
      expect(container.read(exerciseFiltersProvider).search, 'press');
    });

    test('setDifficulty updates difficulty', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(exerciseFiltersProvider.notifier).setDifficulty(2);
      expect(container.read(exerciseFiltersProvider).difficulty, 2);
      container.read(exerciseFiltersProvider.notifier).setDifficulty(null);
      expect(container.read(exerciseFiltersProvider).difficulty, isNull);
    });

    test('setPlace and setMuscleId update state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(exerciseFiltersProvider.notifier).setPlace('home');
      expect(container.read(exerciseFiltersProvider).place, 'home');
      container.read(exerciseFiltersProvider.notifier).setMuscleId('m1');
      expect(container.read(exerciseFiltersProvider).muscleId, 'm1');
    });

    test('clear resets all filters', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(exerciseFiltersProvider.notifier).setSearch('x');
      container.read(exerciseFiltersProvider.notifier).setDifficulty(1);
      container.read(exerciseFiltersProvider.notifier).setPlace('gym');
      container.read(exerciseFiltersProvider.notifier).clear();
      final state = container.read(exerciseFiltersProvider);
      expect(state.search, '');
      expect(state.difficulty, isNull);
      expect(state.place, isNull);
    });
  });
}
