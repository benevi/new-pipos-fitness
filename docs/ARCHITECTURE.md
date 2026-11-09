# Arquitectura

> Estado al cierre de la reconstrucción (Fase 5). Las decisiones están en los [ADR](adr/README.md);
> el alcance funcional en [SPEC_V1.md](SPEC_V1.md) y el modelo de datos en [MODELO_DATOS.md](MODELO_DATOS.md).

## 1. Visión general

Pipos Fitness genera un plan de entrenamiento de fuerza personalizado y explicado, registra los
entrenamientos (también sin red) y muestra el progreso. v1 tiene **tres piezas en ejecución**:

- **App móvil** (`apps/mobile`, Flutter 3.38.10 fijado, ADR-0012): interfaz, cola offline y caché.
- **API** (`apps/api`, NestJS + Prisma): HTTP, autenticación, persistencia y orquestación.
- **Postgres 16**.

Y **tres paquetes TypeScript** compartidos:

- `packages/contracts`: esquemas Zod de la API v1 y del motor (`engineV2`). Fuente única de
  tipos, validación y del documento OpenAPI (`apps/api/openapi.json`, generado).
- `packages/engine-rules`: motor **puro y determinista** (sin E/S): generación del plan,
  progresión sesión a sesión, sustituciones, e1RM y objetivos nutricionales diarios
  (ADR-0004, ADR-0006). Constantes citadas en `src/config/programming.ts`
  (fuentes en [engine/PROGRAMACION.md](engine/PROGRAMACION.md)).
- `packages/catalog`: catálogo de ~144 ejercicios en JSON revisado en git, con músculos y
  fracciones, material, nivel, tipo de carga y etiquetas de riesgo por zona (ADR-0005).

**No existen** en v1: worker ni colas (ADR-0002), coach de IA (ADR-0003), panel o rutas de
administración (ADR-0005), alimentos ni comidas (ADR-0004), notificaciones ni pagos.

## 2. Dependencias entre módulos

```
contracts  ◀── engine-rules ◀── api
    ▲             ▲
    └── catalog ──┘ (datos; el api lo siembra en BD)
mobile ── HTTP/JSON ──▶ api   (los fixtures de la app se validan contra contracts en CI)
```

- `engine-rules` solo depende de `contracts`; no importa Prisma, Nest ni nada con E/S.
- La API no contiene reglas de entrenamiento: llama al motor y persiste el resultado.
- La app no comparte código con el backend; usa la API y valida sus fixtures contra los
  contratos Zod (`node apps/mobile/tool/validate_fixtures.mjs`).

## 3. API (`apps/api/src`)

| Módulo | Responsabilidad |
|---|---|
| `auth` | Registro, login, refresh con rotación y detección de reutilización, logout. JWT de acceso HS256 (15 min) y refresh opaco (solo se guarda su SHA-256). |
| `account` | `GET /me`, `GET /me/export` (RGPD acceso/portabilidad), `DELETE /me` (supresión en cascada). |
| `profile` | Perfil de entrenamiento y consentimiento de salud (`ConsentEvent` append-only). Cambiar el perfil regenera el plan en la misma transacción; retirar el consentimiento borra los datos de salud y lo derivado de ellos (ADR-0011). |
| `plans` | Prepara el plan con el motor (fuera de la transacción) y lo guarda como versión inmutable (`TrainingPlan` → `PlanVersion` → `PlanSession` → `PlanExercise`), con reintento ante colisión del número de versión. |
| `workouts` | `GET /sessions/today` (siguiente sesión pendiente + prescripción de hoy del motor), entrenamientos, series idempotentes por `clientId`, sustituciones, cierre. |
| `analytics` | Proyecciones calculadas **al escribir** en la misma transacción (ADR-0008): `ExerciseE1rm`, `WeeklyMuscleVolume`, `WeeklyGroupVolume`, `WeeklyAdherence`. Reconstruibles con `pnpm --filter @pipos/api analytics:rebuild`. |
| `progress` | `GET /progress/*`: solo leen las proyecciones. |
| `nutrition` | `GET /me/nutrition-targets`: cálculo puro, no se persiste. |
| `catalog` | `GET /exercises[/:id]` y caché en memoria del catálogo para el motor. |
| `common`, `config`, `logging`, `monitoring`, `health`, `openapi` | Errores tipados, interceptor de contratos (valida entrada y salida con Zod), reloj inyectable, entorno validado, logs JSON redactados, sondas, generación de OpenAPI. |

