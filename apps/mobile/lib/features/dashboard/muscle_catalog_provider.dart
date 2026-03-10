import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../models/muscle.dart';

final muscleCatalogProvider =
    AsyncNotifierProvider<MuscleCatalogNotifier, Map<String, Muscle>>(
  MuscleCatalogNotifier.new,
);

class MuscleCatalogNotifier extends AsyncNotifier<Map<String, Muscle>> {
  @override
  Future<Map<String, Muscle>> build() async {
    ref.keepAlive();
    return _fetchAll();
  }

  Future<Map<String, Muscle>> _fetchAll() async {
    final api = ref.read(apiClientProvider);
    final response = await api.get('/muscles');
    final list = (response.data as List<dynamic>)
        .map((e) => Muscle.fromJson(e as Map<String, dynamic>))
        .toList();

    return {for (final m in list) m.id: m};
  }
}

String muscleName(Map<String, Muscle>? catalog, String muscleId) {
  return catalog?[muscleId]?.name ?? muscleId;
}
