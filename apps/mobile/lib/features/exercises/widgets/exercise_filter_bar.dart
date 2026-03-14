import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme.dart';
import '../../../models/muscle.dart';
import '../../dashboard/muscle_catalog_provider.dart';
import '../exercise_filters_provider.dart';

class ExerciseFilterBar extends ConsumerWidget {
  const ExerciseFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(exerciseFiltersProvider);
    final notifier = ref.read(exerciseFiltersProvider.notifier);
    final muscleCatalogAsync = ref.watch(muscleCatalogProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            onChanged: notifier.setSearch,
            decoration: InputDecoration(
              hintText: 'Search exercises',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: filters.search.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => notifier.setSearch(''),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _PlaceChip(
                  label: 'All',
                  selected: filters.place == null,
                  onTap: () => notifier.setPlace(null),
                ),
                const SizedBox(width: AppSpacing.xs),
                _PlaceChip(
                  label: 'Gym',
                  selected: filters.place == 'gym',
                  onTap: () => notifier.setPlace('gym'),
                ),
                const SizedBox(width: AppSpacing.xs),
                _PlaceChip(
                  label: 'Home',
                  selected: filters.place == 'home',
                  onTap: () => notifier.setPlace('home'),
                ),
                const SizedBox(width: AppSpacing.xs),
                _PlaceChip(
                  label: 'Calisthenics',
                  selected: filters.place == 'calisthenics',
                  onTap: () => notifier.setPlace('calisthenics'),
                ),
                const SizedBox(width: AppSpacing.sm),
                _DifficultyChip(
                  label: 'Difficulty',
                  value: filters.difficulty,
                  onTap: () => _showDifficultyMenu(context, notifier, filters.difficulty),
                ),
                const SizedBox(width: AppSpacing.xs),
                _MuscleChip(
                  muscleId: filters.muscleId,
                  muscleCatalogAsync: muscleCatalogAsync,
                  onTap: () => _showMuscleMenu(context, ref, filters.muscleId),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDifficultyMenu(BuildContext context, ExerciseFiltersNotifier notifier, int? current) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Any'),
              selected: current == null,
              onTap: () {
                notifier.setDifficulty(null);
                Navigator.pop(ctx);
              },
            ),
            for (int i = 1; i <= 5; i++)
              ListTile(
                title: Text('Level $i'),
                selected: current == i,
                onTap: () {
                  notifier.setDifficulty(i);
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showMuscleMenu(BuildContext context, WidgetRef ref, String? currentMuscleId) {
    final catalog = ref.read(muscleCatalogProvider).valueOrNull;
    final notifier = ref.read(exerciseFiltersProvider.notifier);
    if (catalog == null || catalog.isEmpty) {
      showModalBottomSheet<void>(
        context: context,
        builder: (ctx) => const SafeArea(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Text('Could not load muscles'),
          ),
        ),
      );
      return;
    }
    final muscles = catalog.values.toList()..sort((a, b) => a.name.compareTo(b.name));
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.5),
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: const Text('Any muscle'),
                selected: currentMuscleId == null,
                onTap: () {
                  notifier.setMuscleId(null);
                  Navigator.pop(ctx);
                },
              ),
              ...muscles.map((m) => ListTile(
                    title: Text(m.name),
                    selected: currentMuscleId == m.id,
                    onTap: () {
                      notifier.setMuscleId(m.id);
                      Navigator.pop(ctx);
                    },
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceChip extends StatelessWidget {
  const _PlaceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _DifficultyChip extends StatelessWidget {
  const _DifficultyChip({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final int? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(value != null ? '$label: $value' : label),
      selected: value != null,
      onSelected: (_) => onTap(),
    );
  }
}

class _MuscleChip extends StatelessWidget {
  const _MuscleChip({
    required this.muscleId,
    required this.muscleCatalogAsync,
    required this.onTap,
  });

  final String? muscleId;
  final AsyncValue<Map<String, Muscle>> muscleCatalogAsync;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = muscleCatalogAsync.when(
      data: (catalog) {
        if (muscleId == null) return 'Muscle';
        final m = catalog[muscleId];
        return m?.name ?? muscleId!;
      },
      loading: () => 'Muscle',
      error: (_, __) => 'Muscle',
    );
    return FilterChip(
      label: Text(label),
      selected: muscleId != null,
      onSelected: (_) => onTap(),
    );
  }
}
