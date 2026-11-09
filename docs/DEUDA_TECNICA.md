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

### [Motor] La descarga reactiva no reinicia el ciclo de descarga programada
- **Severidad:** Baja
- **Impacto:** `weeksSinceDeload` se cuenta desde el inicio del plan (corregido en la Fase 5), pero
  una descarga reactiva no se registra, así que puede haber una programada poco después.
- **Propuesta:** registrar la última semana de descarga real (p. ej. `TrainingPlan.lastDeloadOn`,
  actualizado al cerrar un entreno cuya prescripción era `deload`) y anclar el ciclo a ella.

### [Seguridad] Enumeración de emails por `409 AUTH_EMAIL_TAKEN` en el registro
- **Severidad:** Media
- **Impacto:** el registro revela si un email existe; solo lo frena el rate limiting (5/min/IP).
- **Propuesta:** respuesta neutra y verificación por email (requiere proveedor de correo).

### [Seguridad] Sin registro de auditoría de autenticación ni de cambios de datos de salud
- **Severidad:** Media
- **Impacto:** no hay trazabilidad de logins, revocaciones por reutilización ni cambios del
  perfil (salvo `ConsentEvent`).
- **Propuesta:** tabla `AuditEvent` append-only sin datos personales (tipo, userId, fecha) con
  retención limitada; registrar login, refresh reutilizado, cambio/borrado de datos de salud.

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

### [CI] Migrar a zod 4 (excepción de `pnpm audit`)
- **Severidad:** Media
- **Impacto:** `pnpm audit` ignora GHSA-mrhx-c7xc-m3w5 (zod 3) porque el parche solo existe en zod 4.
- **Propuesta:** migrar `packages/contracts` y la API a zod 4 (o a `zod/v4`), sustituir
  `zod-to-json-schema` por `z.toJSONSchema`, regenerar OpenAPI y validar los fixtures móviles;
  después quitar la excepción de `package.json`.

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
  poco después de volver. Se cruza con «La descarga reactiva no reinicia el ciclo».
- **Propuesta:** reiniciar `weeksSinceDeload` al terminar una pausa de 7 días o más.

### [RGPD] DPIA: medidas corporales, estimaciones derivadas y notas de texto libre
- **Severidad:** Media (bloquea el lanzamiento público junto con la DPIA pendiente)
- **Impacto:** ADR-0013 añade medidas corporales (peso y perímetros), IMC y % de grasa estimado
  (art. 9) y notas de texto libre que podrían contener datos de salud.
- **Propuesta:** incluirlos en la DPIA y en el registro de actividades; revisión legal del texto
  `health-2026-11-v2` del consentimiento. La idea 5 (dolor) necesitará otra versión del texto.

## App móvil

Lista facilitada por la revisión de la app tras sus correcciones de la Fase 5.

### [Móvil] Manejar `409 PLAN_SESSION_OUTDATED` al empezar un entrenamiento
- **Severidad:** Media (sin esto, un inicio encolado offline justo antes de un cambio de plan
  hecho en otro dispositivo queda en `failed` con sus series)
- **Contexto:** desde el issue #10 la API rechaza `POST /workouts` con una sesión de una versión
  del plan que ya no es la vigente. Solo afecta a entrenamientos **nuevos**: si el `clientId` ya
  existe en el servidor, el reenvío devuelve 200 y las series se siguen aceptando.
- **Comportamiento esperado del cliente:**
  1. Tratar `PLAN_SESSION_OUTDATED` como recuperable, **no** como fallo permanente de la cola.
  2. Refrescar `GET /sessions/today` (y la caché del plan, `GET /plans/current`).
  3. Si el entrenamiento local **no tiene series**: reapuntarlo a la `planSessionId` vigente que
     devuelve `/sessions/today` y reintentar el `POST /workouts` con el **mismo `clientId`**.
  4. Si **ya tiene series** locales (hechas offline con la sesión antigua): no se pueden subir a
     la sesión nueva (sus `planExerciseId` son de la versión antigua → 400). Avisar al usuario
     («tu plan cambió mientras entrenabas sin conexión») y ofrecer descartar el entrenamiento
     local o rehacerlo con la sesión vigente; nunca dejarlo bloqueando la cola.
  5. Test de sincronización: inicio encolado + regeneración del plan → reintento con la sesión
     vigente y el mismo `clientId`.

### [Móvil] Poder descartar una serie rechazada de forma permanente por la API
- **Severidad:** Media
- **Impacto:** una serie que la API rechaza con 400/422 (p. ej. desde la Fase 5, un ejercicio que no
  es el del hueco ni su sustitución registrada) queda en `failed` y bloquea el cierre del
  entrenamiento; el usuario no tiene forma de quitarla.
- **Propuesta:** en la fila de la serie fallida, acción «descartar» que la borre de la cola local
  (y, si llegó a existir en el servidor, `DELETE`), con el motivo del rechazo visible.

### [Móvil] Editar o borrar una serie ya registrada desde la interfaz
- **Severidad:** Media
- **Impacto:** la API admite `PATCH`/`DELETE /workouts/:id/sets/:clientId` (última escritura gana),
  pero la app no permite corregir un error de tecleo; el dato malo contamina e1RM y volumen.
- **Propuesta:** acción en la fila de la serie (editar reps/kg/RIR, borrar) que pase por la cola
  offline con `clientUpdatedAt`.

### [Móvil] Cambiar de ejercicio sin conexión
- **Severidad:** Baja
- **Impacto:** la sustitución exige red. Desde la Fase 5 la API rechaza (400) series de un
  ejercicio que no sea el del hueco ni su sustitución registrada, así que una sustitución offline
  tendría que sincronizarse **antes** que esas series.
- **Propuesta:** encolar la sustitución en drift (alternativas cacheadas con el plan) y enviarla en
  orden antes de las series del hueco.

### [Móvil] Notificación del temporizador de descanso en segundo plano
- **Severidad:** Baja
- **Impacto:** si la app pasa a segundo plano, el fin del descanso no avisa.
- **Propuesta:** notificación local programada al iniciar el descanso.

### [Móvil] Dos entrenamientos locales pueden apuntar al mismo id remoto al adoptar un 409
- **Severidad:** Baja
- **Impacto:** cuando `POST /workouts` responde `409 WORKOUT_IN_PROGRESS` y la app adopta el
  entrenamiento remoto, en casos límite dos entrenamientos locales quedan con el mismo `serverId`.
- **Propuesta:** al adoptar, fusionar las series del duplicado en el entrenamiento ya enlazado y
  borrar el duplicado; test de sincronización con dos inicios encolados.

### [Móvil] Login offline con solo el userId en caché muestra el email vacío
- **Severidad:** Baja
- **Impacto:** si solo hay `userId` cacheado, Ajustes muestra el email vacío hasta tener red.
- **Propuesta:** cachear el usuario completo (`id`, `email`) al validar la sesión y mostrar un
  marcador «sin conexión» mientras falte.

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
