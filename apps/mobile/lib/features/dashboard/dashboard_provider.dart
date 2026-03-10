import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/exercise.dart';
import '../../models/muscle.dart';
import '../../models/progress_metrics.dart';
import '../../models/volume_metrics.dart';
import '../workouts/exercise_catalog_provider.dart';
import 'muscle_catalog_provider.dart';
import 'progress_provider.dart';
import 'volume_provider.dart';

class DashboardViewModel {
  final double? adherenceScore;
  final bool fatigueDetected;
  final List<ExerciseProgressVM> exercises;
  final double totalVolume;
  final List<MuscleVolumeVM> volumeByMuscle;
  final int exerciseCount;
  final int muscleCount;
  final bool isEmpty;

  const DashboardViewModel({
    this.adherenceScore,
    this.fatigueDetected = false,
    this.exercises = const [],
    this.totalVolume = 0,
    this.volumeByMuscle = const [],
    this.exerciseCount = 0,
    this.muscleCount = 0,
    this.isEmpty = true,
  });
}

class ExerciseProgressVM {
  final String exerciseId;
  final String displayName;
  final double? estimated1RM;
  final double? volumeLastWeek;
  final String? volumeTrend;
  final double? fatigueScore;

  const ExerciseProgressVM({
    required this.exerciseId,
    required this.displayName,
    this.estimated1RM,
    this.volumeLastWeek,
    this.volumeTrend,
    this.fatigueScore,
  });
}

class MuscleVolumeVM {
  final String muscleId;
  final String displayName;
  final double volume;

  const MuscleVolumeVM({
    required this.muscleId,
    required this.displayName,
    required this.volume,
  });
}

final dashboardProvider = Provider<DashboardViewModel>((ref) {
  final progress = ref.watch(progressProvider).valueOrNull;
  final volume = ref.watch(volumeProvider).valueOrNull;
  final exerciseCatalog = ref.watch(exerciseCatalogProvider).valueOrNull;
  final muscleCatalog = ref.watch(muscleCatalogProvider).valueOrNull;

  return _buildViewModel(progress, volume, exerciseCatalog, muscleCatalog);
});

DashboardViewModel _buildViewModel(
  ProgressMetrics? progress,
  VolumeMetrics? volume,
  Map<String, Exercise>? exerciseCatalog,
  Map<String, Muscle>? muscleCatalog,
) {
  final hasExercises = progress != null && progress.exercises.isNotEmpty;
  final hasVolume = volume != null &&
      (volume.byExercise.isNotEmpty || volume.byMuscle.isNotEmpty);
  final hasAdherence = progress?.adherenceScore != null;

  if (!hasExercises && !hasVolume && !hasAdherence) {
    return const DashboardViewModel();
  }

  final exercises = (progress?.exercises ?? []).map((e) {
    return ExerciseProgressVM(
      exerciseId: e.exerciseId,
      displayName: exerciseName(exerciseCatalog, e.exerciseId),
      estimated1RM: e.estimated1RM,
      volumeLastWeek: e.volumeLastWeek,
      volumeTrend: e.volumeTrend,
      fatigueScore: e.fatigueScore,
    );
  }).toList();

  final totalVolume =
      volume?.byExercise.fold<double>(0, (s, e) => s + e.volume) ?? 0;

  final muscleVolumes = (volume?.byMuscle ?? []).map((m) {
    return MuscleVolumeVM(
      muscleId: m.muscleId,
      displayName: muscleName(muscleCatalog, m.muscleId),
      volume: m.volume,
    );
  }).toList();

  return DashboardViewModel(
    adherenceScore: progress?.adherenceScore,
    fatigueDetected: progress?.fatigueDetected ?? false,
    exercises: exercises,
    totalVolume: totalVolume,
    volumeByMuscle: muscleVolumes,
    exerciseCount: volume?.byExercise.length ?? exercises.length,
    muscleCount: volume?.byMuscle.length ?? 0,
    isEmpty: false,
  );
}
