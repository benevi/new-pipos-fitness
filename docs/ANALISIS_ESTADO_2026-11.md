# Análisis del estado actual de Pipos Fitness (noviembre 2026)

> **Documento histórico.** Describe el proyecto **antes** de la reconstrucción (commit `e7e8c1b`,
> Fase 0). Casi todo lo que señala se corrigió en las Fases 1–5 ([PHASES.md](PHASES.md)); no lo uses
> como descripción del sistema actual: ver [ARCHITECTURE.md](ARCHITECTURE.md) y [SECURITY.md](SECURITY.md).

Análisis hecho sobre el commit `e7e8c1b`. Combina lo que se ejecutó (instalación, build, lint, typecheck, tests) con tres revisiones de código independientes: seguridad de la API, arquitectura y motores, y app Flutter. Los hallazgos más graves se comprobaron a mano.

**Resumen:** la base y el diseño de los motores son sólidos, pero la app no está lista para producción. El build no pasa, el CI no puede ir en verde, el panel de administración no pide login, y el worker y el coach de IA son esqueletos.

## 1. Resultado de la ejecución

| Comprobación | Resultado |
|---|---|
| `pnpm build` | ❌ Falla en `packages/engine-rules`: 16 errores TS6133/TS6196 (imports y variables sin usar) |
| `pnpm lint` | ❌ Falla por los mismos 16 errores |
| `pnpm typecheck` (API) | ❌ Falla sin `prisma generate` previo, y el CI no lo ejecuta. Tras generarlo, 0 errores |
| Tests unitarios | ✅ 182 en verde: engine-rules 82, contracts 71, api 28, worker 1 |
| Tests e2e de la API | ⚠️ El CI no los ejecuta: `*.e2e-spec.ts` no encaja en el patrón de Vitest. Lanzados a mano: 29 fallan y 17 se saltan, de 46. Causa: `import * as request from 'supertest'` no es invocable en Vitest. Además sustituyen Prisma por mocks |
| CI de Flutter | ❌ Usa Flutter 3.16.0; `pubspec.lock` exige Flutter ≥3.38.4 y Dart ≥3.10.3. `theme.dart` usa `WidgetStateProperty`, que no existe en 3.16 |
| `.github/workflows/ci.yml` | ❌ Contiene dos workflows pegados en el mismo YAML |

## 2. Pros (se conservan)

- **Capas:** `contracts` (Zod) → `engine-rules` (funciones puras, sin E/S) → servicios de la API.
- **Motores deterministas:** solución inicial voraz más búsqueda local acotada a 50 iteraciones; puntuación ponderada entre 0 y 1; desempate por id; restricciones incumplidas tipadas.
- **Fórmulas correctas:** Mifflin-St Jeor, factores de actividad estándar, e1RM de Epley, proteína 2 g/kg y grasa 0,8 g/kg.
- **Versionado de planes:** `@@unique([planId, version])`, puntero a versión actual, `engineVersion` y `objectiveScore` por versión.
- **Autenticación:** refresh tokens aleatorios de 32 bytes, guardados como hash SHA-256, rotados y con caducidad; bcrypt; emails normalizados; error de login genérico.
- **Propiedad y validación:** la mayoría de endpoints filtran por el usuario que llama; Zod valida casi todos los cuerpos; los errores no exponen el stack; no hay SQL inseguro ni secretos en el repo.
- **Coach de IA:** la estructura alrededor es buena (contexto mínimo, salida validada con Zod estricto, propuestas re-verificadas contra BD).
- **Flutter:** `flutter_secure_storage`; refresh deduplicado con un Dio aparte (con tests); estados de error, reintento y vacío; reanudar entrenamiento desde el servidor.
- **Catálogos paginados** (alimentos con cursor).

## 3. Contras

### Críticos
1. `/admin` no pide login: `admin-catalog.controller.ts` no tiene `@UseGuards` y `User` no tiene rol.
2. Build, lint y CI rotos (tabla de la sección 1).
3. La app móvil no tiene `android/` ni `ios/`; solo `web/`.

### Seguridad
- Secreto JWT por defecto (`'dev-access-secret-change-in-production'`) si falta `JWT_ACCESS_SECRET`.
- Reutilización de refresh detectada, pero sin revocar las demás sesiones.
- Carrera en la rotación: dos llamadas simultáneas obtienen dos tokens válidos.
- Sin throttling, sin helmet, Swagger público en producción, CORS que refleja cualquier origen en desarrollo.
- `planSessionId` sin comprobar propiedad al empezar un entrenamiento.
- Validación incompleta: `goal` de nutrición, ids de ruta, longitudes de texto, contraseñas de más de 72 bytes.
- Falta índice en `RefreshToken.tokenHash`; la última migración borra el de `userId`.
- `JWT_REFRESH_SECRET` declarado pero sin uso; `expiresIn` fijo a 900; bcrypt con coste 10; diferencia de tiempos en login que delata emails; `uncaughtException` tragada.

### Motor
- Orden de ejercicios por UUID; sin columna de orden persistida.
- Material comprobado con `.some` en vez de `.every` (`constraints.ts:44`).
- «Multiarticular» = cualquier ejercicio con `movementPattern`.
- El scoring no penaliza músculos objetivo sin series ni sesiones demasiado cortas.
- `WEEKLY_SETS_FLOOR` declarado pero sin usar; la adaptación puede bajar series por debajo de cualquier suelo.
- Fatiga todo o nada (0 o 1).
- Nutrición: cualquier sexo distinto de `male` usa la fórmula femenina; sin suelo calórico; peso ausente → 70 kg; datos inválidos → plan falso de 2000 kcal; las comidas cuadran calorías, no macros.

### Backend y datos
- Generación de planes sin `$transaction`, con inserts N+1 y número de versión leído y luego escrito.
- `GET /analytics/progress` escribe en la base de datos.
- Sin FK en `exerciseId`; borrar un alimento borra en cascada partes de versiones antiguas.
- `migration_lock.toml` en `.gitignore`; migraciones añadidas a posteriori.
- Worker: cola `placeholder` con `console.log` y test `expect(true)`; nada le envía trabajos.
- Coach de IA: busca palabras clave y devuelve frases fijas; no llama a ningún modelo.
- La app móvil no usa los contratos Zod: modelos Dart escritos a mano.

### App móvil
- Login y registro pasan por el interceptor de auth: un 401 por contraseña incorrecta puede forzar logout.
- Reintentos sin marcar (posible bucle de refresh) y refresh sin timeout.
- Logout que solo invalida 4 providers: quedan datos del usuario anterior.
- Router recreado en cada cambio de auth.
- Sin persistencia local ni modo offline.
- Sin `Semantics`, sin i18n (textos fijos en inglés; el coach responde en español).
- URL por defecto `http://10.0.2.2:3000`.
- `riverpod_generator` declarado sin uso; mezcla de estilos de Riverpod.

### Higiene
- Distribución de Node para Windows (zip de ~30 MB) versionada en `.tools/`.
- Dos ficheros vacíos `_tmp_*` en la raíz.
- Autor de commits `tu-email@example.com`.
- `docs/PHASES.md` desincronizado con el historial; ~35 `PHASE_*_SUMMARY.md`.
- `apps/mobile/package.json` hace `echo` y da falso verde en `pnpm -r test`.
