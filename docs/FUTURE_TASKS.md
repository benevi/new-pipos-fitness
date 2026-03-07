# Future Tasks

Tasks deferred to later phases. Do not implement in the current phase.

---

**Phase:** Phase 3  
**Task:** Exercise catalog (data, API) — **Done.** Implemented in Phase 3.  

---

**Phase:** Later — Catalog improvements  
**Task:** Support multiple muscle filters in GET /exercises, e.g. `muscleIds[]=chest&muscleIds[]=shoulders`  
**Reason:** Not required for Phase 3; single muscleId filter is enough for now  
**Suggested module:** apps/api/modules/catalog/exercises, packages/contracts  

---

**Phase:** Later — Catalog improvements  
**Task:** Add exercise list sorting: `sortBy` (popularity, difficulty, alphabetical) and `sortDirection` (asc/desc)  
**Reason:** Deferred post–Phase 3  
**Suggested module:** apps/api/modules/catalog/exercises, packages/contracts (ExerciseFilterQuery)  

---

**Phase:** Later — Catalog data  
**Task:** Before production launch, expand seed/catalog to 300+ exercises (dev seed is ~18)  
**Reason:** Current dataset is fine for dev; production needs a full catalog  
**Suggested module:** apps/api/prisma/seed or dedicated catalog import  

---

**Phase:** Later — Search scalability (Risk A)  
**Task:** Replace simple `LIKE '%query%'` search with Postgres full-text search when catalog grows (e.g. 2000+ exercises)  
**Reason:** LIKE is fine for ~300 exercises; will be slow at scale  
**Suggested module:** apps/api/modules/catalog/exercises  

---

**Phase:** Later — Security (Risk B)  
**Task:** Protect admin catalog endpoints before staging: add AdminGuard or x-admin-key header  
**Reason:** POST/PUT /admin/exercises etc. are currently open; acceptable in dev only  
**Suggested module:** apps/api/modules/auth or admin guard  

---

**Phase:** Later — Data consistency (Risk C)  
**Task:** Store `channelId` (FK to YouTubeChannel) on ExerciseMediaYouTube instead of (or in addition to) `channelName` to avoid inconsistencies  
**Reason:** Not blocking; improves referential integrity  
**Suggested module:** apps/api/prisma (schema + migration), admin media flow  

---

**Phase:** Later  
**Task:** Admin authentication for catalog admin endpoints  
**Reason:** Not in Phase 3 scope  
**Suggested module:** apps/api/modules/auth or admin guard  

---

**Phase:** Phase 4  
**Task:** Training engine logic and plan generation  
**Reason:** Implemented in Phase 4 (optimization-based engine in packages/engine-rules).  
**Suggested module:** packages/engine-rules (training), apps/api (orchestration)  

---

**Phase:** Later — Training engine  
**Task:** Multi-objective weighting tuning (e.g. muscleAlignment, durationFit, movementBalance)  
**Reason:** Phase 4 uses fixed weights; may need tuning from usage or A/B tests  
**Suggested module:** packages/engine-rules (scoring.ts)  

---

**Phase:** Later — Training engine  
**Task:** Add optional true ILP/MIP solver for plan optimization if needed  
**Reason:** Greedy + local search is deterministic and dependency-free; ILP could improve quality at cost of dependency  
**Suggested module:** packages/engine-rules  

---

**Phase:** Phase 6 (or later)  
**Task:** Incorporate workout logs / completion data into plan generation  
**Reason:** Not in Phase 4 scope; engine currently uses only in-memory catalog and user preferences  
**Suggested module:** packages/engine-rules, apps/api  

---

**Phase:** Phase 5  
**Task:** Training plan persistence and versioning — **Done.** Implemented in Phase 5 (Prisma models, POST /generate, GET current/versions/:id).  

---

**Phase:** Phase 6  
**Task:** Workout tracking — **Done.** Implemented in Phase 6 (WorkoutSession, WorkoutExercise, WorkoutSet, POST start/exercises/sets/finish, GET history).  

---

**Phase:** Phase 7  
**Task:** Progress analytics and weekly adaptive engine — **Done.** Implemented in Phase 7 (ExerciseProgress, e1RM/volume/adherence/fatigue, GET /analytics/progress and /volume, engine progress input and adaptation).  

---

**Phase:** Phase 7.1  
**Task:** Architecture hardening — **Done.** Invalid plan rejection (400), WorkoutExercise FK to Exercise, set endpoint by workoutExerciseId, VolumeTrend enum, ExerciseProgress documented as derived, localized adaptation, adherence per plan version, indexes/constraints.  

---

**Phase:** Phase 7.2  
**Task:** Final integrity pass — **Done.** WorkoutSession.planVersionId, adherence from direct planVersionId, hardened set-logging ownership, docs (ARCHITECTURE, PHASE_7_2_SUMMARY).  

---

**Phase:** Phase 7.3  
**Task:** Adherence calculation fix — **Done.** Session-based planned sets (TrainingSession), no over-counting; workouts without planSessionId excluded; docs (ARCHITECTURE, PHASE_7_3_SUMMARY).  

---

**Phase:** Phase 8  
**Task:** Nutrition engine — **Done.** Food, MealTemplate, NutritionPlan versioning; Mifflin-St Jeor + goal; macros; meal generation from templates; POST/GET nutrition-plans.  

---

**Phase:** Later (out of Phase 7 scope)  
**Task:** Nutrition engine  
**Reason:** Explicitly out of Phase 6 scope  
**Suggested module:** packages/engine-rules, apps/api  

---

**Phase:** Later (out of Phase 6 scope)  
**Task:** Analytics dashboards  
**Reason:** Explicitly out of Phase 6 scope  

---

**Phase:** Later (out of Phase 6 scope)  
**Task:** AI assistant  
**Reason:** Explicitly out of Phase 6 scope  

---

**Phase:** Later (out of Phase 6 scope)  
**Task:** Notifications  
**Reason:** Explicitly out of Phase 6 scope  

---

**Phase:** Later (out of Phase 6 scope)  
**Task:** Flutter UI for workout tracking  
**Reason:** Explicitly out of Phase 6 scope; API only  

---

**Phase:** Later  
**Task:** Enforce BCRYPT_COST (or similar) in production config check  
**Reason:** Optional in Phase 2.1  
**Suggested module:** apps/api (main.ts or config module)  

---
