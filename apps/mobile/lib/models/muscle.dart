import 'package:freezed_annotation/freezed_annotation.dart';

part 'muscle.freezed.dart';
part 'muscle.g.dart';

@freezed
class Muscle with _$Muscle {
  const factory Muscle({
    required String id,
    required String name,
    required String region,
    String? meshRegionId,
  }) = _Muscle;

  factory Muscle.fromJson(Map<String, dynamic> json) =>
      _$MuscleFromJson(json);
}
