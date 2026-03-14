import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../models/exercise.dart';
import 'exercise_filters_provider.dart';

class FilteredExercisesState {
  const FilteredExercisesState({
    this.items = const [],
    this.totalCount = 0,
    this.page = 0,
    this.isLoadingMore = false,
  });

  final List<Exercise> items;
  final int totalCount;
  final int page;
  final bool isLoadingMore;

  bool get hasMore => items.length < totalCount;

  FilteredExercisesState copyWith({
    List<Exercise>? items,
    int? totalCount,
    int? page,
    bool? isLoadingMore,
  }) {
    return FilteredExercisesState(
      items: items ?? this.items,
      totalCount: totalCount ?? this.totalCount,
      page: page ?? this.page,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

final filteredExercisesProvider =
    AsyncNotifierProvider<FilteredExercisesNotifier, FilteredExercisesState>(
  FilteredExercisesNotifier.new,
);

class FilteredExercisesNotifier extends AsyncNotifier<FilteredExercisesState> {
  static const int _pageSize = 20;

  @override
  Future<FilteredExercisesState> build() async {
    ref.watch(exerciseFiltersProvider);
    return _fetchPage(1);
  }

  Future<FilteredExercisesState> _fetchPage(int page) async {
    final api = ref.read(apiClientProvider);
    final filters = ref.read(exerciseFiltersProvider);
    final query = filters.toQueryParams(page, _pageSize);

    final response = await api.get<Map<String, dynamic>>(
      '/exercises',
      queryParameters: query,
    );
    final data = response.data!;
    final list = (data['items'] as List<dynamic>)
        .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
        .toList();
    final totalCount = data['totalCount'] as int;
    return FilteredExercisesState(
      items: list,
      totalCount: totalCount,
      page: page,
      isLoadingMore: false,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _fetchPage(1));
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final api = ref.read(apiClientProvider);
      final filters = ref.read(exerciseFiltersProvider);
      final nextPage = current.page + 1;
      final query = filters.toQueryParams(nextPage, _pageSize);
      final response = await api.get<Map<String, dynamic>>(
        '/exercises',
        queryParameters: query,
      );
      final data = response.data!;
      final list = (data['items'] as List<dynamic>)
          .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
          .toList();
      final totalCount = data['totalCount'] as int;
      state = AsyncData(FilteredExercisesState(
        items: [...current.items, ...list],
        totalCount: totalCount,
        page: nextPage,
        isLoadingMore: false,
      ));
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }
}
