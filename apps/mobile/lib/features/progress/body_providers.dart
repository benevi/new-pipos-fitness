/// Medidas corporales (idea 7, ADR-0013; CUJ-10). Datos de salud: requieren
/// el ámbito del consentimiento (`weight` para el peso, `body_measurements`
/// para los perímetros). Las altas y bajas van por la cola offline.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/tokens.dart';
import '../../core/api/api_failure.dart';
import '../../core/offline/app_database.dart';
import '../../core/offline/mutation_sender.dart';
import '../../core/offline/offline_providers.dart';
import '../../data/pipos_api.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/failure_messages.dart';
import '../../models/body.dart';
import '../../models/enums.dart';
import '../../models/profile.dart';
import '../onboarding/onboarding_controller.dart';
import '../settings/settings_providers.dart';

/// Evolución corporal (`GET /progress/body`), con la última copia en caché.
final bodyProgressProvider = FutureProvider.autoDispose<BodyProgress>((
  ref,
) async {
  final cache = ref.read(cacheStoreProvider);
  try {
    final body = await ref.watch(bodyApiProvider).getBodyProgress();
    await cache.write(CacheKeys.bodyProgress, body.toJson());
    return body;
  } on ApiFailure catch (f) {
    if (!f.isConnectivity && f.type != ApiFailureType.server) rethrow;
    final cached = await cache.read(CacheKeys.bodyProgress);
    if (cached == null) rethrow;
    return BodyProgress.fromJson(cached.json);
  }
});

/// Medidas guardadas en la API (último año), con respaldo en caché.
final measurementsProvider =
    FutureProvider.autoDispose<List<BodyMeasurementRecord>>((ref) async {
      final cache = ref.read(cacheStoreProvider);
      try {
        final list = await ref.watch(bodyApiProvider).listMeasurements();
        await cache.write(CacheKeys.measurements, list.toJson());
        return list.items;
      } on ApiFailure catch (f) {
        if (!f.isConnectivity && f.type != ApiFailureType.server) rethrow;
        final cached = await cache.read(CacheKeys.measurements);
        if (cached == null) rethrow;
        return BodyMeasurementList.fromJson(cached.json).items;
      }
    });

/// Altas y bajas de medidas aún sin confirmar: fecha → medida (null = se
/// está borrando).
final pendingMeasurementsProvider =
    StreamProvider.autoDispose<Map<String, BodyMeasurement?>>(
      (ref) => ref
          .watch(syncServiceProvider)
          .watchMutations(MutationKeys.measurementPrefix)
          .map(
            (rows) => {
              for (final r in rows)
                r.mutationKey.substring(
                  MutationKeys.measurementPrefix.length,
                ): r.kind == MutationKind.measurementPut
                    ? BodyMeasurement.fromJson(
                        (jsonDecode(r.payload) as Map).cast<String, dynamic>(),
                      )
                    : null,
            },
          ),
    );

/// Medidas tal como se muestran: las de la API con las pendientes encima,
/// de la más reciente a la más antigua.
List<({BodyMeasurement measurement, bool pending})> mergeMeasurements(
  List<BodyMeasurementRecord> server,
  Map<String, BodyMeasurement?> pending,
) {
  final byDate = <String, ({BodyMeasurement measurement, bool pending})>{
    for (final r in server)
      r.measurement.measuredOn: (measurement: r.measurement, pending: false),
  };
  pending.forEach((date, m) {
    if (m == null) {
      byDate.remove(date);
    } else {
      byDate[date] = (measurement: m, pending: true);
    }
  });
  final list = byDate.values.toList()
    ..sort(
      (a, b) => b.measurement.measuredOn.compareTo(a.measurement.measuredOn),
    );
  return list;
}

/// Pide el consentimiento de salud con el texto vigente (que nombra los
/// perímetros y las estimaciones). Devuelve true si se concedió.
Future<bool> askHealthConsent(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final locale = Localizations.localeOf(context);
  final messenger = ScaffoldMessenger.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.onboardingConsentTitle),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.healthConsentText, key: const Key('consent-text')),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.onboardingConsentVersion(healthConsentPolicyVersion),
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          key: const Key('consent-accept'),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(l10n.onboardingConsentAccept),
        ),
      ],
    ),
  );
  if (ok != true) return false;
  try {
    await ref
        .read(profileApiProvider)
        .grantHealthConsent(
          version: healthConsentPolicyVersion,
          locale: locale.languageCode == 'en' ? AppLocale.en : AppLocale.es,
        );
    ref.invalidate(healthConsentProvider);
    ref.invalidate(profileProvider);
    ref.invalidate(bodyProgressProvider);
    return true;
  } catch (e) {
    final f = ApiFailure.from(e);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          f.isConnectivity ? l10n.errorOfflineAction : f.localized(l10n),
        ),
      ),
    );
    return false;
  }
}

/// ¿El consentimiento permite registrar este campo?
bool consentAllows(HealthConsentStatus? consent, BodyField field) =>
    consent?.covers(field.scope) ?? false;
