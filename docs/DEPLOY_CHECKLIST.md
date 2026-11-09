# Checklist de despliegue — Pipos Fitness v1

> Nunca se ha desplegado. Esta lista recoge todo lo que hay que hacer (y comprobar) antes del
> primer despliegue a producción y en cada despliegue posterior. Lo marcado **[BLOQUEA]** impide
> abrir la app a usuarios reales. Contexto de seguridad en [SECURITY.md](SECURITY.md).

**Fecha:** ____ · **Responsable:** ____ · **Versión (commit/tag):** ____

## 0. Bloqueantes legales y de producto

- [ ] **[BLOQUEA]** Evaluación de impacto (EIPD/DPIA): se tratan datos de salud (art. 9 RGPD).
- [ ] **[BLOQUEA]** Texto legal del consentimiento de salud revisado por un jurista. Si cambia, subir
      `HEALTH_CONSENT_POLICY.version` en `packages/contracts` (los usuarios deberán volver a consentir).
- [ ] **[BLOQUEA]** Política de privacidad, registro de actividades de tratamiento y procedimiento
      de notificación de brechas (72 h).
- [ ] **[BLOQUEA]** Contratos de encargado (DPA) con hosting, base de datos, backups y Sentry, con
      datos en la UE.
- [ ] Revisión de los planes de ejemplo por un entrenador titulado (`docs/engine/ejemplos/REVISION.md`).
- [ ] Revisión de la ficha de los 144 ejercicios (descripción y errores comunes,
      `packages/catalog/data/exercises.json`) por un entrenador titulado (ADR-0014); al terminar,
      `GUIDE_CONTENT_REVIEW.status = 'professionally_reviewed'` con la fecha en `packages/catalog`.

## 1. Pre-despliegue

- [ ] CI en verde en el commit a desplegar (backend: build, lint 0 avisos, typecheck, unitarios con
      cobertura, migraciones sin deriva, OpenAPI al día, fixtures móviles, e2e; móvil: analyze,
      test, integration, APK).
- [ ] PR revisado y mezclado en `main`; sin bugs críticos abiertos ([DEUDA_TECNICA.md](DEUDA_TECNICA.md)).
- [ ] Imagen/artefacto construido desde ese commit con `pnpm install --frozen-lockfile`, `prisma generate`
      y `pnpm build`; arranque con `node apps/api/dist/main.js` (`start:prod`).

### Variables de entorno (validadas al arrancar; la API no arranca si falta algo)

| Variable | Producción |
|---|---|
| `NODE_ENV` | `production` (desactiva Swagger, CSP estricta, prohíbe `THROTTLE_ENABLED=false`) |
| `PORT` | El que exponga el hosting |
| `DATABASE_URL` | `postgresql://…` con usuario de mínimo privilegio y `sslmode=require` |
| `JWT_ACCESS_SECRET` | **Secreto**, ≥ 32 caracteres aleatorios (p. ej. `openssl rand -base64 48`); en el gestor de secretos, nunca en el repo |
| `JWT_ACCESS_EXPIRES_IN` | 900 (por defecto) |
| `REFRESH_TOKEN_TTL_DAYS` | 30 (por defecto) |
| `REFRESH_REUSE_GRACE_SECONDS` | 10 (por defecto) |
| `CORS_ORIGINS` | Vacío si solo hay app móvil; si hay web, sus orígenes HTTPS exactos |
| `LOG_LEVEL` | `info` |
| `SENTRY_DSN` | DSN del proyecto (región UE) o vacío |
| `THROTTLE_ENABLED` | Sin definir (true) |
| `TRUST_PROXY_HOPS` | Número de proxies de confianza delante de la API (normalmente `1`: el balanceador del hosting). `0` (por defecto) ignora `X-Forwarded-For`. **Nunca** más saltos de los reales: un cliente podría falsificar su IP y saltarse el rate limiting |
| `THROTTLE_STORE` | `postgres` (por defecto con `NODE_ENV=production`): contadores del rate limiting compartidos entre réplicas en la tabla `ThrottlerRecord`. `memory` solo con una única instancia |

- [ ] Secretos en el gestor de secretos del hosting; rotación de `JWT_ACCESS_SECRET` documentada
      (rotarlo invalida todos los access tokens; los refresh siguen valiendo).

### Base de datos

- [ ] Postgres 16 gestionado, cifrado en reposo, en la UE, sin acceso público.
- [ ] **Backups** automáticos diarios + PITR, retención acordada en la EIPD; **restauración probada**.
- [ ] Migraciones: `pnpm --filter @pipos/api prisma:migrate:deploy` (`prisma migrate deploy`) como paso
      previo al arranque, **una sola vez por despliegue**. Comprobar antes en staging.
- [ ] Seed del catálogo: `pnpm --filter @pipos/api prisma:seed` (idempotente; retira con `deletedAt`).
      Tras `20261113000000_ficha_ejercicio`, el seed rellena la ficha (`descriptionEs`, `mistakesEs`);
      hasta entonces el motor toma la ficha del catálogo empaquetado.
