import { Module } from '@nestjs/common';
import { APP_INTERCEPTOR } from '@nestjs/core';
import { AuthModule } from './modules/auth/auth.module';
import { CatalogModule } from './modules/catalog/catalog.module';
import { UsersModule } from './modules/users/users.module';
import { TrainingPlansModule } from './modules/training-plans/training-plans.module';
import { WorkoutsModule } from './modules/workouts/workouts.module';
import { AnalyticsModule } from './modules/analytics/analytics.module';
import { HealthModule } from './health/health.module';
import { PrismaModule } from './prisma/prisma.module';
import { ZodValidationInterceptor } from './zod/zod-validation.interceptor';

@Module({
  imports: [HealthModule, PrismaModule, AuthModule, UsersModule, CatalogModule, TrainingPlansModule, WorkoutsModule, AnalyticsModule],
  providers: [
    { provide: APP_INTERCEPTOR, useClass: ZodValidationInterceptor },
  ],
})
export class AppModule {}
