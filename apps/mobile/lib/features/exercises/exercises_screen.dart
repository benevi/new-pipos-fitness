/// Biblioteca por músculo (ADR-0014, Fase 3a; CUJ-12 en docs/CUJS.md).
///
/// Plan › «Ver ejercicios por músculo» abre **Ejercicios**, con dos vistas:
/// - **Cuerpo**: figura propia, delante y detrás; cada región es un botón.
/// - **Lista**: los 19 músculos agrupados por grupo de volumen (alternativa
///   accesible a la figura).
///
/// Al tocar un músculo se ven los ejercicios que lo trabajan como principal,
/// con tu material (o todo el catálogo), ordenados por nivel; cada uno abre
/// su ficha. Tres toques desde Plan hasta cualquier ficha.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/tokens.dart';
import '../../data/pipos_api.dart';
import '../../l10n/app_localizations.dart';
import '../../models/enums.dart';
import '../../models/plan.dart' show Paginated;
import '../../models/progress.dart';
import '../../shared/widgets.dart';
import '../exercise/exercise_detail_screen.dart';
import '../onboarding/onboarding_controller.dart' show profileProvider;
import 'body_figure.dart';
import 'body_geometry.dart';
import 'muscle_groups.dart';

/// Ruta de la biblioteca (rama de Plan, conserva la barra inferior).
const exercisesLocation = '/plan/exercises';

String muscleExercisesLocation(Muscle m) => '$exercisesLocation/${m.wire}';

/// Estilo de las regiones en la biblioteca: todas iguales (son botones).
RegionStyle libraryRegionStyle(ColorScheme scheme) => RegionStyle(
  fill: scheme.primaryContainer,
  pattern: RegionPattern.solid,
  ink: scheme.primary,
);

String sideLabel(AppLocalizations l10n, BodySide side) =>
    side == BodySide.front ? l10n.exercisesFront : l10n.exercisesBack;

class ExercisesScreen extends StatelessWidget {
  const ExercisesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.exercisesTitle),
          bottom: TabBar(
            tabs: [
              Tab(
                key: const Key('exercises-tab-body'),
                text: l10n.exercisesTabBody,
              ),
              Tab(
                key: const Key('exercises-tab-list'),
                text: l10n.exercisesTabList,
              ),
            ],
          ),
        ),
        body: const TabBarView(children: [_BodyView(), _MuscleListView()]),
      ),
    );
  }
}

void _openMuscle(BuildContext context, Muscle m) =>
    context.go(muscleExercisesLocation(m));

