import { Module } from '@nestjs/common';
import { APP_FILTER, APP_GUARD, APP_INTERCEPTOR } from '@nestjs/core';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { AppConfigModule } from './config/config.module';
import { APP_ENV, type Env } from './config/env';
import { THROTTLE_LIMITS } from './config/throttle';
import { AuthModule } from './modules/auth/auth.module';
import { CatalogModule } from './modules/catalog/catalog.module';
import { UsersModule } from './modules/users/users.module';
import { TrainingPlansModule } from './modules/training-plans/training-plans.module';
import { WorkoutsModule } from './modules/workouts/workouts.module';
import { AnalyticsModule } from './modules/analytics/analytics.module';
import { NutritionPlansModule } from './modules/nutrition-plans/nutrition-plans.module';
import { AICoachModule } from './modules/ai-coach/ai-coach.module';
import { HealthModule } from './health/health.module';
import { PrismaModule } from './prisma/prisma.module';
import { ZodValidationInterceptor } from './zod/zod-validation.interceptor';
import { ZodExceptionFilter } from './zod/zod-exception.filter';

@Module({
  imports: [
    AppConfigModule,
    ThrottlerModule.forRootAsync({
      inject: [APP_ENV],
      useFactory: (env: Env) => ({
        throttlers: [{ name: 'default', ...THROTTLE_LIMITS.DEFAULT }],
        skipIf: () => !env.THROTTLE_ENABLED,
      }),
    }),
    HealthModule,
    PrismaModule,
    AuthModule,
    UsersModule,
    CatalogModule,
    TrainingPlansModule,
    WorkoutsModule,
    AnalyticsModule,
    NutritionPlansModule,
    AICoachModule,
  ],
  providers: [
    { provide: APP_GUARD, useClass: ThrottlerGuard },
    { provide: APP_FILTER, useClass: ZodExceptionFilter },
    { provide: APP_INTERCEPTOR, useClass: ZodValidationInterceptor },
  ],
})
export class AppModule {}
