# Plan: guía de ejercicios (músculos, ficha, mapa muscular y vídeos)

**Fecha:** 2026-11-09 · **Base:** `main` @ `ac8c074` · **Estado:** aprobado · **Decisión asociada:** [ADR-0014](adr/0014-guia-de-ejercicios.md) (Fase 0 hecha; respuestas a la sección 6 en el ADR)

## 1. Objetivo

Que el usuario sepa **qué trabaja** cada ejercicio y **cómo se hace** sin salir de la app, con contenido
revisado y sin romper los principios del producto («nada falso», evidencia, RGPD, sin panel de
administración).

Cuatro funciones, una por fase de producto:

| # | Función | Para qué |
|---|---|---|
| 1 | Músculos visibles en cada ejercicio | Ver en Hoy, Plan y al cambiar ejercicio qué músculos trabaja (principales y secundarios). |
| 2 | Ficha del ejercicio | Una pantalla por ejercicio: descripción, músculos, claves técnicas, errores comunes, material y nivel. |
| 3 | Mapa muscular y biblioteca | Tocar un músculo en un cuerpo (delante y detrás) y ver los ejercicios que lo trabajan con tu material; opcionalmente, colorearlo por tus series de la semana. |
| 4 | Vídeos e imágenes | Un vídeo concreto y revisado por ejercicio (no una búsqueda), abierto fuera de la app. |

## 2. Punto de partida (qué hay hoy)

| Pieza | Estado | Dónde |
|---|---|---|
| Músculos por ejercicio (19 músculos, principal/secundario, fracción) | **Existen** en el catálogo y en la BD; el motor los usa | `packages/catalog/data/exercises.json`, `ExerciseMuscle` |
| Músculos en la respuesta de Hoy y de Plan | **No llegan**: `TodayExerciseSchema` y `PlanExerciseResponseSchema` no los incluyen | `packages/contracts/src/schemas/workouts.ts`, `plans.ts` |
| Músculos en `GET /exercises` | `primaryMuscles` en la lista; `muscles` completos en el detalle | `packages/contracts/src/schemas/catalog.ts` |
| Nombres de los músculos en es/en | **Existen** en la app (los usa el onboarding) | `apps/mobile/lib/l10n/` |
| Claves técnicas | 2-3 frases por ejercicio, solo en español; se ven en Hoy | `cuesEs` |
| Descripción del ejercicio | Columnas `descriptionEs`/`descriptionEn` en la BD, **sin usar**; el catálogo no tiene el campo | `apps/api/prisma/schema.prisma` |
| Vídeos e imágenes | Tabla `ExerciseMedia` (YouTube o imagen, inicio y fin, canal, idioma, estado de revisión) **sin usar**; el contrato obliga a `media: null` | `schema.prisma`, `packages/contracts/src/engine-v2/catalog.ts` |
| Pantalla de ficha o biblioteca | No existe | — |
| Abrir enlaces externos | No hay `url_launcher` en la app | `apps/mobile/pubspec.yaml` |

### Qué se toma de El Plan y qué no

La app previa (analizada en [IDEAS_EL_PLAN.md](IDEAS_EL_PLAN.md)) tenía las cuatro cosas, pero hechas de
forma que este plan **no copia**:

| En El Plan | Problema | En Pipos |
|---|---|---|
| «Vídeo» = enlace a una **búsqueda** de YouTube | Contenido sin revisar; cada día puede salir otro vídeo | Un vídeo concreto, elegido y revisado, con inicio y fin (Fase 4) |
| Guía **deducida del nombre** por palabras clave, con texto genérico si no reconoce el nombre | Falla en silencio; no es contenido por ejercicio | Descripción escrita por ejercicio en el catálogo, revisada por PR (Fase 2) |
| Músculos deducidos del nombre (10 grupos) | «Puente» cuenta como isquios y no como glúteo; sin coincidencia, sin músculos | Datos del catálogo, ya validados y usados por el motor (Fase 1) |
| Mapa corporal SVG con lista de ejercicios por lugar | La idea es buena | Se adopta con dibujo propio y los datos del catálogo (Fase 3) |

Los textos de `exGuide` de El Plan pueden servir **como borrador por patrón de movimiento** para la
Fase 2, nunca como texto final. El HTML de El Plan contiene datos personales de su plan: no se copia al
repositorio.

## 3. Principios y restricciones

- **Nada falso.** Si un ejercicio no tiene vídeo revisado, no se muestra nada; nunca un enlace de búsqueda.
  Las descripciones no prometen efectos («quema grasa», «previene lesiones») sin fuente.
- **Un solo origen del contenido.** Todo vive en `packages/catalog`, validado con Zod y revisado por PR
  (ADR-0005). Sin panel de administración.
- **Compatibilidad.** Los campos nuevos de los contratos llevan `default` para no romper clientes y
  fixtures anteriores (mismo criterio que ADR-0013).
