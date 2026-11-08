# ADR-0010: Tests e2e contra Postgres real, sin mocks de Prisma

**Estado**: Propuesto · **Fecha**: 2026-11-09

## Contexto
Los 6 ficheros `*.e2e-spec.ts` nunca se ejecutan en CI, fallan por el import de supertest y sustituyen Prisma por mocks, así que no prueban restricciones, cascadas ni migraciones.

## Decisión
- Config de Vitest separada (`vitest.e2e.config.ts`) que incluye `**/*.e2e-spec.ts`; `import request from 'supertest'` con `esModuleInterop`.
- En CI, **servicio `postgres:16`** del propio workflow; en local, el mismo Postgres vía `docker compose`. Cada fichero e2e usa un esquema propio y aplica migraciones con `prisma migrate deploy`.
- Prohibido mockear `PrismaService` en e2e (regla de lint sobre los ficheros `*.e2e-spec.ts`).

Se prefiere el servicio de CI frente a testcontainers por ser más rápido en GitHub Actions y no depender de Docker-in-Docker.

## Consecuencias
- **Más fácil:** los e2e prueban de verdad los CUJs, transacciones e idempotencia.
- **Más difícil:** los e2e necesitan Docker en local; el CI tarda algo más.

## Alternativas
- **testcontainers.** Válida en local; más lenta en CI. Se puede añadir para desarrolladores sin docker compose.
- **Mocks (estado actual).** Rechazada.
