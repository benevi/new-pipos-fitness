# Seguridad de Pipos Fitness

> Estado a la Fase 1 de la reconstrucción ("parar el sangrado"). Este documento se revisa
> al cerrar cada fase. Última revisión: Fase 1.

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
┌──────────────────────────────┐        ┌──────────────────────────────────────────────┐
│ Frontera: dispositivo usuario│        │ Frontera: backend (red privada del hosting)   │
│                              │ HTTPS  │                                              │
│  App Flutter (apps/mobile)   │───────▶│  API NestJS (apps/api) ──Prisma──▶ Postgres  │
│  - access token (memoria)    │  JSON  │   helmet · CORS allowlist · throttler        │
│  - refresh token (secure     │◀───────│   JwtAuthGuard · RolesGuard · Zod            │
│    storage)                  │        │                                              │
└──────────────────────────────┘        │  (sin worker ni Redis: ADR-0002, Fase 3)     │
                                        │                                              │
  Navegador (Swagger, sólo dev) ───────▶│                                              │
                                        └──────────────────────────────────────────────┘
```

Fronteras de confianza que se cruzan:

1. **Cliente → API** (Internet): todo lo que llega en body, query, params y cabeceras es
   no confiable. Se valida con Zod (`@pipos/contracts`) antes de llegar a los servicios.
2. **API → Postgres**: credenciales en `DATABASE_URL`; consultas parametrizadas vía Prisma.
3. **Operador → configuración**: variables de entorno validadas al arrancar
   (`apps/api/src/config/env.ts`); la API no arranca con configuración inválida.
4. **Repositorio → catálogo**: el catálogo de ejercicios/alimentos es un seed revisado en
   git (ADR-0005); no existe escritura del catálogo desde la API.

## 3. Activos

| Activo | Por qué importa |
|---|---|
| Datos de salud y perfil (peso, altura, edad, sexo, objetivos, lesiones/limitaciones) | Categoría especial (RGPD art. 9). Su fuga es el peor impacto posible. |
| Credenciales (`passwordHash`) y tokens (refresh `tokenHash`, access JWT) | Permiten suplantar al usuario. |
| `JWT_ACCESS_SECRET` | Con él se forja cualquier identidad, incluido ADMIN. |
| Historial de entrenamientos (series, cargas, notas) | Dato personal; las notas son texto libre que puede contener salud. |
| Integridad del catálogo | Un catálogo manipulado alimenta planes peligrosos (ejercicios/vídeos maliciosos). |
| Disponibilidad de la API | La generación de planes es CPU intensiva. |

## 4. Actores

| Actor | Capacidad |
|---|---|
| Anónimo en Internet | Llama a cualquier endpoint público; puede automatizar (fuerza bruta, scraping). |
| Usuario autenticado malicioso | Tiene un JWT válido propio; intenta acceder a recursos de otros (IDOR) o escalar rol. |
| Atacante con un refresh token robado | Lo obtuvo de un dispositivo, backup o log. |
| Operador/infra comprometida | Acceso a variables de entorno, logs o backups. |
| Dependencia comprometida | Paquete npm/pub malicioso (cadena de suministro). |

## 5. Puntos de entrada

| Entrada | Auth | Notas |
|---|---|---|
| `POST /auth/register`, `POST /auth/login` | No | 5 req/min por IP |
| `POST /auth/refresh`, `POST /auth/logout` | Refresh token | 10 req/min por IP; ventana de gracia `REFRESH_REUSE_GRACE_SECONDS` (401 `AUTH_REFRESH_RACE`) |
| `GET /me`, `GET /me/export`, `DELETE /me` | JWT | Exportar/borrar: 5 req/min; borrar exige contraseña |
| `GET/PUT /me/profile`, `GET/POST/DELETE /me/consents/health` | JWT | Datos de salud solo con consentimiento vigente (409 `HEALTH_CONSENT_REQUIRED`) |
| `GET /me/nutrition-targets` | JWT | Cálculo puro; no se persiste |
| `POST /plans/generate`, `GET /plans/*` | JWT | Generar: 10 req/min; propiedad por `userId` (otro → 404) |
| `GET /sessions/today`, `POST/GET/PATCH/DELETE /workouts/*`, `GET /exercises/:id/substitutes` | JWT | Recursos anidados; propiedad en servicio + FK compuestas `(id, userId)` en BD; idempotencia por `clientId` |
| `GET /progress/*` | JWT | Derivado de datos de salud; solo lectura (e2e: ningún GET escribe) |
| `GET /exercises`, `GET /exercises/:id` | No | Catálogo de sólo lectura, paginado (`pageSize ≤ 100`) |
| `GET /health`, `GET /health/ready` | No | 60 req/min; `ready` comprueba Postgres (503 si falla) |
| `GET /docs` (Swagger, generado desde los contratos Zod) | No | **Sólo** si `NODE_ENV !== 'production'` |
| Variables de entorno / arranque | Operador | Validadas con Zod |

## 6. STRIDE por punto de entrada

Valoración: Probabilidad × Impacto → **Crítico / Alto / Medio / Bajo**. Estado:
✅ mitigado en Fase 1 · ⏳ pendiente (fase indicada) · ⚠️ riesgo aceptado.

### 6.1 Autenticación (`/auth/*`)

| STRIDE | Amenaza | Riesgo | Mitigación | Estado |
|---|---|---|---|---|
| S | Fuerza bruta / credential stuffing en login | Alto | Throttler 5/min/IP en login y registro; bcrypt coste 12 | ✅ |
| S | Enumeración de usuarios por tiempo de respuesta en login | Medio | `bcrypt.compare` contra hash ficticio si el usuario no existe; mismo mensaje 401 | ✅ |
| S | Enumeración por `409` en registro | Medio | Throttler 5/min. Respuesta neutra + verificación por email | ⏳ Fase 3 |
| S | Forja de JWT con secreto por defecto (`dev-access-secret-…` en el código) | **Crítico** | Eliminado el fallback; `JWT_ACCESS_SECRET` obligatorio ≥ 32 caracteres; HS256 explícito (sin `alg` confusión) | ✅ |
| S | Reutilización de refresh token robado | Alto | Rotación en cada uso; reutilizar un token revocado revoca **todas** las sesiones del usuario (`AUTH_REFRESH_REUSED`) | ✅ |
| T | Carrera: dos refresh concurrentes con el mismo token generan dos sesiones válidas | Alto | Rotación atómica en `$transaction` con `updateMany … where revokedAt IS NULL` y `count === 1`; el perdedor se trata como reutilización | ✅ (e2e) |
| T | Contraseñas > 72 bytes truncadas silenciosamente por bcrypt | Medio | Registro exige 8–72 **bytes** UTF-8 | ✅ |
| R | Sin registro de inicios de sesión / revocaciones | Medio | Log de auditoría de eventos de auth (sin datos personales) | ⏳ Fase 3 |
| I | Fuga de hash o tokens en respuestas/logs | Alto | Respuestas tipadas (`AuthResponseSchema`); sólo se almacena SHA-256 del refresh token; unique en `tokenHash` | ✅ |
| D | Coste de bcrypt como amplificador de DoS | Medio | Throttler; tamaño de contraseña acotado (registro 72 B, login 256 car.) | ✅ |
| E | Escalada a ADMIN | Alto | Rol en BD (`UserRole`, por defecto USER); `JwtStrategy` lee el rol de BD, no del token; `RolesGuard` + `@Roles()` | ✅ |

### 6.2 Recursos del usuario (`/me`, `/workouts`, `/training-plans`, `/nutrition-plans`, `/analytics`)

| STRIDE | Amenaza | Riesgo | Mitigación | Estado |
|---|---|---|---|---|
| S | Acceso sin token | Alto | `JwtAuthGuard` en todos los controladores privados | ✅ |
| T/E | IDOR: iniciar un entrenamiento sobre la `planSession` de otro usuario | **Alto** | `trainingSession.findFirst({ where: { id, planVersion: { plan: { userId } } } })` | ✅ (e2e) |
| T/E | IDOR: registrar series / añadir ejercicios / finalizar en la sesión de otro | Alto | Todas las consultas filtran por `userId` en el `where` | ✅ (e2e) |
| I | Oráculo de existencia (403 vs 404) | Medio | Recursos ajenos devuelven **404**, idéntico a inexistente | ✅ (e2e) |
| I | Adherencia calculada con sesiones planificadas ajenas (datos heredados) | Bajo | Lectura de `TrainingSession` acotada al plan del usuario | ✅ |
| T | Ids malformados / inyección en parámetros | Medio | `@UuidParam` (400 antes de tocar BD); Prisma parametriza | ✅ |
| T | Mass assignment / campos extra | Medio | Bodies validados con Zod; `goal` de nutrición es enum cerrado y `strict()` | ✅ |
| D | Payloads gigantes en texto libre | Medio | `.max()` en notes (1000), customText (200), search (100), nombres, ids | ✅ |
| D | Generación de planes en bucle | Medio | 10/min por IP en `generate` | ✅ |
| D | Throttler en memoria por instancia; detrás de proxy todas las IPs son la del proxy | Medio | Store Redis + `trust proxy` configurado según el hosting | ⏳ despliegue |
| R | Sin trazabilidad de cambios en datos de salud | Medio | Auditoría de escrituras sensibles | ⏳ Fase 3 |
| I | Respuesta de `/me` con más datos de los necesarios | Bajo | `select` explícito (sin `passwordHash`) | ✅ |

### 6.3 Catálogo (`/exercises`, `/muscles`, `/equipment-items`, `/foods`, antes `/admin/*`)

| STRIDE | Amenaza | Riesgo | Mitigación | Estado |
|---|---|---|---|---|
| T/E | `/admin/*` **sin autenticación**: cualquiera creaba/editaba ejercicios y aprobaba vídeos | **Crítico** | Módulo admin eliminado; catálogo = seed revisado en git (ADR-0005). Las futuras rutas admin usarán `JwtAuthGuard + RolesGuard + @Roles(ADMIN)` | ✅ (e2e: 404) |
| D | Paginación sin límite (`limit`) o cursores arbitrarios | Medio | `limit` 1–100 (ejercicios), 1–1000 (alimentos); cursor con forma de id | ✅ |
| I | Scraping del catálogo | Bajo | Es contenido público; throttler global 100/min | ⚠️ aceptado |

### 6.4 Superficie HTTP y configuración

| STRIDE | Amenaza | Riesgo | Mitigación | Estado |
|---|---|---|---|---|
| S | CORS reflejando cualquier origen con `credentials: true` en no-producción | Alto | Allowlist `CORS_ORIGINS`; sin coincidencia no hay cabeceras CORS | ✅ (e2e) |
| I | Swagger expuesto en producción (mapa completo de la API) | Medio | Sólo si `NODE_ENV !== 'production'` | ✅ (e2e) |
| I/T | Cabeceras de seguridad ausentes, `X-Powered-By` | Bajo | `helmet` (CSP en producción, HSTS, nosniff, frame-options) | ✅ (e2e) |
| D | Proceso en estado corrupto tras `uncaughtException` | Medio | Se registra y `process.exit(1)` (el orquestador reinicia) | ✅ |
| I | Mensajes de error de configuración que filtran secretos | Medio | `parseEnv` informa claves y reglas, nunca valores | ✅ |
| T | Desactivar el rate limiting en producción por error | Medio | `THROTTLE_ENABLED=false` rechazado si `NODE_ENV=production` | ✅ |
| I | TLS | Alto | Terminación TLS en el hosting/proxy; HSTS ya enviado | ⏳ despliegue |

### 6.5 Logs y cadena de suministro

| STRIDE | Amenaza | Riesgo | Mitigación | Estado |
|---|---|---|---|---|
| I | Logs con PII o datos de salud | Medio | Logs JSON con `requestId`; nunca cuerpos ni query; redacción por clave (email, tokens, peso, altura, limitaciones…); errores inesperados sin mensaje (solo pila). e2e lo comprueba | ✅ Fase 3 |
| I | El worker registraba `job.data` | Medio | Worker eliminado (ADR-0002) | ✅ Fase 3 |
| I | Artefactos binarios versionados (`.tools/`, zip de Node para Windows) | Medio | Eliminados del árbol y en `.gitignore` (permanecen en el historial; no se reescribe) | ✅ / ⚠️ |
| T | Dependencias comprometidas | Medio | `--frozen-lockfile` en CI | ✅ parcial · Dependabot / `pnpm audit` en CI ⏳ |
| T | CI con permisos amplios | Bajo | `permissions: contents: read` | ✅ |

### 6.6 AI coach (retirado en Fase 3)

| STRIDE | Amenaza | Riesgo | Mitigación | Estado |
|---|---|---|---|---|
| I | Persistencia de preguntas en texto libre (`AIInteraction.question`, puede contener salud) | Medio | Módulo y tabla eliminados (ADR-0003) | ✅ Fase 3 |
| T | Propuestas no validadas aplicadas al plan | Medio | Sin endpoint; la interfaz `AiProvider` documenta la re-verificación obligatoria | ✅ Fase 3 |

## 7. Clasificación de datos

| Elemento | Origen | Nivel | Dato personal | Ámbito regulatorio |
|---|---|---|---|---|
| `User.weightKg`, `heightCm`, `age`, `sex` | Usuario | **Restringido** | Sí — salud (art. 9 RGPD) | RGPD art. 9, LOPDGDD |
| Lesiones / limitaciones (previsto en Fase 3) | Usuario | **Restringido** | Sí — salud (art. 9) | RGPD art. 9 |
| `goals`, `muscleFocus` (incl. `customText`) | Usuario | **Restringido** | Sí — puede revelar salud | RGPD art. 9 |
| `WorkoutSession.notes` | Usuario | **Restringido** | Sí — texto libre, puede contener salud | RGPD art. 9 |
| `WorkoutSet` (cargas, reps, RIR), `ExerciseProgress`, analytics | Usuario / derivado | Confidencial | Sí (rendimiento físico; derivado puede inferir salud) | RGPD |
| Planes de entrenamiento y nutrición generados | Derivado | Confidencial | Sí (derivados de datos de salud) | RGPD |
| `AIInteraction.question` | Usuario | **Restringido** | Sí — texto libre | RGPD art. 9 |
| `User.email`, `emailNormalized` | Usuario | Confidencial | Sí | RGPD |
| `User.passwordHash`, `RefreshToken.tokenHash`, access JWT | Sistema | **Restringido** (credencial) | No / vinculado | — |
| `RefreshToken.createdByIp`, `userAgent` (hoy no se rellenan) | Sistema | Confidencial | Sí | RGPD |
| `JWT_ACCESS_SECRET`, `DATABASE_URL` | Operador | **Restringido** (secreto) | No | — |
| Catálogo (ejercicios, músculos, equipamiento, alimentos) | Repositorio | Público | No | — |

Requisitos de manejo:

| Nivel | Acceso | Cifrado en reposo | En tránsito | Logs | Retención |
|---|---|---|---|---|---|
| Restringido | Sólo el propio usuario vía API; operadores con necesidad justificada | Disco/BD cifrados del proveedor (AES-256); cifrado a nivel de campo ⏳ | TLS 1.2+ | **Nunca** se registran | Mientras la cuenta exista; borrado en cascada |
| Confidencial | Propio usuario; operadores con rol | Disco/BD cifrados | TLS 1.2+ | Enmascarado / sólo ids | Mientras la cuenta exista |
| Público | Abierto | Opcional | TLS 1.2+ | Libre | Ilimitada |

Reglas vigentes: los logs sólo contienen ids y metadatos técnicos (nunca bodies); los
entornos de test usan datos sintéticos (los e2e truncan una BD desechable cuyo nombre
debe contener `test`/`e2e`); el borrado de `User` cascada a tokens, planes,
entrenamientos, progreso e interacciones (`onDelete: Cascade`).

## 8. Cumplimiento (RGPD) — pendientes

Los datos de salud son **categoría especial** (art. 9 RGPD): su tratamiento requiere una
base legal del art. 9.2, en la práctica el **consentimiento explícito**.

| Requisito | Estado |
|---|---|
| Consentimiento explícito, granular y registrado (versión, fecha) antes de recoger datos de salud | ⏳ Fase 3 |
| Derecho de acceso/portabilidad: exportación de todos los datos del usuario | ⏳ Fase 3 |
| Derecho de supresión: borrado de cuenta y datos (la cascada en BD ya existe; falta endpoint) | ⏳ Fase 3 |
| Política de privacidad y registro de actividades de tratamiento | ⏳ antes de producción |
| Evaluación de impacto (EIPD/DPIA): probablemente obligatoria por tratar salud a escala | ⏳ antes de producción |
| Minimización: no recoger IP/User-Agent salvo necesidad justificada | ✅ (no se rellenan hoy) |
| Encargados del tratamiento (hosting, Sentry) con DPA y ubicación UE | ⏳ despliegue |
| Notificación de brechas en 72 h: procedimiento documentado | ⏳ |

## 9. Riesgos residuales

- **Rate limiting por instancia y por IP**: insuficiente con varias réplicas o tras un
  proxy sin `trust proxy`. Aceptado mientras haya una sola instancia; se resuelve al
  desplegar (store Redis, `trust proxy`).
- **Revocación agresiva**: perder una carrera de refresh (p. ej. reintento de red del
  móvil) se trata como reutilización y cierra todas las sesiones. Se acepta por seguridad;
  la app (Fase 4) debe serializar el refresh (single-flight).
- **Access token válido hasta caducar** (15 min por defecto) tras logout/revocación. El
  rol y la existencia del usuario sí se comprueban en BD en cada petición.
- **Historial de git** conserva `.tools/` (binarios de Node de terceros, no secretos).
  No se reescribe la historia.
- **Enumeración de emails por registro (409)**: mitigada sólo por rate limiting hasta Fase 3.
- **Job `mobile` de CI no bloqueante** hasta que la app se rehaga en la Fase 4.

## 10. Resumen de controles de la Fase 1

- Catálogo admin sin auth eliminado; `UserRole` + `RolesGuard`/`@Roles()`.
- Entorno validado con Zod; sin secretos por defecto (tampoco en tests).
- Refresh tokens: rotación atómica, detección de reutilización con revocación total,
  `tokenHash` único, índice por `userId`.
- `@nestjs/throttler` global y estricto en auth y generación de planes.
- `helmet`, CORS por allowlist, Swagger fuera de producción.
- Ownership con 404 en workouts y analytics; ids UUID validados; `.max()` en textos libres;
  contraseña 8–72 bytes; login sin oráculo de tiempo; bcrypt 12.
- `uncaughtException` → exit(1); el worker no registra `job.data`.
- e2e contra Postgres real (sin mocks de Prisma, forzado por test y ESLint) en CI.
