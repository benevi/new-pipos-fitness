import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../models/nutrition_plan.dart';

final nutritionVersionsProvider =
    AsyncNotifierProvider<NutritionVersionsNotifier, List<NutritionVersionSummary>>(
  NutritionVersionsNotifier.new,
);

class NutritionVersionsNotifier
    extends AsyncNotifier<List<NutritionVersionSummary>> {
  @override
  Future<List<NutritionVersionSummary>> build() async {
    ref.keepAlive();
    return _fetch();
  }

  Future<List<NutritionVersionSummary>> _fetch() async {
    final api = ref.read(apiClientProvider);
    final response = await api.get('/nutrition-plans/versions');
    final list = response.data as List<dynamic>;
    return list
        .map((e) =>
            NutritionVersionSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _fetch());
  }
}
