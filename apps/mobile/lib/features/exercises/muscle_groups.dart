/// Agrupación de los 19 músculos por grupo de volumen del motor (la misma
/// que `GROUP_MAP` de `packages/engine-rules/src/config/programming.ts`,
/// PROGRAMACION.md §16.1). La usan la vista de lista de la biblioteca y el
/// mapa de calor de Progreso.
library;

import '../../models/enums.dart';

/// Grupo de volumen de cada músculo; null si no cuenta para ninguno
/// (deltoides anterior, trapecio, antebrazos, lumbares y aductores).
const Map<Muscle, VolumeGroup?> muscleVolumeGroup = {
  Muscle.chest: VolumeGroup.chest,
  Muscle.frontDelts: null,
  Muscle.sideDelts: VolumeGroup.shoulders,
  Muscle.rearDelts: VolumeGroup.shoulders,
  Muscle.lats: VolumeGroup.back,
  Muscle.upperBack: VolumeGroup.back,
  Muscle.traps: null,
  Muscle.biceps: VolumeGroup.biceps,
  Muscle.triceps: VolumeGroup.triceps,
  Muscle.forearms: null,
  Muscle.abs: VolumeGroup.core,
  Muscle.obliques: VolumeGroup.core,
  Muscle.lowerBack: null,
  Muscle.glutes: VolumeGroup.glutes,
  Muscle.quads: VolumeGroup.quads,
  Muscle.hamstrings: VolumeGroup.hamstrings,
  Muscle.adductors: null,
  Muscle.abductors: VolumeGroup.glutes,
  Muscle.calves: VolumeGroup.calves,
};

/// Sección de la vista de lista: un grupo de volumen (o null: «otros
/// músculos», los que no cuentan para ningún grupo) y sus músculos en el
/// orden del enum.
typedef MuscleSection = ({VolumeGroup? group, List<Muscle> muscles});

/// Las 10 secciones de grupo en el orden del enum y, al final, «otros».
List<MuscleSection> muscleSections() => [
  for (final g in VolumeGroup.values)
    (
      group: g,
      muscles: [
        for (final m in Muscle.values)
          if (muscleVolumeGroup[m] == g) m,
      ],
    ),
  (
    group: null,
    muscles: [
      for (final m in Muscle.values)
        if (muscleVolumeGroup[m] == null) m,
    ],
  ),
];
