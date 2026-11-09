# Informe final de la reconstrucción

**Fecha:** 9 nov 2026 · **Base inicial:** `main` @ `e7e8c1b` · **Estado final:** `main` @ `ad2f2b1` más este informe.

## Qué se ha hecho

| Fase | PR | Resultado |
|---|---|---|
| 0. Diagnóstico | [#1](https://github.com/benevi/new-pipos-fitness/pull/1) | Análisis, spec v1, CUJs, modelo de datos, ADR 0001–0012 y `PROGRAMACION.md` con 86 constantes y 41 fuentes. |
| 1. Parar el sangrado | [#2](https://github.com/benevi/new-pipos-fitness/pull/2) | CI único; e2e contra Postgres real. Fuera `/admin` abierto y el secreto JWT por defecto. Rotación de refresh atómica con revocación, throttler, helmet, CORS y Swagger fuera de producción. Propiedad de recursos y validaciones. Limpieza del repo. |
| 4a. Base móvil | [#3](https://github.com/benevi/new-pipos-fitness/pull/3) | Android e iOS creados y Flutter 3.38.10 fijado. Auth corregida. Cola offline con drift. i18n y tokens de diseño. APK de debug en CI. |
| 2. Motor y catálogo | [#4](https://github.com/benevi/new-pipos-fitness/pull/4) | Motor v2 determinista con constantes citadas. Catálogo de 144 ejercicios. Property tests; cobertura del 99 %; 25 ms por plan. Búsqueda local retirada según su propio criterio (ADR-0006). |
| 3. API y datos | [#5](https://github.com/benevi/new-pipos-fitness/pull/5) | Esquema v1 con una migración única. Generación en una transacción y series idempotentes. Analytics al escribir. Consentimiento de salud, exportar y borrar. OpenAPI desde Zod. Fuera el worker, el coach de IA y las comidas. |
| 4b. App v1 | [#6](https://github.com/benevi/new-pipos-fitness/pull/6) | Onboarding, Plan, Hoy (offline), Progreso y Ajustes sobre la API v1. Accesibilidad, i18n e integration test «completar una sesión». |
| 5. Cierre | [#7](https://github.com/benevi/new-pipos-fitness/pull/7), [#8](https://github.com/benevi/new-pipos-fitness/pull/8) | Tres revisiones independientes (seguridad; arquitectura y motor; Flutter y UX) **sin hallazgos críticos**. Corregidos todos los altos y la mayoría de los medios. Documentación honesta, checklist de despliegue y deuda registrada en las issues #9–#29. |

## Estado verificable

Todo en CI, en el último commit de cada PR:
- **Backend:** build, lint sin avisos, typecheck, comprobación de deriva entre esquema y migraciones, OpenAPI al día y fixtures móviles validados contra Zod.
- **Tests del backend:** contracts 43, catalog 15, engine-rules 210, API 124 unitarios y 62 e2e contra Postgres 16, sin mocks de Prisma.
- **Móvil:** `flutter analyze --fatal-infos`, 151 tests, el integration test y el APK de debug, que se publica como artefacto del CI.

Cómo comprobarlo en local:
```bash
docker compose up -d
```
```bash
pnpm install --frozen-lockfile && pnpm --filter @pipos/api prisma:generate && pnpm build && pnpm lint && pnpm typecheck && pnpm test && pnpm test:e2e
```
```bash
cd apps/mobile && flutter pub get && flutter analyze --fatal-infos --fatal-warnings && flutter test && flutter test -d flutter-tester integration_test
```

## Decisiones que cambiaron el alcance del prompt maestro
- **Panel admin fuera de v1** (ADR-0005). El catálogo es un seed revisado por PR; se mantienen `role` y `RolesGuard` para el futuro.
- **Búsqueda local retirada** (ADR-0006): solo mejoraba un 1,83 % de media, por debajo del umbral del 2 %.
- **Añadidos:**
  - Gestión de sesiones perdidas y vuelta tras ausencia.
  - Series de calentamiento.
  - Cribado no médico.
  - Zona horaria del usuario.
  - Ventana de gracia en el refresh.
  - Minimización de datos: no se guardan IP ni user-agent.

## Qué queda fuera y por qué
- **Coach de IA, menús, worker y panel admin:** fuera de v1 por decisión (ADR-0002 a 0005). El README lo dice.
- **iOS publicado:** la plataforma está generada, pero la QA y la tienda quedan para después de v1 (ADR-0012).
- **Deuda técnica:** 21 issues, de [#9](https://github.com/benevi/new-pipos-fitness/issues/9) a [#29](https://github.com/benevi/new-pipos-fitness/issues/29). La única de severidad alta es [#9](https://github.com/benevi/new-pipos-fitness/issues/9), `trust proxy` y el almacén del rate limiting.

## Antes de ir a producción
Detalle en [DEPLOY_CHECKLIST.md](DEPLOY_CHECKLIST.md). Esto no lo puede cerrar el equipo técnico solo:
1. **DPIA** y revisión legal del texto de consentimiento de salud, la política de privacidad y los contratos de encargado (DPA).
2. **Revisión de los planes de ejemplo por un entrenador titulado** (`docs/engine/ejemplos/REVISION.md`).
3. **Firma de release propia**: hoy el release se firma con las claves de debug. Además, HTTPS en `API_BASE_URL`.
4. **Configurar `trust proxy`** para el hosting elegido (#9) y **ejecutar `analytics:rebuild`** tras migrar.

## Limitaciones de este trabajo
- Ninguna prueba se ha hecho en un dispositivo Android real. El APK lo compila el CI; el entorno de desarrollo no tenía SDK de Android.
- Las cifras del motor se tomaron de abstracts y registros, no de los textos completos, que estaban bloqueados por la red. Las fuentes principales sí están verificadas (ACSM 2026; Pelland et al. 2026).
