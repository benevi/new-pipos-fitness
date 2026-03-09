/// Provider Responsibility
///
/// Fetches current training plan on first access. Kept alive across tab
/// switches to avoid redundant network calls. Use [refresh()] or [generate()]
/// to update data explicitly.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../models/training_plan.dart';

final trainingPlanProvider =
    AsyncNotifierProvider<TrainingPlanNotifier, TrainingPlan?>(
  TrainingPlanNotifier.new,
);

class TrainingPlanNotifier extends AsyncNotifier<TrainingPlan?> {
  @override
  Future<TrainingPlan?> build() async {
    ref.keepAlive();
    return _fetchCurrent();
  }

  Future<TrainingPlan?> _fetchCurrent() async {
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get('/training-plans/current');
      return TrainingPlan.fromJson(response.data as Map<String, dynamic>);
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
      final response = await api.post('/training-plans/generate');
      state = AsyncData(
        TrainingPlan.fromJson(response.data as Map<String, dynamic>),
      );
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }
}
