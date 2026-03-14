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

  await Promise.all([
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

  // --- Phase 13.3: Nutrition seed (idempotent, deterministic ids) ---
  const foodData: Array<{ id: string; name: string; caloriesPer100g: number; proteinPer100g: number; carbsPer100g: number; fatPer100g: number }> = [
    { id: 'food-chicken-breast', name: 'Chicken breast', caloriesPer100g: 165, proteinPer100g: 31, carbsPer100g: 0, fatPer100g: 3.6 },
    { id: 'food-rice-white', name: 'Rice white cooked', caloriesPer100g: 130, proteinPer100g: 2.7, carbsPer100g: 28, fatPer100g: 0.3 },
    { id: 'food-broccoli', name: 'Broccoli', caloriesPer100g: 34, proteinPer100g: 2.8, carbsPer100g: 7, fatPer100g: 0.4 },
    { id: 'food-egg-whole', name: 'Egg whole', caloriesPer100g: 155, proteinPer100g: 13, carbsPer100g: 1.1, fatPer100g: 11 },
    { id: 'food-oatmeal', name: 'Oatmeal', caloriesPer100g: 68, proteinPer100g: 2.4, carbsPer100g: 12, fatPer100g: 1.4 },
    { id: 'food-banana', name: 'Banana', caloriesPer100g: 89, proteinPer100g: 1.1, carbsPer100g: 23, fatPer100g: 0.3 },
    { id: 'food-greek-yogurt', name: 'Greek yogurt', caloriesPer100g: 97, proteinPer100g: 9, carbsPer100g: 3.5, fatPer100g: 5 },
    { id: 'food-salmon', name: 'Salmon', caloriesPer100g: 208, proteinPer100g: 20, carbsPer100g: 0, fatPer100g: 13 },
    { id: 'food-beef-lean', name: 'Beef lean', caloriesPer100g: 250, proteinPer100g: 26, carbsPer100g: 0, fatPer100g: 15 },
    { id: 'food-tuna', name: 'Tuna canned', caloriesPer100g: 116, proteinPer100g: 26, carbsPer100g: 0, fatPer100g: 0.8 },
    { id: 'food-turkey-breast', name: 'Turkey breast', caloriesPer100g: 135, proteinPer100g: 30, carbsPer100g: 0, fatPer100g: 0.7 },
    { id: 'food-tofu', name: 'Tofu firm', caloriesPer100g: 76, proteinPer100g: 8, carbsPer100g: 1.9, fatPer100g: 4.8 },
    { id: 'food-lentils', name: 'Lentils cooked', caloriesPer100g: 116, proteinPer100g: 9, carbsPer100g: 20, fatPer100g: 0.4 },
    { id: 'food-quinoa', name: 'Quinoa cooked', caloriesPer100g: 120, proteinPer100g: 4.4, carbsPer100g: 21, fatPer100g: 1.9 },
    { id: 'food-sweet-potato', name: 'Sweet potato', caloriesPer100g: 86, proteinPer100g: 1.6, carbsPer100g: 20, fatPer100g: 0.1 },
    { id: 'food-pasta', name: 'Pasta cooked', caloriesPer100g: 131, proteinPer100g: 5, carbsPer100g: 25, fatPer100g: 1.1 },
    { id: 'food-bread-whole', name: 'Whole grain bread', caloriesPer100g: 247, proteinPer100g: 13, carbsPer100g: 41, fatPer100g: 3.4 },
    { id: 'food-avocado', name: 'Avocado', caloriesPer100g: 160, proteinPer100g: 2, carbsPer100g: 9, fatPer100g: 15 },
    { id: 'food-olive-oil', name: 'Olive oil', caloriesPer100g: 884, proteinPer100g: 0, carbsPer100g: 0, fatPer100g: 100 },
    { id: 'food-almonds', name: 'Almonds', caloriesPer100g: 579, proteinPer100g: 21, carbsPer100g: 22, fatPer100g: 50 },
    { id: 'food-apple', name: 'Apple', caloriesPer100g: 52, proteinPer100g: 0.3, carbsPer100g: 14, fatPer100g: 0.2 },
    { id: 'food-orange', name: 'Orange', caloriesPer100g: 47, proteinPer100g: 0.9, carbsPer100g: 12, fatPer100g: 0.1 },
    { id: 'food-spinach', name: 'Spinach raw', caloriesPer100g: 23, proteinPer100g: 2.9, carbsPer100g: 3.6, fatPer100g: 0.4 },
    { id: 'food-tomato', name: 'Tomato', caloriesPer100g: 18, proteinPer100g: 0.9, carbsPer100g: 3.9, fatPer100g: 0.2 },
    { id: 'food-milk', name: 'Milk semi-skimmed', caloriesPer100g: 50, proteinPer100g: 3.4, carbsPer100g: 4.7, fatPer100g: 1.8 },
    { id: 'food-cottage-cheese', name: 'Cottage cheese', caloriesPer100g: 98, proteinPer100g: 11, carbsPer100g: 3.4, fatPer100g: 4.3 },
    { id: 'food-hummus', name: 'Hummus', caloriesPer100g: 166, proteinPer100g: 7.9, carbsPer100g: 14, fatPer100g: 9.6 },
    { id: 'food-black-beans', name: 'Black beans cooked', caloriesPer100g: 132, proteinPer100g: 8.9, carbsPer100g: 24, fatPer100g: 0.5 },
    { id: 'food-blueberries', name: 'Blueberries', caloriesPer100g: 57, proteinPer100g: 0.7, carbsPer100g: 14, fatPer100g: 0.3 },
    { id: 'food-carrot', name: 'Carrot', caloriesPer100g: 41, proteinPer100g: 0.9, carbsPer100g: 10, fatPer100g: 0.2 },
  ];
  for (const f of foodData) {
    await prisma.food.upsert({
      where: { id: f.id },
      create: f,
      update: { name: f.name, caloriesPer100g: f.caloriesPer100g, proteinPer100g: f.proteinPer100g, carbsPer100g: f.carbsPer100g, fatPer100g: f.fatPer100g },
    });
  }

  const templateData: Array<{ id: string; name: string }> = [
    { id: 'tpl-breakfast-oatmeal', name: 'Breakfast: Oatmeal & fruit' },
    { id: 'tpl-breakfast-eggs', name: 'Breakfast: Eggs & toast' },
    { id: 'tpl-breakfast-yogurt', name: 'Breakfast: Yogurt & fruit' },
    { id: 'tpl-lunch-chicken-rice', name: 'Lunch: Chicken & rice' },
    { id: 'tpl-lunch-salmon-veg', name: 'Lunch: Salmon & vegetables' },
    { id: 'tpl-lunch-beans-rice', name: 'Lunch: Beans & rice' },
    { id: 'tpl-dinner-beef-veg', name: 'Dinner: Beef & vegetables' },
    { id: 'tpl-dinner-tofu', name: 'Dinner: Tofu stir-fry' },
    { id: 'tpl-dinner-pasta', name: 'Dinner: Pasta & vegetables' },
    { id: 'tpl-snack-banana-nuts', name: 'Snack: Banana & nuts' },
    { id: 'tpl-snack-apple-cheese', name: 'Snack: Apple & cottage cheese' },
    { id: 'tpl-snack-hummus-veg', name: 'Snack: Hummus & vegetables' },
  ];
  for (const t of templateData) {
    await prisma.mealTemplate.upsert({
      where: { id: t.id },
      create: t,
      update: { name: t.name },
    });
  }

  type TemplateFoodEntry = { mealTemplateId: string; foodId: string; quantityG: number };
  const templateFoodData: TemplateFoodEntry[] = [
    { mealTemplateId: 'tpl-breakfast-oatmeal', foodId: 'food-oatmeal', quantityG: 80 },
    { mealTemplateId: 'tpl-breakfast-oatmeal', foodId: 'food-banana', quantityG: 100 },
    { mealTemplateId: 'tpl-breakfast-oatmeal', foodId: 'food-milk', quantityG: 120 },
    { mealTemplateId: 'tpl-breakfast-eggs', foodId: 'food-egg-whole', quantityG: 150 },
    { mealTemplateId: 'tpl-breakfast-eggs', foodId: 'food-bread-whole', quantityG: 60 },
    { mealTemplateId: 'tpl-breakfast-eggs', foodId: 'food-avocado', quantityG: 50 },
    { mealTemplateId: 'tpl-breakfast-yogurt', foodId: 'food-greek-yogurt', quantityG: 150 },
    { mealTemplateId: 'tpl-breakfast-yogurt', foodId: 'food-blueberries', quantityG: 80 },
    { mealTemplateId: 'tpl-breakfast-yogurt', foodId: 'food-almonds', quantityG: 20 },
    { mealTemplateId: 'tpl-lunch-chicken-rice', foodId: 'food-chicken-breast', quantityG: 150 },
    { mealTemplateId: 'tpl-lunch-chicken-rice', foodId: 'food-rice-white', quantityG: 180 },
    { mealTemplateId: 'tpl-lunch-chicken-rice', foodId: 'food-broccoli', quantityG: 100 },
    { mealTemplateId: 'tpl-lunch-salmon-veg', foodId: 'food-salmon', quantityG: 120 },
    { mealTemplateId: 'tpl-lunch-salmon-veg', foodId: 'food-sweet-potato', quantityG: 150 },
    { mealTemplateId: 'tpl-lunch-salmon-veg', foodId: 'food-spinach', quantityG: 80 },
    { mealTemplateId: 'tpl-lunch-beans-rice', foodId: 'food-black-beans', quantityG: 150 },
    { mealTemplateId: 'tpl-lunch-beans-rice', foodId: 'food-rice-white', quantityG: 150 },
    { mealTemplateId: 'tpl-lunch-beans-rice', foodId: 'food-tomato', quantityG: 60 },
    { mealTemplateId: 'tpl-dinner-beef-veg', foodId: 'food-beef-lean', quantityG: 120 },
    { mealTemplateId: 'tpl-dinner-beef-veg', foodId: 'food-quinoa', quantityG: 150 },
    { mealTemplateId: 'tpl-dinner-beef-veg', foodId: 'food-broccoli', quantityG: 100 },
    { mealTemplateId: 'tpl-dinner-tofu', foodId: 'food-tofu', quantityG: 150 },
    { mealTemplateId: 'tpl-dinner-tofu', foodId: 'food-rice-white', quantityG: 120 },
    { mealTemplateId: 'tpl-dinner-tofu', foodId: 'food-spinach', quantityG: 80 },
    { mealTemplateId: 'tpl-dinner-pasta', foodId: 'food-pasta', quantityG: 200 },
    { mealTemplateId: 'tpl-dinner-pasta', foodId: 'food-tomato', quantityG: 100 },
    { mealTemplateId: 'tpl-dinner-pasta', foodId: 'food-cottage-cheese', quantityG: 30 },
    { mealTemplateId: 'tpl-snack-banana-nuts', foodId: 'food-banana', quantityG: 120 },
    { mealTemplateId: 'tpl-snack-banana-nuts', foodId: 'food-almonds', quantityG: 25 },
    { mealTemplateId: 'tpl-snack-apple-cheese', foodId: 'food-apple', quantityG: 150 },
    { mealTemplateId: 'tpl-snack-apple-cheese', foodId: 'food-cottage-cheese', quantityG: 80 },
    { mealTemplateId: 'tpl-snack-hummus-veg', foodId: 'food-hummus', quantityG: 60 },
    { mealTemplateId: 'tpl-snack-hummus-veg', foodId: 'food-carrot', quantityG: 80 },
    { mealTemplateId: 'tpl-snack-hummus-veg', foodId: 'food-tomato', quantityG: 50 },
  ];
  for (const tf of templateFoodData) {
    await prisma.mealTemplateFood.upsert({
      where: { mealTemplateId_foodId: { mealTemplateId: tf.mealTemplateId, foodId: tf.foodId } },
      create: tf,
      update: { quantityG: tf.quantityG },
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
