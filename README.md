# Pipos Fitness

App móvil de entrenamiento de fuerza para adultos sanos que entrenan sin entrenador. A partir de un
cuestionario corto genera un **plan determinista y explicado** que encaja con tu material, tus días,
tus minutos y tus molestias, te dice qué toca hoy, registra tus series (también sin red) y ajusta la
carga sesión a sesión.

> Estado (noviembre 2026): reconstrucción completada ([PLAN](docs/PLAN_RECONSTRUCCION.md), [fases](docs/PHASES.md)):
> decisiones, seguridad + CI, motor v2, API v1 y app móvil v1. **No está desplegada**: lo que falta para
> producción está en el [checklist de despliegue](docs/DEPLOY_CHECKLIST.md) y la deuda en [DEUDA_TECNICA.md](docs/DEUDA_TECNICA.md).

## Qué hace v1

- **Perfil y consentimiento** — objetivo, nivel, días (2–6), minutos (30–90), material (lista cerrada),
  músculos prioritarios, ejercicios vetados/favoritos, zona horaria. Peso, altura y limitaciones son
  datos de salud: solo se aceptan con un consentimiento explícito y versionado, que se puede retirar
  (borra esos datos y regenera el plan) — [ADR-0011](docs/adr/0011-datos-salud-gdpr.md).
- **Plan versionado** — el motor por reglas (`packages/engine-rules`, constantes citadas en
  [PROGRAMACION.md](docs/engine/PROGRAMACION.md)) genera split, sesiones, ejercicios, series, reps, RIR,
  descanso y carga inicial, con explicación (`rationale`) por plan, sesión y ejercicio. Cambiar el perfil
  crea una versión nueva; las anteriores siguen consultables.
- **Sesión de hoy** — siguiente sesión pendiente (faltar no salta sesiones), calentamiento y prescripción
  de hoy calculada con tu historial: doble progresión, autorregulación por RIR, descarga programada y
  reactiva, y bajada de carga tras 14+ días sin entrenar.
- **Registro offline-first** — cada entrenamiento y cada serie llevan un UUID del cliente: reenviar es
  idempotente (nunca duplica), las ediciones aplican «última escritura gana» y el borrado es lógico
  ([ADR-0007](docs/adr/0007-offline-first-idempotencia.md)).
- **Cambiar un ejercicio** — 3 alternativas que respetan patrón, músculos, material y limitaciones.
- **Qué trabaja cada ejercicio** — Hoy, Plan y el cambio de ejercicio muestran los músculos principales
  («Trabaja: …») y, desplegados, los secundarios, del ejercicio que se hace de verdad (sustituto o fijado
  incluidos), a partir del catálogo ([ADR-0014](docs/adr/0014-guia-de-ejercicios.md), Fase 1).
- **Progreso** — e1RM por ejercicio, series efectivas semanales por músculo/grupo frente al rango
  objetivo y adherencia, calculados **al escribir** ([ADR-0008](docs/adr/0008-analytics-al-escribir.md)).
- **Nutrición mínima** — objetivos diarios de kcal y macros (Mifflin-St Jeor + PAL), sin menús
  ([ADR-0004](docs/adr/0004-nutricion-objetivos-diarios.md)).
- **Tus datos** — exportar todo en JSON y borrar la cuenta con borrado real en cascada.

## Qué NO hay (y por qué)

| No hay | Por qué |
|---|---|
| Coach de IA / chat | Retirado: el motor explica sus decisiones sin LLM. Queda solo la interfaz `AiProvider` (sin implementación) — [ADR-0003](docs/adr/0003-retirar-coach-ia.md) |
| Menús, alimentos, plantillas de comidas | Fuera de v1; solo objetivos diarios — [ADR-0004](docs/adr/0004-nutricion-objetivos-diarios.md) |
| Worker, colas, Redis | No hay trabajo asíncrono real; un proceso + Postgres — [ADR-0002](docs/adr/0002-eliminar-worker.md) |
| Panel de administración | El catálogo es un seed revisado por PR (`packages/catalog`) — [ADR-0005](docs/adr/0005-catalogo-seed-sin-panel-admin.md) |
| iOS publicado | La plataforma se genera, pero la QA y la tienda se posponen — [ADR-0012](docs/adr/0012-flutter-version-fijada.md) |
| Consejo médico, menores, embarazo, rehabilitación | La app asume un adulto sano y deriva a un profesional ante dolor ([SPEC_V1](docs/SPEC_V1.md)) |

Pendiente antes del lanzamiento público: DPIA y revisión legal del texto de consentimiento, y revisión
del catálogo y de los planes de ejemplo por un entrenador titulado.

## Estructura

```
apps/
  api/            NestJS + Prisma (PostgreSQL). openapi.json generado desde los contratos
  mobile/         Flutter (Android primero)
packages/
  contracts/      Esquemas Zod de entrada y salida de cada endpoint + enums (compartidos con la BD)
  engine-rules/   Motor puro y determinista: generatePlan, nextPrescription, substitutes, dailyTargets…
  catalog/        Catálogo de ejercicios versionado (JSON validado con Zod)
docs/             Plan, spec, CUJ, ADR, modelo de datos, seguridad, programación del motor
```

