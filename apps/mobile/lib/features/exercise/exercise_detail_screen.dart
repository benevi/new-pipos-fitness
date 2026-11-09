/// Ficha del ejercicio (CUJ-11, ADR-0014; docs/UX_MOVIL.md).
///
/// Qué es el movimiento, qué trabaja (músculos principales y secundarios),
/// claves técnicas, errores comunes, material y nivel mínimo. Las zonas a
/// vigilar solo aparecen si el usuario dio su consentimiento de salud para
/// las limitaciones y alguna coincide con las `riskTags` del ejercicio.
///
/// Sin red: abre la última copia guardada (las del plan vigente y de la
/// sesión de hoy se precargan); sin copia, «Necesitas conexión…».
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/tokens.dart';
import '../../core/api/api_failure.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/failure_messages.dart';
import '../../models/enums.dart';
import '../../models/exercise.dart';
import '../../models/profile.dart';
import '../../shared/widgets.dart';
import '../onboarding/onboarding_controller.dart' show profileProvider;
import '../onboarding/profile_draft.dart' show PickedExercise, ProfilePick;
import '../setup/setup_provider.dart';
import 'exercise_providers.dart';
import 'exercise_video.dart';

/// Ruta de la ficha (`/exercise/:id`, id o slug).
String exerciseDetailLocation(String idOrSlug) =>
    '/exercise/${Uri.encodeComponent(idOrSlug)}';

/// Abre la ficha. Desde una hoja o diálogo ([fromModal]) se apila encima con
/// el `Navigator` raíz para no quedar debajo del modal; si no, por GoRouter.
void openExerciseDetail(
  BuildContext context,
  String idOrSlug, {
  bool fromModal = false,
}) {
  if (fromModal) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (_) => ExerciseDetailScreen(idOrSlug: idOrSlug),
      ),
    );
  } else {
    context.push(exerciseDetailLocation(idOrSlug));
  }
}

class ExerciseDetailScreen extends ConsumerWidget {
  const ExerciseDetailScreen({super.key, required this.idOrSlug});

