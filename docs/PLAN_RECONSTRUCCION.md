# Plan de reconstrucción de Pipos Fitness

**Fecha:** 2026-11-09 · **Base:** `main` @ `e7e8c1b` · **Estado:** Fase 0 cerrada; el resto de fases se ejecutan sin pausa (indicación de Victor del 9 nov 2026).

Documentos de esta fase:
- [Análisis del estado actual](ANALISIS_ESTADO_2026-11.md)
- [Spec de producto v1](SPEC_V1.md)
- [Recorridos críticos (CUJs)](CUJS.md)
- [Programación del motor: reglas, constantes y fuentes](engine/PROGRAMACION.md)
- [Modelo de datos propuesto](MODELO_DATOS.md)
- [ADRs](adr/README.md)

## 1. Inventario: qué se queda, qué se va y qué se rehace

| Pieza | Decisión | Por qué |
|---|---|---|
| Monorepo pnpm, capas contracts → engine-rules → API | **Se queda** | Dirección de dependencias sana; motores puros y testeables |
| `packages/contracts` (Zod) | **Se queda y crece** | Fuente única de entradas y salidas; de ahí sale el OpenAPI |
| `packages/engine-rules/training` | **Se rehace** (ADR-0006) | Enfoque válido, pero con errores de dominio: orden por UUID, `.some` en material, «compuesto» mal definido, scoring incompleto, suelo de volumen sin usar |
| `packages/engine-rules/nutrition` | **Se reduce** a objetivos diarios (ADR-0004) | Comidas que no cuadran macros; valores por defecto silenciosos |
| `apps/api` auth | **Se queda y se endurece** | Base buena (hash, rotación); faltan rotación atómica, revocación, throttling y validación de env |
| `apps/api` training-plans, workouts, analytics | **Se rehacen** sobre el nuevo esquema | Sin transacciones, N+1, GET que escribe, propiedad sin comprobar |
| `apps/api` catalog (lectura) | **Se queda**; el catálogo pasa a seed versionado | Paginación correcta |
| `apps/api` catalog/admin | **Se elimina** (ADR-0005) | Abierto sin auth; sin contenido de usuarios que moderar |
| `apps/api` ai-coach + `AiInteraction` | **Se elimina** (ADR-0003) | Stub de palabras clave anunciado como IA |
| `apps/api` foods, meal templates | **Se eliminan** (ADR-0004) | Fuera del alcance de v1 |
| `apps/worker` (BullMQ/Redis) | **Se elimina** (ADR-0002) | Placeholder sin productores; test `expect(true)` |
| Prisma schema y migraciones | **Se regeneran** (ADR-0009) | Migraciones incoherentes; faltan FK, índices y orden |
| `apps/mobile` core (secure storage, refresh deduplicado, error mapper) | **Se queda y se corrige** | Funciona y está testeado; fallos de auth concretos |
| `apps/mobile` features | **Se rehacen** con las pantallas de v1 | Sin offline, sin i18n ni a11y; pantallas de IA y nutrición fuera |
| Identidad visual (`theme.dart`: azul marino oscuro y acento naranja `#FF6D00`) | **Se queda** como base de los tokens | Ya define tono; se formaliza en tokens con contraste comprobado |
| CI | **Se rehace** (un solo workflow) | Dos workflows pegados; Flutter 3.16 incompatible; e2e sin ejecutar |
| `.tools/`, `_tmp_*`, `apps/mobile/package.json` | **Se eliminan** | Binarios en git; falso verde |
| `docs/PHASE_*_SUMMARY.md` (~35) y `docs/DECISIONS.md` | **Se archivan** en `docs/archivo/` | Ruido; describen cosas que ya no existen |

## 2. Spec de producto v1
Resumen (detalle en [SPEC_V1.md](SPEC_V1.md) y [CUJS.md](CUJS.md)).

- **Para quién:** adultos sanos que entrenan fuerza sin entrenador, de principiante a avanzado, en gimnasio o en casa.
- **Qué hace:** genera un plan explicado y adaptado (material, tiempo, nivel, limitaciones, preferencias); guía cada sesión con registro rápido y offline; ajusta cargas semana a semana; muestra el progreso.
- **Pantallas de v1:** onboarding (cuestionario más consentimiento de salud), plan actual, sesión de hoy, progreso, ajustes (perfil, material, limitaciones, objetivos nutricionales, exportar y borrar cuenta).
- **No-objetivos:** chat de IA, menús, panel web admin, social, wearables, push del servidor, poblaciones clínicas, iOS publicado.

