import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../models/exercise_detail.dart';
import '../dashboard/muscle_catalog_provider.dart';
import 'exercise_detail_provider.dart';
import 'exercise_media_provider.dart';
import 'widgets/exercise_metadata_chips.dart';
import 'widgets/exercise_video_card.dart';

class ExerciseDetailScreen extends ConsumerWidget {
  const ExerciseDetailScreen({super.key, required this.exerciseId});

  final String exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(exerciseDetailProvider(exerciseId));

    return Scaffold(
      appBar: AppBar(title: const Text('Exercise')),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Failed to load exercise',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.error),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () => ref.invalidate(exerciseDetailProvider(exerciseId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (detail) {
          if (detail == null) {
            return const Center(child: Text('Exercise not found'));
          }
          return _ExerciseDetailContent(detail: detail, exerciseId: exerciseId);
        },
      ),
    );
  }
}

class _ExerciseDetailContent extends ConsumerWidget {
  const _ExerciseDetailContent({required this.detail, required this.exerciseId});

  final ExerciseDetail detail;
  final String exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final muscleCatalog = ref.watch(muscleCatalogProvider).valueOrNull;
    final mediaAsync = ref.watch(exerciseMediaProvider(exerciseId));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            detail.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ExerciseMetadataChips(
            difficulty: detail.difficulty,
            place: detail.place,
            movementPattern: detail.movementPattern,
          ),
          if (detail.description != null && detail.description!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Description',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              detail.description!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurface,
                  ),
            ),
          ],
          if (detail.muscles.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Muscles',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: detail.muscles
                  .map((em) => Chip(
                        label: Text(
                          em.muscle?.name ??
                              muscleName(muscleCatalog, em.muscleId),
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Videos',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          mediaAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (_, __) => _MediaErrorCard(
              onRetry: () => ref.invalidate(exerciseMediaProvider(exerciseId)),
            ),
            data: (mediaList) {
              if (mediaList.isEmpty) {
                return _NoVideoCard();
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: mediaList.map((m) => ExerciseVideoCard(media: m)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _NoVideoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surfaceVariant,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: Text(
            'No video available yet',
            style: TextStyle(color: AppColors.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}

class _MediaErrorCard extends StatelessWidget {
  const _MediaErrorCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surfaceVariant,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Couldn\'t load videos',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
