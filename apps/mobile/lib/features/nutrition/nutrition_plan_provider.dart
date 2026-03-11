import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../models/nutrition_plan.dart';

final nutritionPlanProvider =
    AsyncNotifierProvider<NutritionPlanNotifier, NutritionPlan?>(
  NutritionPlanNotifier.new,
);

class NutritionPlanNotifier extends AsyncNotifier<NutritionPlan?> {
  @override
  Future<NutritionPlan?> build() async {
    ref.keepAlive();
    return _fetchCurrent();
  }

  Future<NutritionPlan?> _fetchCurrent() async {
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get('/nutrition-plans/current');
      return NutritionPlan.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _fetchCurrent());
  }

  Future<void> generate() async {
    state = const AsyncLoading();
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.post('/nutrition-plans/generate');
      state = AsyncData(
        NutritionPlan.fromJson(response.data as Map<String, dynamic>),
      );
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }
}
