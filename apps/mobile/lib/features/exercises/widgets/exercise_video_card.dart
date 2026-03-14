import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/theme.dart';
import '../../../models/exercise_media.dart';

class ExerciseVideoCard extends StatelessWidget {
  const ExerciseVideoCard({
    super.key,
    required this.media,
  });

  final ExerciseMedia media;

  static String youtubeWatchUrl(String videoId) {
    return 'https://www.youtube.com/watch?v=$videoId';
  }

  Future<void> _openVideo(BuildContext context) async {
    final uri = Uri.parse(youtubeWatchUrl(media.youtubeVideoId));
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = media.channelName != null && media.channelName!.isNotEmpty
        ? media.channelName!
        : 'Watch on YouTube';

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      color: AppColors.surfaceVariant,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: InkWell(
        onTap: () => _openVideo(context),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(Icons.play_arrow, color: Colors.white, size: 32),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.onSurface,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.open_in_new, color: AppColors.accent, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
