# Invariantes, casos límite y modos de fallo del motor v2

Resultado (resumido) de aplicar análisis de invariantes, enumeración de casos límite y análisis de modos de fallo **antes** de escribir los tests del motor (`packages/engine-rules`). Las reglas y números están en [PROGRAMACION.md](PROGRAMACION.md); aquí solo se dice **qué debe cumplirse siempre** y cómo se comprueba.

## 1. Invariantes

Todas son de seguridad (deben cumplirse en cada plan que devuelva `generatePlan` con `ok: true`). Se comprueban con fast-check sobre perfiles aleatorios válidos y el catálogo real (`@pipos/catalog`), en `src/training/invariants.property.test.ts`.

| ID | Invariante | Predicado | Supuestos |
|---|---|---|---|
| I1 | Material completo | `∀ ej ∈ plan: ej.equipment ⊆ perfil.equipment ∪ {bodyweight}` | El catálogo declara **todo** el material (`equipment.every`); `bodyweight` siempre disponible |
| I2 | Limitaciones respetadas | `∀ ej, ∀ zona ∈ perfil.limitations: riesgo(ej, zona) ≠ avoid` | Tags de riesgo conservadores en el catálogo (revisados en PR) |
| I3 | Vetados y nivel | `∀ ej: ej.id ∉ banned ∧ nivel(ej.minLevel) ≤ nivel(perfil)` | — |
| I4 | Suelo de volumen | `∀ grupo: vol(grupo) ≥ suelo(nivel)` **o** existe aviso `VOLUME_BELOW_FLOOR` para ese grupo | Factible solo si hay tiempo y ejercicios; si no, aviso explícito (nunca hueco silencioso) |
| I5 | Techo de volumen | `∀ grupo: vol(grupo) ≤ techo(nivel, prioridad)` | — |
| I6 | Presupuesto de tiempo | `∀ sesión: est ≤ minutos × (1 + tolerancia)`; y `est ≥ minutos × (1 − tolerancia)` **o** aviso `TIME_UNDERUSED` | Modelo de tiempo heurístico (§8) |
| I7 | Orden | En cada sesión, ningún multiarticular aparece después de un ejercicio de aislamiento o core, salvo el aislamiento del músculo prioritario en objetivo de hipertrofia (§6, `ORDEN_PERMITE_AISLAMIENTO_PRIMERO`) | `isCompound` explícito en catálogo |
| I8 | Frecuencia | `días ≥ 2 ⇒ ∀ grupo: sesiones(grupo) ≥ 2` **o** aviso `FREQUENCY_BELOW_MIN` | El split elegido incluye cada grupo en ≥ 2 sesiones |
| I9 | Determinismo | `generatePlan(x) ≡ generatePlan(x)` (igualdad profunda) y no depende del orden del catálogo | Sin `Math.random`, sin `Date.now` en la lógica; el corte por tiempo de la búsqueda local solo actúa como red de seguridad y se avisa |
| I10 | Prescripción válida | `1 ≤ series ≤ 10`, `1 ≤ repMin ≤ repMax ≤ 50`, `0 ≤ RIR ≤ 5`, `descanso ≥ 60 s`, sin RIR 0 en multiarticulares | Rangos del modelo de datos |
| I11 | Sin duplicados | Un ejercicio aparece como mucho una vez por sesión | — |
| I12 | Progresión acotada | `nextPrescription` nunca sube la carga más del incremento configurado ni la baja por debajo de 0; en deload nunca deja 0 series | — |
| I13 | Sustitutos válidos | Todo sustituto cumple I1–I3 para el perfil y comparte grupo de sustitución o patrón | — |
| I14 | Nutrición sin valores inventados | Entrada incompleta o inválida ⇒ `ok: false`; con `ok: true`, `kcal ≥ REE` y macros que suman las kcal (±1 %) | Mifflin-St Jeor solo para sexo `male`/`female` |

Verificación formal (TLA+, etc.) no compensa aquí: el espacio de estados es finito pero enorme (perfil × catálogo); los tests de propiedades con fast-check (200 casos por propiedad) más casos fijos dan la confianza adecuada para una función pura.

## 2. Casos límite enumerados (tests fijos)

