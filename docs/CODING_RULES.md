# Reglas de código

Reglas para el código escrito por personas o por IA, para mantener el sistema coherente y seguro.

## Alcance y módulos

- **No toques módulos ajenos al cambio.** Limita los cambios a la funcionalidad o el arreglo.
- **Respeta las fronteras** (ver [ARCHITECTURE.md](ARCHITECTURE.md)): las reglas de entrenamiento
  y nutrición viven en `packages/engine-rules`; la API orquesta y persiste; sin E/S en el motor.
- **Cambios mínimos.** Claridad antes que ingenio; nada de refactors grandes sin pedirlo.

## Contratos

- **Primero los contratos.** Al añadir o cambiar un endpoint, cambia `packages/contracts`
  (esquemas, enums) y regenera `apps/api/openapi.json` (`pnpm --filter @pipos/api openapi:generate`;
  CI ejecuta `openapi:check`).
- **Valida con los contratos.** Entrada y salida de la API se validan con los esquemas Zod
  (`@Contract`); sin DTOs duplicados en las apps.
- **Enums BD ↔ contratos** idénticos (lo comprueba `src/contracts-enums.spec.ts`).
- Si cambia un contrato, actualiza los fixtures de la app (`apps/mobile/test/fixtures/api_v1`) y
  comprueba `node apps/mobile/tool/validate_fixtures.mjs`.

## Lógica de negocio

- **Solo en engine-rules**, como funciones puras y **deterministas** (misma entrada → misma salida).
- **Constantes citadas**: todo número del motor está en `src/config/programming.ts` con su fuente
  en `docs/engine/PROGRAMACION.md`; las heurísticas se marcan como tales.
- Cambios del motor o del catálogo: regenera los ejemplos (`pnpm --filter @pipos/engine-rules examples`)
  y actualiza `docs/engine/ejemplos/REVISION.md` si cambian las decisiones.

## Datos y migraciones

- **Nunca edites una migración aplicada**: cada cambio es una migración nueva; CI comprueba la deriva.
- Si cambia una fórmula de analítica, sube su `formulaVersion` y documenta que hay que ejecutar
  `analytics:rebuild`.
- Datos de salud (art. 9): solo con consentimiento vigente; todo lo derivado de ellos debe poder
  borrarse al retirarlo (ADR-0011). Nada de datos personales en logs.

## Tests

- Cada función exportada del motor tiene tests unitarios (sin BD ni HTTP).
- Cada arreglo lleva un test que falla antes y pasa después.
- Los e2e usan Postgres real: **prohibido** sustituir `PrismaService` por un mock (lo comprueban
  un test y una regla de ESLint).
- **CI en verde** (build, lint con 0 avisos, typecheck, unitarios, e2e, OpenAPI, fixtures) antes de mezclar.

## Dependencias y decisiones

- Evita dependencias innecesarias; versiones fijadas por el lockfile (`--frozen-lockfile`).
- Las decisiones de arquitectura no obvias se registran como ADR en `docs/adr/`.
