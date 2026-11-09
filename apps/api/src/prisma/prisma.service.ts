import { Injectable, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { Prisma, PrismaClient } from '@prisma/client';

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
    super();
    // Observabilidad de escrituras: permite a los e2e comprobar que ningún GET escribe (ADR-0008).
    this.$use(async (params, next) => {
      if (this.writeListeners.size > 0 && WRITE_ACTIONS.has(params.action)) {
        for (const listener of this.writeListeners) listener({ model: params.model, action: params.action });
      }
      return next(params);
    });
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
