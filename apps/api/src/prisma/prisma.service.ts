import { Injectable, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { PrismaPg } from '@prisma/adapter-pg';
import { Prisma, PrismaClient } from '@prisma/client';

/**
 * Opciones del cliente: Prisma 7 conecta a Postgres con un driver adapter (`pg`) en lugar del
 * motor nativo. La URL es la misma `DATABASE_URL` que valida `config/env.ts`.
 */
export function prismaClientOptions(databaseUrl = process.env.DATABASE_URL): Prisma.PrismaClientOptions {
  if (!databaseUrl) throw new Error('DATABASE_URL is required');
  return { adapter: new PrismaPg({ connectionString: databaseUrl }) };
}

/** Cliente de Prisma suelto para scripts y el setup de los e2e (la API usa `PrismaService`). */
export function createPrismaClient(databaseUrl?: string): PrismaClient {
  return new PrismaClient(prismaClientOptions(databaseUrl));
}

export const WRITE_ACTIONS: ReadonlySet<string> = new Set([
  'create',
  'createMany',
  'createManyAndReturn',
  'update',
  'updateMany',
  'upsert',
  'delete',
  'deleteMany',
  'executeRaw',
  'executeRawUnsafe',
]);

export interface WriteEvent {
  model?: string;
  action: string;
}

export type TransactionClient = Prisma.TransactionClient;

/** Código de Prisma para violación de unicidad (también índices únicos parciales). */
export function isUniqueViolation(error: unknown): boolean {
  return error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002';
}

@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit, OnModuleDestroy {
  private readonly writeListeners = new Set<(event: WriteEvent) => void>();

  constructor() {
    super(prismaClientOptions());
    // Observabilidad de escrituras: permite a los e2e comprobar que ningún GET escribe (ADR-0008).
    // Prisma 7 ya no tiene `$use`: una extensión de consultas ve todas las operaciones (también
    // dentro de `$transaction` y las crudas, `$executeRaw…`). `$extends` devuelve un proxy sobre
    // este mismo objeto, así que los métodos de la clase (onWrite, hooks de Nest) siguen ahí.
    const listeners = this.writeListeners;
    const observed = this.$extends({
      query: {
        async $allOperations({ model, operation, args, query }) {
          const action = operation.replace(/^\$/, '');
          if (listeners.size > 0 && WRITE_ACTIONS.has(action)) {
            for (const listener of listeners) listener({ model, action });
          }
          return query(args);
        },
      },
    });
    return observed as unknown as PrismaService;
  }

  /** Registra un observador de escrituras; devuelve la función para quitarlo. */
  onWrite(listener: (event: WriteEvent) => void): () => void {
    this.writeListeners.add(listener);
    return () => this.writeListeners.delete(listener);
  }

  async onModuleInit() {
    await this.$connect();
  }

  async onModuleDestroy() {
    await this.$disconnect();
  }
}