| Caso | Comportamiento esperado | Prioridad |
|---|---|---|
| 2 días, 30 min, solo peso corporal | Plan full body válido; avisos explícitos de huecos de patrón (tirón) y de volumen bajo el suelo | P0 |
| 6 días, 90 min, gimnasio completo, avanzado | PPL ×2; todos los grupos ≥ suelo; < 200 ms | P0 |
| Lesión de hombro | Ningún ejercicio con `shoulder: avoid` (press tras nuca, fondos, remo al mentón…); empuje vertical cubierto por variantes `caution` o aviso | P0 |
| Lesión de rodilla | Ningún `knee: avoid` (sissy squat…); se explica la penalización de `caution` | P0 |
| Principiante sin historial | Cargas `isEstimate: true`, RIR ≥ 2, reps 8–12 | P0 |
| Avanzado con historial largo | Cargas desde e1RM (Epley con reps + RIR ≤ 10); peso muerto marcado como estimación | P1 |
| Material que no cubre un patrón | Aviso `PATTERN_UNCOVERED` con el patrón y el material que lo cubriría | P0 |
| Todos los ejercicios de un patrón vetados | Igual que el anterior: aviso, no hueco silencioso | P1 |
| Perfil inválido (días = 7, minutos = 20, material desconocido) | `ok: false` con `INVALID_PROFILE`, sin valores por defecto | P0 |
| Catálogo vacío o con slugs duplicados | `ok: false` (`NO_EXERCISES` / `INVALID_CATALOG`) | P1 |
| Músculo prioritario sin ejercicios disponibles | Aviso `PRIORITY_UNCOVERED` | P1 |
| Favorito que viola una limitación | La restricción dura gana; se explica en el rationale | P1 |
| Catálogo en otro orden | Mismo plan (I9) | P0 |
| Progresión: techo de reps con RIR ≥ objetivo | Sube carga (2,5 % superior / 5 % inferior, mínimo 1 kg) — CUJ-3 | P0 |
| Progresión: reps o RIR caen 2 sesiones seguidas | Deload reactivo — CUJ-3 | P0 |
| ≥ 14 días sin entrenar | Primera sesión baja la carga y lo explica — CUJ-5 | P0 |
| Sesiones saltadas | Se continúa por la siguiente sesión pendiente — CUJ-5 | P1 |
| Fechas del historial desordenadas o en el futuro | Se ordenan; fechas posteriores a `today` se ignoran | P2 |
| Ejercicio de peso corporal en el techo de reps | Propone variante más difícil (sin carga inventada) | P1 |
| Nutrición: sexo `other`, peso ausente, edad < 18 | `ok: false` con el campo que falta; nunca 70 kg ni 2000 kcal | P0 |
| Nutrición: déficit que bajaría de REE | Se fija en REE y se avisa | P0 |

Concurrencia, permisos y zonas horarias no aplican al motor (función pura); pertenecen a la API (Fase 3). La fecha `today` y las fechas del historial llegan ya normalizadas (ISO `YYYY-MM-DD`).

## 3. Modos de fallo de `generatePlan`

| Componente | Fallo | Severidad | Mitigación | Señal |
|---|---|---|---|---|
| Validación | Perfil incompleto → se rellenan valores por defecto | Crítica | Zod estricto; `ok: false`; test de entradas inválidas | `error.code` |
| Filtro | `.some` en material (bug del motor viejo) | Crítica | `.every` + I1 en propiedades | Test I1 |
| Filtro | Catálogo con tags de riesgo incompletos | Alta | Tags revisados por PR; tests de catálogo (ejemplos concretos: press tras nuca → hombro, buenos días → lumbar) | Test del catálogo |
| Split | Grupo entrenado 1 vez/semana | Media | Plantillas que incluyen cada grupo ≥ 2 veces; I8 | Aviso `FREQUENCY_BELOW_MIN` |
| Volumen | Suelo inalcanzable en el tiempo dado | Media | Aviso por grupo con el déficit; nunca silencioso | `VOLUME_BELOW_FLOOR` |
| Solución inicial | Patrón sin candidatos | Alta | Alternativas de patrón por hueco y aviso `PATTERN_UNCOVERED` | Aviso |
| Búsqueda local | No termina o tarda | Media | Máximo de iteraciones y evaluaciones; corte por tiempo como red de seguridad con aviso `LOCAL_SEARCH_TIME_LIMIT` | `meta.localSearch` |
| Búsqueda local | Empeora restricciones duras | Alta | Solo se aceptan vecinos que mantienen I1–I7; los movimientos solo usan candidatos filtrados | Tests de propiedades |
| Búsqueda local | Erosiona suelos o la calidad de los ejercicios para ganar balance o variedad | Alta | No acepta movimientos que dejen un grupo bajo su suelo o con < 2 sesiones, ni intercambios a un ejercicio de menor calidad estática (§16.8) | Revisión de ejemplos; I4, I8 |
| Scoring | Pesos que premian sesiones cortas | Media | `timeFit` penaliza pasarse y quedarse corto | Test de scoring |
| Determinismo | Desempate por UUID o `localeCompare` dependiente del locale | Alta | Desempate por `slug` con comparación por código (`<`) | I9 |
| Explicaciones | Texto genérico | Baja | Plantillas con datos del usuario (días, minutos, objetivo, e1RM) | Revisión en `ejemplos/REVISION.md` |

Cascada: un fallo del filtro (I1/I2) contamina todo lo posterior; por eso las restricciones duras se aplican una sola vez, antes, y la búsqueda local trabaja solo sobre el catálogo filtrado. Reversión: `ENGINE_VERSION` se guarda en cada versión de plan; volver a la versión anterior del paquete regenera planes idénticos (I9).