- **Offline.** La ficha de los ejercicios del plan vigente debe verse sin red (caché drift). Los vídeos
  necesitan red y lo dicen.
- **Privacidad.** Los vídeos se abren **fuera** de la app (app de YouTube o navegador), así la app no
  carga código de terceros ni envía datos a Google. Si más adelante se embebe un reproductor, se usa
  `youtube-nocookie.com` y se actualiza la política de privacidad y la DPIA.
- **Revisión profesional.** Descripciones y vídeos los revisa un entrenador titulado antes del lanzamiento
  público (igual que el catálogo, SPEC_V1). No bloquea el desarrollo.
- **Accesibilidad.** El mapa muscular tiene alternativa en lista; cada región tiene etiqueta para
  TalkBack; los colores del mapa de calor no son la única señal.

## 4. Fases

Cada fase sale de su rama `mejoras/guia-fase-N-*`, se mezcla en `main` por PR con el CI en verde y deja la
app usable. Tamaños: S (≤ 2 días), M (3-5 días), L (> 1 semana), contando solo el trabajo de código.

```
Fase 0 (decisiones)
   │
   ├── Fase 1 (músculos visibles) ──────────────┐
   │                                            ▼
   └── Fase 2 (ficha del ejercicio) ──▶ Fase 3 (mapa y biblioteca)
                    │
                    └──▶ Fase 4 (vídeos)  ← bloqueada por el contenido revisado
```

Las fases 1 y 2 pueden ir en paralelo. La 3 necesita la ficha (destino al tocar un ejercicio) y las
etiquetas de músculos de la 1. La 4 necesita la ficha y el contenido.

---

### Fase 0. Decisiones · S

**Entregables**
- **ADR-0014 «Guía de ejercicios»**: acepta las cuatro funciones con las condiciones de la sección 3;
  confirma que siguen rechazadas la guía deducida del nombre y el enlace a una búsqueda; promueve de
  LATER a aceptados «medios de técnica curados» y «mapa de calor» de ADR-0013.
- Decisión de contenido (Victor): quién escribe las descripciones, quién elige y revisa los vídeos, y si
  habrá imágenes propias. Ver preguntas abiertas (sección 6).
- Este plan enlazado desde `docs/PHASES.md` y `docs/adr/README.md`.

**Hecho cuando:** ADR-0014 aceptado y las preguntas que bloquean la Fase 4 tienen responsable.

---

### Fase 1. Músculos visibles en cada ejercicio · S-M

**Contratos** (`packages/contracts`)
- `ExerciseMuscleRefSchema = { muscle, role }` (sin la fracción: es un detalle del motor).
- `TodayExerciseSchema.muscles` y `PlanExerciseResponseSchema.muscles`: `z.array(...).default([])`,
  ordenados: principales primero y, dentro de cada rol, en el orden del enum `MUSCLES`.
- Cuando hay sustitución o cambio fijado, los músculos son los del ejercicio **realmente hecho**.

**API** (`apps/api`)
- Rellenar `muscles` desde la caché del catálogo en `GET /sessions/today` y `GET /plans/current`
  (y versiones), sin consultas extra por ejercicio.
- Regenerar `openapi.json` (`openapi:generate`).

**App** (`apps/mobile`)
- Tarjeta de Hoy: línea «Trabaja: Cuádriceps, Glúteos» y, desplegable, «También: Aductores, Lumbar».
- Plan: los mismos chips en cada ejercicio de la sesión.
- Hoja de cambiar ejercicio: músculos principales de cada alternativa (`primaryMuscles` ya llega).
- Actualizar modelos, fixtures y su validación contra los contratos (`tool/validate_fixtures.mjs`).

**Tests**
- Contratos: respuesta antigua sin `muscles` sigue siendo válida; orden principal → secundario.
- e2e: `today` y `plans/current` devuelven los músculos del catálogo; con sustitución, los del sustituto.
- Widget: la tarjeta muestra principales y secundarios; texto al 200 % sin desbordes.

**Docs:** UX_MOVIL (tarjeta de Hoy), MODELO_DATOS no cambia, README («Qué hace v1»).

**Hecho cuando:** en Hoy, Plan y el cambio de ejercicio se ven los músculos del ejercicio que se hace, en
claro y oscuro, con TalkBack leyendo «Trabaja: …».

---

### Fase 2. Ficha del ejercicio · M (+ contenido)

**Catálogo** (`packages/catalog`, `packages/contracts`)
- `CatalogExerciseSchema.descriptionEs`: 1-3 frases (≤ 400 caracteres) que dicen qué es el movimiento y
  qué trabaja; sin promesas de efectos.
