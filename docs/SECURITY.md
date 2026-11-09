# Seguridad de Pipos Fitness

> Estado al cierre de la reconstrucción (Fases 0–5). Se revisa al cerrar cada fase y antes de
> cada despliegue. Última revisión: **Fase 5 (cierre)**. Lo pendiente para producción está en
> [DEPLOY_CHECKLIST.md](DEPLOY_CHECKLIST.md) y la deuda conocida en [DEUDA_TECNICA.md](DEUDA_TECNICA.md).

## 1. Cómo informar de una vulnerabilidad

- **No abras un issue público.** Usa *GitHub → Security → Report a vulnerability*
  (aviso privado del repositorio) o escribe a **vfbeneitez@gmail.com** con el asunto
  `[SECURITY] Pipos Fitness`.
- Incluye: endpoint o componente, pasos de reproducción, impacto estimado y, si la hay,
  una prueba de concepto mínima. No accedas a datos de otros usuarios más allá de lo
  imprescindible para demostrar el fallo y no ejecutes pruebas de denegación de servicio.
- Compromiso: acuse de recibo en 72 h, evaluación inicial en 7 días y corrección de los
  fallos críticos/altos antes de 30 días. Se reconocerá la autoría si lo deseas.

## 2. Alcance y arquitectura

```
┌───────────────────────────────────┐        ┌───────────────────────────────────────────┐
│ Frontera: dispositivo del usuario │        │ Frontera: backend (red privada del hosting)│
│                                   │ HTTPS  │                                           │
│  App Flutter (apps/mobile)        │───────▶│  API NestJS (apps/api) ─Prisma─▶ Postgres │
│  - access + refresh token en      │  JSON  │   helmet · CORS allowlist · throttler     │
│    almacenamiento seguro          │◀───────│   JwtAuthGuard · Zod (contratos)          │
│    (flutter_secure_storage)       │        │   motor puro (@pipos/engine-rules)        │
│  - cola offline y caché de        │        │   analítica al escribir (misma tx)        │
│    lecturas en SQLite (drift)     │        │   sin worker, sin Redis, sin IA (ADR-2/3) │
└───────────────────────────────────┘        └───────────────────────────────────────────┘
```

Fronteras de confianza:

1. **Cliente → API** (Internet): body, query, params y cabeceras son no confiables. Se
   validan con los esquemas Zod de `@pipos/contracts` antes de llegar a los servicios
   (`.strict()`: campos extra → 400).
2. **API → Postgres**: credenciales en `DATABASE_URL`; consultas parametrizadas vía Prisma
   (las pocas `$executeRaw`/`$queryRaw` usan plantillas parametrizadas).
3. **Operador → configuración**: variables validadas al arrancar (`apps/api/src/config/env.ts`);
   la API no arranca con configuración inválida ni con secretos por defecto.
4. **Repositorio → catálogo**: el catálogo de ejercicios es un seed revisado en git
   (`packages/catalog`, ADR-0005). No hay endpoints de escritura del catálogo ni rutas admin.
5. **App → YouTube (destino externo, ADR-0014 Fase 4)**: el botón «Ver vídeo (YouTube)» abre
   un vídeo concreto, elegido y aprobado por PR, **fuera** de la app (`url_launcher` en modo
   aplicación externa: app de YouTube o navegador). La app no embebe reproductor ni carga
   código de terceros, y la URL solo lleva el id público del vídeo y el segundo de inicio
   (`https://www.youtube.com/watch?v=<id>&t=<s>s`): **ningún dato del usuario**. Antes de
   salir, un diálogo avisa de que se abandona Pipos. La API no llama a YouTube; solo el script
   manual `media:check` consulta el oEmbed público con el id del vídeo (sin datos de usuarios).

## 3. Activos

