import { NestFactory } from '@nestjs/core';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { AppModule } from './app.module';

function enforceProductionConfig(): void {
  if (process.env.NODE_ENV !== 'production') return;
  const missing: string[] = [];
  if (!process.env.JWT_ACCESS_SECRET?.length) missing.push('JWT_ACCESS_SECRET');
  if (!process.env.JWT_REFRESH_SECRET?.length) missing.push('JWT_REFRESH_SECRET');
  if (missing.length > 0) {
    console.error('Production requires the following env vars to be set:', missing.join(', '));
    process.exit(1);
  }
}

async function bootstrap() {
  enforceProductionConfig();
  const app = await NestFactory.create(AppModule);
  const config = new DocumentBuilder()
    .setTitle('Pipos Fitness API')
    .setDescription('API for Pipos Fitness application')
    .setVersion('0.0.1')
    .build();
  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('docs', app, document);
  await app.listen(process.env.PORT ?? 3000);
}

bootstrap();
