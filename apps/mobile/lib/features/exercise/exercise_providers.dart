/// Ficha del ejercicio (CUJ-11, ADR-0014): `GET /exercises/:id` con respaldo
/// en la caché local para verla sin red.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_failure.dart';
import '../../core/offline/offline_providers.dart';
import '../../data/pipos_api.dart';
import '../../models/exercise.dart';

/// Cada cuánto se vuelve a descargar una ficha ya guardada al precargar. El
/// catálogo solo cambia con un despliegue (ADR-0005): una semana basta.
const exerciseDetailRefreshAfter = Duration(days: 7);

/// Ficha de un ejercicio por id o slug: de la API (y a la caché) o, sin red
/// o con el servidor caído, la última copia guardada. Sin copia, el fallo
/// llega a la pantalla («Necesitas conexión para ver esta ficha»).
final exerciseDetailProvider = FutureProvider.autoDispose
    .family<Cached<ExerciseDetail>, String>((ref, idOrSlug) async {
      final cache = ref.read(cacheStoreProvider);
      final key = CacheKeys.exercise(idOrSlug);
      try {
        final detail = await ref
            .watch(catalogApiProvider)
            .getExercise(idOrSlug);
        await cache.write(key, detail.toJson());
        return Cached(detail);
      } on ApiFailure catch (f) {
        if (!f.isConnectivity && f.type != ApiFailureType.server) rethrow;
        final saved = await cache.read(key);
        if (saved == null) rethrow;
        return Cached(
          ExerciseDetail.fromJson(saved.json),
          savedAt: saved.savedAt,
          fromCache: true,
        );
      }
    });

/// Guarda en caché las fichas de [exerciseIds] que falten o tengan más de
/// [exerciseDetailRefreshAfter], para abrirlas sin red (plan vigente y
/// sesión de hoy). Nunca falla: es una mejora oportunista; si se corta la
/// red, para y lo intenta la próxima vez.
Future<void> prefetchExerciseDetails(
  CatalogApi api,
  CacheStore cache,
  Iterable<String> exerciseIds,
  DateTime now,
) async {
  try {
    for (final id in exerciseIds.toSet()) {
      final key = CacheKeys.exercise(id);
      final saved = await cache.read(key);
      if (saved != null &&
          now.difference(saved.savedAt) < exerciseDetailRefreshAfter) {
        continue;
      }
      final detail = await api.getExercise(id);
      await cache.write(key, detail.toJson());
    }
  } catch (_) {}
}
