# Deuda técnica conocida (cierre de la Fase 5)

Hallazgos de las revisiones de cierre **no corregidos** en la Fase 5, más los conocidos de antes.
Cada entrada está lista para copiarse como issue de GitHub: el `###` es el título y lo de debajo el
cuerpo. Severidad: **Alta** (riesgo para datos o seguridad, o bloquea producción) · **Media**
(comportamiento incorrecto visible) · **Baja** (mejora o caso raro).

Lo que bloquea el despliegue (firma, TLS, DPIA…) está además en [DEPLOY_CHECKLIST.md](DEPLOY_CHECKLIST.md).

## API y backend

### ~~[API] Configurar `trust proxy` y un almacén compartido para el rate limiting~~ — RESUELTO
- **Estado:** resuelto (PR pendiente); cierra el issue #9.
- **Qué se hizo:** `TRUST_PROXY_HOPS` (entero 0-10, por defecto 0, validado en `env.ts`) →
  `app.set('trust proxy', n)`; contadores del throttler en Postgres (`ThrottlerRecord`, un
  `INSERT … ON CONFLICT DO UPDATE` atómico con caducidad y bloqueo; limpieza de filas caducadas
  como mucho una vez por minuto y réplica) con `THROTTLE_STORE=memory|postgres` (por defecto
  `postgres` en producción, `memory` fuera). e2e: límites por cliente con `X-Forwarded-For` y
  1 salto, cabecera ignorada con 0, dos réplicas compartiendo el contador, upsert concurrente sin
  pérdidas. Ya no hace falta una sola instancia (DEPLOY_CHECKLIST actualizado).

### ~~[API] Rechazar entrenamientos sobre sesiones de una versión de plan antigua~~ — RESUELTO (API)
- **Estado:** resuelto en la API (PR pendiente); cierra el issue #10. Falta el manejo en la app
  (entrada «[Móvil] Manejar `409 PLAN_SESSION_OUTDATED`» más abajo).
- **Qué se hizo:** `POST /workouts` devuelve `409 PLAN_SESSION_OUTDATED` si `planSessionId` no es de
  la versión vigente del plan activo, **solo al crear** un entrenamiento (que nunca tiene series
  todavía). Reenviar un `clientId` ya registrado devuelve el existente (200) aunque su versión ya
  no sea la vigente, y ese entrenamiento sigue aceptando series, ediciones, sustituciones y cierre.
  e2e: `plan-outdated.e2e-spec.ts`.

### ~~[API] Idempotencia de `POST /plans/generate` (doble toque → dos versiones)~~ — RESUELTO (API)
- **Estado:** resuelto en la API (PR pendiente); cierra el issue #11. La app debe enviar la cabecera.
- **Qué se hizo:** cabecera opcional `Idempotency-Key` (1-128 caracteres ASCII visibles; 400 si no)
  con `UNIQUE(userId, idempotencyKey)` en `PlanVersion` y la huella SHA-256 de la entrada del motor.
  Misma clave y misma entrada → la versión ya creada con **200** (la primera vez, 201); misma clave
  con otra entrada (el perfil cambió entre medias) → **422 `IDEMPOTENCY_KEY_REUSED`**. Dos toques
  simultáneos con la misma clave crean una sola versión. Sin cabecera nada cambia (el e2e de dos
  generaciones simultáneas sigue esperando dos versiones). e2e: `plan-idempotency.e2e-spec.ts`.
- **Para la app:** generar un UUID v4 por pulsación de «Generar plan» y reenviar el mismo en cada
  reintento de esa pulsación; tratar 200 y 201 igual; ante 422 `IDEMPOTENCY_KEY_REUSED`, generar
  una clave nueva y reintentar una vez.