### Cambios de alcance propuestos respecto al prompt maestro
Salen de la revisión crítica de alcance:
1. **Panel admin fuera de v1 (ADR-0005).** El catálogo como seed revisado por PR controla mejor la calidad y elimina el hallazgo crítico. Se mantiene `role` y `RolesGuard` para el futuro.
2. **Añadidos que el prompt no listaba y son esenciales:**
   - Gestión de sesiones perdidas y vuelta tras ausencia (CUJ-5).
   - Series de calentamiento en el primer multiarticular de la sesión.
   - Cribado previo no médico (aviso de consultar a un profesional si hay dolor, enfermedad cardiovascular conocida o síntomas), sin bloquear ni diagnosticar.
   - Zona horaria del usuario para cerrar bien las semanas.
3. **La nutrición se mantiene reducida** (ADR-0004), con la alternativa documentada de sacarla del todo.
4. **La búsqueda local se midió y se retiró** (ADR-0006): en los 10 perfiles de ejemplo mejoraba el score un 1,83 % de media, por debajo del umbral del 2 %.

## 3. Diseño del motor
Detalle completo, con cada constante y su fuente, en [engine/PROGRAMACION.md](engine/PROGRAMACION.md).

**Pipeline** (función pura `generatePlan(profile, catalog, history, config) → PlanDraft`):
1. **Normalizar y validar** el perfil con Zod; si hay error, se devuelve el error, nunca valores por defecto.
2. **Filtrar el catálogo** con restricciones duras: material con `.every`, limitaciones (tags de riesgo por zona), vetados y nivel mínimo.
3. **Elegir el split** por días disponibles, con al menos 2 veces por semana por grupo. Se justifica en `rationale`.
4. **Repartir el volumen:** objetivo de series semanales por grupo según nivel y prioridad, entre suelo y techo; las series de los músculos secundarios cuentan a fracción.
5. **Solución inicial:** por sesión, multiarticulares del patrón requerido → accesorios → aislamiento y core; el músculo prioritario primero; elección por afinidad (favoritos, cobertura, variedad). Desempate estable por `slug`.
6. **Asignar la prescripción:** reps, RIR y descanso según objetivo y tipo de ejercicio; carga desde el e1RM del historial o marcada como «estimación inicial».
7. ~~Búsqueda local acotada~~ **Retirada en la Fase 2** (ADR-0006): solo aportaba un +1,83 % medio en 10 perfiles, umbral 2 %. La solución por reglas del paso 5 (con relleno de volumen hasta suelo y techo, reparación de frecuencia y ajuste al tiempo) es el plan final; el scoring se mantiene como medida de calidad del plan.
8. **Explicaciones:** `rationale[]` por plan, sesión y ejercicio, con plantillas en castellano.

**Scoring**, con pesos en la tabla de config: cobertura de músculos objetivo (penaliza huecos), ajuste al rango de volumen, ajuste al tiempo de sesión (penaliza pasarse y quedarse corto), frecuencia, balance empuje/tracción, variedad sin redundancia, preferencias.

**Progresión** (`nextPrescription(history, prescription, config)`): doble progresión, autorregulación por RIR, deload programado y reactivo (reps o RIR caen dos sesiones seguidas), reajuste tras 14 días o más sin entrenar.

**Sustitución** (`substitutes(exercise, profile, catalog) → top 3`): mismo grupo de sustitución o patrón, similitud muscular, material disponible y limitaciones respetadas.

**Invariantes**, comprobados con fast-check:
1. Ningún ejercicio sin todo su material.
2. Ningún patrón vetado por una limitación.
3. Todos los grupos objetivo por encima del suelo.
4. Sesión dentro del presupuesto ± tolerancia.
5. Multiarticulares antes que aislamiento.
6. Determinismo.
7. Al menos 2 veces por semana por grupo cuando hay 2 días o más.

**Casos límite fijos:**
- 2 días, 30 min, solo peso corporal.
- 6 días, 90 min, gimnasio completo.
- Lesión de hombro.
- Principiante sin historial.
- Avanzado con historial largo.
- Material que no cubre algún patrón, que debe dar aviso explícito y no un hueco silencioso.

## 4. Modelo de datos
Detalle en [MODELO_DATOS.md](MODELO_DATOS.md).