## Ejecutar en local

Requisitos: Node ≥ 20, pnpm 9 (`corepack enable`), Docker (o un Postgres 16 propio).

```bash
docker compose up -d                       # Postgres 16 con pipos_dev, pipos_e2e y pipos_shadow
cp .env.example apps/api/.env              # y rellena JWT_ACCESS_SECRET (openssl rand -base64 48)
pnpm install
pnpm build                                 # contracts, catalog y engine-rules antes que la API
pnpm --filter @pipos/api prisma:generate
pnpm --filter @pipos/api prisma:migrate:deploy
pnpm --filter @pipos/api prisma:seed       # catálogo de @pipos/catalog (idempotente)
pnpm --filter @pipos/api start:dev         # http://localhost:3000, Swagger en /docs (no en producción)
```

### Variables de entorno (`apps/api/.env`)

Validadas con Zod al arrancar (`apps/api/src/config/env.ts`); sin secretos por defecto.

| Variable | Obligatoria | Por defecto | Para qué |
|---|---|---|---|
| `DATABASE_URL` | Sí | — | Postgres |
| `JWT_ACCESS_SECRET` | Sí (≥ 32 caracteres) | — | Firma HS256 del access token |
| `JWT_ACCESS_EXPIRES_IN` | No | `900` | Vida del access token (s) |
| `REFRESH_TOKEN_TTL_DAYS` | No | `30` | Vida del refresh token |
| `REFRESH_REUSE_GRACE_SECONDS` | No | `10` | Reenviar un refresh recién rotado → `AUTH_REFRESH_RACE` sin revocar |
| `CORS_ORIGINS` | No | vacío | Orígenes de navegador permitidos |
| `LOG_LEVEL` | No | `info` | Logs JSON con `requestId`, sin PII ni datos de salud |
| `THROTTLE_ENABLED` | No | `true` | No se puede desactivar en producción |
| `PORT`, `NODE_ENV`, `SENTRY_DSN` | No | `3000`, `development`, — | |
| `DATABASE_URL_SHADOW` | Solo `prisma:diff` | — | Base sombra para comprobar la deriva |

### Comandos

```bash
pnpm build | pnpm lint | pnpm typecheck      # todo el monorepo, 0 avisos
pnpm test                                    # unitarios (+ cobertura: API ≥ 80 % en servicios, motor ≥ 90 %)
DATABASE_URL=postgresql://pipos:pipos@localhost:5432/pipos_e2e pnpm test:e2e   # e2e contra Postgres real
pnpm --filter @pipos/api prisma:diff         # schema.prisma y migraciones sin deriva
pnpm --filter @pipos/api openapi:generate    # regenera apps/api/openapi.json (openapi:check en CI)
pnpm --filter @pipos/api analytics:rebuild   # recalcula e1RM/volumen (músculo y grupo)/adherencia desde las series
pnpm --filter @pipos/engine-rules examples   # 10 planes de ejemplo del motor
```

Los e2e usan la app Nest completa contra un Postgres real (sin mocks de Prisma —
[ADR-0010](docs/adr/0010-e2e-postgres-real.md)); la base debe llamarse `*test*` o `*e2e*` porque se vacía.

## CI

`.github/workflows/ci.yml` (en cada push/PR a `main` y `develop`):

- **Backend**: install `--frozen-lockfile` → prisma generate → base sombra + `prisma migrate diff
  --exit-code` → build → lint → typecheck → `openapi:check` → unitarios con umbrales de cobertura →
  `migrate deploy` → e2e (CUJ-1..8, concurrencia, idempotencia, propiedad) contra Postgres 16.
- **Mobile**: versión de Flutter fijada, `analyze`, `test` y APK de debug.

## API

Contratos en `packages/contracts`; documento OpenAPI 3 en [`apps/api/openapi.json`](apps/api/openapi.json)
(generado, no editar). Errores: `{ statusCode, code, message, issues?, requestId }` con `code` estable.

## Documentación

- [Plan de reconstrucción](docs/PLAN_RECONSTRUCCION.md) · [Spec v1](docs/SPEC_V1.md) · [CUJ](docs/CUJS.md)
- [Programación del motor](docs/engine/PROGRAMACION.md) · [Invariantes](docs/engine/INVARIANTES.md)
- [Modelo de datos](docs/MODELO_DATOS.md) · [Seguridad](docs/SECURITY.md) · [ADR](docs/adr/README.md)
- [Ideas recuperadas de una app previa](docs/IDEAS_EL_PLAN.md) ([ADR-0013](docs/adr/0013-ideas-recuperadas.md))
- [Arquitectura](docs/ARCHITECTURE.md) · [Fases](docs/PHASES.md) · [Reglas de código](docs/CODING_RULES.md)
- [Checklist de despliegue](docs/DEPLOY_CHECKLIST.md) · [Deuda técnica](docs/DEUDA_TECNICA.md) · [Informe final de la reconstrucción](docs/INFORME_FINAL.md)
- Histórico (anterior a la reconstrucción): [docs/archivo/](docs/archivo/README.md) y [análisis inicial](docs/ANALISIS_ESTADO_2026-11.md)
