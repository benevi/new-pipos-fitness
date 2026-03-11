import 'package:flutter/material.dart';
import '../../../app/theme.dart';

class DaySelector extends StatelessWidget {
  final int dayCount;
  final int selectedDay;
  final ValueChanged<int> onDaySelected;

  const DaySelector({
    super.key,
    required this.dayCount,
    required this.selectedDay,
    required this.onDaySelected,
  });

  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    if (dayCount == 0) return const SizedBox.shrink();

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: dayCount,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final isSelected = index == selectedDay;
          final label = index < _dayLabels.length
              ? _dayLabels[index]
              : 'D${index + 1}';
          return ChoiceChip(
            label: Text(label),
            selected: isSelected,
            selectedColor: AppColors.accent,
            backgroundColor: AppColors.surface,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            side: BorderSide.none,
            onSelected: (_) => onDaySelected(index),
          );
        },
      ),
    );
  }
}