### ~~[Motor] Redondear la carga a los incrementos reales del material (mancuernas, máquinas)~~ — RESUELTO
- **Estado:** resuelto con ADR-0013 (idea 1); cierra el issue #12.
- **Qué se hizo:** paso de carga por material en `PROGRAMMING.load` (barra 2,5 kg en total,
  mancuernas 2 kg, kettlebell 4 kg, máquina 5 kg…; heurística, PROGRAMACION §16.16), aplicado a
  cargas iniciales, aproximaciones, subidas (al siguiente peso disponible, con aviso si el salto
  supera el 10 %) y bajadas; desglose de discos por lado en la sesión de hoy. Test de propiedad
  «la carga propuesta es múltiplo del paso del material».

### ~~[API] Estado `abandoned` sin flujo: un entreno en curso olvidado bloquea los siguientes~~ — RESUELTO (API)
- **Estado:** resuelto en la API (PR pendiente); cierra el issue #13.
- **Qué se hizo:** `POST /workouts/:id/abandon` (idempotente: abandonar uno ya abandonado devuelve
  200 con el mismo estado; uno terminado → `409 WORKOUT_FINISHED`; ajeno → 404). Al empezar un
  entrenamiento, si el que está en curso lleva más de `STALE_WORKOUT_HOURS` = **12 h** sin
  actividad (inicio o última serie, reloj del cliente) se abandona solo y se crea el nuevo; si no,
  sigue el `409 WORKOUT_IN_PROGRESS`. Un abandonado conserva sus series pero no cuenta en e1RM,
  volumen ni adherencia (se recalcula su semana en la misma transacción) y no admite series nuevas
  ni cierre (`409 WORKOUT_FINISHED`). e2e: `abandon.e2e-spec.ts`.
- **Para la app:** botón «Descartar entrenamiento» que llame a `abandon` (idempotente, apto para la
  cola offline). Si una serie encolada recibe `409 WORKOUT_FINISHED` y `GET /workouts/:id` dice
  `abandoned`, avisar de que ese entrenamiento se descartó (automáticamente tras 12 h) y no
  reintentar.

### ~~[API] La adherencia de semanas pasadas usa la versión vigente del plan~~ — RESUELTO
- **Estado:** resuelto (PR pendiente); cierra el issue #14.
- **Qué se hizo:** `recomputeWeek` (al escribir y en `analytics:rebuild`) toma la versión del plan
  activo creada antes del final de esa semana (`createdAt < lunes siguiente`, zona del usuario) y
  la guarda en `WeeklyAdherence.planVersionId`; `GET /progress/adherence` rellena cada semana sin
  actividad con la versión vigente en esa semana (nada antes del primer plan). Helpers puros
  `versionForWeek`/`plannedOf`. e2e con dos versiones (3 → 5 días):
  `adherence-versions.e2e-spec.ts`. Tras desplegar, `analytics:rebuild` corrige las filas antiguas.

### ~~[Motor] La descarga reactiva no reinicia el ciclo de descarga programada~~ — RESUELTO
- **Estado:** resuelto (PR pendiente); cierra el issue #15.
- **Qué se hizo:** `TrainingPlan.lastDeloadOn` (fecha local, migración incremental) se fija al
  cerrar un entrenamiento cuya prescripción era de descarga: la sesión cuenta como descarga si al
  menos la mitad de sus ejercicios la tenían (la programada descarga todos; la reactiva de un solo
  ejercicio estancado no es una semana de descarga del plan). Solo se mueve si ya terminó la
  descarga anterior (`deloadDurationDays`, 7). `weeksSinceDeload` se ancla a esa fecha: durante
  esos 7 días sigue la descarga y después cuenta las semanas desde que terminó; sin descarga
  registrada, desde el inicio del plan como antes. Unit (`weeksSinceDeload`, `isDeloadSession`,
  `startsNewDeload`, cierre) y e2e (`deload.e2e-spec.ts`).

### [Seguridad] Enumeración de emails por `409 AUTH_EMAIL_TAKEN` en el registro
- **Severidad:** Media
- **Impacto:** el registro revela si un email existe; solo lo frena el rate limiting (5/min/IP).
- **Propuesta:** respuesta neutra y verificación por email (requiere proveedor de correo).

