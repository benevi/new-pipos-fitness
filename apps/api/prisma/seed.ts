/**
 * Seed del catálogo de ejercicios desde @pipos/catalog (idempotente; borrado lógico).
 * Ejecutar: pnpm --filter @pipos/api prisma:seed
 */
import { createPrismaClient } from '../src/prisma/prisma.service';
import { seedCatalog } from '../src/catalog-seed/seed-catalog';

async function main(): Promise<void> {
  const prisma = createPrismaClient();
  try {
    const result = await seedCatalog(prisma);
    console.log(JSON.stringify({ level: 'info', message: 'catalog seeded', ...result }));
  } finally {
    await prisma.$disconnect();
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