| Activo | Por qué importa |
|---|---|
| Datos de salud: limitaciones (zonas corporales), peso, altura | Categoría especial (RGPD art. 9). Su fuga es el peor impacto posible. |
| Perfil (objetivo, nivel, año de nacimiento, sexo, material, preferencias) | Dato personal; combinado puede revelar salud. |
| Historial de entrenamientos (series, cargas, RIR) y analítica derivada | Dato personal de rendimiento físico. |
| Planes generados y sus explicaciones | Derivados del perfil; con consentimiento pueden mencionar limitaciones. |
| Credenciales (`passwordHash`), refresh tokens (`tokenHash`), access JWT | Permiten suplantar al usuario. |
| `JWT_ACCESS_SECRET` | Con él se forja cualquier identidad. |
| Integridad del catálogo | Un catálogo manipulado produce planes peligrosos (etiquetas de riesgo). |
| Disponibilidad de la API | La generación de planes usa CPU (mediana ~20 ms, máx. ~120 ms en el peor perfil). |

## 4. Actores

| Actor | Capacidad |
|---|---|
| Anónimo en Internet | Llama a cualquier endpoint público; puede automatizar (fuerza bruta, scraping). |
| Usuario autenticado malicioso | Tiene un JWT válido propio; intenta acceder a recursos de otros (IDOR). |
| Atacante con un refresh token robado | Lo obtuvo de un dispositivo, backup o log. |
| Atacante con acceso físico/backup del móvil | Lee la base SQLite local o un backup de Android. |
| Operador/infra comprometida | Acceso a variables de entorno, logs o backups. |
| Dependencia comprometida | Paquete npm/pub malicioso (cadena de suministro). |

## 5. Puntos de entrada (API v1)

| Entrada | Auth | Notas |
|---|---|---|
| `POST /auth/register`, `POST /auth/login` | No | 5 req/min por IP; bcrypt coste 12; contraseña 8–72 bytes |
| `POST /auth/refresh`, `POST /auth/logout` | Refresh token | 10 req/min por IP; rotación con detección de reutilización (§6.1) |
| `GET /me`, `GET /me/export`, `DELETE /me` | JWT | Exportar/borrar: 5 req/min; borrar exige contraseña |
| `GET/PUT /me/profile`, `GET/POST/DELETE /me/consents/health` | JWT | Datos de salud solo con consentimiento vigente (409 `HEALTH_CONSENT_REQUIRED`) |
| `GET /me/nutrition-targets` | JWT | Cálculo puro; no se persiste |
| `POST /plans/generate`, `GET /plans/current`, `GET /plans/versions[/:id]` | JWT | Generar: 10 req/min; recursos de otro usuario → 404 |
| `GET /sessions/today`, `POST /workouts`, `GET /workouts/:id`, `POST/PATCH/DELETE /workouts/:id/sets[/:clientId]`, `POST /workouts/:id/finish`, `POST /workouts/:id/abandon`, `POST /workouts/:id/exercises/:planExerciseId/substitute`, `GET /exercises/:id/substitutes` | JWT | Idempotencia por `clientId`; propiedad en servicio + FK compuestas `(id, userId)` en BD |
| `GET /progress/e1rm`, `/progress/volume`, `/progress/adherence` | JWT | Solo leen tablas resumen (e2e: ningún GET escribe) |
| ADR-0013: `PUT/DELETE /exercises/:id/note`, `GET /me/exercise-notes`, `PUT/DELETE /plans/current/exercises/:planExerciseId/override`, `PATCH /me/profile/schedule`, `GET/POST/DELETE /me/breaks`, `GET/PUT /me/measurements`, `DELETE /me/measurements/:date`, `GET /progress/body`, `GET /sessions/today?minutes=&mode=` | JWT | Todo filtrado por `userId` (otro usuario → 404 o sin efecto); medidas solo con el ámbito del consentimiento (409 `HEALTH_CONSENT_REQUIRED`); pausas idempotentes por `clientId`; los GET no escriben (e2e) |
| `GET /exercises`, `GET /exercises/:id` | No | Catálogo de solo lectura, paginado (`pageSize ≤ 100`) |
| `GET /health`, `GET /health/ready` | No | 60 req/min; `ready` comprueba Postgres (503 si falla) |
| `GET /docs` (Swagger desde los contratos) | No | **Solo** si `NODE_ENV !== 'production'` |

Límite global por defecto: 100 req/min por IP (`apps/api/src/config/throttle.ts`); IP real tras
`TRUST_PROXY_HOPS` proxies y contadores compartidos en Postgres (`THROTTLE_STORE`).

