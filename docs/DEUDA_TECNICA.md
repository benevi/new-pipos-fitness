# Deuda técnica conocida (cierre de la Fase 5)

Hallazgos de las revisiones de cierre **no corregidos** en la Fase 5, más los conocidos de antes.
Cada entrada está lista para copiarse como issue de GitHub: el `###` es el título y lo de debajo el
cuerpo. Severidad: **Alta** (riesgo para datos o seguridad, o bloquea producción) · **Media**
(comportamiento incorrecto visible) · **Baja** (mejora o caso raro).

Lo que bloquea el despliegue (firma, TLS, DPIA…) está además en [DEPLOY_CHECKLIST.md](DEPLOY_CHECKLIST.md).

## API y backend

### [API] Configurar `trust proxy` y un almacén compartido para el rate limiting
- **Severidad:** Alta (bloquea producción)
- **Impacto:** detrás del proxy del hosting todas las peticiones llegan con la IP del proxy: el
  throttler (por IP, en memoria) limitaría a todos los usuarios a la vez (p. ej. 5 logins/min en
  total). Con varias réplicas, cada una cuenta por separado.
- **Propuesta:** `app.set('trust proxy', <n saltos>)` configurable por entorno (`TRUST_PROXY_HOPS`)
  con test e2e de `X-Forwarded-For`; almacén compartido (Postgres o Redis) antes de escalar a >1 réplica.

### [API] Rechazar entrenamientos sobre sesiones de una versión de plan antigua
- **Severidad:** Baja
- **Impacto:** `POST /workouts` acepta una `planSessionId` de una versión no vigente
  (`workouts.service.ts`, `start`). El entreno cuenta para la analítica, pero no avanza el
  microciclo de la versión vigente (`nextPendingSession` solo mira la vigente).
- **Por qué no se hizo en la Fase 5:** la cola offline de la app trata cualquier 4xx como fallo
  permanente: rechazarlo podría dejar en `failed` un entreno hecho sin red justo antes de un cambio
  de perfil hecho desde otro dispositivo.
- **Propuesta:** devolver `409 PLAN_SESSION_OUTDATED` solo para entrenos nuevos sin series, y en la
  app refrescar `/sessions/today` ante ese código; o aceptar y mapear la sesión a la vigente por `order`.

### [API] Idempotencia de `POST /plans/generate` (doble toque → dos versiones)
- **Severidad:** Baja
- **Impacto:** dos pulsaciones seguidas crean dos versiones idénticas del plan; reinicia el
  microciclo de la versión (no el ciclo de descarga, que ya se ancla al plan).
- **Propuesta:** cabecera opcional `Idempotency-Key` (columna única `(userId, idempotencyKey)` en
  `PlanVersion`) que la app envíe; o devolver la última versión si su `inputSnapshot` es idéntico
  y se creó hace < 10 s. Ojo: hay un e2e que espera dos versiones con dos generaciones simultáneas.

### [Motor] Redondear la carga a los incrementos reales del material (mancuernas, máquinas)
- **Severidad:** Media
- **Impacto:** el motor redondea todas las cargas a 1 kg (`e1rm.loadRoundingKg`); con mancuernas
  (saltos de 2–2,5 kg) o máquinas de placas propone pesos que no existen (PROGRAMACION §7,
  `INCREMENTO_MIN_KG`: «mancuernas: el siguiente peso disponible»).
- **Propuesta:** incremento por tipo de material en el catálogo o en la configuración
  (`barbell` 2,5 kg en total, `dumbbell` 2 kg, `machine` 5 kg), aplicado al subir carga y a las
  cargas iniciales; test de propiedad «la carga propuesta es múltiplo del incremento».

### [API] Estado `abandoned` sin flujo: un entreno en curso olvidado bloquea los siguientes
- **Severidad:** Media
- **Impacto:** `WorkoutStatus.abandoned` existe pero ningún endpoint lo usa. Un entreno sin
  cerrar devuelve `409 WORKOUT_IN_PROGRESS` a cualquier inicio nuevo hasta que se cierre.
- **Propuesta:** `POST /workouts/:id/abandon` (idempotente) y/o abandono automático al iniciar uno
  nuevo si el anterior lleva > 12 h; excluirlo de adherencia (ya se excluye de la analítica).

### [API] La adherencia de semanas pasadas usa la versión vigente del plan
- **Severidad:** Baja
- **Impacto:** `recomputeWeek` toma las sesiones/series planificadas de la versión vigente al
  escribir, y `GET /progress/adherence` rellena las semanas sin actividad con la última versión.
  Tras cambiar de 3 a 5 días, las semanas antiguas aparecen con 5 sesiones previstas al recalcular.