- `CatalogExerciseSchema.mistakesEs`: 0-3 errores comunes (≤ 120 caracteres cada uno).
- Se introduce primero como **opcional**; un test informa de la cobertura. Cuando los 144 la tengan, se
  vuelve obligatoria (otro PR) y el test pasa a exigirla.
- Borrador por patrón de movimiento (18 patrones) a partir de los textos de El Plan, reescrito para cada
  ejercicio. Revisión por PR; revisión profesional antes del lanzamiento.

**API**
- El seed escribe `descriptionEs` (columna existente) y `mistakesEs` (migración nueva: `String[]`).
- `ExerciseDetailSchema` añade `descriptionEs`, `mistakesEs` y `media` (lista vacía hasta la Fase 4).
- `GET /exercises/:id` acepta también el slug, para enlazar desde cualquier pantalla.

**App**
- Pantalla nueva **Ficha del ejercicio** (ruta `/exercise/:id`): nombre, descripción, músculos
  (principales y secundarios), claves técnicas, errores comunes, material, nivel mínimo y zonas a
  vigilar si el usuario tiene una limitación (solo con consentimiento; se usan las `riskTags`).
- Se abre desde: el nombre del ejercicio en Hoy y en Plan, cada alternativa al cambiar ejercicio y la
  búsqueda de favoritos y vetados del onboarding.
- Sin red: se guarda en la caché drift; al cargar el plan vigente se precargan las fichas de sus
  ejercicios. Fuera de caché y sin red: «Necesitas conexión para ver esta ficha».

**Tests**
- Catálogo: validación del esquema; informe de cobertura; ningún texto supera los límites.
- e2e: el detalle devuelve los campos nuevos por id y por slug; ejercicio retirado → 404.
- Widget: ficha completa, ficha sin descripción (no deja huecos), modo sin red con y sin caché.

**Docs:** CUJ nuevo **CUJ-11 «Conocer un ejercicio»** (desde Hoy, en menos de 2 toques, ver qué trabaja y
cómo se hace, también sin red para el plan vigente). UX_MOVIL, MODELO_DATOS, ARCHITECTURE.

**Hecho cuando:** los 144 ejercicios tienen descripción revisada por PR, la ficha se abre desde los cuatro
puntos de entrada y funciona sin red para el plan vigente.

---

### Fase 3. Mapa muscular y biblioteca · M-L

**3a. Biblioteca por músculo**
- API: `GET /exercises` acepta `muscle` (uno de los 19) y `role` (`primary` por defecto); el filtro
  `equipment` ya existe.
- App: pantalla **Ejercicios** con entrada desde Plan («Ver ejercicios por músculo»). Dos vistas:
  - **Cuerpo**: figura propia, delante y detrás, con una región por músculo (los 19 del enum; los que no
    se ven de un lado se muestran en el otro). Dibujo original en SVG como recurso de la app.
  - **Lista**: los mismos músculos agrupados por grupo de volumen. Es la alternativa accesible.
- Al tocar un músculo: ejercicios que lo trabajan como principal, filtrados por **tu material** (con un
  interruptor «Todo el catálogo»), ordenados por nivel. Cada uno abre su ficha.
- Desde la ficha, «Añadir a favoritos» o «No quiero hacerlo» lleva a la edición del perfil, que ya
  regenera el plan (no se crea un camino nuevo de escritura).

**3b. Mapa de calor de la semana** (promovido desde LATER en ADR-0013)
- Colorea cada región por las series efectivas de la semana frente al rango objetivo de su grupo
  (`GET /progress/volume`, que ya devuelve el volumen por músculo y por grupo).
- Tres estados (por debajo, dentro, por encima) con color **y** patrón o etiqueta; leyenda visible.
- Se muestra en Progreso → Entreno, junto a las barras actuales; no las sustituye.

**Tests**
- e2e: filtro por músculo y rol, combinado con material; músculo inválido → 400.
- Widget: tocar cada región abre su lista; la vista de lista cubre los 19 músculos; etiquetas de
  accesibilidad en todas las regiones; mapa de calor sin datos (semana vacía) y con datos.
- Golden de la figura en claro y oscuro.

**Hecho cuando:** desde Plan se llega a cualquier ejercicio del catálogo por músculo en ≤ 3 toques, y
Progreso muestra el mapa de la semana con alternativa en lista.

---

### Fase 4. Vídeos e imágenes · M de código + contenido (L)

**Bloqueada** hasta tener contenido revisado (preguntas abiertas). El código puede prepararse antes.

**Estado (2026-11-09):** código preparado (rama `mejoras/guia-fase-4-videos`): esquema y validación de
`media`, `media:check`, seed y API (`media`, `hasVideo`), botón en la app y docs. El catálogo sigue **sin
vídeos**: la fase no está «hecha» hasta que una persona elija y apruebe los vídeos por PR según el
procedimiento de `packages/catalog/README.md`.

