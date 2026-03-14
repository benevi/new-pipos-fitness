import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Search and filter state for the exercise catalog. All optional.
class ExerciseFiltersState {
  const ExerciseFiltersState({
    this.search = '',
    this.difficulty,
    this.place,
    this.muscleId,
  });

  final String search;
  final int? difficulty;
  final String? place;
  final String? muscleId;

  ExerciseFiltersState copyWith({
    String? search,
    int? difficulty,
    String? place,
    String? muscleId,
    bool clearDifficulty = false,
    bool clearPlace = false,
    bool clearMuscleId = false,
  }) {
    return ExerciseFiltersState(
      search: search ?? this.search,
      difficulty: clearDifficulty ? null : (difficulty ?? this.difficulty),
      place: clearPlace ? null : (place ?? this.place),
      muscleId: clearMuscleId ? null : (muscleId ?? this.muscleId),
    );
  }

  Map<String, String> toQueryParams(int page, int limit) {
    final map = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (search.trim().isNotEmpty) map['search'] = search.trim();
    if (difficulty != null) map['difficulty'] = difficulty.toString();
    if (place != null && place!.isNotEmpty) map['place'] = place!;
    if (muscleId != null && muscleId!.isNotEmpty) map['muscleId'] = muscleId!;
    return map;
  }
}

final exerciseFiltersProvider =
    NotifierProvider<ExerciseFiltersNotifier, ExerciseFiltersState>(
  ExerciseFiltersNotifier.new,
);

class ExerciseFiltersNotifier extends Notifier<ExerciseFiltersState> {
  @override
  ExerciseFiltersState build() => const ExerciseFiltersState();

  void setSearch(String value) {
    state = state.copyWith(search: value);
  }

  void setDifficulty(int? value) {
    state = state.copyWith(difficulty: value, clearDifficulty: value == null);
  }

  void setPlace(String? value) {
    state = state.copyWith(place: value, clearPlace: value == null);
  }

  void setMuscleId(String? value) {
    state = state.copyWith(muscleId: value, clearMuscleId: value == null);
  }

  void clear() {
    state = const ExerciseFiltersState();
  }
}
