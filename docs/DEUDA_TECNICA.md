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

### ~~[Motor] Redondear la carga a los incrementos reales del material (mancuernas, máquinas)~~ — RESUELTO
- **Estado:** resuelto con ADR-0013 (idea 1); cierra el issue #12.
- **Qué se hizo:** paso de carga por material en `PROGRAMMING.load` (barra 2,5 kg en total,
  mancuernas 2 kg, kettlebell 4 kg, máquina 5 kg…; heurística, PROGRAMACION §16.16), aplicado a
  cargas iniciales, aproximaciones, subidas (al siguiente peso disponible, con aviso si el salto
  supera el 10 %) y bajadas; desglose de discos por lado en la sesión de hoy. Test de propiedad
  «la carga propuesta es múltiplo del paso del material».

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