- **Propuesta:** usar la versión vigente en cada semana (`PlanVersion.createdAt ≤ fin de semana`),
  también en `analytics:rebuild`; test con dos versiones.

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

### [CI] Dependabot y `pnpm audit` / `flutter pub outdated` en CI
- **Severidad:** Media
- **Impacto:** solo hay `--frozen-lockfile`; nada avisa de dependencias vulnerables.
- **Propuesta:** `.github/dependabot.yml` (npm, pub, actions) y un paso `pnpm audit --prod --audit-level high`.

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

## App móvil

### [Móvil] Editar o borrar una serie registrada desde la interfaz
- **Severidad:** Media
- **Impacto:** la API admite `PATCH`/`DELETE /workouts/:id/sets/:clientId` (última escritura gana),
  pero la app no ofrece corregir un error de tecleo; el dato malo contamina e1RM y volumen.
- **Propuesta:** acción en la fila de la serie (editar reps/kg/RIR, borrar) que pase por la cola
  offline con `clientUpdatedAt`.

### [Móvil] Cambiar de ejercicio sin conexión
- **Severidad:** Media
- **Impacto:** la sustitución exige red; en el gimnasio sin cobertura el usuario no puede
  cambiar una máquina ocupada. Ojo: desde la Fase 5 la API rechaza (400) series de un ejercicio
  que no sea el del hueco ni su sustitución registrada, así que la sustitución debe sincronizarse
  **antes** que esas series.
- **Propuesta:** encolar la sustitución en drift (alternativas cacheadas con el plan) y enviarla en
  orden antes de las series del hueco.

### [Móvil] Una sesión terminada sin conexión sigue apareciendo como «hoy» hasta sincronizar
- **Severidad:** Media
- **Impacto:** `GET /sessions/today` viene de la caché; hasta que el cierre llega al servidor la
  app vuelve a ofrecer la misma sesión.
- **Propuesta:** calcular localmente la siguiente sesión pendiente (misma regla que
  `nextPendingSession`) cuando hay cierres en cola.

### [Móvil] Notificación del temporizador de descanso en segundo plano
- **Severidad:** Baja
- **Impacto:** si la app pasa a segundo plano, el fin del descanso no avisa.
- **Propuesta:** notificación local programada (`flutter_local_notifications`) al iniciar el descanso.

### [Móvil] Prueba de accesibilidad con TalkBack en dispositivo real
- **Severidad:** Media
- **Impacto:** la accesibilidad solo se ha comprobado con tests de semántica; falta una pasada real.
- **Propuesta:** guion de prueba manual con TalkBack (registro, onboarding, registrar series,
  progreso) y corrección de lo que aparezca.

### [Motor/Móvil] Textos del motor solo en español
- **Severidad:** Baja
- **Impacto:** la app tiene i18n (ARB), pero las explicaciones, avisos y prescripciones del motor
  llegan como texto en español.
- **Propuesta:** el motor emite códigos con parámetros (`{ code, params }`) y la app los traduce;
  mantener el texto en español como respaldo.

### [Móvil] Escritura no atómica de los tokens
- **Severidad:** Media
- **Impacto:** access y refresh se guardan con dos escrituras en el almacenamiento seguro; si la
  app muere entre ambas puede quedar un refresh viejo (ya rotado) → `AUTH_REFRESH_RACE`/
  `AUTH_REFRESH_REUSED` y cierre de sesión.
- **Propuesta:** guardar ambos en una sola clave (JSON) o escribir primero el refresh y validar la
  pareja al leer.

### [Móvil] Base local (drift) sin cifrar y `allowBackup` activo
- **Severidad:** Alta (bloquea producción)
- **Impacto:** la base SQLite guarda la cola de series y una caché de lecturas que puede incluir
  el perfil (con limitaciones) y el plan; Android la incluye en las copias de seguridad.
- **Propuesta:** `android:allowBackup="false"` (o reglas que excluyan la base) y valorar SQLCipher
  con la clave en el almacenamiento seguro; no cachear el perfil con datos de salud.

### [Móvil] Firma de release propia
- **Severidad:** Alta (bloquea producción)
- **Impacto:** el build `release` firma con las claves de debug (`android/app/build.gradle.kts`).
- **Propuesta:** keystore de subida en los secretos del CI y `signingConfig` de release.
