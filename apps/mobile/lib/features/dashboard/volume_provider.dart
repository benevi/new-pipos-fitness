import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../models/volume_metrics.dart';

final volumeProvider =
    AsyncNotifierProvider<VolumeNotifier, VolumeMetrics?>(
  VolumeNotifier.new,
);

class VolumeNotifier extends AsyncNotifier<VolumeMetrics?> {
  @override
  Future<VolumeMetrics?> build() async {
    ref.keepAlive();
    return _fetch();
  }

  Future<VolumeMetrics?> _fetch() async {
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get('/analytics/volume');
      return VolumeMetrics.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _fetch());
  }
}
