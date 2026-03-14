import 'package:freezed_annotation/freezed_annotation.dart';

part 'exercise_media.freezed.dart';
part 'exercise_media.g.dart';

@freezed
class ExerciseMedia with _$ExerciseMedia {
  const factory ExerciseMedia({
    required String id,
    required String exerciseId,
    required String youtubeVideoId,
    String? channelName,
    @Default(false) bool isPrimary,
    int? startSeconds,
    int? endSeconds,
    String? curationStatus,
  }) = _ExerciseMedia;

  factory ExerciseMedia.fromJson(Map<String, dynamic> json) =>
      _$ExerciseMediaFromJson(json);
}