### ~~[Seguridad] Sin registro de auditoría de autenticación ni de cambios de datos de salud~~ — RESUELTO
- **Estado:** resuelto (PR pendiente); cierra el issue #17.
- **Qué se hizo:** tabla `AuditEvent` append-only (un trigger rechaza UPDATE; INSERT y DELETE sí)
  con solo `type`, `userId`, `subjectRef` y `createdAt`. Eventos: `login_succeeded`,
  `login_failed` (con un email desconocido, `userId` null y nada que lo identifique: ni email ni
  hash), `refresh_reuse_detected`, `health_consent_granted`/`withdrawn`,
  `health_profile_changed` (limitaciones, peso o altura: solo el tipo), `body_measurement_saved`/
  `deleted` y `account_deleted`. Decisión RGPD: al borrar la cuenta sus eventos se borran en
  cascada y queda solo `account_deleted` **sin userId**, con un id de borrado aleatorio
  (`subjectRef`, también en el log). Retención `AUDIT_RETENTION_DAYS` = 180 días con
  `pnpm --filter @pipos/api audit:cleanup` (tarea diaria, DEPLOY_CHECKLIST). Se incluye en
  `GET /me/export` (`auditEvents`: tipo y fecha). Unit + e2e (`audit.e2e-spec.ts`).

### ~~[CI] Dependabot y `pnpm audit` / `flutter pub outdated` en CI~~ — RESUELTO
- **Estado:** resuelto (PR pendiente); cierra el issue #18.
- **Qué se hizo:** `.github/dependabot.yml` (npm en la raíz, pub en `apps/mobile`, github-actions;
  semanal, agrupado por menores/parches) y paso de CI `pnpm audit --prod --audit-level high`, que
  falla con vulnerabilidades altas o críticas. Para dejarlo en verde: `bcrypt` 5 → 6 (quita
  `node-pre-gyp`, `tar` y `brace-expansion`) y `pnpm.overrides` mínimos a la versión parcheada
  dentro de la misma mayor (multer, body-parser, path-to-regexp, proxy-addr, lodash, js-yaml).
  Excepción documentada en SECURITY §6.3: `zod` (GHSA-mrhx-c7xc-m3w5, solo parcheado en zod 4;
  entrada acotada por el límite de cuerpo). `flutter pub outdated` no se añade: Dependabot de pub
  cubre las actualizaciones de la app.

