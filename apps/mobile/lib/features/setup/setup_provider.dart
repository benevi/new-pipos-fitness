/// Puerta de onboarding: ¿el usuario autenticado ya tiene plan?
///
/// - Hay plan en caché local → `ready` al instante (la app abre en modo
///   avión) y se revalida en segundo plano.
/// - `GET /plans/current` 404 → `needsOnboarding`.
/// - Sin red y sin caché → `ready`: las pestañas muestran su estado offline
///   (no se bloquea al usuario en el cuestionario por no tener cobertura).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_failure.dart';
import '../../core/offline/offline_providers.dart';
import '../../data/pipos_api.dart';
import '../auth/auth_provider.dart';

enum SetupStatus { checking, needsOnboarding, ready }

class SetupNotifier extends StateNotifier<SetupStatus> {
  SetupNotifier(this._ref, {required bool authenticated})
    : super(SetupStatus.checking) {
    if (authenticated) _check();
  }

  final Ref _ref;

  Future<void> _check() async {
    final cache = _ref.read(cacheStoreProvider);
    final cached = await cache.read(CacheKeys.currentPlan);
    if (!mounted) return;
    if (cached != null) state = SetupStatus.ready;
    try {
      final plan = await _ref.read(planApiProvider).getCurrentPlan();
      if (!mounted) return;
      if (plan == null) {
        await cache.remove(CacheKeys.currentPlan);
        if (mounted) state = SetupStatus.needsOnboarding;
        return;
      }
      await cache.write(CacheKeys.currentPlan, plan.toJson());
      if (mounted) state = SetupStatus.ready;
    } catch (e) {
      if (!mounted) return;
      final f = ApiFailure.from(e);
      if (f.type == ApiFailureType.unauthorized) return;
      state = SetupStatus.ready;
    }
  }

  /// El cuestionario terminó y hay plan.
  void markReady() => state = SetupStatus.ready;

  /// Volver a pasar por el cuestionario (p. ej. si la API dice que no hay
  /// plan).
  void requireOnboarding() => state = SetupStatus.needsOnboarding;
}

final setupStatusProvider = StateNotifierProvider<SetupNotifier, SetupStatus>((
  ref,
) {
  final authenticated = ref.watch(
    authProvider.select((s) => s.isAuthenticated),
  );
  return SetupNotifier(ref, authenticated: authenticated);
});