**Catálogo**
- `media` deja de ser `null`: lista de `{ kind: 'youtube', videoId, startSeconds?, endSeconds?,
  channelName, locale }` o `{ kind: 'image', file, credit, licence }`. Máximo 2 por ejercicio, uno
  marcado como principal.
- Validación: formato de `videoId`, `endSeconds > startSeconds`, imagen existente en el paquete y con
  licencia declarada.
- Script manual `pnpm --filter @pipos/catalog media:check` que comprueba por oEmbed que cada vídeo sigue
  disponible (no corre en CI porque necesita red).

**API**
- El seed escribe `ExerciseMedia` con `moderationStatus = approved` (la revisión es el PR, ADR-0005) y
  borra los medios retirados del JSON.
- `ExerciseDetailSchema.media` y, en `TodayExerciseSchema`, `hasVideo: boolean` para pintar el botón sin
  pedir la ficha.

**App**
- Añadir `url_launcher`. En la ficha y en la tarjeta de Hoy, botón «Ver vídeo (YouTube)» que abre el
  vídeo en el segundo de inicio, fuera de la app, con aviso de que sale de Pipos.
- Imágenes propias: dentro de la app, con su crédito.
- Sin vídeo revisado: no hay botón.

**Tests**
- Catálogo: validación de medios; ningún medio sin licencia o crédito.
- e2e: el detalle incluye los medios aprobados; los retirados desaparecen tras el seed.
- Widget: botón presente o ausente según `hasVideo`; sin red, el botón avisa.

**Docs:** SECURITY (nuevo destino externo: YouTube, sin datos del usuario), política de privacidad,
DPIA si alguna vez se embebe un reproductor, DEPLOY_CHECKLIST.

**Hecho cuando:** los ejercicios principales de los 10 planes de ejemplo tienen vídeo revisado, y ningún
ejercicio muestra un vídeo que no haya pasado por PR.

## 5. Contenido: cuánto hay que escribir

| Fase | Contenido | Volumen | Quién (a decidir) |
|---|---|---|---|
| 1 | Ninguno: los músculos ya existen | — | — |
| 2 | Descripción + errores comunes | 144 ejercicios × (1-3 frases + 0-3 errores) | Redacción: equipo; revisión: entrenador titulado |
| 3 | Figura del cuerpo (19 regiones, delante y detrás) | 2 ilustraciones SVG | Diseño propio o encargo con cesión de derechos |
| 4 | Vídeos | Primero los ~40 ejercicios más usados en los planes de ejemplo; después el resto | Selección y revisión: entrenador titulado |

Orden sugerido para la Fase 2: primero los ejercicios que aparecen en los 10 planes de ejemplo
(`docs/engine/ejemplos/`), después el resto del catálogo.

## 6. Preguntas abiertas

| Pregunta | Quién | ¿Bloquea? |
|---|---|---|
| ¿Quién escribe las 144 descripciones y quién las revisa? | Victor | Bloquea cerrar la Fase 2 (no empezarla) |
| ¿Vídeos de YouTube de terceros (enlazados) o vídeos propios? | Victor | Bloquea la Fase 4 |
| Si son de terceros: ¿criterio de selección de canales (titulación, idioma, sin publicidad de suplementos)? | Victor + entrenador | Bloquea la Fase 4 |
| ¿Imágenes propias o GIF? ¿Con qué licencia? | Victor | No; la Fase 4 puede salir solo con vídeos |
| ¿La figura del cuerpo se dibuja en casa o se encarga? | Victor | Bloquea la Fase 3a |
| ¿Inglés (`descriptionEn`, `cuesEn`) en este plan o aparte? | Victor | No. Propuesta: aparte, junto a la deuda «explicaciones solo en español» |

## 7. Riesgos

| Riesgo | Mitigación |
|---|---|
| Un vídeo de terceros desaparece o cambia | `media:check` antes de cada release; sin vídeo, no se muestra botón |
| Descripciones con afirmaciones sin fuente | Guía de estilo en el PR de la Fase 2 y revisión profesional |
| La figura del cuerpo no se entiende en pantallas pequeñas | Vista de lista equivalente; regiones con área táctil mínima de 48 dp |
| El mapa de calor se lee como diagnóstico de «músculo débil» | Texto: «series de esta semana frente a tu objetivo»; nada de recuperación ni predicciones (rechazado en ADR-0013) |
| Crece el tamaño de la app con imágenes | Imágenes solo si se aprueban; WebP y límite por imagen en la validación |

## 8. Fuera de este plan

- Embeber un reproductor de vídeo dentro de la app.
- Ejercicios por tiempo, búsqueda en vídeo, guía deducida del nombre (siguen rechazados o LATER en ADR-0013).
- Panel para editar el catálogo (ADR-0005).
- Traducción al inglés del contenido nuevo (pregunta abierta 6).