### ~~[CI] Migrar a zod 4 (excepción de `pnpm audit`)~~ — RESUELTO
- **Estado:** resuelto en la rama `deps/migracion-zod` (migración de dependencias mayores, PR #50).
- **Qué se hizo:** `packages/contracts` y la API en zod 4.6 (`z.record` con clave, `z.iso.datetime`,
  `z.uuid`, `z.email`, `error` en lugar de `required_error`; rutas de los issues con `PropertyKey`).
  `zod-to-json-schema` sustituido por `z.toJSONSchema` (OpenAPI 3.0, `io` de entrada/salida),
  quitando el `pattern` redundante de los formatos estándar y los límites ±2^53−1 de `.int()`.
  `openapi.json` regenerado: mismos contratos, más precisos (los campos con `default` son
  obligatorios en las respuestas, parámetros opcionales sin `anyOf`, fechas con tipo). Fixtures
  móviles validados. Fuera la excepción GHSA-mrhx-c7xc-m3w5: `pnpm audit` ya no ignora nada.

### [Catálogo] Pullover en polea frente al jalón con hombro limitado
- **Severidad:** Baja
- **Impacto:** tras etiquetar el jalón con `shoulder:caution` (Fase 5), con hombro limitado el
  motor elige el pullover con brazos rectos, que también lleva el hombro a flexión completa.
- **Propuesta:** revisar la etiqueta del pullover con un fisioterapeuta/entrenador y preferir
  remos para el tirón en ese caso.

### [RGPD] Explicaciones de planes anteriores a la Fase 5 sin marcar los textos de salud
- **Severidad:** Baja (no hay datos de producción)
- **Impacto:** antes de la Fase 5 las notas derivadas de la limitación se guardaban como texto
  normal; la retirada del consentimiento no las encontraría.
- **Propuesta:** solo si hubiera datos previos: migración que marque como `health` las notas que
  empiecen por «Precaución por tu limitación» / «Por tu limitación» y los avisos con
  `data.reason = 'limitation'`.
- **Estado (issue #20, abierto):** no hace falta mientras no exista ninguna base de datos con planes
  generados antes de la Fase 5 (la API nunca se ha desplegado). Solo habría que hacerlo si se
  importaran o restauraran datos de esa época; si se confirma que no los hay, se puede cerrar.

### [Motor] Pasos de carga propios del usuario (microdiscos, mancuernas de 1 kg)
- **Severidad:** Baja
- **Impacto:** el paso por material es el típico de un gimnasio (ADR-0013, idea 1); quien tenga
  microdiscos o mancuernas de 1 en 1 recibe saltos mayores de lo necesario.
- **Propuesta:** `TrainingProfile.loadSteps Json?` opcional que sustituya a `PROGRAMMING.load` por
  material, con el mismo test de propiedad.

### [API] La adherencia de una sesión ajustada cuenta las series del plan completo
- **Severidad:** Baja
- **Impacto:** con «poco tiempo» o «volumen reducido» (ADR-0013, idea 4) las series previstas de
  la semana siguen siendo las del plan, así que la adherencia de series baja aunque el usuario hizo
  todo lo que eligió.
- **Propuesta:** guardar las series previstas ajustadas al empezar el entreno y usarlas en
  `recomputeWeek`.

### [API] Ejercicios quitados por el ajuste de hoy con series ya registradas
- **Severidad:** Baja
- **Impacto:** si se registran series de un ejercicio y después se aplica un ajuste que lo quita,
  `GET /sessions/today` deja de mostrarlo (las series siguen guardadas y cuentan).
- **Propuesta:** no quitar nunca un ejercicio con series registradas en el entreno en curso.

### [Motor] Anclar la descarga programada al final de una pausa planificada
- **Severidad:** Baja
- **Impacto:** tras una pausa de 7 días o más (ADR-0013, idea 6) la descarga programada puede caer
  poco después de volver. La descarga reactiva ya ancla el ciclo (issue #15); la pausa todavía no.
- **Propuesta:** reiniciar `weeksSinceDeload` al terminar una pausa de 7 días o más (con el ancla
  `TrainingPlan.lastDeloadOn` del issue #15 basta con tratar el fin de la pausa como una descarga).

### [RGPD] DPIA: medidas corporales, estimaciones derivadas y notas de texto libre
- **Severidad:** Media (bloquea el lanzamiento público junto con la DPIA pendiente)
- **Impacto:** ADR-0013 añade medidas corporales (peso y perímetros), IMC y % de grasa estimado
  (art. 9) y notas de texto libre que podrían contener datos de salud.
- **Propuesta:** incluirlos en la DPIA y en el registro de actividades; revisión legal del texto
  `health-2026-11-v2` del consentimiento. La idea 5 (dolor) necesitará otra versión del texto.

## App móvil

Lista facilitada por la revisión de la app tras sus correcciones de la Fase 5.

### ~~[Móvil] Manejar `409 PLAN_SESSION_OUTDATED` al empezar un entrenamiento~~ — RESUELTO (PR pendiente)
- **Estado:** resuelto en la rama `deuda/movil-1`.
- **Qué se hizo:** `SyncService._startOnServer` trata `PLAN_SESSION_OUTDATED` como recuperable:
  relee `GET /sessions/today` y, si el entrenamiento local no tiene series ni cambios de ejercicio,
  lo reapunta a la sesión vigente y reintenta `POST /workouts` con el mismo `clientId`. Si ya tiene
  series, queda en conflicto con su motivo (sin bloquear la cola): Hoy avisa de que el plan cambió
  y ofrece descartarlo (se conserva en el móvil hasta entonces); la sesión y el plan se releen.
  Tests en `test/core/offline/sync_service_test.dart`.

### ~~[Móvil] Enviar `Idempotency-Key` al generar el plan y descartar entrenamientos~~ — RESUELTO (PR pendiente)
- **Estado:** resuelto en la rama `deuda/movil-1`.
- **Qué se hizo:**
  - «Generar mi plan» envía `Idempotency-Key` (UUID v4 por pulsación, reutilizado en cada
    reintento hasta que sale bien); ante `422 IDEMPOTENCY_KEY_REUSED`, clave nueva y un reintento.
    La edición del perfil no llama a `/plans/generate` (la versión la crea `PUT /me/profile`).
    Tests en `test/features/onboarding/onboarding_test.dart`.
  - «Abandonar entrenamiento» en Hoy (con confirmación), también sin red: cierra el entrenamiento en
    local (columna `abandoned`, drift v5), descarta las series no confirmadas y la cola envía
    `POST /workouts/:id/abandon` (idempotente; `409 WORKOUT_FINISHED` se da por cerrado).
  - Una serie o un cambio de ejercicio que recibe `409 WORKOUT_FINISHED` (entrenamiento cerrado en
    el servidor, p. ej. abandonado solo tras 12 h) cierra el entrenamiento en local sin reintentar
    ni bloquear la cola, y Hoy avisa de cuántas series no se subieron. Un entrenamiento abierto, sin
    nada pendiente y sin actividad desde hace más de 12 h se cierra como abandonado al empezar otro.
    Tests: `test/core/offline/abandon_queue_test.dart`, `test/features/today/abandon_workout_test.dart`.

### ~~[Móvil] Poder descartar una serie rechazada de forma permanente por la API~~ — RESUELTO (PR pendiente)
- **Estado:** resuelto en la rama `deuda/movil-1`; cierra el issue #21.
- **Qué se hizo:** la fila de la serie fallida muestra el motivo del rechazo y «Descartar» (con
  confirmación). `SyncService.deleteSet` la quita de la cola; si pudo existir en el servidor
  (confirmada o con un intento de resultado desconocido) queda como lápida hasta que la API
  confirme `DELETE /workouts/:id/sets/:clientId` (404 también vale). Un rechazo de validación al
  crearla garantiza que la API no la guardó, así que se borra sin petición. Después el finish sale.
  Tests: `test/core/offline/set_queue_test.dart`, `test/features/today/discard_set_test.dart`.

### ~~[Móvil] Editar o borrar una serie ya registrada desde la interfaz~~ — RESUELTO (PR pendiente)
- **Estado:** resuelto en la rama `deuda/movil-1`; cierra el issue #22.
- **Qué se hizo:** menú por serie con «Editar» (reps, kg con `decimal_input`, RIR) y «Borrar»
  (con confirmación), optimista desde drift. `SyncService.updateSet` funde la edición con la
  creación pendiente si aún no se envió (un solo `POST`); si ya existía, envía
  `PATCH /workouts/:id/sets/:clientId` con `clientUpdatedAt` (también tras un reenvío que responde
  200 con valores viejos). La fila adopta la versión del servidor si otra edición gana. Las series
  que solo están en la API se adoptan en drift antes de editarlas. Borrar deja una lápida hasta el
  `DELETE`. Tests: `test/core/offline/set_queue_test.dart`, `test/features/today/edit_set_test.dart`.

### ~~[Móvil] Cambiar de ejercicio sin conexión~~ — RESUELTO (PR pendiente)
- **Estado:** resuelto en la rama `deuda/movil-1`; cierra el issue #23.
- **Qué se hizo:** las alternativas de cada ejercicio se guardan en caché con la sesión de hoy
  (`CacheKeys.substitutes`). El cambio de hoy se encola en drift (`PendingMutations`, tipo
  `substitute`, una fila por cambio) y Hoy lo muestra al momento («Cambio pendiente de enviar», sin
  la carga del original). `SyncService` lo envía intercalado por orden de registro con las series:
  antes que las registradas después (a igual segundo, primero el cambio) y, si se aplaza, la pasada
  se detiene para no desordenar. Fijar el cambio en el plan sigue necesitando red (mensaje propio).
  Tests de orden: `test/core/offline/swap_queue_test.dart` (el fake de la API rechaza, como la
  real, series de un ejercicio que no sea el del hueco ni su sustitución) y
  `test/features/today/swap_exercise_test.dart`.

### ~~[Móvil] Notificación del temporizador de descanso en segundo plano~~ — RESUELTO (PR pendiente)
- **Estado:** resuelto en la rama `deuda/movil-1`; cierra el issue #24.
- **Qué se hizo:** al pasar la app a segundo plano con un descanso en marcha, `RestTimerController`
  programa una notificación local (`flutter_local_notifications`, canal propio `rest_timer`) para
  `endsAt`, solo si ya hay permiso (no lo pide); se cancela al volver, al saltar el descanso o al
  empezar otro. Tests con planificador inyectado: `test/features/today/rest_notification_test.dart`.
- **Pendiente:** el aviso es inexacto (`inexactAllowWhileIdle`, sin el permiso de alarmas exactas):
  Android puede retrasarlo algunos minutos en reposo. Probarlo en un dispositivo real.

### ~~[Móvil] Dos entrenamientos locales pueden apuntar al mismo id remoto al adoptar un 409~~ — RESUELTO (PR pendiente)
- **Estado:** resuelto en la rama `deuda/movil-1`; cierra el issue #25.
- **Qué se hizo:** todo enlace con un id de la API pasa por `SyncService._linkToServer`: si otro
  entrenamiento local ya apunta a ese id, las series del duplicado pasan al ya enlazado y el
  duplicado se borra; queda terminado solo si los dos lo estaban. Tests en
  `test/core/offline/sync_service_test.dart` (dos inicios encolados; adopción desde Hoy).

### ~~[Móvil] Login offline con solo el userId en caché muestra el email vacío~~ — RESUELTO (PR pendiente)
- **Estado:** resuelto en la rama `deuda/movil-1`; cierra el issue #26.
- **Qué se hizo:** al validar la sesión (login, registro o `GET /me`) el usuario completo (`id`,
  `email`) se guarda también en el mismo valor que los tokens; `readCachedUser` lo usa si falta su
  clave propia (un refresh lo conserva; otro dueño no lo hereda). Si aun así solo hay `userId`
  (sesiones antiguas), Ajustes muestra «Sin conexión: tu correo aparecerá al recuperar la red» en
  vez de un correo vacío. Tests: `test/core/auth/token_storage_test.dart`,
  `test/features/settings/offline_email_test.dart`.

### [Móvil] Validar las reglas de exclusión de backup en un build Android real
- **Severidad:** Baja
- **Impacto:** las reglas que excluyen la base local y el almacenamiento seguro de las copias de
  seguridad no se han comprobado en un dispositivo/build real.
- **Propuesta:** `adb shell bmgr backupnow` en un build release y comprobar que la base drift y
  los tokens no aparecen en la copia.

### [Móvil] Prueba de accesibilidad con TalkBack en dispositivo real
- **Severidad:** Baja
- **Impacto:** la accesibilidad solo se ha comprobado con tests de semántica.
- **Propuesta:** guion manual con TalkBack (registro, onboarding, registrar series, progreso) y
  corrección de lo que aparezca.

### [Motor/Móvil] Explicaciones del motor y nombres de ejercicios solo en español
- **Severidad:** Baja
- **Impacto:** con la interfaz en inglés, las explicaciones, avisos, prescripciones y nombres de
  ejercicios siguen en español.
- **Propuesta:** el motor emite códigos con parámetros (`{ code, params }`) que la app traduce; usar
  `nameEn` del catálogo según el idioma.
