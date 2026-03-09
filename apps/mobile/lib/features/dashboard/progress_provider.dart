/// Provider Responsibility
///
/// Fetches progress metrics from the API on first access. Data is kept alive
/// for the session duration (keepAlive) so tab switches don't trigger re-fetches.
/// Manual refresh is available via [refresh()].
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../models/progress_metrics.dart';

final progressProvider =
    AsyncNotifierProvider<ProgressNotifier, ProgressMetrics?>(
  ProgressNotifier.new,
);

class ProgressNotifier extends AsyncNotifier<ProgressMetrics?> {
  @override
  Future<ProgressMetrics?> build() async {
    ref.keepAlive();
    return _fetchProgress();
  }

  Future<ProgressMetrics?> _fetchProgress() async {
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get('/analytics/progress');
      return ProgressMetrics.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _fetchProgress());
  }
}
