import 'package:flutter/material.dart';
import '../../../app/theme.dart';

class FatigueBanner extends StatelessWidget {
  final bool detected;
  const FatigueBanner({super.key, required this.detected});

  @override
  Widget build(BuildContext context) {
    final bgColor = detected
        ? AppColors.error.withOpacity(0.12)
        : AppColors.success.withOpacity(0.12);
    final fgColor = detected ? AppColors.error : AppColors.success;
    final icon =
        detected ? Icons.warning_amber_rounded : Icons.shield_outlined;
    final text = detected
        ? 'Fatigue detected — consider reducing volume or taking a deload.'
        : 'No fatigue detected — you are recovering well.';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Icon(icon, color: fgColor, size: 28),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: fgColor),
            ),
          ),
        ],
      ),
    );
  }
}
