import { Module } from '@nestjs/common';
import { APP_FILTER, APP_GUARD, APP_INTERCEPTOR } from '@nestjs/core';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { CommonModule } from './common/common.module';
import { ContractInterceptor } from './common/contract.interceptor';
import { HttpExceptionFilter } from './common/http-exception.filter';
import { AppConfigModule } from './config/config.module';
import { APP_ENV, type Env } from './config/env';
import { PostgresThrottlerStorage } from './config/postgres-throttler.storage';
import { THROTTLE_LIMITS } from './config/throttle';
import { HealthModule } from './health/health.module';
import { AccountModule } from './modules/account/account.module';
import { AnalyticsModule } from './modules/analytics/analytics.module';
import { AuthModule } from './modules/auth/auth.module';
import { CatalogModule } from './modules/catalog/catalog.module';
import { NutritionModule } from './modules/nutrition/nutrition.module';
import { PlansModule } from './modules/plans/plans.module';
import { ProfileModule } from './modules/profile/profile.module';
import { ProgressModule } from './modules/progress/progress.module';
import { WorkoutsModule } from './modules/workouts/workouts.module';
import { PrismaModule } from './prisma/prisma.module';
import { PrismaService } from './prisma/prisma.service';

/** Módulos con controladores HTTP (los recorre el generador de OpenAPI). */
export const FEATURE_MODULES = [
  HealthModule,
  AuthModule,
  AccountModule,
  ProfileModule,
  CatalogModule,
  PlansModule,
  WorkoutsModule,
  ProgressModule,
  NutritionModule,
] as const;

@Module({
  imports: [
    AppConfigModule,
    CommonModule,
    PrismaModule,
    ThrottlerModule.forRootAsync({
      inject: [APP_ENV, PrismaService],
      useFactory: (env: Env, prisma: PrismaService) => ({
        throttlers: [{ name: 'default', ...THROTTLE_LIMITS.DEFAULT }],
        skipIf: () => !env.THROTTLE_ENABLED,
        // Postgres: contadores compartidos entre réplicas (issue #9). Memoria: por proceso.
        ...(env.THROTTLE_STORE === 'postgres' ? { storage: new PostgresThrottlerStorage(prisma) } : {}),
      }),
    }),
    AnalyticsModule,
    ...FEATURE_MODULES,
  ],
  providers: [
    { provide: APP_GUARD, useClass: ThrottlerGuard },
    { provide: APP_FILTER, useClass: HttpExceptionFilter },
    { provide: APP_INTERCEPTOR, useClass: ContractInterceptor },
  ],
})
export class AppModule {}
