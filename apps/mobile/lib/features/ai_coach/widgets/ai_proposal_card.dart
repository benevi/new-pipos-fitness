import 'package:flutter/material.dart';
import '../../../app/theme.dart';

/// Displays an AI proposal with type, summary and status. Display only; no actions.
class AiProposalCard extends StatelessWidget {
  const AiProposalCard({
    super.key,
    required this.proposal,
    this.status,
    this.rejectionReason,
  });

  final Map<String, dynamic> proposal;
  final String? status;
  final String? rejectionReason;

  static String _proposalTypeLabel(String? type) {
    if (type == null) return 'Proposal';
    switch (type) {
      case 'exercise_swap':
        return 'Exercise swap';
      case 'exercise_remove':
        return 'Remove exercise';
      case 'exercise_add':
        return 'Add exercise';
      case 'nutrition_swap':
        return 'Food swap';
      case 'volume_adjustment':
        return 'Volume adjustment';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = proposal['type'] as String?;
    final isValid = status == 'valid';
    final isRejected = status == 'rejected';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.onSurfaceVariant.withValues(alpha: 0.3)
              : Colors.black26,
        ),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                _proposalTypeLabel(type),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(width: AppSpacing.sm),
              if (isValid)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Text(
                    'Valid',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                ),
              if (isRejected)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Text(
                    'Rejected',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
                ),
            ],
          ),
          if (isRejected && rejectionReason != null && rejectionReason!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                rejectionReason!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}
