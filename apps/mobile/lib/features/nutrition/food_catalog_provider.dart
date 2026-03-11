import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../models/food.dart';

final foodCatalogProvider =
    AsyncNotifierProvider<FoodCatalogNotifier, Map<String, Food>>(
  FoodCatalogNotifier.new,
);

class FoodCatalogNotifier extends AsyncNotifier<Map<String, Food>> {
  @override
  Future<Map<String, Food>> build() async {
    ref.keepAlive();
    return _fetchAll();
  }

  Future<Map<String, Food>> _fetchAll() async {
    final api = ref.read(apiClientProvider);
    final response = await api.get('/foods');
    final list = (response.data as List<dynamic>)
        .map((e) => Food.fromJson(e as Map<String, dynamic>))
        .toList();
    return {for (final f in list) f.id: f};
  }
}

String foodName(Map<String, Food>? catalog, String foodId) {
  return catalog?[foodId]?.name ?? foodId;
}
