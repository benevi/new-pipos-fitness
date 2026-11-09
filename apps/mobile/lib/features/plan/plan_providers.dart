import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_failure.dart';
import '../../core/offline/offline_providers.dart';
import '../../data/pipos_api.dart';
import '../../models/plan.dart';
import '../exercise/exercise_providers.dart';

/// Plan actual con respaldo en caché (abre en modo avión). `null` = sin plan.
final currentPlanProvider = FutureProvider.autoDispose<Cached<PlanVersion>?>((
  ref,
) async {
  final cache = ref.read(cacheStoreProvider);
  try {
    final plan = await ref.watch(planApiProvider).getCurrentPlan();
    if (plan == null) {
      await cache.remove(CacheKeys.currentPlan);
      return null;
    }
    await cache.write(CacheKeys.currentPlan, plan.toJson());
    // Fichas de los ejercicios del plan vigente, para verlas sin red (CUJ-11).
    unawaited(
      prefetchExerciseDetails(
        ref.read(catalogApiProvider),
        cache,
        planExerciseIds(plan),
        ref.read(clockProvider)(),
      ),
    );
    return Cached(plan);
  } on ApiFailure catch (f) {
    if (!f.isConnectivity && f.type != ApiFailureType.server) rethrow;
    final cached = await cache.read(CacheKeys.currentPlan);
    if (cached == null) rethrow;
    return Cached(
      PlanVersion.fromJson(cached.json),
      savedAt: cached.savedAt,
      fromCache: true,
    );
  }
});

final planVersionsProvider =
    FutureProvider.autoDispose<Paginated<PlanVersionSummary>>(
      (ref) => ref.watch(planApiProvider).listVersions(),
    );

final planVersionProvider = FutureProvider.autoDispose
    .family<PlanVersion, String>(
      (ref, id) => ref.watch(planApiProvider).getVersion(id),
    );

/// Ejercicios del plan: los programados y los fijados en su lugar.
List<String> planExerciseIds(PlanVersion plan) => [
  for (final s in plan.sessions)
    for (final e in s.exercises) ...[e.exerciseId, ?e.pinned?.id],
];