- [ ] Si el despliegue incluye `20261110000100_volumen_por_grupo`, cambia una `formulaVersion` o
      cambia cómo se calcula la adherencia (p. ej. issue #14, versión del plan por semana):
      `pnpm --filter @pipos/api analytics:rebuild` tras migrar.

### Red, TLS y límites

- [ ] **[BLOQUEA]** HTTPS con TLS 1.2+ terminado en el hosting/proxy; HTTP redirige o se cierra.
      La API ya envía HSTS.
- [ ] **[BLOQUEA]** `TRUST_PROXY_HOPS` igual al número de proxies del hosting delante de la API
      (sin él el rate limiting vería la IP del proxy y limitaría a todos a la vez). Comprobar en
      staging: dos clientes con IP distinta no comparten el límite de login (5/min), y una cabecera
      `X-Forwarded-For` inventada por el cliente no cambia su IP.
- [ ] `THROTTLE_STORE=postgres` (por defecto en producción): las réplicas comparten los contadores,
      así que se puede escalar a varias instancias. La tabla `ThrottlerRecord` se limpia sola (filas
      caducadas, como mucho una vez por minuto y réplica); no guarda IPs en claro (clave = hash).
- [ ] Límites vigentes revisados: global 100/min, login/registro 5/min, refresh 10/min, generar
      plan 10/min, exportar/borrar 5/min, health 60/min (`apps/api/src/config/throttle.ts`).
- [ ] CORS: solo los orígenes de `CORS_ORIGINS`.

### Monitorización

- [ ] Tarea diaria `pnpm --filter @pipos/api audit:cleanup` (planificador del hosting): borra los
      `AuditEvent` con más de 180 días (`AUDIT_RETENTION_DAYS`, issue #17). Retención acordada en la EIPD.

- [ ] Sondas del orquestador: liveness `GET /health`, readiness `GET /health/ready` (503 sin BD).
- [ ] Logs JSON a un sistema con retención limitada y acceso restringido; comprobar que no salen
      cuerpos ni datos personales (redacción por clave, errores sin mensaje).
- [ ] Sentry (o equivalente) con DSN UE y sin PII; alertas de tasa de 5xx y de reinicios
      (`uncaughtException` → exit 1).
- [ ] Alertas de latencia (p95) y de errores de BD.

## 2. App móvil (release)

- [ ] **[BLOQUEA]** Firma de release propia (hoy `release` firma con las claves de debug en
      `android/app/build.gradle.kts`); keystore fuera del repo, en el gestor de secretos del CI.
- [ ] **[BLOQUEA]** `--dart-define=API_BASE_URL=https://…` (HTTPS; release prohíbe HTTP en claro).
- [ ] **[BLOQUEA]** Comprobar en el build release que las reglas de backup excluyen la base drift y
      el almacenamiento seguro (`adb shell bmgr backupnow` + inspección): la base local contiene la
      cola de series y caché de perfil/plan.
- [ ] `versionCode`/`versionName` incrementados; build `flutter build appbundle --release`.
- [ ] Prueba con TalkBack en dispositivo real y en un móvil de gama baja.
- [ ] Ficha de la tienda: política de privacidad enlazada y formulario de seguridad de datos
      (salud, actividad física) coherente con la EIPD.

## 3. Despliegue

- [ ] Desplegar en **staging** con una copia anonimizada o datos sintéticos; migrar y sembrar.
- [ ] Humo en staging: registro → consentimiento → perfil → plan → `GET /sessions/today` →
      registrar series → cerrar → `/progress/*` → exportar → retirar consentimiento → borrar cuenta.
- [ ] Desplegar en producción; migraciones antes de enrutar tráfico a la versión nueva.
- [ ] Vigilar 15 min: tasa de 5xx, latencia, reinicios y errores de BD.
- [ ] Verificar `GET /health/ready` = 200 y un login real.

## 4. Rollback

- [ ] Plan decidido **antes** de desplegar:
  - Código: volver a la imagen anterior (las migraciones de v1 son aditivas o eliminan columnas
    sin uso; la anterior a `20261110000000_minimizacion_ip_user_agent` sigue funcionando sin esas
    columnas solo si su código no las lee → comprobar en staging).
  - Base de datos: **no** se hace rollback de migraciones en caliente; si una migración rompe,
    restaurar desde PITR al instante previo y redesplegar la versión anterior.
  - Proyecciones de analítica: siempre reconstruibles con `analytics:rebuild`.
- Disparadores de rollback: 5xx > 2 % durante 5 min; p95 > 1 s sostenido; fallo del flujo
  registro → plan → registrar serie; errores de migración.

## 5. Post-despliegue

- [ ] Métricas normales tras 24 h; sin errores nuevos en Sentry.
- [ ] Notas de versión / changelog actualizados.
- [ ] Revisar SECURITY.md y DEUDA_TECNICA.md con lo aprendido.
