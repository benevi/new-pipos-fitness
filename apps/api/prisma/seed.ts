/**
 * Seed catalog and optional data. Run: pnpm exec prisma db seed
 */
import { PrismaClient, TrainingLocation, CurationStatus } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  const muscles = await Promise.all([
    prisma.muscle.upsert({ where: { id: 'muscle-chest' }, create: { id: 'muscle-chest', name: 'Chest', region: 'upper', meshRegionId: null }, update: {} }),
    prisma.muscle.upsert({ where: { id: 'muscle-back' }, create: { id: 'muscle-back', name: 'Back', region: 'upper', meshRegionId: null }, update: {} }),
    prisma.muscle.upsert({ where: { id: 'muscle-shoulders' }, create: { id: 'muscle-shoulders', name: 'Shoulders', region: 'upper', meshRegionId: null }, update: {} }),
    prisma.muscle.upsert({ where: { id: 'muscle-biceps' }, create: { id: 'muscle-biceps', name: 'Biceps', region: 'upper', meshRegionId: null }, update: {} }),
    prisma.muscle.upsert({ where: { id: 'muscle-triceps' }, create: { id: 'muscle-triceps', name: 'Triceps', region: 'upper', meshRegionId: null }, update: {} }),
    prisma.muscle.upsert({ where: { id: 'muscle-quads' }, create: { id: 'muscle-quads', name: 'Quadriceps', region: 'lower', meshRegionId: null }, update: {} }),
    prisma.muscle.upsert({ where: { id: 'muscle-hamstrings' }, create: { id: 'muscle-hamstrings', name: 'Hamstrings', region: 'lower', meshRegionId: null }, update: {} }),
    prisma.muscle.upsert({ where: { id: 'muscle-glutes' }, create: { id: 'muscle-glutes', name: 'Glutes', region: 'lower', meshRegionId: null }, update: {} }),
    prisma.muscle.upsert({ where: { id: 'muscle-core' }, create: { id: 'muscle-core', name: 'Core', region: 'core', meshRegionId: null }, update: {} }),
  ]);

  const equipment = await Promise.all([
    prisma.equipmentItem.upsert({ where: { id: 'eq-dumbbell' }, create: { id: 'eq-dumbbell', name: 'Dumbbell', category: 'free_weights' }, update: {} }),
    prisma.equipmentItem.upsert({ where: { id: 'eq-barbell' }, create: { id: 'eq-barbell', name: 'Barbell', category: 'free_weights' }, update: {} }),
    prisma.equipmentItem.upsert({ where: { id: 'eq-kettlebell' }, create: { id: 'eq-kettlebell', name: 'Kettlebell', category: 'free_weights' }, update: {} }),
    prisma.equipmentItem.upsert({ where: { id: 'eq-bench' }, create: { id: 'eq-bench', name: 'Bench', category: 'stationary' }, update: {} }),
    prisma.equipmentItem.upsert({ where: { id: 'eq-pull-up-bar' }, create: { id: 'eq-pull-up-bar', name: 'Pull-up bar', category: 'bodyweight' }, update: {} }),
    prisma.equipmentItem.upsert({ where: { id: 'eq-resistance-band' }, create: { id: 'eq-resistance-band', name: 'Resistance band', category: 'bands' }, update: {} }),
  ]);

  const exerciseData = [
    { slug: 'bench-press', name: 'Bench Press', description: 'Classic chest press', difficulty: 2, movementPattern: 'push', place: TrainingLocation.gym },
    { slug: 'squat', name: 'Squat', description: 'Barbell back squat', difficulty: 2, movementPattern: 'squat', place: TrainingLocation.gym },
    { slug: 'deadlift', name: 'Deadlift', description: 'Conventional deadlift', difficulty: 3, movementPattern: 'hinge', place: TrainingLocation.gym },
    { slug: 'overhead-press', name: 'Overhead Press', description: 'Standing barbell press', difficulty: 2, movementPattern: 'push', place: TrainingLocation.gym },
    { slug: 'bent-over-row', name: 'Bent Over Row', description: 'Barbell row', difficulty: 2, movementPattern: 'pull', place: TrainingLocation.gym },
    { slug: 'pull-up', name: 'Pull-up', description: 'Bodyweight pull-up', difficulty: 2, movementPattern: 'pull', place: TrainingLocation.calisthenics },
    { slug: 'push-up', name: 'Push-up', description: 'Standard push-up', difficulty: 1, movementPattern: 'push', place: TrainingLocation.home },
    { slug: 'lunges', name: 'Lunges', description: 'Walking or stationary lunges', difficulty: 1, movementPattern: 'lunge', place: TrainingLocation.home },
    { slug: 'plank', name: 'Plank', description: 'Front plank hold', difficulty: 1, movementPattern: 'core', place: TrainingLocation.home },
    { slug: 'goblet-squat', name: 'Goblet Squat', description: 'Kettlebell goblet squat', difficulty: 1, movementPattern: 'squat', place: TrainingLocation.gym },
    { slug: 'romanian-deadlift', name: 'Romanian Deadlift', description: 'RDL for hamstrings', difficulty: 2, movementPattern: 'hinge', place: TrainingLocation.gym },
    { slug: 'lat-pulldown', name: 'Lat Pulldown', description: 'Cable lat pulldown', difficulty: 1, movementPattern: 'pull', place: TrainingLocation.gym },
    { slug: 'dumbbell-row', name: 'Dumbbell Row', description: 'Single-arm row', difficulty: 2, movementPattern: 'pull', place: TrainingLocation.gym },
    { slug: 'incline-dumbbell-press', name: 'Incline Dumbbell Press', description: 'Incline chest press', difficulty: 2, movementPattern: 'push', place: TrainingLocation.gym },
    { slug: 'leg-press', name: 'Leg Press', description: 'Machine leg press', difficulty: 1, movementPattern: 'squat', place: TrainingLocation.gym },
    { slug: 'hip-thrust', name: 'Hip Thrust', description: 'Barbell hip thrust', difficulty: 2, movementPattern: 'hinge', place: TrainingLocation.gym },
    { slug: 'dips', name: 'Dips', description: 'Chest/triceps dips', difficulty: 2, movementPattern: 'push', place: TrainingLocation.calisthenics },
    { slug: 'bicep-curl', name: 'Bicep Curl', description: 'Dumbbell bicep curl', difficulty: 1, movementPattern: 'isolation', place: TrainingLocation.gym },
  ];

  for (const ex of exerciseData) {
    await prisma.exercise.upsert({
      where: { slug: ex.slug },
      create: ex,
      update: { name: ex.name, description: ex.description, difficulty: ex.difficulty, movementPattern: ex.movementPattern, place: ex.place },
    });
  }

  const bench = await prisma.exercise.findUnique({ where: { slug: 'bench-press' } });
  const squat = await prisma.exercise.findUnique({ where: { slug: 'squat' } });
  if (bench && squat && muscles[0] && muscles[1]) {
    await prisma.exerciseMuscle.upsert({
      where: { exerciseId_muscleId: { exerciseId: bench.id, muscleId: muscles[0].id } },
      create: { exerciseId: bench.id, muscleId: muscles[0].id, role: 'primary' },
      update: {},
    });
    await prisma.exerciseMuscle.upsert({
      where: { exerciseId_muscleId: { exerciseId: squat.id, muscleId: muscles[5].id } },
      create: { exerciseId: squat.id, muscleId: muscles[5].id, role: 'primary' },
      update: {},
    });
  }

  await prisma.youTubeChannel.upsert({
    where: { channelName: 'Pipos Fitness' },
    create: { channelName: 'Pipos Fitness', trustedScore: 1, whitelisted: true },
    update: {},
  });

  if (bench) {
    const existingMedia = await prisma.exerciseMediaYouTube.findFirst({
      where: { exerciseId: bench.id, youtubeVideoId: 'dG2oQXXqJb0' },
    });
    if (!existingMedia) {
      await prisma.exerciseMediaYouTube.create({
        data: {
          exerciseId: bench.id,
          youtubeVideoId: 'dG2oQXXqJb0',
          channelName: 'Example Channel',
          isPrimary: true,
          startSeconds: 0,
          endSeconds: 60,
          curationStatus: CurationStatus.approved,
        },
      });
    }
  }
}

main()
  .then(() => prisma.$disconnect())
  .catch((e) => {
    console.error(e);
    prisma.$disconnect();
    process.exit(1);
  });
