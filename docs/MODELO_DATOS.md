# Modelo de datos v1 — Pipos Fitness (Prisma 5 / PostgreSQL)

> Estado: **implementado en la Fase 3** (`apps/api/prisma/schema.prisma` y la migración única `*_init`).
> El schema real es la referencia; este documento conserva el razonamiento de la Fase 0.

### Desviaciones de la implementación respecto a la propuesta (Fase 3)

| Cambio | Motivo |
|---|---|
| `TrainingProfile.age` → `birthYear` (CHECK 1900..2100) | Decisión tomada: no caduca. La edad se calcula en la zona del usuario. |
| `TrainingProfile.timezone` (IANA, obligatorio) | Decisión tomada (pendiente 6): límites de semana de la analítica y «hoy» de la progresión. |
| `TrainingProfile.activityLevel` (enum `ActivityLevel`, opcional) | Lo exige `dailyTargets` del motor (ADR-0004). |
| `Exercise.loadType` (enum `LoadType`) | El motor distingue carga en kg de peso corporal/bandas. `SubstitutionGroup` sin nombres (el catálogo solo trae la clave). |
| `PlanSession.kind`, `estimatedMinutes`; `PlanExercise.role`, `warmupSets` (Json), `estimatedMinutes` | Salida del motor v2 que la sesión de hoy necesita. |
| `PlanVersion` y `PlanSession` sin relación directa redundante a `User` | Permite crear versión + sesiones + ejercicios en una sola escritura anidada; la cascada desde `User` llega por `TrainingPlan` y la propiedad sigue impuesta por las FK compuestas `(id, userId)`. |
| `SetLog.clientUpdatedAt`, `updatedAt`, `deletedAt` | ADR-0007: última escritura gana y borrado lógico (la cola offline puede reenviar). |
| Nueva tabla `WorkoutSubstitution` (`UNIQUE(workoutSessionId, planExerciseId)`) | CUJ-4: el cambio de ejercicio se registra y se ve en sesión e historial. |
| **Sin** tabla `NutritionTarget` | Los objetivos se calculan al vuelo (función pura) y no se guardan: menos copias de datos de salud (minimización, ADR-0011) y ningún GET escribe (ADR-0008). |
| **Sin** `lastLoginAt` ni `AccountDeletionLog` | Decisiones tomadas: la prueba de supresión es un log con `sha256(userId)`. |
| CHECK extra: `priorityMuscles ≤ 3`, `setIndex 0..50`, analítica ≥ 0 | Coherencia con los contratos. |
| **ADR-0013** · `UserExerciseNote` (`@@id([userId, exerciseId])`, `text VARCHAR(280)` con CHECK de no vacío, `clientUpdatedAt`) — migración `20261111000000_nota_por_ejercicio` | Nota fija por ejercicio; última escritura gana (ADR-0007). Texto libre: se exporta y se borra con la cuenta. |
| **ADR-0013** · `PlanExerciseOverride` (`planExerciseId` PK → `PlanExercise` CASCADE, `userId`, `exerciseId` RESTRICT) — `20261111000100_cambio_fijado` | Cambio de ejercicio fijado fuera de la versión (inmutable); se hereda al generar versiones nuevas si sigue siendo válido. |
| **ADR-0013** · `WorkoutSession.adjustedMinutes SMALLINT?` (CHECK 15-90) y `reducedVolume BOOLEAN` — `20261111000200_ajuste_de_hoy` | Ajuste de hoy elegido al empezar; solo el modo, nunca el motivo. Las sesiones ajustadas no cuentan para descargas. |
| **ADR-0013** · `TrainingProfile.trainingWeekdays SMALLINT[]` (CHECK ⊆ 1..7, ≤ 6) y `TrainingBreak` (`clientId` único por usuario, `startsOn`/`endsOn` DATE con CHECK de 1 a 60 días) — `20261111000300_dias_y_pausas` | Días de entreno (no son entrada del motor) y pausas planificadas sin motivo. |
| **ADR-0013** · `BodyMeasurement` (`UNIQUE(userId, measuredOn)`, peso y perímetros nulables, CHECK de al menos uno) — `20261111000400_medidas_corporales` | Dato de salud (art. 9). IMC y % de grasa no se guardan: se calculan al leer. |
| **Deuda #9** · `ThrottlerRecord` (`key` PK = hash del throttler, `hits`, `expiresAt`, `blockedUntil`) — `20261112000000_rate_limit_compartido` | Contadores del rate limiting compartidos entre réplicas (`THROTTLE_STORE=postgres`). Efímera; sin IPs en claro. |
| **Deuda #11** · `PlanVersion.idempotencyKey VARCHAR(128)?`, `idempotencyHash CHAR(64)?`, `UNIQUE(userId, idempotencyKey)` — `20261112000100_idempotencia_generar_plan` | `Idempotency-Key` de `POST /plans/generate`: misma clave → misma versión. |
| **Deuda #15** · `TrainingPlan.lastDeloadOn DATE?` — `20261112000200_ultima_descarga` | Última descarga real; ancla el ciclo de descarga programada. |
| **ADR-0014** · `Exercise.mistakesEs TEXT[]` (default `{}`) — `20261113000000_ficha_ejercicio`; el seed rellena además `descriptionEs` (columna que ya existía) | Ficha del ejercicio (Fase 2 de la guía): descripción (≤ 400 caracteres, 1-3 frases) y 0-3 errores comunes (≤ 120) escritos por ejercicio en `packages/catalog` y revisados por PR. Contenido **pendiente de revisión por un entrenador titulado** antes del lanzamiento (`GUIDE_CONTENT_REVIEW` en el catálogo). `descriptionEn` sigue sin usar (deuda #29). |
| **ADR-0014** · `ExerciseMedia.file VARCHAR(96)`, `credit VARCHAR(120)`, `licence VARCHAR(32)` y nuevo CHECK `media_source_chk` — `20261114000000_medios_ejercicio` | Vídeos e imágenes (Fase 4 de la guía). El seed escribe los medios de `packages/catalog` (`media`: 0-2 por ejercicio, uno principal) con `moderationStatus = approved` y sin `moderatedById` (la revisión es el PR, ADR-0005), conserva las filas que siguen en el JSON y **borra** las que salen de él. La API solo lee los aprobados: el detalle los devuelve en `media` (principal primero) y Hoy, `hasVideo`. Una imagen exige fichero, crédito y licencia (CHECK). El catálogo no tiene medios hasta que una persona los elija y apruebe por PR. |
| **Deuda #17** · `AuditEvent` (enum `AuditEventType`, `userId?` CASCADE, `subjectRef?`, `createdAt`; trigger sin UPDATE) — `20261112000300_registro_auditoria` | Auditoría append-only sin datos personales ni de salud; retención 180 días. |
> Fuentes leídas: `apps/api/prisma/schema.prisma` (366 líneas), las 6 migraciones en `apps/api/prisma/migrations/`, `packages/contracts/src/enums/index.ts`. Prisma instalado: `^5.9.0`.

## 0. Hallazgos sobre el estado actual (motivan el rediseño)

| # | Hallazgo | Impacto |
|---|----------|---------|
| H1 | `RefreshToken` **no tiene índice en `tokenHash`** y la migración `20260311222510_add_remaining_tables` hace `DROP INDEX "RefreshToken_userId_idx"` (deriva entre schema y migraciones). | Cada refresh hace seq-scan; no hay unicidad del hash; no hay detección de reutilización por familia. |
| H2 | No existe `migrations/migration_lock.toml`. | `prisma migrate` no puede verificar el proveedor; riesgo de aplicar migraciones contra otro motor. |
| H3 | `TrainingSessionExercise.exerciseId` y `ExerciseProgress.exerciseId` **no tienen FK** a `Exercise`. | Se pueden referenciar ejercicios inexistentes; el historial de planes puede quedar huérfano. |
| H4 | `TrainingSessionExercise` no tiene columna de orden. | El orden de los ejercicios depende del orden de inserción (no garantizado en SQL). |
| H5 | Perfil de entrenamiento embebido en `User` con columnas `Json` (`goals`, `muscleFocus`, `availableEquipment`) y `sex`/`trainingLevel` como `String`. | Sin validación en BD; listas cerradas no se aplican; mezcla de datos de salud con identidad. |
| H6 | `Exercise` se borra en cascada sobre `ExerciseMuscle`, `ExerciseMediaYouTube`, etc. y no tiene borrado lógico. | Borrar un ejercicio rompe planes históricos (o falla sin mensaje claro). |
| H7 | `WorkoutSet` no tiene clave de idempotencia. | Reintentos offline del móvil duplican series. |
| H8 | No hay registro de consentimiento RGPD para datos de salud (peso, limitaciones). | Incumplimiento art. 9 RGPD. |
| H9 | Enums de `contracts` desalineados con el alcance v1 (`GoalType` = fat_loss, muscle_gain, strength, endurance, health, custom). | Hay que actualizar `packages/contracts` en paralelo. |
| H10 | Dominio de nutrición completo (Food, MealTemplate, NutritionPlan…) y `AIInteraction`, fuera del alcance v1. | Superficie de mantenimiento y de datos personales innecesaria. |

---

## 1. `schema.prisma` propuesto

Convenciones:
- PK `String @id @default(uuid()) @db.Uuid` (tipo nativo `uuid`, 16 bytes, en lugar de `text`).
- Valores de enum en **minúsculas** para que coincidan 1:1 con los strings de `packages/contracts` (como ya hacía `TrainingLocation`). `Role` usa `user`/`admin` (el alcance dice USER/ADMIN; es el mismo concepto, solo cambia la capitalización, que se elige por coherencia).
- Cantidades físicas en `Decimal` con precisión fija (sin errores de coma flotante en kg).
- Todo lo que Prisma no expresa (CHECK, índices parciales, unicidad parcial) va como SQL crudo al final de la migración inicial (ver §6).

```prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

// ─────────────────────────────────────────────────────────────
// ENUMS (listas cerradas)
// ─────────────────────────────────────────────────────────────

enum Role {
  user
  admin
}

enum Locale {
  es
  en
}

enum Sex {
  male
  female
  other
}

enum TrainingGoal {
  strength
  hypertrophy
  general_health
  fat_loss
  muscular_endurance
}

enum TrainingLevel {
  beginner
  intermediate
  advanced
}

enum Equipment {
  bodyweight          // "sin material": todo ejercicio sin equipo lleva [bodyweight]
  barbell
  ez_bar
  trap_bar
  dumbbell
  kettlebell
  weight_plate
  bench
  squat_rack
  cable
  machine
  smith_machine
  pull_up_bar
  dip_station
  gymnastic_rings
  suspension_trainer
  resistance_band
  medicine_ball
  plyo_box
}

enum BodyZone {
  shoulder
  elbow
  wrist
  lumbar
  hip
  knee
  ankle
}

enum Muscle {
  chest
  front_delts
  side_delts
  rear_delts
  lats
  upper_back
  traps
  biceps
  triceps
  forearms
  abs
  obliques
  lower_back
  glutes
  quads
  hamstrings
  adductors
  abductors
  calves
}

enum MuscleRole {
  primary
  secondary
}

enum MovementPattern {
  squat
  hinge
  lunge
  horizontal_push
  vertical_push
  horizontal_pull
  vertical_pull
  elbow_flexion
  elbow_extension
  shoulder_isolation
  knee_extension
  knee_flexion
  hip_isolation
  calf_raise
  core_anti_extension
  core_anti_rotation
  core_flexion
  carry
}

enum RiskLevel {
  caution    // permitido con limitación leve; el motor penaliza
  avoid      // excluido si el usuario declara limitación en esa zona
}

enum ExercisePreferenceKind {
  banned
  favourite
}

enum MediaKind {
  youtube
  image
}

enum ModerationStatus {
  pending
  approved
  rejected
  unavailable
}

enum ConsentPurpose {
  health_data_processing   // art. 9.2.a RGPD: peso, altura, limitaciones
}

enum ConsentAction {
  granted
  withdrawn
}

enum RefreshTokenRevokeReason {
  rotated
  logout
  reuse_detected
  password_changed
  account_deleted
  admin
}

enum PlanStatus {
  active
  archived
}

enum WorkoutStatus {
  in_progress
  completed
  abandoned
}

// ─────────────────────────────────────────────────────────────
// IDENTIDAD Y AUTH
// ─────────────────────────────────────────────────────────────

model User {
  id              String   @id @default(uuid()) @db.Uuid
  email           String                          // tal como lo escribió el usuario (para mostrar)
  emailNormalized String   @unique                // lower(trim(email)); login y unicidad
  passwordHash    String                          // argon2id
  role            Role     @default(user)
  locale          Locale   @default(es)
  createdAt       DateTime @default(now()) @db.Timestamptz(3)
  updatedAt       DateTime @updatedAt @db.Timestamptz(3)

  refreshTokens       RefreshToken[]
  trainingProfile     TrainingProfile?
  exercisePreferences UserExercisePreference[]
  consentEvents       ConsentEvent[]
  trainingPlans       TrainingPlan[]
  planVersions        PlanVersion[]
  planSessions        PlanSession[]
  workoutSessions     WorkoutSession[]
  setLogs             SetLog[]
  e1rmHistory         ExerciseE1rm[]
  weeklyMuscleVolume  WeeklyMuscleVolume[]
  weeklyAdherence     WeeklyAdherence[]
  nutritionTargets    NutritionTarget[]
  moderatedMedia      ExerciseMedia[]          @relation("MediaModeratedBy")
}

model RefreshToken {
  id            String                    @id @default(uuid()) @db.Uuid
  userId        String                    @db.Uuid
  user          User                      @relation(fields: [userId], references: [id], onDelete: Cascade)
  familyId      String                    @db.Uuid     // = id del primer token del login; se hereda en cada rotación
  tokenHash     String                    @unique      // SHA-256 (hex) del token opaco; nunca el token en claro
  expiresAt     DateTime                  @db.Timestamptz(3)
  createdAt     DateTime                  @default(now()) @db.Timestamptz(3)
  rotatedAt     DateTime?                 @db.Timestamptz(3) // se usó para emitir el siguiente
  revokedAt     DateTime?                 @db.Timestamptz(3)
  revokedReason RefreshTokenRevokeReason?
  replacedById  String?                   @unique @db.Uuid
  replacedBy    RefreshToken?             @relation("Rotation", fields: [replacedById], references: [id], onDelete: SetNull)
  replaces      RefreshToken?             @relation("Rotation")

  @@index([userId])
  @@index([familyId])
  @@index([expiresAt])
}

// ─────────────────────────────────────────────────────────────
// PERFIL DE ENTRENAMIENTO (1:1 con User)
// ─────────────────────────────────────────────────────────────

model TrainingProfile {
  userId            String        @id @db.Uuid
  user              User          @relation(fields: [userId], references: [id], onDelete: Cascade)
  goal              TrainingGoal
  level             TrainingLevel
  daysPerWeek       Int           @db.SmallInt        // CHECK 2..6
  minutesPerSession Int           @db.SmallInt        // CHECK 30..90
  equipment         Equipment[]                       // lo que el usuario tiene disponible
  priorityMuscles   Muscle[]
  // ── categoría especial (art. 9): solo se escriben con consentimiento vigente ──
  limitations       BodyZone[]    @default([])
  weightKg          Decimal?      @db.Decimal(5, 2)   // CHECK 25..400
  heightCm          Decimal?      @db.Decimal(5, 1)   // CHECK 100..250
  // ── datos personales ordinarios ──
  age               Int?          @db.SmallInt        // CHECK 14..100
  sex               Sex?
  createdAt         DateTime      @default(now()) @db.Timestamptz(3)
  updatedAt         DateTime      @updatedAt @db.Timestamptz(3)
}

model UserExercisePreference {
  userId     String                 @db.Uuid
  user       User                   @relation(fields: [userId], references: [id], onDelete: Cascade)
  exerciseId String                 @db.Uuid
  exercise   Exercise               @relation(fields: [exerciseId], references: [id], onDelete: Restrict)
  kind       ExercisePreferenceKind // un ejercicio no puede ser vetado y favorito a la vez (PK)
  createdAt  DateTime               @default(now()) @db.Timestamptz(3)

  @@id([userId, exerciseId])
  @@index([exerciseId])
}

// Registro append-only. El estado vigente = último evento por (userId, purpose).
model ConsentEvent {
  id            String         @id @default(uuid()) @db.Uuid
  userId        String         @db.Uuid
  user          User           @relation(fields: [userId], references: [id], onDelete: Cascade)
  purpose       ConsentPurpose
  action        ConsentAction
  policyVersion String         @db.VarChar(32)    // p. ej. "health-2026-11"
  textHash      String         @db.Char(64)       // SHA-256 del texto exacto mostrado
  locale        Locale
  occurredAt    DateTime       @default(now()) @db.Timestamptz(3)

  @@index([userId, purpose, occurredAt(sort: Desc)])
}

// ─────────────────────────────────────────────────────────────
// CATÁLOGO DE EJERCICIOS
// ─────────────────────────────────────────────────────────────

model SubstitutionGroup {
  id        String     @id @default(uuid()) @db.Uuid
  key       String     @unique @db.VarChar(64)   // p. ej. "horizontal_press_chest"
  nameEs    String
  nameEn    String
  exercises Exercise[]
}

model Exercise {
  id                  String             @id @default(uuid()) @db.Uuid
  slug                String             @unique @db.VarChar(96)
  nameEs              String
  nameEn              String
  descriptionEs       String?
  descriptionEn       String?
  movementPattern     MovementPattern
  isCompound          Boolean
  isUnilateral        Boolean            @default(false)
  minLevel            TrainingLevel
  equipment           Equipment[]                       // TODOS requeridos; [] prohibido (CHECK), usar [bodyweight]
  substitutionGroupId String?            @db.Uuid
  substitutionGroup   SubstitutionGroup? @relation(fields: [substitutionGroupId], references: [id], onDelete: SetNull)
  cuesEs              String[]           @default([])   // orden del array = orden de presentación
  cuesEn              String[]           @default([])
  mistakesEs          String[]           @default([])   // ADR-0014: errores comunes (0-3) de la ficha
  createdAt           DateTime           @default(now()) @db.Timestamptz(3)
  updatedAt           DateTime           @updatedAt @db.Timestamptz(3)
  deletedAt           DateTime?          @db.Timestamptz(3) // borrado lógico; nunca DELETE físico

  muscles       ExerciseMuscle[]
  riskTags      ExerciseRiskTag[]
  media         ExerciseMedia[]
  planExercises PlanExercise[]
  setLogs       SetLog[]
  e1rmHistory   ExerciseE1rm[]
  preferences   UserExercisePreference[]

  @@index([movementPattern])
  @@index([substitutionGroupId])
  @@index([equipment], type: Gin)
}

model ExerciseMuscle {
  exerciseId String     @db.Uuid
  exercise   Exercise   @relation(fields: [exerciseId], references: [id], onDelete: Cascade)
  muscle     Muscle
  role       MuscleRole
  fraction   Decimal    @db.Decimal(3, 2)   // CHECK 0 < fraction <= 1; series efectivas = series × fraction

  @@id([exerciseId, muscle])
  @@index([muscle, role])
}

model ExerciseRiskTag {
  exerciseId String    @db.Uuid
  exercise   Exercise  @relation(fields: [exerciseId], references: [id], onDelete: Cascade)
  zone       BodyZone
  level      RiskLevel

  @@id([exerciseId, zone])
  @@index([zone])
}

model ExerciseMedia {
  id               String           @id @default(uuid()) @db.Uuid
  exerciseId       String           @db.Uuid
  exercise         Exercise         @relation(fields: [exerciseId], references: [id], onDelete: Cascade)
  kind             MediaKind
  externalId       String?          @db.VarChar(64)    // youtube videoId
  url              String?                             // image (CDN; sin uso: las imágenes son ficheros del catálogo)
  file             String?          @db.VarChar(96)    // image: fichero de packages/catalog/media (ADR-0014, Fase 4)
  credit           String?          @db.VarChar(120)   // image: crédito (obligatorio)
  licence          String?          @db.VarChar(32)    // image: licencia (obligatoria)
  channelName      String?
  startSeconds     Int?
  endSeconds       Int?                                // CHECK end > start
  locale           Locale?                             // null = válido para ambos idiomas
  isPrimary        Boolean          @default(false)
  moderationStatus ModerationStatus @default(pending)
  moderatedById    String?          @db.Uuid
  moderatedBy      User?            @relation("MediaModeratedBy", fields: [moderatedById], references: [id], onDelete: SetNull)
  moderatedAt      DateTime?        @db.Timestamptz(3)
  createdAt        DateTime         @default(now()) @db.Timestamptz(3)

  @@index([exerciseId, moderationStatus])
  @@index([moderationStatus, createdAt])
}

// ─────────────────────────────────────────────────────────────
// PLANES DE ENTRENAMIENTO (versionados, inmutables por versión)
// userId se desnormaliza en PlanVersion y PlanSession para poder
// imponer en BD (FK compuestas) que un WorkoutSession solo apunte
// a una PlanSession del mismo usuario.
// ─────────────────────────────────────────────────────────────

model TrainingPlan {
  id        String        @id @default(uuid()) @db.Uuid
  userId    String        @db.Uuid
  user      User          @relation(fields: [userId], references: [id], onDelete: Cascade)
  status    PlanStatus    @default(active)        // índice único parcial: 1 activo por usuario
  createdAt DateTime      @default(now()) @db.Timestamptz(3)
  updatedAt DateTime      @updatedAt @db.Timestamptz(3)
  versions  PlanVersion[]

  @@unique([id, userId])                          // destino de FK compuesta
  @@index([userId, status])
}

model PlanVersion {
  id             String        @id @default(uuid()) @db.Uuid
  planId         String        @db.Uuid
  userId         String        @db.Uuid
  plan           TrainingPlan  @relation(fields: [planId, userId], references: [id, userId], onDelete: Cascade)
  user           User          @relation(fields: [userId], references: [id], onDelete: Cascade)
  version        Int                                // 1..n, monotónico por plan
  engineVersion  String        @db.VarChar(32)      // semver del motor que la generó
  objectiveScore Float
  mesocycleWeeks Int           @db.SmallInt         // CHECK 1..16
  rationale      Json                               // explicación estructurada del motor
  inputSnapshot  Json                               // perfil + preferencias usados (contiene datos art. 9)
  createdAt      DateTime      @default(now()) @db.Timestamptz(3)
  sessions       PlanSession[]

  @@unique([planId, version])
  @@unique([id, userId])
  @@index([userId, createdAt(sort: Desc)])
}

model PlanSession {
  id               String           @id @default(uuid()) @db.Uuid
  planVersionId    String           @db.Uuid
  userId           String           @db.Uuid
  planVersion      PlanVersion      @relation(fields: [planVersionId, userId], references: [id, userId], onDelete: Cascade)
  user             User             @relation(fields: [userId], references: [id], onDelete: Cascade)
  dayIndex         Int              @db.SmallInt    // 0..6 día de la semana del microciclo
  order            Int              @db.SmallInt    // posición en el microciclo (0..daysPerWeek-1)
  name             String
  targetMinutes    Int              @db.SmallInt
  rationale        Json?
  exercises        PlanExercise[]
  workoutSessions  WorkoutSession[]

  @@unique([planVersionId, order])
  @@unique([planVersionId, dayIndex])
  @@unique([id, userId])
}

model PlanExercise {
  id                  String      @id @default(uuid()) @db.Uuid
  planSessionId       String      @db.Uuid
  planSession         PlanSession @relation(fields: [planSessionId], references: [id], onDelete: Cascade)
  exerciseId          String      @db.Uuid
  exercise            Exercise    @relation(fields: [exerciseId], references: [id], onDelete: Restrict)
  order               Int         @db.SmallInt     // persistido; nunca depender del orden de inserción
  sets                Int         @db.SmallInt     // CHECK 1..10
  repMin              Int         @db.SmallInt     // CHECK 1 <= repMin <= repMax <= 50
  repMax              Int         @db.SmallInt
  targetRir           Int         @db.SmallInt     // CHECK 0..5
  restSeconds         Int         @db.SmallInt     // CHECK 15..600
  initialLoadKg       Decimal?    @db.Decimal(6, 2)
  initialLoadIsEstimate Boolean   @default(true)
  rationale           Json?
  setLogs             SetLog[]

  @@unique([planSessionId, order])
  @@index([exerciseId])
}

// ─────────────────────────────────────────────────────────────
// REGISTRO DE ENTRENAMIENTOS
// ─────────────────────────────────────────────────────────────

model WorkoutSession {
  id              String        @id @default(uuid()) @db.Uuid
  clientId        String        @db.Uuid           // UUID generado en el móvil (idempotencia de creación)
  userId          String        @db.Uuid
  user            User          @relation(fields: [userId], references: [id], onDelete: Cascade)
  planSessionId   String        @db.Uuid
  planSession     PlanSession   @relation(fields: [planSessionId, userId], references: [id, userId], onDelete: NoAction)
  status          WorkoutStatus @default(in_progress)
  startedAt       DateTime      @db.Timestamptz(3)
  completedAt     DateTime?     @db.Timestamptz(3)  // CHECK completedAt >= startedAt
  createdAt       DateTime      @default(now()) @db.Timestamptz(3)
  updatedAt       DateTime      @updatedAt @db.Timestamptz(3)
  setLogs         SetLog[]
  e1rmEntries     ExerciseE1rm[]

  @@unique([userId, clientId])
  @@unique([id, userId])
  @@index([userId, startedAt(sort: Desc)])
  @@index([planSessionId])
}

model SetLog {
  id               String         @id @default(uuid()) @db.Uuid
  clientId         String         @db.Uuid          // clave de idempotencia generada en cliente
  userId           String         @db.Uuid
  user             User           @relation(fields: [userId], references: [id], onDelete: Cascade)
  workoutSessionId String         @db.Uuid
  workoutSession   WorkoutSession @relation(fields: [workoutSessionId, userId], references: [id, userId], onDelete: Cascade)
  planExerciseId   String?        @db.Uuid          // hueco prescrito (null = ejercicio añadido libremente)
  planExercise     PlanExercise?  @relation(fields: [planExerciseId], references: [id], onDelete: NoAction)
  exerciseId       String         @db.Uuid          // ejercicio realmente hecho (puede ser sustituto)
  exercise         Exercise       @relation(fields: [exerciseId], references: [id], onDelete: Restrict)
  setIndex         Int            @db.SmallInt      // 0..n dentro del ejercicio en esa sesión
  reps             Int            @db.SmallInt      // CHECK 0..100
  loadKg           Decimal        @db.Decimal(6, 2) // CHECK >= 0 (peso corporal = 0 + nota en contrato)
  rir              Int?           @db.SmallInt      // CHECK 0..10
  isWarmup         Boolean        @default(false)
  completedAt      DateTime       @db.Timestamptz(3) // reloj del cliente
  createdAt        DateTime       @default(now()) @db.Timestamptz(3) // reloj del servidor

  @@unique([userId, clientId])
  @@index([workoutSessionId, exerciseId, setIndex])
  @@index([userId, exerciseId, completedAt(sort: Desc)])
  @@index([planExerciseId])
}

// ─────────────────────────────────────────────────────────────
// ANALÍTICA (calculada en escritura, misma transacción que SetLog)
// Son proyecciones reconstruibles desde SetLog; formulaVersion
// permite recalcular si cambia la fórmula.
// ─────────────────────────────────────────────────────────────

model ExerciseE1rm {
  id               String         @id @default(uuid()) @db.Uuid
  userId           String         @db.Uuid
  user             User           @relation(fields: [userId], references: [id], onDelete: Cascade)
  exerciseId       String         @db.Uuid
  exercise         Exercise       @relation(fields: [exerciseId], references: [id], onDelete: Restrict)
  workoutSessionId String         @db.Uuid
  workoutSession   WorkoutSession @relation(fields: [workoutSessionId], references: [id], onDelete: Cascade)
  performedOn      DateTime       @db.Date
  e1rmKg           Decimal        @db.Decimal(6, 2)  // mejor e1RM de la sesión (series no warm-up)
  sourceSetLogId   String?        @db.Uuid            // sin FK: proyección; ver §4
  formulaVersion   String         @db.VarChar(16)     // p. ej. "epley-rir-v1"
  computedAt       DateTime       @default(now()) @db.Timestamptz(3)

  @@unique([userId, exerciseId, workoutSessionId])
  @@index([userId, exerciseId, performedOn(sort: Desc)])
}

model WeeklyMuscleVolume {
  userId         String   @db.Uuid
  user           User     @relation(fields: [userId], references: [id], onDelete: Cascade)
  weekStart      DateTime @db.Date                 // lunes ISO, en la zona horaria del usuario
  muscle         Muscle
  effectiveSets  Decimal  @db.Decimal(6, 2)        // Σ series × fraction (sin warm-up)
  tonnageKg      Decimal  @db.Decimal(10, 2)
  formulaVersion String   @db.VarChar(16)
  computedAt     DateTime @default(now()) @db.Timestamptz(3)

  @@id([userId, weekStart, muscle])
}

model WeeklyAdherence {
  userId            String   @db.Uuid
  user              User     @relation(fields: [userId], references: [id], onDelete: Cascade)
  weekStart         DateTime @db.Date
  plannedSessions   Int      @db.SmallInt
  completedSessions Int      @db.SmallInt
  plannedSets       Int      @db.SmallInt
  completedSets     Int      @db.SmallInt
  planVersionId     String?  @db.Uuid               // versión vigente esa semana (sin FK, informativo)
  computedAt        DateTime @default(now()) @db.Timestamptz(3)

  @@id([userId, weekStart])
}

// ─────────────────────────────────────────────────────────────
// NUTRICIÓN (solo objetivos diarios en v1; append-only)
// ─────────────────────────────────────────────────────────────

model NutritionTarget {
  id             String   @id @default(uuid()) @db.Uuid
  userId         String   @db.Uuid
  user           User     @relation(fields: [userId], references: [id], onDelete: Cascade)
  kcal           Int                                // CHECK 800..6000
  proteinG       Int      @db.SmallInt
  fatG           Int      @db.SmallInt
  carbsG         Int      @db.SmallInt
  formulaVersion String   @db.VarChar(16)           // p. ej. "mifflin-v1"
  inputsSnapshot Json                               // peso, altura, edad, sexo, actividad (contiene datos art. 9)
  createdAt      DateTime @default(now()) @db.Timestamptz(3)

  @@index([userId, createdAt(sort: Desc)])
}
```

Notas de diseño clave:
- **Sin `currentVersionId` circular** en `TrainingPlan`: la versión vigente es `MAX(version)` por plan (servida por `@@unique([planId, version])`). Elimina la FK cíclica plan↔versión del modelo actual.
- **`WorkoutExercise` desaparece**: `SetLog` cuelga directamente de `WorkoutSession` con `exerciseId` + `setIndex`. Una tabla menos y la idempotencia queda en una sola fila.
- **`age`** se mantiene como pide el alcance; alternativa a valorar: `birthYear` (no caduca). Decisión pendiente, no bloqueante.
- **Peso corporal** solo vive en `TrainingProfile` (valor actual). No hay historial de peso en v1 (sería más dato de salud que custodiar sin una función que lo use).

---

## 2. Mapeo modelos actuales → v1

| Modelo actual | Decisión | Modelo v1 | Motivo |
|---|---|---|---|
| `User` | **Cambiar** | `User` + `TrainingProfile` | Se separa identidad de perfil (H5); se añaden `role`, `locale`; se eliminan `Json` sin tipar, `trainingLocation`, `dislikedFoodIds`. |
| `RefreshToken` | **Cambiar** | `RefreshToken` | `tokenHash @unique`, `@@index(userId)` (restaura el índice borrado, H1), `familyId` + `rotatedAt` + `revokedReason` para detección de reutilización; `replacedById @unique` (1:1). |
| `AIInteraction` | **Eliminar** | — | Coach IA fuera de v1; además almacenaba preguntas libres con posible contenido de salud. |
| `ExerciseProgress` | **Eliminar** (sustituido) | `ExerciseE1rm`, `WeeklyMuscleVolume` | Mezclaba e1RM, volumen y "fatigueScore" en una fila sin historial ni FK (H3). |
| `TrainingPlan` | **Cambiar** | `TrainingPlan` | `status` + 1 activo por usuario; sin FK circular `currentVersionId`. |
| `TrainingPlanVersion` | **Cambiar/renombrar** | `PlanVersion` | Añade `rationale`, `mesocycleWeeks`, `inputSnapshot`, `userId` desnormalizado. |
| `TrainingSession` | **Cambiar/renombrar** | `PlanSession` | `sessionIndex` → `dayIndex` + `order`; añade `rationale`. |
| `TrainingSessionExercise` | **Cambiar/renombrar** | `PlanExercise` | FK a `Exercise` con RESTRICT (H3), `order` persistido (H4), carga inicial + `isEstimate`, `rationale`. |
| `WorkoutSession` | **Cambiar** | `WorkoutSession` | `planSessionId` obligatorio y del mismo usuario (FK compuesta); `clientId` idempotente; `status`; se quita `planVersionId` (derivable) y `notes` (texto libre). |
| `WorkoutExercise` | **Eliminar** | (absorbido en `SetLog`) | Capa intermedia innecesaria; complicaba la idempotencia. |
| `WorkoutSet` | **Cambiar/renombrar** | `SetLog` | `clientId` único por usuario (H7), `completedAt`, `isWarmup`, `planExerciseId`, `loadKg` Decimal. |
| `Muscle` (tabla) | **Cambiar a enum** | `enum Muscle` | Lista cerrada y estable; el motor la necesita en compilación. `meshRegionId` pasa al cliente móvil (mapa enum→malla). |
| `EquipmentItem` + `ExerciseEquipment` | **Cambiar a enum[]** | `enum Equipment`, `Exercise.equipment[]` | Lista cerrada; la consulta "ejercicios realizables" es `equipment <@ userEquipment` con GIN. |
| `Exercise` | **Cambiar** | `Exercise` | `nameEs/nameEn`, `movementPattern` enum, `isCompound`, `isUnilateral`, `minLevel` (sustituye `difficulty Int`), cues, `deletedAt` (H6); se quita `place` (se deriva del equipo). |
| `ExerciseMuscle` | **Cambiar** | `ExerciseMuscle` | `role` enum + `fraction`. |
| `ExerciseVariant` | **Eliminar** (sustituido) | `SubstitutionGroup` | Grafo N:M de variantes → grupo de equivalencia; más simple para el motor. |
| `ExerciseMediaYouTube` | **Cambiar/renombrar** | `ExerciseMedia` | Soporta imagen; `moderationStatus`, quién/cuándo moderó; `locale`. |
| `YouTubeChannel` | **Eliminar** | — | Lista de confianza no necesaria en v1; la moderación es manual por admin. |
| `Food`, `MealTemplate`, `MealTemplateFood` | **Eliminar** | — | Sin alimentos/comidas en v1. |
| `NutritionPlan`, `NutritionPlanVersion`, `NutritionDay`, `NutritionMeal`, `NutritionMealItem` | **Eliminar** | `NutritionTarget` | Solo objetivos diarios (kcal/macros) con snapshot y versión de fórmula. |
| enums `TrainingLocation`, `VolumeTrend`, `CurationStatus` | **Eliminar / renombrar** | `ModerationStatus` (mismos valores que `CurationStatus`) | `TrainingLocation` y `VolumeTrend` ya no se usan. |
| — | **Nuevo** | `UserExercisePreference`, `ConsentEvent`, `ExerciseRiskTag`, `SubstitutionGroup`, `WeeklyAdherence` | Requisitos v1. |

Impacto en `packages/contracts/src/enums/index.ts`: reemplazar `GoalType` por `TrainingGoal` (5 valores), eliminar `TrainingLocation`, `MusclePriority`, `NutritionGoalType`; `MuscleRole` pierde `stabilizer`; añadir `Role`, `Equipment`, `BodyZone`, `Muscle`, `MovementPattern`, `ModerationStatus` (renombra `CurationStatus`). `PlanStatus` pierde `draft` (las versiones no publicadas no se persisten). Idealmente los enums de contracts se **generan** o se validan con un test contra el cliente Prisma para evitar deriva.

---

## 3. Índices y la consulta que sirve cada uno

| Tabla | Índice | Consulta servida |
|---|---|---|
| User | `UNIQUE(emailNormalized)` | Login / registro: `WHERE emailNormalized = $1`. |
| RefreshToken | `UNIQUE(tokenHash)` | Refresh: `WHERE tokenHash = sha256($token)` (búsqueda puntual en cada rotación). |
| RefreshToken | `(userId)` | Logout global / cambio de contraseña: `UPDATE … SET revokedAt WHERE userId = $1 AND revokedAt IS NULL`. |
| RefreshToken | `(familyId)` | Detección de reutilización: revocar toda la familia `WHERE familyId = $1`. |
| RefreshToken | `(expiresAt)` | Limpieza periódica (cron en la API, sin tabla de worker): `DELETE WHERE expiresAt < now() - interval '7 days'`. |
| RefreshToken | `UNIQUE(replacedById)` | Garantiza cadena 1:1; navegar al sucesor. |
| TrainingProfile | PK `(userId)` | Cargar perfil del usuario autenticado. |
| UserExercisePreference | PK `(userId, exerciseId)` | Motor: vetados/favoritos del usuario. |
| UserExercisePreference | `(exerciseId)` | Admin: "¿cuántos usuarios vetan X?"; soporte a FK RESTRICT. |
| ConsentEvent | `(userId, purpose, occurredAt DESC)` | Estado vigente: último evento por propósito (`LIMIT 1`); antes de cada escritura de datos art. 9. |
| SubstitutionGroup | `UNIQUE(key)` | Seed idempotente / lookup por clave. |
| Exercise | `UNIQUE(slug)` | Seed idempotente, URLs. |
| Exercise | GIN `(equipment)` | Motor: `WHERE equipment <@ $userEquipment::"Equipment"[] AND deletedAt IS NULL`. |
| Exercise | `(movementPattern)` | Motor: candidatos por patrón. |
| Exercise | `(substitutionGroupId)` | Sustituciones: hermanos del grupo. |
| Exercise | parcial `(minLevel, movementPattern) WHERE deletedAt IS NULL` *(SQL crudo)* | Catálogo activo filtrado por nivel. |
| ExerciseMuscle | PK `(exerciseId, muscle)` | Músculos de un ejercicio. |
| ExerciseMuscle | `(muscle, role)` | Motor: ejercicios con músculo prioritario como primario. |
| ExerciseRiskTag | PK `(exerciseId, zone)` + `(zone)` | Motor: excluir/penalizar `WHERE zone = ANY($limitations)`. |
| ExerciseMedia | `(exerciseId, moderationStatus)` | App: media aprobada de un ejercicio. |
| ExerciseMedia | `(moderationStatus, createdAt)` | Admin: cola de moderación pendiente. |
| ExerciseMedia | parcial único `(exerciseId) WHERE isPrimary AND moderationStatus='approved'` *(SQL crudo)* | Garantiza ≤1 media principal aprobada. |
| TrainingPlan | `(userId, status)` | "Mi plan activo". |
| TrainingPlan | parcial único `(userId) WHERE status='active'` *(SQL crudo)* | Invariante: un solo plan activo por usuario. |
| TrainingPlan / PlanVersion / PlanSession / WorkoutSession | `UNIQUE(id, userId)` | Destinos de FK compuesta (propiedad por usuario en BD). |
| PlanVersion | `UNIQUE(planId, version)` | Versión vigente (`ORDER BY version DESC LIMIT 1`) e histórico; evita versiones duplicadas en carrera. |
| PlanVersion | `(userId, createdAt DESC)` | Historial de versiones del usuario / exportación. |
| PlanSession | `UNIQUE(planVersionId, order)`, `UNIQUE(planVersionId, dayIndex)` | Sesiones de una versión en orden; invariante de un día = una sesión. |
| PlanExercise | `UNIQUE(planSessionId, order)` | Ejercicios de la sesión en orden persistido. |
| PlanExercise | `(exerciseId)` | FK RESTRICT (Postgres no indexa FKs automáticamente) y "planes que usan X". |
| WorkoutSession | `UNIQUE(userId, clientId)` | Creación idempotente desde móvil (`INSERT … ON CONFLICT DO NOTHING`). |
| WorkoutSession | `(userId, startedAt DESC)` | Historial de entrenamientos paginado. |
| WorkoutSession | `(planSessionId)` | "¿Se hizo ya esta sesión del plan?" y adherencia. |
| WorkoutSession | parcial único `(userId) WHERE status='in_progress'` *(SQL crudo, opcional)* | Un solo entrenamiento en curso por usuario. |
| SetLog | `UNIQUE(userId, clientId)` | Upsert idempotente de series reintentadas offline. Ámbito por usuario: un cliente no puede colisionar ni sondear UUIDs de otro. |
| SetLog | `(workoutSessionId, exerciseId, setIndex)` | Pintar la sesión en curso / detalle de sesión. |
| SetLog | `(userId, exerciseId, completedAt DESC)` | "Última vez que hice X" (sugerencia de carga) y recálculo e1RM. |
| SetLog | `(planExerciseId)` | Prescrito vs realizado; soporte a FK. |
| ExerciseE1rm | `UNIQUE(userId, exerciseId, workoutSessionId)` | Upsert en escritura (una fila por ejercicio y sesión). |
| ExerciseE1rm | `(userId, exerciseId, performedOn DESC)` | Gráfica de progresión de e1RM. |
| WeeklyMuscleVolume | PK `(userId, weekStart, muscle)` | Upsert en escritura; gráfica semanal por músculo (`WHERE userId AND weekStart BETWEEN`). |
| WeeklyGroupVolume | PK `(userId, weekStart, group)` | Upsert en escritura; volumen por grupo con la regla del motor (máxima fracción por ejercicio y grupo, PROGRAMACION §16.1). Fase 5: no derivable de WeeklyMuscleVolume. |
| WeeklyAdherence | PK `(userId, weekStart)` | Upsert en escritura; tarjeta de adherencia. |
| NutritionTarget | `(userId, createdAt DESC)` | Objetivo vigente (`LIMIT 1`) e historial. |

---

## 4. Política `onDelete` por relación

Principio: **el usuario es la raíz de borrado** (borrar cuenta = borrar todo lo suyo en una sola sentencia); **el catálogo nunca se borra físicamente** (RESTRICT desde cualquier historial).

| Relación (hijo → padre) | onDelete | Motivo |
|---|---|---|
| RefreshToken → User | Cascade | Sin usuario no hay sesión. |
| RefreshToken.replacedBy → RefreshToken | SetNull | La limpieza de tokens caducados no debe bloquearse por la cadena de rotación. |
| TrainingProfile → User | Cascade | 1:1, dato del usuario. |
| UserExercisePreference → User | Cascade | Dato del usuario. |
| UserExercisePreference → Exercise | Restrict | Los ejercicios solo se borran lógicamente; un DELETE físico accidental debe fallar. |
| ConsentEvent → User | Cascade | Al borrar la cuenta ya no hay tratamiento que justificar (ver §5 sobre prueba de supresión). |
| Exercise → SubstitutionGroup | SetNull | Eliminar un grupo no debe afectar al ejercicio; solo pierde sustituciones. |
| ExerciseMuscle / ExerciseRiskTag / ExerciseMedia → Exercise | Cascade | Son partes del ejercicio; como el ejercicio nunca se borra físicamente, en la práctica solo actúa en limpieza administrativa explícita. |
| ExerciseMedia.moderatedBy → User | SetNull | Borrar la cuenta de un admin no borra el contenido moderado. |
| TrainingPlan → User | Cascade | Raíz de borrado. |
| PlanVersion → TrainingPlan (FK compuesta) | Cascade | La versión no existe sin plan. |
| PlanVersion / PlanSession → User | Cascade | Redundante con la cadena, pero coherente; evita filas huérfanas si se borra por otro camino. |
| PlanSession → PlanVersion (FK compuesta) | Cascade | Parte de la versión. |
| PlanExercise → PlanSession | Cascade | Parte de la sesión. |
| **PlanExercise → Exercise** | **Restrict** | Requisito: nunca destruir historial de planes. Fuerza borrado lógico del catálogo. |
| WorkoutSession → User | Cascade | Raíz de borrado. |
| **WorkoutSession → PlanSession (FK compuesta)** | **NoAction** | Debe impedir borrar una sesión de plan que tiene entrenamientos, **pero** permitir el borrado de cuenta: con `RESTRICT` Postgres comprueba de inmediato y el borrado en cascada desde `User` puede fallar según el orden interno; `NO ACTION` comprueba al final de la sentencia, cuando la cascada ya ha eliminado también los `WorkoutSession`. |
| SetLog → User | Cascade | Raíz de borrado. |
| SetLog → WorkoutSession (FK compuesta) | Cascade | La serie es parte del entrenamiento (borrar un entrenamiento — función de usuario — borra sus series y se recalculan agregados). |
| SetLog → PlanExercise | NoAction | Mismo razonamiento que WorkoutSession → PlanSession. |
| **SetLog → Exercise** | **Restrict** | Historial de entrenamiento nunca huérfano. |
| ExerciseE1rm → User | Cascade | Raíz. |
| ExerciseE1rm → WorkoutSession | Cascade | Si se borra un entrenamiento, su e1RM deja de ser válido. |
| ExerciseE1rm → Exercise | Restrict | Historial. |
| ExerciseE1rm.sourceSetLogId | sin FK | Proyección reconstruible; una FK aquí obligaría a ordenar el recálculo y no aporta integridad útil (la fila se recalcula desde la sesión). |
| WeeklyMuscleVolume / WeeklyGroupVolume / WeeklyAdherence → User | Cascade | Raíz. `planVersionId` informativo sin FK. |
| NutritionTarget → User | Cascade | Raíz. |

Borrado lógico de `Exercise`: el servicio de catálogo filtra `deletedAt IS NULL` en todas las lecturas para el motor y el catálogo público; las lecturas de historial (planes, logs) **no** filtran, para mostrar el nombre del ejercicio retirado.

---

## 5. Notas RGPD

### 5.1 Clasificación de campos

| Categoría | Campos | Base jurídica |
|---|---|---|
| **Categoría especial (art. 9, datos de salud)** | `TrainingProfile.limitations`, `TrainingProfile.weightKg`, `TrainingProfile.heightCm`; los mismos valores copiados en `PlanVersion.inputSnapshot` y `NutritionTarget.inputsSnapshot`; `BodyMeasurement` (peso y perímetros; ADR-0013). | Consentimiento explícito (art. 9.2.a) → `ConsentEvent`, por ámbitos según la versión del texto. |
| Texto libre que puede contener salud | `UserExerciseNote.text` (ADR-0013). | Ejecución del contrato; se trata como restringido (exportación, borrado, nunca en logs; riesgo residual en la DPIA). |
| Datos personales ordinarios | `User.email`, `TrainingProfile.age`, `sex`, `goal`, `level`, días/minutos, equipo, músculos prioritarios, preferencias de ejercicios, planes, `SetLog`, analítica, objetivos nutricionales (kcal/macros). | Ejecución del contrato (art. 6.1.b). |
| Datos técnicos | Ninguno: no se guarda IP ni user-agent (minimización; migración `20261110000000_minimizacion_ip_user_agent`). La prueba del consentimiento es el evento autenticado con versión y hash del texto. | — |

Nota: los registros de carga/repeticiones no se consideran por sí solos datos de salud, pero combinados con limitaciones podrían inferirse; se tratan con el mismo control de acceso (solo el titular y procesos del sistema; los admin **no** tienen endpoints de lectura de datos de usuario en v1).

`sex` no es categoría especial (el art. 9 cubre vida/orientación sexual, no sexo), pero es opcional y se trata como sensible a efectos de minimización.

### 5.2 Consentimiento
- Append-only: cada concesión o retirada es una fila nueva con `policyVersion` y `textHash` del texto exacto mostrado (prueba art. 7.1).
- Escritura condicionada: la API rechaza (`409/422`) escribir `weightKg`, `heightCm` o `limitations` si el último `ConsentEvent` para `health_data_processing` no es `granted` con la `policyVersion` vigente. Un cambio de versión material exige reconsentir.
- **Retirada** (en la misma transacción): `limitations = []`, `weightKg = NULL`, `heightCm = NULL`; se **redactan** las claves de salud en `PlanVersion.inputSnapshot` y `NutritionTarget.inputsSnapshot` (`jsonb - 'weightKg' - 'heightCm' - 'limitations'`), marcando `"redacted": true`. El plan y los objetivos ya generados se conservan (los valores derivados — kcal, ejercicios — no son el dato de salud en sí). El motor pasa a operar sin limitaciones y sin peso (cargas iniciales sin estimar por peso corporal).
- Sin consentimiento la app es plenamente usable (el consentimiento debe ser libre: no puede condicionar el servicio).
- **Ámbitos por versión (ADR-0013).** Cada versión del texto cubre unos ámbitos (`weight`, `height`, `limitations`, `body_measurements`, `derived_estimates`; `HEALTH_CONSENT_POLICIES` en contratos y `HealthConsentStatus.scopes`). La versión anterior (`health-2026-11`) sigue vigente para peso, altura y limitaciones; los perímetros y las estimaciones (IMC, % de grasa) exigen la versión `health-2026-11-v2`. Conceder la versión actual con una anterior vigente añade un evento nuevo. La retirada borra además todas las filas de `BodyMeasurement`.

### 5.3 Exportación (art. 15 y 20)
- Endpoint síncrono `GET /me/export` (sin tablas de worker): JSON en streaming con `User` (sin `passwordHash`), `TrainingProfile`, `UserExercisePreference`, `ConsentEvent`, `TrainingPlan` → `PlanVersion` → `PlanSession` → `PlanExercise`, `WorkoutSession` → `SetLog`, analítica, `NutritionTarget`. Desde ADR-0013 también `exerciseNotes`, `trainingBreaks`, `bodyMeasurements` y, en cada ejercicio del plan, el cambio fijado (`pinned`). Los ejercicios se exportan por `slug` + nombre (no IDs internos opacos). Se excluyen `RefreshToken.tokenHash`.
- Volumen esperado (años de logs ≈ decenas de miles de filas) cabe en streaming; si deja de caber, se reconsidera un job asíncrono en v2.

### 5.4 Supresión (art. 17)
- `DELETE /me` con reautenticación (contraseña): una transacción que hace `DELETE FROM "User" WHERE id = $1`; la cascada de §4 elimina todo. Las FK `NoAction` se resuelven al final de la sentencia. `Exercise` no se ve afectado (RESTRICT solo apunta hacia el catálogo).
- `ExerciseMedia.moderatedById` → NULL si el usuario era admin.
- Copias de seguridad: los datos borrados persisten en backups hasta su rotación (propuesta: 30 días); documentarlo en la política de privacidad. Tras restaurar un backup, reaplicar las supresiones registradas.
- Prueba de supresión sin datos personales: log de aplicación con `sha256(userId)` + timestamp y, desde el issue #17, un `AuditEvent` `account_deleted` **sin userId** con un id de borrado aleatorio (`subjectRef`, también en el log). Los demás eventos de auditoría del usuario se borran en cascada.

### 5.5 Retención

| Dato | Retención |
|---|---|
| Cuenta y datos de entrenamiento | Mientras la cuenta exista. |
| Cuentas inactivas | Propuesta: aviso a los 24 meses sin login y supresión a los 27 (requiere `lastLoginAt` en `User` — **decisión pendiente**, no incluido en el schema). |
| `RefreshToken` | Borrado físico a `expiresAt + 7 días` (los revocados conservan 7 días para investigación de reutilización). IP/UA desaparecen con el token. |
| `ConsentEvent` | Vida de la cuenta (prueba del consentimiento mientras se trata el dato). |
| `AuditEvent` | 180 días (`AUDIT_RETENTION_DAYS`, `pnpm --filter @pipos/api audit:cleanup` diario); se borra antes con la cuenta (salvo `account_deleted`, sin userId). |
| `ThrottlerRecord` | Minutos: se borra al caducar la ventana o el bloqueo. |
| Snapshots `inputSnapshot` | Vida de la versión; redactados al retirar consentimiento. |
| Backups | 30 días (propuesta). |

---

## 6. Estrategia de migración

1. **Confirmar que no hay datos de producción** (ni staging con datos reales). Es la premisa: si existiera algún entorno con datos, esta estrategia no vale y habría que escribir migraciones de transformación. ⚠️ *Pendiente de confirmación explícita por el responsable del despliegue.*
2. **Borrar** las 6 migraciones actuales (`20240305000000_init` … `20260311222510_add_remaining_tables`), que además tienen deriva respecto al schema (H1).
3. Sustituir `schema.prisma` por el de §1 y generar **una única migración inicial limpia**:
   ```bash
   cd apps/api
   pnpm prisma migrate dev --name init_v1 --create-only
   ```
4. **Añadir a mano al final de `migration.sql`** lo que Prisma no expresa (mantenerlo en un bloque comentado `-- RAW: constraints no expresables en Prisma`):
   ```sql
   -- Perfil
   ALTER TABLE "TrainingProfile"
     ADD CONSTRAINT tp_days_chk    CHECK ("daysPerWeek" BETWEEN 2 AND 6),
     ADD CONSTRAINT tp_minutes_chk CHECK ("minutesPerSession" BETWEEN 30 AND 90),
     ADD CONSTRAINT tp_weight_chk  CHECK ("weightKg" IS NULL OR "weightKg" BETWEEN 25 AND 400),
     ADD CONSTRAINT tp_height_chk  CHECK ("heightCm" IS NULL OR "heightCm" BETWEEN 100 AND 250),
     ADD CONSTRAINT tp_age_chk     CHECK ("age" IS NULL OR "age" BETWEEN 14 AND 100);

   -- Catálogo
   ALTER TABLE "Exercise" ADD CONSTRAINT ex_equipment_nonempty CHECK (cardinality("equipment") >= 1);
   ALTER TABLE "ExerciseMuscle" ADD CONSTRAINT em_fraction_chk CHECK ("fraction" > 0 AND "fraction" <= 1);
   ALTER TABLE "ExerciseMedia"
     ADD CONSTRAINT media_range_chk  CHECK ("endSeconds" IS NULL OR "startSeconds" IS NULL OR "endSeconds" > "startSeconds"),
     ADD CONSTRAINT media_source_chk CHECK (("kind" = 'youtube' AND "externalId" IS NOT NULL) OR ("kind" = 'image' AND "url" IS NOT NULL));
   -- 20261114000000_medios_ejercicio (ADR-0014, Fase 4) la sustituye: una imagen necesita
   -- ("file" o "url"), "credit" y "licence"; un vídeo, su "externalId".
   CREATE UNIQUE INDEX media_one_primary ON "ExerciseMedia"("exerciseId")
     WHERE "isPrimary" AND "moderationStatus" = 'approved';
   CREATE INDEX exercise_active_level ON "Exercise"("minLevel", "movementPattern") WHERE "deletedAt" IS NULL;

   -- Planes
   CREATE UNIQUE INDEX plan_one_active_per_user ON "TrainingPlan"("userId") WHERE "status" = 'active';
   ALTER TABLE "PlanVersion" ADD CONSTRAINT pv_meso_chk CHECK ("mesocycleWeeks" BETWEEN 1 AND 16),
                             ADD CONSTRAINT pv_version_chk CHECK ("version" >= 1);
   ALTER TABLE "PlanSession" ADD CONSTRAINT ps_day_chk CHECK ("dayIndex" BETWEEN 0 AND 6),
                             ADD CONSTRAINT ps_minutes_chk CHECK ("targetMinutes" BETWEEN 30 AND 90);
   ALTER TABLE "PlanExercise"
     ADD CONSTRAINT pe_sets_chk CHECK ("sets" BETWEEN 1 AND 10),
     ADD CONSTRAINT pe_reps_chk CHECK ("repMin" >= 1 AND "repMin" <= "repMax" AND "repMax" <= 50),
     ADD CONSTRAINT pe_rir_chk  CHECK ("targetRir" BETWEEN 0 AND 5),
     ADD CONSTRAINT pe_rest_chk CHECK ("restSeconds" BETWEEN 15 AND 600),
     ADD CONSTRAINT pe_load_chk CHECK ("initialLoadKg" IS NULL OR "initialLoadKg" >= 0);

   -- Registro
   ALTER TABLE "WorkoutSession" ADD CONSTRAINT ws_time_chk CHECK ("completedAt" IS NULL OR "completedAt" >= "startedAt");
   CREATE UNIQUE INDEX ws_one_in_progress ON "WorkoutSession"("userId") WHERE "status" = 'in_progress';
   ALTER TABLE "SetLog"
     ADD CONSTRAINT sl_reps_chk CHECK ("reps" BETWEEN 0 AND 100),
     ADD CONSTRAINT sl_load_chk CHECK ("loadKg" >= 0),
     ADD CONSTRAINT sl_rir_chk  CHECK ("rir" IS NULL OR "rir" BETWEEN 0 AND 10);

   -- Nutrición
   ALTER TABLE "NutritionTarget"
     ADD CONSTRAINT nt_kcal_chk   CHECK ("kcal" BETWEEN 800 AND 6000),
     ADD CONSTRAINT nt_macros_chk CHECK ("proteinG" >= 0 AND "fatG" >= 0 AND "carbsG" >= 0);
   ```
5. Aplicar y verificar sin deriva:
   ```bash
   pnpm prisma migrate reset        # BD local vacía
   pnpm prisma migrate diff --from-migrations prisma/migrations --to-schema-datamodel prisma/schema.prisma --shadow-database-url "$SHADOW_DATABASE_URL" --exit-code
   ```
   El `diff` debe salir con código 0 (los CHECK/índices parciales en SQL crudo no generan deriva porque Prisma no los modela).
6. **Commitear `apps/api/prisma/migrations/migration_lock.toml`** (`provider = "postgresql"`), hoy ausente (H2), junto con la migración.
7. **CI**: añadir el paso `prisma migrate diff … --exit-code` y un `prisma migrate deploy` contra un Postgres efímero, para que no vuelva a aparecer deriva como H1.
8. Reescribir `prisma/seed.ts`: catálogo de ejercicios idempotente por `slug` (upsert), `SubstitutionGroup` por `key`; eliminar el seed de nutrición/alimentos.
9. A partir de aquí, **nunca** editar migraciones aplicadas; cada cambio = nueva migración.

### Rollback
Al no haber datos, el rollback de la migración inicial es `DROP SCHEMA public CASCADE; CREATE SCHEMA public;` (o `prisma migrate reset`) y volver al commit anterior.

### Pendientes de confirmar
1. Ausencia de datos de producción/staging (bloqueante para el paso 2).
2. `age` vs `birthYear`.
3. `lastLoginAt` + política de inactividad.
4. Tabla `AccountDeletionLog` (sí/no).
5. Lista cerrada de `Equipment` y de `MovementPattern` (revisión por el responsable del motor).
6. Zona horaria del usuario para `weekStart` (propuesta: campo `timezone` en `User` o enviado por el cliente al escribir; hoy el schema no lo incluye).