class _BodyView extends StatelessWidget {
  const _BodyView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final style = libraryRegionStyle(theme.colorScheme);
    Widget figure(BodySide side) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          sideLabel(l10n, side),
          textAlign: TextAlign.center,
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        BodyFigure(
          key: Key('body-figure-${side.name}'),
          side: side,
          styleFor: (_) => style,
          labelFor: (r) => l10n.exercisesRegionLabel(
            l10n.muscleLabel(r.muscle.wire),
            sideLabel(l10n, r.side),
          ),
          onRegionTap: (r) => _openMuscle(context, r.muscle),
        ),
      ],
    );
    return ListView(
      key: const Key('exercises-body'),
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text(l10n.exercisesBodyHint, style: theme.textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: figure(BodySide.front)),
            const SizedBox(width: AppSpacing.lg),
            Expanded(child: figure(BodySide.back)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(l10n.exercisesListAlternative, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _MuscleListView extends StatelessWidget {
  const _MuscleListView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ListView(
      key: const Key('exercises-list'),
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        for (final section in muscleSections())
          SectionCard(
            key: Key('muscle-section-${section.group?.wire ?? 'other'}'),
            title: section.group == null
                ? l10n.exercisesOtherMuscles
                : l10n.groupLabel(section.group!.wire),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (section.group == null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Text(
                      l10n.exercisesOtherMusclesNote,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                for (final m in section.muscles)
                  ListTile(
                    key: Key('muscle-list-${m.wire}'),
                    contentPadding: EdgeInsets.zero,
                    minTileHeight: AppSpacing.xxl,
                    title: Text(l10n.muscleLabel(m.wire)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openMuscle(context, m),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Consulta de la lista de un músculo: con el material del usuario (lista
/// ordenada, para que el registro tenga igualdad por valor) o, con `null`,
/// todo el catálogo.
typedef MuscleQuery = ({Muscle muscle, String? equipment});

final muscleExercisesProvider = FutureProvider.autoDispose
    .family<Paginated<ExerciseSummary>, MuscleQuery>((ref, q) {
      final equipment = q.equipment == null
          ? null
          : [
              for (final e in Equipment.values)
                if (q.equipment!.split(',').contains(e.wire)) e,
            ];
      return ref
          .watch(catalogApiProvider)
          .exercisesByMuscle(q.muscle, equipment: equipment);
    });

class MuscleExercisesScreen extends ConsumerStatefulWidget {
  const MuscleExercisesScreen({super.key, required this.muscle});

  final Muscle muscle;

  /// Músculo de la ruta (`/plan/exercises/:muscle`); null si no existe.
  static Muscle? parse(String? wire) {
    for (final m in Muscle.values) {
      if (m.wire == wire) return m;
    }
    return null;
  }

  @override
  ConsumerState<MuscleExercisesScreen> createState() =>
      _MuscleExercisesScreenState();
}

class _MuscleExercisesScreenState extends ConsumerState<MuscleExercisesScreen> {
  bool _allCatalog = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muscle = widget.muscle;
    final name = l10n.muscleLabel(muscle.wire);
    final profile = ref.watch(profileProvider);
    // Sin perfil legible (p. ej. sin red) no se adivina el material: todo el
    // catálogo, y el interruptor no se puede apagar.
    final myEquipment = profile.valueOrNull?.equipment;
    final all = _allCatalog || (!profile.isLoading && myEquipment == null);
    final query = (
      muscle: muscle,
      equipment: all ? null : wiresOf(myEquipment ?? const []),
    );
    final list = profile.isLoading
        ? const AsyncLoading<Paginated<ExerciseSummary>>()
        : ref.watch(muscleExercisesProvider(query));

    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: ListView(
        key: const Key('muscle-exercises'),
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(
            l10n.muscleExercisesIntro(name),
            style: theme.textTheme.bodyMedium,
          ),
          SwitchListTile(
            key: const Key('library-all-catalog'),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.muscleExercisesAllCatalog),
            subtitle: Text(
              all
                  ? l10n.muscleExercisesAllCatalogOn
                  : l10n.muscleExercisesAllCatalogOff,
            ),
            value: all,
            onChanged: myEquipment == null
                ? null
                : (v) => setState(() => _allCatalog = v),
          ),
          const Divider(),
          ...list.when(
            loading: () => [const LoadingView()],
            error: (e, _) => [
              ErrorView(
                error: e,
                onRetry: () => ref.invalidate(muscleExercisesProvider(query)),
              ),
            ],
            data: (page) => page.items.isEmpty
                ? [
                    EmptyState(
                      key: const Key('muscle-exercises-empty'),
                      icon: Icons.fitness_center,
                      title: l10n.muscleExercisesEmptyTitle,
                      body: all
                          ? l10n.muscleExercisesEmptyAll
                          : l10n.muscleExercisesEmptyMine,
                      actionLabel: all ? null : l10n.muscleExercisesShowAll,
                      onAction: all
                          ? null
                          : () => setState(() => _allCatalog = true),
                    ),
                  ]
                : _items(context, page.items),
          ),
        ],
      ),
    );
  }

  /// Ejercicios por nivel (ya vienen ordenados), con un encabezado por nivel.
  List<Widget> _items(BuildContext context, List<ExerciseSummary> items) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    TrainingLevel? level;
    return [
      for (final e in items) ...[
        if (e.minLevel != level) ...[
          Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.md,
              bottom: AppSpacing.xs,
            ),
            child: Semantics(
              header: true,
              child: Text(
                l10n.levelLabel((level = e.minLevel).wire),
                key: Key('library-level-${e.minLevel.wire}'),
                style: theme.textTheme.titleSmall,
              ),
            ),
          ),
        ],
        Card(
          child: ListTile(
            key: Key('library-exercise-${e.slug}'),
            minTileHeight: AppSpacing.xxl + AppSpacing.md,
            title: Text(e.localizedName(lang)),
            subtitle: Text(
              e.equipment.map((q) => l10n.equipmentLabel(q.wire)).join(', '),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => openExerciseDetail(context, e.id),
          ),
        ),
      ],
    ];
  }
}

/// Material en forma estable para la clave del proveedor.
String wiresOf(Iterable<Equipment> equipment) => [
  for (final e in Equipment.values)
    if (equipment.contains(e)) e.wire,
].join(',');
