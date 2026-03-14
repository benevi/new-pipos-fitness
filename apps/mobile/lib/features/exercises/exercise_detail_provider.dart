import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../models/exercise_detail.dart';

final exerciseDetailProvider =
    AsyncNotifierProvider.family<ExerciseDetailNotifier, ExerciseDetail?, String>(
  ExerciseDetailNotifier.new,
);

class ExerciseDetailNotifier extends FamilyAsyncNotifier<ExerciseDetail?, String> {
  @override
  Future<ExerciseDetail?> build(String id) async {
    if (id.isEmpty) return null;
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get<Map<String, dynamic>>('/exercises/$id');
      final data = response.data;
      if (data == null) return null;
      return ExerciseDetail.fromJson(data);
    } catch (_) {
      rethrow;
    }
  }
}
