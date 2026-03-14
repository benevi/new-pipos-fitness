import 'package:flutter/material.dart';
import '../../../app/theme.dart';

class ExerciseMetadataChips extends StatelessWidget {
  const ExerciseMetadataChips({
    super.key,
    this.difficulty,
    this.place,
    this.movementPattern,
  });

  final int? difficulty;
  final String? place;
  final String? movementPattern;

  static String _placeLabel(String? p) {
    if (p == null || p.isEmpty) return '—';
    switch (p.toLowerCase()) {
      case 'gym':
        return 'Gym';
      case 'home':
        return 'Home';
      case 'calisthenics':
        return 'Calisthenics';
      default:
        return p;
    }
  }

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];
    if (difficulty != null) {
      chips.add(_Chip(label: 'Lv.$difficulty'));
    }
    if (place != null && place!.isNotEmpty) {
      chips.add(_Chip(label: _placeLabel(place)));
    }
    if (movementPattern != null && movementPattern!.isNotEmpty) {
      chips.add(_Chip(label: movementPattern!));
    }
    if (chips.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: chips,
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
      ),
    );
  }
}
