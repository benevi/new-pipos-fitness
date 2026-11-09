/**
 * Recalcula las proyecciones de analítica (ExerciseE1rm, WeeklyMuscleVolume, WeeklyGroupVolume,
 * WeeklyAdherence)
 * desde SetLog, usuario a usuario (ADR-0008). Úsalo tras cambiar una fórmula.
 *   pnpm --filter @pipos/api analytics:rebuild [userId]
 */
import 'reflect-metadata';
import { PrismaClient } from '@prisma/client';
import { AnalyticsService } from '../src/modules/analytics/analytics.service';

async function main(): Promise<void> {
  const prisma = new PrismaClient();
  const analytics = new AnalyticsService();
  try {
    const only = process.argv[2];
    const users = only ? [{ id: only }] : await prisma.user.findMany({ select: { id: true }, orderBy: { id: 'asc' } });
    let workouts = 0;
    for (const { id } of users) {
      const r = await prisma.$transaction(
        async (tx) => {
          await analytics.lockUser(tx, id);
          return analytics.rebuildUser(tx, id);
        },
        { timeout: 120_000 },
      );
      workouts += r.workouts;
    }
    console.log(JSON.stringify({ level: 'info', message: 'analytics rebuilt', users: users.length, workouts }));
  } finally {
    await prisma.$disconnect();
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