  final String idOrSlug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final detail = ref.watch(exerciseDetailProvider(idOrSlug));
    final lang = Localizations.localeOf(context).languageCode;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          detail.valueOrNull?.value.localizedName(lang) ??
              l10n.exerciseDetailTitle,
        ),
      ),
      body: SafeArea(
        child: detail.when(
          loading: () => const LoadingView(),
          error: (e, _) {
            final failure = ApiFailure.from(e);
            final offline =
                failure.isConnectivity || failure.type == ApiFailureType.server;
            return ErrorView(
              key: const Key('exercise-detail-error'),
              error: e,
              message: offline
                  ? l10n.exerciseDetailNeedsConnection
                  : failure.statusCode == 404
                  ? l10n.exerciseDetailNotFound
                  : null,
              onRetry: failure.statusCode == 404
                  ? null
                  : () => ref.invalidate(exerciseDetailProvider(idOrSlug)),
            );
          },
          data: (cached) => _DetailBody(
            detail: cached.value,
            savedAt: cached.fromCache ? cached.savedAt : null,
          ),
        ),
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.detail, this.savedAt});

  final ExerciseDetail detail;

  /// Momento de la copia en caché (solo si se abre sin red).
  final DateTime? savedAt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final primary = detail.musclesWith(MuscleRole.primary);
    final secondary = detail.musclesWith(MuscleRole.secondary);
    final description = detail.descriptionEs?.trim() ?? '';
    // El perfil puede no estar disponible (sin red): entonces no se muestran
    // las zonas a vigilar, nunca se adivinan.
    final profile = ref.watch(profileProvider).valueOrNull;
    final watchZones = zonesToWatch(detail, profile);
    final video = detail.primaryVideo;
    final lang = Localizations.localeOf(context).languageCode;

    return ListView(
      key: const Key('exercise-detail'),
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        if (savedAt != null)
          NoticeBanner(
            icon: Icons.cloud_off_outlined,
            text: l10n.cachedDataNotice(l10n.dateTime(savedAt!)),
          ),
        if (description.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text(
              description,
              key: const Key('exercise-description'),
              style: theme.textTheme.bodyLarge,
            ),
          ),
        // Vídeo revisado (ADR-0014, Fase 4): sin vídeo, ni botón ni hueco.
        if (video != null)
          Padding(
            key: const Key('exercise-video'),
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExerciseVideoButton(
                  idOrSlug: detail.id,
                  exerciseName: detail.localizedName(lang),
                  video: video,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.exerciseVideoChannel(video.channelName),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        SectionCard(
          title: l10n.exerciseDetailMuscles,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MuscleGroup(
                key: const Key('exercise-primary-muscles'),
                label: l10n.exerciseDetailPrimary,
                muscles: primary,
                emphasis: true,
              ),
              if (secondary.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                _MuscleGroup(
                  key: const Key('exercise-secondary-muscles'),
                  label: l10n.exerciseDetailSecondary,
                  muscles: secondary,
                  emphasis: false,
                ),
              ],
            ],
          ),
        ),
        if (detail.cuesEs.isNotEmpty)
          SectionCard(
            title: l10n.exerciseDetailCues,
            child: _Bullets(
              key: const Key('exercise-cues'),
              lines: detail.cuesEs,
              icon: Icons.check_circle_outline,
            ),
          ),
        if (detail.mistakesEs.isNotEmpty)
          SectionCard(
            title: l10n.exerciseDetailMistakes,
            child: _Bullets(
              key: const Key('exercise-mistakes'),
              lines: detail.mistakesEs,
              icon: Icons.highlight_off,
            ),
          ),
        SectionCard(
          title: l10n.exerciseDetailRequirements,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Fact(
                key: const Key('exercise-equipment'),
                label: l10n.exerciseDetailEquipment,
                value: detail.equipment
                    .map((e) => l10n.equipmentLabel(e.wire))
                    .join(', '),
              ),
              const SizedBox(height: AppSpacing.sm),
              _Fact(
                key: const Key('exercise-level'),
                label: l10n.exerciseDetailMinLevel,
                value: l10n.levelLabel(detail.minLevel.wire),
              ),
            ],
          ),
        ),
        // Favoritos y vetados (ADR-0014, Fase 3): solo con el perfil hecho
        // (en el onboarding ya se eligen en su paso) y legible.
        if (profile != null &&
            ref.watch(setupStatusProvider) == SetupStatus.ready)
          _PreferencesCard(detail: detail),
        if (watchZones.isNotEmpty)
          SectionCard(
            key: const Key('exercise-watch-zones'),
            title: l10n.exerciseDetailWatchZones,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final tag in watchZones)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ExcludeSemantics(
                          child: Icon(
                            tag.level == RiskLevel.avoid
                                ? Icons.report_outlined
                                : Icons.warning_amber_outlined,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            l10n.exerciseDetailZoneLine(
                              l10n.zoneLabel(tag.zone.wire),
                              tag.level.wire,
                            ),
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.exerciseDetailWatchZonesNote,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// «Añadir a favoritos» / «No quiero hacerlo»: llevan a la edición del perfil
/// existente con el cambio preparado; no hay otro camino de escritura (al
/// guardar, el perfil regenera el plan).
class _PreferencesCard extends StatelessWidget {
  const _PreferencesCard({required this.detail});

  final ExerciseDetail detail;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    // `go` y no `push`: la edición vive en la rama de Ajustes del shell, y
    // apilarla sobre la ficha duplicaría la página del shell.
    void open({required bool favourite}) => context.go(
      '/settings/profile',
      extra: ProfilePick(
        exercise: PickedExercise(
          slug: detail.slug,
          name: detail.localizedName(lang),
        ),
        favourite: favourite,
      ),
    );
    const buttonSize = Size(0, AppSpacing.xxl);
    return SectionCard(
      key: const Key('exercise-preferences'),
      title: l10n.exerciseDetailPreferences,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            key: const Key('exercise-add-favourite'),
            style: OutlinedButton.styleFrom(minimumSize: buttonSize),
            icon: const Icon(Icons.star_outline),
            label: Text(l10n.exerciseDetailAddFavourite),
            onPressed: () => open(favourite: true),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            key: const Key('exercise-ban'),
            style: OutlinedButton.styleFrom(minimumSize: buttonSize),
            icon: const Icon(Icons.block),
            label: Text(l10n.exerciseDetailBan),
            onPressed: () => open(favourite: false),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.exerciseDetailPreferencesNote,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Zonas a vigilar: `riskTags` del ejercicio que coinciden con las
/// limitaciones del usuario, solo si su consentimiento de salud cubre las
/// limitaciones (RGPD art. 9). Las de «evitar» primero.
List<ExerciseRiskTag> zonesToWatch(
  ExerciseDetail detail,
  ProfileResponse? profile,
) {
  if (profile == null) return const [];
  if (!profile.healthConsent.covers(HealthDataScope.limitations)) {
    return const [];
  }
  final limited = profile.limitations.toSet();
  final tags = [
    for (final t in detail.riskTags)
      if (limited.contains(t.zone)) t,
  ];
  tags.sort((a, b) {
    if (a.level == b.level) return 0;
    return a.level == RiskLevel.avoid ? -1 : 1;
  });
  return tags;
}

class _MuscleGroup extends StatelessWidget {
  const _MuscleGroup({
    super.key,
    required this.label,
    required this.muscles,
    required this.emphasis,
  });

  final String label;
  final List<Muscle> muscles;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final names = [for (final m in muscles) l10n.muscleLabel(m.wire)];
    return MergeSemantics(
      child: Semantics(
        label: '$label: ${names.join(', ')}',
        excludeSemantics: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.labelLarge),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                for (final name in names)
                  Chip(
                    label: Text(name),
                    backgroundColor: emphasis
                        ? theme.colorScheme.primaryContainer
                        : null,
                    labelStyle: emphasis
                        ? TextStyle(color: theme.colorScheme.onPrimaryContainer)
                        : null,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Bullets extends StatelessWidget {
  const _Bullets({super.key, required this.lines, required this.icon});

  final List<String> lines;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(line, style: theme.textTheme.bodyMedium)),
              ],
            ),
          ),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelLarge),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

/// Nombre de un ejercicio que abre su ficha: área táctil ≥ 48 dp y TalkBack
/// lee «Ver ficha de …». [header] lo marca como encabezado (tarjeta de Hoy).
class ExerciseNameLink extends StatelessWidget {
  const ExerciseNameLink({
    super.key,
    required this.idOrSlug,
    required this.name,
    this.style,
    this.header = false,
    this.fromModal = false,
  });

  final String idOrSlug;
  final String name;
  final TextStyle? style;
  final bool header;
  final bool fromModal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Semantics(
      header: header,
      button: true,
      label: l10n.exerciseDetailOpen(name),
      excludeSemantics: true,
      child: InkWell(
        key: Key('exercise-link-$idOrSlug'),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: () =>
            openExerciseDetail(context, idOrSlug, fromModal: fromModal),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSpacing.xxl),
          child: Row(
            children: [
              Flexible(child: Text(name, style: style)),
              const SizedBox(width: AppSpacing.xs),
              Icon(
                Icons.info_outline,
                size: AppSpacing.md + AppSpacing.xs,
                color: theme.colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