### Flujo de datos principal

1. **Onboarding:** `PUT /me/profile` (y, si el usuario quiere declarar salud, antes
   `POST /me/consents/health`) → `POST /plans/generate`.
2. **Generación:** `EngineInputService` arma la entrada del motor (perfil, preferencias,
   consentimiento, historial reciente para cargas por e1RM) → `generatePlan` (puro) →
   una escritura anidada en `$transaction`.
3. **Entrenar:** `GET /sessions/today` elige la siguiente sesión pendiente de la versión vigente
   y pide al motor la prescripción de cada ejercicio (`nextPrescription`: doble progresión,
   descarga programada anclada al inicio del plan, descarga reactiva por estancamiento,
   vuelta tras pausa). La app crea el entrenamiento y envía las series.
4. **Escribir una serie** (`POST /workouts/:id/sets`): candado por usuario
   (`pg_advisory_xact_lock`), inserción idempotente y recálculo de e1RM y de la semana en la
   misma transacción.
5. **Progreso:** lecturas directas de las proyecciones.

### Concurrencia e idempotencia

- Series y entrenamientos: `UNIQUE(userId, clientId)`; reenviar devuelve la fila existente
  (200 en vez de 201). Edición «última escritura gana» por `clientUpdatedAt`; borrado lógico.
- Escrituras que afectan a la analítica o al consentimiento toman el candado por usuario.
- Versiones de plan: `UNIQUE(planId, version)` + reintento de la transacción.
- Propiedad: filtros por `userId` en servicio y FK compuestas `(id, userId)` en BD.

## 4. App móvil (`apps/mobile/lib`)

- `core/api`: cliente Dio, interceptor de auth con refresh *single-flight*, mapeo de errores.
- `core/auth`: tokens en `flutter_secure_storage`.
- `core/offline`: base drift (SQLite) con la cola de entrenamientos/series y una caché de
  lecturas; `SyncService` sincroniza en orden con reintentos exponenciales (ADR-0007).
- `features/`: `auth`, `onboarding`, `today`, `plan`, `progress`, `settings`.
  UX documentada en [UX_MOVIL.md](UX_MOVIL.md).

### Sincronización offline

Registrar una serie escribe primero en drift con un UUID de cliente; la UI se pinta desde
drift. Con red, `SyncService` envía en orden: entrenamientos sin `serverId`, series
pendientes y cierres. Errores transitorios (red, 5xx, 401, 408, 429) → reintento con backoff;
4xx → `failed` (reintentable a mano). Al arrancar, lo que quedó «enviando» vuelve a la cola: el
servidor es idempotente.

## 5. Datos

Esquema Prisma en `apps/api/prisma/schema.prisma` (documentado en [MODELO_DATOS.md](MODELO_DATOS.md)).
Migraciones en `apps/api/prisma/migrations` (inicial + cambios de la Fase 5); CI comprueba que no
hay deriva (`prisma migrate diff --exit-code`). El catálogo se siembra desde `packages/catalog`
(`pnpm --filter @pipos/api prisma:seed`, idempotente, borrado lógico de lo retirado).

## 6. Calidad

- Unitarios (Vitest) en contracts, catalog, engine-rules (incl. propiedades con fast-check) y
  servicios de la API; e2e contra Postgres real **sin mocks de Prisma** (ADR-0010).
- Flutter: `analyze --fatal-infos`, tests de widgets y un integration test headless.
- CI: `.github/workflows/ci.yml` (backend y móvil). Ver [CODING_RULES.md](CODING_RULES.md).
