import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../models/exercise_media.dart';

/// Fetches approved media for an exercise via GET /exercises/:id/media.
/// Decoupled from exercise detail so detail screen stays stable if media fails.
final exerciseMediaProvider =
    AsyncNotifierProvider.family<ExerciseMediaNotifier, List<ExerciseMedia>, String>(
  ExerciseMediaNotifier.new,
);

class ExerciseMediaNotifier extends FamilyAsyncNotifier<List<ExerciseMedia>, String> {
  @override
  Future<List<ExerciseMedia>> build(String exerciseId) async {
    if (exerciseId.isEmpty) return [];
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get<List<dynamic>>('/exercises/$exerciseId/media');
      final list = response.data;
      if (list == null) return [];
      return list
          .map((e) => ExerciseMedia.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      rethrow;
    }
  }
}
