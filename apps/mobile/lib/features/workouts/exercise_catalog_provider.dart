import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../models/exercise.dart';

final exerciseCatalogProvider =
    AsyncNotifierProvider<ExerciseCatalogNotifier, Map<String, Exercise>>(
  ExerciseCatalogNotifier.new,
);

class ExerciseCatalogNotifier extends AsyncNotifier<Map<String, Exercise>> {
  @override
  Future<Map<String, Exercise>> build() async {
    ref.keepAlive();
    return _fetchAll();
  }

  Future<Map<String, Exercise>> _fetchAll() async {
    final api = ref.read(apiClientProvider);
    final map = <String, Exercise>{};
    int page = 1;
    const limit = 100;

    while (true) {
      final response = await api.get(
        '/exercises',
        queryParameters: {'page': page, 'limit': limit},
      );
      final data = response.data as Map<String, dynamic>;
      final items = (data['items'] as List<dynamic>)
          .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
          .toList();

      for (final ex in items) {
        map[ex.id] = ex;
      }

      final totalCount = data['totalCount'] as int;
      if (map.length >= totalCount || items.isEmpty) break;
      page++;
    }

    return map;
  }
}

/// Convenience: resolve exercise name from catalog, fallback to exerciseId.
String exerciseName(Map<String, Exercise>? catalog, String exerciseId) {
  return catalog?[exerciseId]?.name ?? exerciseId;
}
