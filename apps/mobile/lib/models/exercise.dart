/// Ficha del ejercicio: `GET /exercises/:id` (contracts/src/schemas/catalog.ts,
/// `ExerciseDetailSchema`; ADR-0014).
library;

import 'enums.dart';
import 'json.dart';

class ExerciseMuscleRef {
  const ExerciseMuscleRef({
    required this.muscle,
    required this.role,
    required this.fraction,
  });

  final Muscle muscle;
  final MuscleRole role;

  /// Fracción de serie efectiva (detalle del motor; la ficha no la muestra).
  final double fraction;

  factory ExerciseMuscleRef.fromJson(Json j) => ExerciseMuscleRef(
    muscle: j.enumValue('muscle', Muscle.values),
    role: j.enumValue('role', MuscleRole.values),
    fraction: j.number('fraction'),
  );

  Json toJson() => {
    'muscle': muscle.wire,
    'role': role.wire,
    'fraction': jsonNum(fraction),
  };
}

class ExerciseRiskTag {
  const ExerciseRiskTag({required this.zone, required this.level});

  final BodyZone zone;
  final RiskLevel level;

  factory ExerciseRiskTag.fromJson(Json j) => ExerciseRiskTag(
    zone: j.enumValue('zone', BodyZone.values),
    level: j.enumValue('level', RiskLevel.values),
  );

  Json toJson() => {'zone': zone.wire, 'level': level.wire};
}

class ExerciseDetail {
  const ExerciseDetail({
    required this.id,
    required this.slug,
    required this.nameEs,
    required this.nameEn,
    required this.movementPattern,
    required this.isCompound,
    required this.isUnilateral,
    required this.minLevel,
    required this.equipment,
    required this.loadType,
    required this.primaryMuscles,
    required this.muscles,
    required this.riskTags,
    required this.substitutionGroup,
    required this.cuesEs,
    this.descriptionEs,
    this.mistakesEs = const [],
    this.media = const [],
  });

  final String id;
  final String slug;
  final String nameEs;
  final String nameEn;
  final MovementPattern movementPattern;
  final bool isCompound;
  final bool isUnilateral;
  final TrainingLevel minLevel;
  final List<Equipment> equipment;
  final LoadType loadType;
  final List<Muscle> primaryMuscles;
  final List<ExerciseMuscleRef> muscles;
  final List<ExerciseRiskTag> riskTags;
  final String? substitutionGroup;
  final List<String> cuesEs;

  /// Qué es el movimiento y qué trabaja; null si aún no está escrita.
  final String? descriptionEs;

  /// Errores comunes (0-3).
  final List<String> mistakesEs;

  /// Vídeos e imágenes revisados (Fase 4). Hasta entonces llega vacía y se
  /// conserva tal cual para que la copia en caché no pierda datos.
  final List<Json> media;

  /// Nombre en el idioma de la UI (el catálogo trae ES y EN).
  String localizedName(String languageCode) =>
      languageCode == 'en' ? nameEn : nameEs;

  /// Músculos de [role] en el orden en que los envía la API.
  List<Muscle> musclesWith(MuscleRole role) => [
    for (final m in muscles)
      if (m.role == role) m.muscle,
  ];

  factory ExerciseDetail.fromJson(Json j) => ExerciseDetail(
    id: j.str('id'),
    slug: j.str('slug'),
    nameEs: j.str('nameEs'),
    nameEn: j.str('nameEn'),
    movementPattern: j.enumValue('movementPattern', MovementPattern.values),
    isCompound: j.boolean('isCompound'),
    isUnilateral: j.boolean('isUnilateral'),
    minLevel: j.enumValue('minLevel', TrainingLevel.values),
    equipment: j.enumList('equipment', Equipment.values),
    loadType: j.enumValue('loadType', LoadType.values),
    primaryMuscles: j.enumList('primaryMuscles', Muscle.values),
    muscles: j.objList('muscles', ExerciseMuscleRef.fromJson),
    riskTags: j.objList('riskTags', ExerciseRiskTag.fromJson),
    substitutionGroup: j.strOrNull('substitutionGroup'),
    cuesEs: j.strList('cuesEs'),
    descriptionEs: j.orDefault('descriptionEs', null, j.strOrNull),
    mistakesEs: j.orDefault('mistakesEs', const [], j.strList),
    media: j.orDefault('media', const [], (k) => j.objList(k, (m) => m)),
  );

  Json toJson() => {
    'id': id,
    'slug': slug,
    'nameEs': nameEs,
    'nameEn': nameEn,
    'movementPattern': movementPattern.wire,
    'isCompound': isCompound,
    'isUnilateral': isUnilateral,
    'minLevel': minLevel.wire,
    'equipment': wires(equipment),
    'loadType': loadType.wire,
    'primaryMuscles': wires(primaryMuscles),
    'muscles': muscles.map((m) => m.toJson()).toList(),
    'riskTags': riskTags.map((r) => r.toJson()).toList(),
    'substitutionGroup': substitutionGroup,
    'cuesEs': cuesEs,
    'descriptionEs': descriptionEs,
    'mistakesEs': mistakesEs,
    'media': media,
  };
}
