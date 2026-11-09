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

/// Vídeo de técnica de YouTube revisado (ADR-0014, Fase 4): un vídeo
/// concreto, elegido y aprobado por PR. Nunca un enlace a una búsqueda.
class ExerciseVideo {
  const ExerciseVideo({
    required this.videoId,
    required this.channelName,
    required this.locale,
    this.startSeconds,
    this.endSeconds,
    this.isPrimary = false,
  });

  /// Identificador de YouTube: 11 caracteres de `[A-Za-z0-9_-]`.
  static final videoIdPattern = RegExp(r'^[A-Za-z0-9_-]{11}$');

  final String videoId;
  final String channelName;
  final String locale;
  final int? startSeconds;
  final int? endSeconds;
  final bool isPrimary;

  /// Vídeo de un elemento de `media`; null si no es un vídeo de YouTube o
  /// no tiene la forma esperada (la app nunca abre un enlace dudoso).
  static ExerciseVideo? tryParse(Json j) {
    if (j['kind'] != 'youtube') return null;
    final id = j['videoId'];
    final channel = j['channelName'];
    final locale = j['locale'];
    if (id is! String || !videoIdPattern.hasMatch(id)) return null;
    if (channel is! String || locale is! String) return null;
    final start = j['startSeconds'];
    final end = j['endSeconds'];
    return ExerciseVideo(
      videoId: id,
      channelName: channel,
      locale: locale,
      startSeconds: start is int && start > 0 ? start : null,
      endSeconds: end is int ? end : null,
      isPrimary: j['isPrimary'] == true,
    );
  }

  /// Enlace público del vídeo en el segundo de inicio. Se abre FUERA de la
  /// app (app de YouTube o navegador): Pipos no carga código de terceros.
  Uri get watchUri => Uri.https('www.youtube.com', '/watch', {
    'v': videoId,
    if (startSeconds != null) 't': '${startSeconds}s',
  });
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

  /// Vídeos e imágenes revisados (ADR-0014, Fase 4), el principal primero.
  /// Se conservan tal cual para que la copia en caché no pierda datos; las
  /// imágenes aún no se muestran (ADR-0014: esta iteración sale con vídeos).
  final List<Json> media;

  /// Vídeo que abre «Ver vídeo»: el principal o, si el principal es una
  /// imagen, el primer vídeo. null si no hay ninguno revisado.
  ExerciseVideo? get primaryVideo {
    final videos = [for (final m in media) ?ExerciseVideo.tryParse(m)];
    if (videos.isEmpty) return null;
    return videos.firstWhere((v) => v.isPrimary, orElse: () => videos.first);
  }

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