Claves:
- `User.role`.
- Consentimiento de salud como registro solo de añadidos.
- Material y músculos como enums cerrados.
- `PlanVersion` con instantánea del input, `engineVersion` y `rationale`.
- `PlanExercise.order` persistido y FK `RESTRICT` a `Exercise`, que solo se borra de forma lógica.
- `SetLog` único por `(userId, clientId)` para la idempotencia.
- Tablas resumen de analytics.
- `NutritionTarget` sin alimentos.
- FK compuestas que garantizan en la BD que un entrenamiento solo enlaza con sesiones de plan del mismo usuario.
- Una única migración inicial y `migration_lock.toml` versionado.

Decisiones menores tomadas en la Fase 0:
- `birthYear` en vez de `age`, por minimización (la edad para Mifflin-St Jeor se calcula con ±1 año).
- Zona horaria IANA en el perfil.
- Sin `lastLoginAt` ni registro de borrados.
- Se asume que **no hay datos de producción** (no hay configuración de despliegue en el repo).

## 5. ADRs
Ver el [índice](adr/README.md): ADR-0001 a ADR-0012.

## 6. Plan de PRs por fase

Estimación en días de trabajo de un desarrollador senior. Cada PR sale de su propia rama `reconstruccion/fase-N-*` y se mezcla en `main` con el CI en verde.

| Fase | PRs | Estimación |
|---|---|---|
| **0. Diagnóstico** | 1 PR de documentación (este) | 1 d |
| **1. Parar el sangrado** | CI único; e2e contra Postgres real; build y lint en verde; fuera `/admin` y `role` más `RolesGuard`; env validada sin secretos por defecto; throttler, helmet, CORS y Swagger fuera de producción; rotación atómica y revocación; propiedad de recursos; validaciones; limpieza del repo; `docs/SECURITY.md` | 4–5 d |
| **2. Motor y catálogo** | Config de constantes citadas; nuevo pipeline de generación; progresión y deload; sustitución; explicaciones; property tests y casos límite; seed de 80–150 ejercicios con test de huecos; 10 perfiles de ejemplo en `docs/engine/ejemplos/` | 8–10 d |
| **3. API y datos** | Nuevo esquema y migración única; generación en `$transaction` con reintento de versión; registro idempotente; analytics al escribir; nutrición reducida; consentimiento, exportar y borrar; OpenAPI desde Zod; fuera worker, coach, alimentos y comidas; README honesto; e2e de todos los CUJs | 6–8 d |
| **4. App móvil** | Plataformas y versión fijada; auth corregida (interceptor, reintentos marcados, timeout, logout total, router estable); cola offline con drift; pantallas de v1; i18n con ARB; a11y; tests (contraseña incorrecta, offline → sync, integration «completar sesión»); APK de debug en CI | 10–12 d |
| **5. Cierre** | Tres revisiones independientes y correcciones; deuda en issues; docs y `PHASES.md` coherentes; checklist de despliegue; informe final | 2–3 d |

**Paralelismo:** la Fase 2 (paquete puro) se ejecuta en paralelo a la Fase 1. La Fase 3 espera a las dos. La Fase 4 empieza con lo que no depende de contratos (plataformas, auth, cola local) y engancha los contratos al cerrar la Fase 3.

## 7. Riesgos y mitigación
| Riesgo | Mitigación |
|---|---|
| Plan no creíble para avanzados o inseguro para principiantes | Constantes citadas; invariantes; 10 perfiles revisados; revisión por un entrenador titulado antes del lanzamiento público |
| Pérdida o duplicado de series al sincronizar | Idempotencia por UUID; tests de offline → sync e e2e de reenvío |
| Explicaciones que suenan a plantilla | Plantillas con datos concretos del usuario («porque entrenas 4 días…»); revisión de copy UX |
| GDPR con datos de salud | ADR-0011; borrado real probado por e2e; DPIA antes del lanzamiento |
| Entorno de esta sesión sin acceso al SDK de Android | El APK de debug lo construye el CI de GitHub; en local solo `analyze` y `test` |

## 8. Supuestos que conviene confirmar
1. No hay datos de producción ni staging (ADR-0009).
2. Panel admin fuera de v1 (ADR-0005) y nutrición reducida (ADR-0004).
3. Autor de commits: «Victor <vfbeneitez@gmail.com>» (configurado en el repo local).
