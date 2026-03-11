import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../models/nutrition_plan.dart';

class NutritionVersionsSheet extends StatelessWidget {
  final List<NutritionVersionSummary> versions;

  const NutritionVersionsSheet({super.key, required this.versions});

  static void show(BuildContext context, List<NutritionVersionSummary> versions) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => NutritionVersionsSheet(versions: versions),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Plan Versions', style: tt.titleMedium),
          const SizedBox(height: AppSpacing.md),
          if (versions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(
                child: Text('No versions available',
                    style: tt.bodyMedium
                        ?.copyWith(color: AppColors.onSurfaceVariant)),
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: versions.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final v = versions[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.accent.withValues(alpha: 0.15),
                      child: Text(
                        'v${v.version}',
                        style: tt.bodySmall?.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text('Version ${v.version}', style: tt.bodyMedium),
                    subtitle: Text(
                      'Engine ${v.engineVersion}',
                      style: tt.bodySmall
                          ?.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                    trailing: Text(
                      _formatDate(v.createdAt),
                      style: tt.bodySmall
                          ?.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}
