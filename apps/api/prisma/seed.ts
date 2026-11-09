/**
 * Seed del catálogo de ejercicios desde @pipos/catalog (idempotente; borrado lógico).
 * Ejecutar: pnpm --filter @pipos/api prisma:seed
 */
import { PrismaClient } from '@prisma/client';
import { seedCatalog } from '../src/catalog-seed/seed-catalog';

async function main(): Promise<void> {
  const prisma = new PrismaClient();
  try {
    const result = await seedCatalog(prisma);
    // eslint-disable-next-line no-console
    console.log(JSON.stringify({ level: 'info', message: 'catalog seeded', ...result }));
  } finally {
    await prisma.$disconnect();
  }
}

main().catch((error) => {
  // eslint-disable-next-line no-console
  console.error(error);
  process.exit(1);
});