## 6. STRIDE

Estado: ✅ mitigado (con la prueba que lo cubre) · ⏳ pendiente (ver DEPLOY_CHECKLIST /
DEUDA_TECNICA) · ⚠️ riesgo aceptado.

### 6.1 Autenticación

| STRIDE | Amenaza | Mitigación | Estado |
|---|---|---|---|
| S | Fuerza bruta / credential stuffing | Throttler 5/min/IP en login y registro; bcrypt 12 | ✅ e2e |
| S | Enumeración por tiempo en login | `bcrypt.compare` contra hash ficticio; mismo 401 | ✅ |
| S | Enumeración por `409 AUTH_EMAIL_TAKEN` en registro | Solo rate limiting; respuesta neutra + verificación por email no implementadas | ⚠️ / ⏳ deuda |
| S | Forja de JWT | Sin secreto por defecto; `JWT_ACCESS_SECRET` ≥ 32 car.; HS256 explícito | ✅ |
| S | Reutilización de refresh token robado | Rotación en cada uso; reutilizar uno revocado fuera de la ventana de gracia revoca **todas** las sesiones (`AUTH_REFRESH_REUSED`) | ✅ e2e |
| T | Dos refresh concurrentes → dos sesiones | Rotación atómica (`updateMany … revokedAt IS NULL`, `count === 1`) | ✅ e2e |
| T | Contraseñas > 72 bytes truncadas por bcrypt | Registro exige 8–72 bytes UTF-8 | ✅ |
| R | Sin auditoría de inicios de sesión / revocaciones | `AuditEvent` append-only (trigger sin UPDATE): login correcto/fallido (email desconocido → sin userId ni nada que lo identifique) y revocación por reutilización de refresh token | ✅ e2e (`audit.e2e-spec.ts`; issue #17) |
| I | Fuga de hashes o tokens | Respuestas tipadas; solo SHA-256 del refresh token; redacción en logs | ✅ |
| E | Escalada de rol | Rol en BD leído en cada petición por `JwtStrategy`; no existe ninguna ruta admin en v1 | ✅ |

**Ventana de gracia del refresh (`REFRESH_REUSE_GRACE_SECONDS`, 10 s).** Reenviar un token
rotado hace menos de la ventana devuelve `401 AUTH_REFRESH_RACE` sin revocar nada. Cubre el
caso de **peticiones simultáneas del mismo cliente** (la app además serializa el refresh con
un *single-flight*, `apps/mobile/lib/core/api/refresh_lock.dart`). **Limitación honesta:** no
recupera una **respuesta perdida**. La API solo guarda el hash del token nuevo, así que no puede
reenviarlo; el cliente que no lo recibió recibe `AUTH_REFRESH_RACE` (o, pasada la ventana,
`AUTH_REFRESH_REUSED`, que revoca todas sus sesiones) y debe volver a iniciar sesión. Lo fija un
e2e (`auth.e2e-spec.ts`, «limitación: si se pierde la respuesta…»).

### 6.2 Recursos del usuario

| STRIDE | Amenaza | Mitigación | Estado |
|---|---|---|---|
| S | Acceso sin token | `JwtAuthGuard` en todos los controladores privados | ✅ e2e |
| T/E | IDOR en planes, sesiones, entrenos, series, sustituciones | `where: { userId }` en servicio y FK compuestas `(id, userId)` en BD | ✅ e2e (`concurrency-ownership`) |
| I | Oráculo de existencia (403 vs 404) | Ajeno = inexistente = 404 | ✅ e2e |
| T | Ids malformados | Validación UUID → 400 antes de tocar la BD | ✅ |
| T | Mass assignment / campos extra | Zod `.strict()` | ✅ |
| T | Series registradas en un hueco con un ejercicio ajeno (contamina e1RM/volumen) | Solo el ejercicio del hueco o su sustitución registrada | ✅ e2e (Fase 5) |
| T | Datos de salud guardados sin consentimiento por carrera con la retirada | Candado por usuario (`pg_advisory_xact_lock`) y relectura del consentimiento dentro de la transacción | ✅ e2e (Fase 5) |
| D | Generación de planes en bucle | 10/min por IP | ✅ e2e |
| D | Throttler en memoria por instancia; tras un proxy todas las IPs son la del proxy | `TRUST_PROXY_HOPS` (`trust proxy` de Express) y contadores compartidos en Postgres (`THROTTLE_STORE=postgres`, upsert atómico con caducidad) | ✅ e2e (`throttle-proxy.e2e-spec.ts`; issue #9) |
| R | Sin trazabilidad de escrituras sensibles (salvo `ConsentEvent`, append-only) | `AuditEvent`: concesión/retirada del consentimiento, cambio de datos de salud del perfil y alta/borrado de medidas (solo el tipo, nunca valores), borrado de la cuenta; retención 180 días | ✅ e2e (issue #17) |

### 6.3 Superficie HTTP, configuración y logs

| STRIDE | Amenaza | Mitigación | Estado |
|---|---|---|---|
| S | CORS permisivo | Allowlist `CORS_ORIGINS`; sin coincidencia no hay cabeceras CORS (la app móvil no usa CORS) | ✅ e2e |
| I | Swagger en producción | Solo si `NODE_ENV !== 'production'` | ✅ e2e |
| I/T | Cabeceras de seguridad | `helmet` (HSTS, nosniff, frame-options; CSP en producción) | ✅ e2e |
| I | TLS | Terminación TLS en el hosting; la app release prohíbe HTTP (`usesCleartextTraffic=false`) | ⏳ despliegue |
| I | Logs con PII o salud | Logs JSON con `requestId`; nunca cuerpos ni query; redacción por clave; errores inesperados y no capturados (`uncaughtException`/`unhandledRejection`) **sin mensaje**, solo nombre, código y frames de pila | ✅ e2e + unit (Fase 5) |
| I | Errores de configuración que filtran secretos | `parseEnv` informa claves y reglas, nunca valores | ✅ |
| T | Rate limiting desactivado en producción por error | `THROTTLE_ENABLED=false` rechazado con `NODE_ENV=production` | ✅ |
| D | Proceso corrupto tras `uncaughtException` | Se registra y `exit(1)` (el orquestador reinicia) | ✅ |
| T | Dependencias comprometidas o vulnerables | `--frozen-lockfile`; `pnpm audit --prod --audit-level high` en CI (falla con altas/críticas); Dependabot semanal agrupado (npm, pub, actions). Excepción documentada abajo | ✅ CI (issue #18) |
| T | CI con permisos amplios | `permissions: contents: read` | ✅ |

#**Excepciones de `pnpm audit`**: ninguna. Si alguna vez hiciera falta, se declara en `package.json`
(`pnpm.auditConfig.ignoreGhsas`) con su motivo y su salida en esta sección. La última,
GHSA-mrhx-c7xc-m3w5 (`zod` 3), se cerró al migrar a zod 4.6 (contratos, API y OpenAPI con
`z.toJSONSchema`).

Las demás vulnerabilidades altas/críticas transitivas se corrigen con `pnpm.overrides` a la versión
parcheada más cercana dentro de la misma mayor: hoy solo `proxy-addr` (de Express 5) y `js-yaml` 4
(herramientas de desarrollo). Las de multer, body-parser, path-to-regexp y lodash desaparecieron con
NestJS 12 (Express 5 y `@nestjs/swagger` 12 ya traen versiones parcheadas) y sus overrides se
quitaron; tar y brace-expansion desaparecen al pasar a `bcrypt` 6 (sin `node-pre-gyp`; mismo formato
de hash `$2b$`).

### 6.4 App móvil

| STRIDE | Amenaza | Mitigación | Estado |
|---|---|---|---|
| I | Robo de tokens del dispositivo | Access y refresh token en `flutter_secure_storage` (Keystore/Keychain) | ✅ |
| I | Base SQLite local (drift) sin cifrar: cola offline y caché de lecturas (puede incluir perfil y plan) | Sandbox de la app | ⚠️ / ⏳ deuda |
| I | Copia de seguridad de Android con la base local y los tokens | Reglas de exclusión de backup en la app (Fase 5); falta validarlas en un build real | ⏳ deuda |
| T | Escrituras de tokens no atómicas (access y refresh por separado) | Corregido en la app (Fase 5) | ✅ |
| I | HTTP en claro | Release exige HTTPS; HTTP solo en debug | ✅ |
| I | Vídeos de YouTube: fuga de datos a Google o contenido de terceros dentro de la app | Se abren fuera de la app con una URL que solo lleva el id público del vídeo y el segundo de inicio; sin reproductor embebido ni WebView; aviso de que se sale de Pipos. Si algún día se embebe: `youtube-nocookie.com` y actualizar política de privacidad y DPIA (ADR-0014) | ✅ |
| T | Un vídeo enlazado cambia de contenido, de dueño o desaparece | Solo vídeos concretos aprobados por PR (nunca búsquedas; el `videoId` se valida en catálogo, API y app); `media:check` antes de cada release detecta los no disponibles y los cambios de canal; un medio retirado del JSON se borra al sembrar | ✅ |

## 7. Clasificación de datos

| Elemento | Nivel | Dato personal | Ámbito |
|---|---|---|---|
| `TrainingProfile.limitations`, `weightKg`, `heightCm` | **Restringido** | Sí — salud (art. 9) | RGPD art. 9, LOPDGDD |
| `PlanVersion.inputSnapshot` (copia del perfil) y explicaciones derivadas de la limitación (`healthNotes`, avisos `health: true`, notas `{ text, health: true }` de cada ejercicio) | **Restringido** | Sí — salud | RGPD art. 9 |
| `BodyMeasurement` (peso y perímetros de cintura, cuello, cadera, pecho, brazo y muslo) y lo que se deriva al leer en `GET /progress/body` (tendencia de peso, IMC, % de grasa estimado) — ADR-0013 | **Restringido** | Sí — salud | RGPD art. 9 (ámbitos `weight`, `body_measurements` y `derived_estimates` del consentimiento) |
| `UserExerciseNote.text` (nota fija por ejercicio, texto libre) — ADR-0013 | **Restringido** (por precaución) | Sí; **puede contener datos de salud** si el usuario los escribe | RGPD; riesgo residual en la DPIA |
| `TrainingBreak` (fechas de pausa, sin motivo), `TrainingProfile.trainingWeekdays`, `PlanExerciseOverride`, ajuste de la sesión (`WorkoutSession.adjustedMinutes`, `reducedVolume`) — ADR-0013 | Confidencial | Sí | RGPD (no se guarda ningún motivo: sería dato de salud) |
| Resto del perfil, preferencias, planes, entrenos, series, analítica | Confidencial | Sí | RGPD |
| `User.email`, `emailNormalized` | Confidencial | Sí | RGPD |
| `ConsentEvent` (acción, versión, hash del texto, idioma, fecha) | Confidencial | Sí | RGPD (prueba del consentimiento) |
| `AuditEvent` (tipo, userId, fecha; issue #17). Sin emails, IPs, tokens ni valores de salud; `account_deleted` sin userId, con un id de borrado aleatorio | Confidencial | Sí (vinculado al userId) | RGPD; retención 180 días (`audit:cleanup`); se exporta y se borra con la cuenta |
| `User.passwordHash`, `RefreshToken.tokenHash`, JWT | **Restringido** (credencial) | Vinculado | — |
| `JWT_ACCESS_SECRET`, `DATABASE_URL` | **Restringido** (secreto) | No | — |
| Catálogo | Público | No | — |

**No se guarda IP ni user-agent** en ninguna tabla (minimización, Fase 5: migración
`20261110000000_minimizacion_ip_user_agent`). Los logs de acceso no registran cuerpos.

Requisitos de manejo:

| Nivel | Acceso | Cifrado en reposo | En tránsito | Logs | Retención |
|---|---|---|---|---|---|
| Restringido | Solo el propio usuario vía API; operadores con necesidad justificada | Disco/BD cifrados del proveedor; sin cifrado a nivel de campo | TLS 1.2+ | **Nunca** | Hasta retirar el consentimiento o borrar la cuenta |
| Confidencial | Propio usuario; operadores con necesidad justificada | Disco/BD cifrados | TLS 1.2+ | Solo ids | Mientras exista la cuenta |
| Público | Abierto | — | TLS 1.2+ | Libre | — |

## 8. Cumplimiento (RGPD)

Los datos de salud son categoría especial (art. 9): base legal = **consentimiento explícito**
(art. 9.2.a; ADR-0011).

| Requisito | Estado |
|---|---|
| Consentimiento explícito, versionado (versión + SHA-256 del texto), registrado append-only antes de aceptar datos de salud | ✅ (`ConsentEvent`, e2e) |
| Retirada del consentimiento: en una transacción borra limitaciones/peso/altura, redacta `inputSnapshot` de todas las versiones, **borra las explicaciones derivadas de la limitación** de todas las versiones y ejercicios, y regenera el plan sin ellos | ✅ e2e (Fase 5: versión antigua, `/me/export` y BD sin rastro de la zona) |
| Acceso/portabilidad: `GET /me/export` (JSON con todo, sin hashes) | ✅ e2e |
| ADR-0013: consentimiento por ámbitos (`health-2026-11-v2` cubre perímetros y estimaciones; la versión anterior solo peso, altura y limitaciones); la retirada borra `BodyMeasurement`; notas, pausas, cambios fijados y medidas en la exportación y en `DELETE /me` | ✅ e2e (`ideas.e2e-spec.ts`) |
| Supresión: `DELETE /me` con contraseña; borrado real en cascada (también sus eventos de auditoría; queda solo `account_deleted` sin userId) | ✅ e2e (0 filas del usuario) |
| Registro de auditoría sin datos personales ni de salud, con retención limitada (180 días) e incluido en `GET /me/export` | ✅ e2e (issue #17) |
| Minimización: sin IP ni user-agent | ✅ (Fase 5) |
| Política de privacidad y texto legal del consentimiento revisados por un jurista | ⏳ antes de producción |
| Evaluación de impacto (EIPD/DPIA), probablemente obligatoria (salud a escala) | ⏳ antes de producción |
| Registro de actividades de tratamiento | ⏳ antes de producción |
| Encargados (hosting, Sentry) con DPA y ubicación UE | ⏳ despliegue |
| Procedimiento de notificación de brechas en 72 h | ⏳ antes de producción |

## 9. Riesgos residuales

- **Rate limiting por IP**: con `TRUST_PROXY_HOPS` mal configurado (más saltos de los reales)
  un cliente podría falsificar su IP con `X-Forwarded-For`; con menos, todos compartirían la IP
  del proxy. Los contadores se comparten entre réplicas en Postgres (issue #9).
- **Respuesta de refresh perdida** → el usuario debe volver a iniciar sesión (§6.1).
- **Access token válido hasta caducar** (15 min) tras logout/revocación; el rol y la
  existencia del usuario sí se comprueban en BD en cada petición.
- **Enumeración de emails** por el 409 del registro, mitigada solo por rate limiting.
- **Notas de texto libre** (`UserExerciseNote`, ADR-0013): el usuario podría escribir datos de salud
  («me duele la rodilla»). No se pide consentimiento del art. 9 porque la finalidad no es tratar
  salud. Mitigación: la ayuda orienta a ajustes de máquina y agarre, límite de 280 caracteres,
  se incluyen en la exportación y en el borrado y **nunca se registran en logs** (los logs no
  guardan cuerpos de petición). Anotado para la DPIA.
- **Estimaciones corporales** (IMC, % de grasa; ADR-0013): se presentan como estimación, con sus
  límites y «no es un diagnóstico»; no se dan categorías de % de grasa.
- **Vídeos de terceros** (ADR-0014): al abrir YouTube, lo que haga allí el usuario lo gestiona
  Google con su propia política; Pipos no le envía datos, pero el usuario sale de la app (se le
  avisa). El contenido de un vídeo puede cambiar sin que cambie su id: se mitiga con la revisión
  por PR, `media:check` antes de cada release y la revisión profesional antes del lanzamiento.
- **Base local del móvil sin cifrar** (sandbox de la app; excluida de las copias de seguridad).
- **Historial de git** conserva binarios antiguos (`.tools/`), sin secretos; no se reescribe.
- Los textos de las explicaciones de planes **anteriores a la Fase 5** no marcaban los
  derivados de salud; no hay datos de producción, así que no se migran.
