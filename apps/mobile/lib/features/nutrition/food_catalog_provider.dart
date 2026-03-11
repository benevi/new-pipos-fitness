import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../models/food.dart';

final foodCatalogProvider =
    AsyncNotifierProvider<FoodCatalogNotifier, Map<String, String>>(
  FoodCatalogNotifier.new,
);

class FoodCatalogNotifier extends AsyncNotifier<Map<String, String>> {
  static const _staleThreshold = Duration(hours: 1);
  DateTime? _lastFetchedAt;

  @override
  Future<Map<String, String>> build() async {
    ref.keepAlive();
    return _fetchAll();
  }

  Future<Map<String, String>> _fetchAll() async {
    final api = ref.read(apiClientProvider);
    final response = await api.get('/foods');
    final list = (response.data as List<dynamic>)
        .map((e) => Food.fromJson(e as Map<String, dynamic>))
        .toList();
    _lastFetchedAt = DateTime.now();
    return {for (final f in list) f.id: f.name};
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _fetchAll());
  }

  /// Refreshes if the cache is older than [_staleThreshold].
  Future<void> refreshIfStale() async {
    if (_lastFetchedAt == null) return;
    if (DateTime.now().difference(_lastFetchedAt!) > _staleThreshold) {
      await refresh();
    }
  }

  bool get isStale {
    if (_lastFetchedAt == null) return false;
    return DateTime.now().difference(_lastFetchedAt!) > _staleThreshold;
  }
}

/// Returns human-readable food name, or a safe fallback for unknown foods.
String foodDisplayName(Map<String, String>? catalog, String foodId) {
  if (catalog != null) {
    final name = catalog[foodId];
    if (name != null) return name;
  }
  return 'Food item';
}
