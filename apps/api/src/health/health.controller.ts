import { Controller, Get, Res } from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import type { Response } from 'express';
import { HealthResponseSchema, ReadinessResponseSchema, type HealthResponse, type ReadinessResponse } from '@pipos/contracts';
import { Contract } from '../common/contract';
import { THROTTLE_LIMITS } from '../config/throttle';
import { log } from '../logging/logging';
import { PrismaService } from '../prisma/prisma.service';

@Controller('health')
@Throttle({ default: THROTTLE_LIMITS.HEALTH })
export class HealthController {
  constructor(private readonly prisma: PrismaService) {}

  /** Liveness: el proceso responde (no toca dependencias). */
  @Get()
  @Contract({ tag: 'health', summary: 'Liveness', auth: false, response: HealthResponseSchema })
  get(): HealthResponse {
    return { status: 'ok' };
  }

  /** Readiness: Postgres responde. 503 si no (el balanceador deja de enviar tráfico). */
  @Get('ready')
  @Contract({
    tag: 'health',
    summary: 'Readiness (base de datos)',
    auth: false,
    response: ReadinessResponseSchema,
    alternateStatuses: [503],
  })
  async ready(@Res({ passthrough: true }) res: Response): Promise<ReadinessResponse> {
    try {
      await this.prisma.$queryRaw`SELECT 1`;
      return { status: 'ok', checks: { database: 'ok' } };
    } catch (error) {
      log('error', 'Readiness check failed', { errorName: error instanceof Error ? error.name : 'unknown' });
      res.status(503);
      return { status: 'error', checks: { database: 'error' } };
    }
  }
}
