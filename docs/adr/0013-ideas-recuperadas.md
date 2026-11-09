# ADR-0013: Ideas recuperadas de una app previa (carga real, notas, cambios fijados, ajuste de hoy, días y pausas, medidas corporales)

**Estado**: Aceptado; implementado en motor, contratos y API (ideas 1, 2, 3, 4, 6 y 7). Idea 5 aplazada. App móvil pendiente · **Fecha**: 2026-11-09

## Contexto
Se analizó, como datos y sin ejecutarla, una app de entrenamiento previa sin generador de planes, centrada en el registro y el seguimiento. El análisis completo, anonimizado, está en [`docs/IDEAS_EL_PLAN.md`](../IDEAS_EL_PLAN.md). De más de 50 funciones, solo unas pocas mejoran de verdad el plan, la ejecución o el progreso sin romper los principios del producto: utilidad real, «nada falso», evidencia, art. 9 del RGPD, sin coach de IA (ADR-0003), sin panel de administración (ADR-0005) y nutrición limitada a objetivos diarios (ADR-0004).

## Decisión

### Aceptadas e implementadas
| # | Idea | Qué se hace | Dónde |
|---|---|---|---|
| 1 | Carga real según el material y discos | El motor solo propone pesos que existen: paso por material (barra 2,5 kg, mancuernas 2 kg, máquina 5 kg…), redondeo hacia abajo en cargas iniciales y bajadas, hacia arriba en subidas, aviso de salto > 10 % y desglose de discos por lado. Cierra la deuda «Redondear la carga a los incrementos reales del material» (issue #12). | PROGRAMACION §16.16; `training/load.ts`; `TodayExercise.loadImplement/loadStepKg/plates` |
| 2 | Nota fija por ejercicio | Texto libre del usuario por ejercicio (≤ 280), última escritura gana, se ve en la sesión de hoy. | `UserExerciseNote`; `PUT/DELETE /exercises/:id/note`, `GET /me/exercise-notes` |
| 3 | Cambio de ejercicio permanente | «Usar siempre en este plan»: el cambio vive aparte de la versión (inmutable), se aplica a todos los huecos del mismo ejercicio y se hereda al generar versiones nuevas si sigue siendo válido; si no, se descarta con aviso. | `PlanExerciseOverride`; `training/pins.ts`; `PUT/DELETE /plans/current/exercises/:id/override` |
| 4 | Ajuste de hoy | Poco tiempo: se quitan ejercicios enteros de menor prioridad (nunca el principal). Volumen reducido voluntario: una serie menos, RIR + 1, sin subir carga. Nunca aumenta el volumen ni crea una versión del plan. Las sesiones ajustadas no disparan descargas ni bajadas. | PROGRAMACION §16.17; `training/adjust.ts`; `GET /sessions/today?minutes=&mode=`, `POST /workouts {adjustment}` |
| 6 | Días de entreno y pausas planificadas | Días preferidos (≤ días por semana) para el recordatorio **local** del móvil y para «hoy toca». Pausas (1-60 días, sin motivo) que descuentan sus días de la adherencia y de la ausencia que baja la carga. | PROGRAMACION §16.18; `training/schedule.ts`; `PATCH /me/profile/schedule`, `/me/breaks` |
| 7 | Medidas corporales | Registro diario de peso y perímetros (cintura, cuello, cadera, pecho, brazo, muslo); tendencia de peso frente al ritmo de §11.5; **IMC con las categorías de adultos de la OMS** y **% de grasa estimado por el método de la Marina** (decisión de producto), siempre como estimación, con sus límites y «no es un diagnóstico». Pecho, brazo y muslo son solo de seguimiento: ninguna regla los usa ni tienen umbrales. | PROGRAMACION §16.19; `body/index.ts`; `BodyMeasurement`; `/me/measurements`, `GET /progress/body` |

**Datos de salud (idea 7).** Las medidas son datos del art. 9. El consentimiento de salud pasa a versionarse por **ámbitos** (`weight`, `height`, `limitations`, `body_measurements`, `derived_estimates`): la nueva versión del texto (`health-2026-11-v2`) nombra los perímetros y las estimaciones derivadas; quien consintió la versión anterior conserva sus ámbitos (peso, altura, limitaciones) y debe volver a consentir para registrar perímetros o ver IMC y % de grasa. Retirar el consentimiento borra el registro entero. Todo se exporta y se borra con la cuenta; nada va a los logs.

**Notas (idea 2).** El fin no es tratar salud, así que no se pide consentimiento del art. 9. Pero es texto libre y el usuario podría escribir una molestia: se exporta, se borra con la cuenta, nunca se registra en logs y se anota como riesgo residual en la DPIA (docs/SECURITY.md).

### Aplazada: idea 5, monitor de dolor por zona y ejercicio
Es la de más valor para entrenar «sin agravar una molestia» (historia de usuario 4) y conecta con §12 (`DOLOR_UMBRAL_RETIRAR`), hoy sin forma de registrar dolor. **No se implementa ahora** porque añade una **finalidad nueva de tratamiento de datos de salud** (registrar y evaluar dolor), que exige:
- una versión nueva del texto del consentimiento que la nombre (con su `textHash`);
- actualizar la DPIA (pendiente, ADR-0011);
- revisión legal del texto de derivación a un profesional;
- revisión de los umbrales por un profesional sanitario.

Diseño resumido para retomarla (detalle en `docs/IDEAS_EL_PLAN.md`):
- `PainReport` (zona, ejercicio opcional, fase «durante» con intensidad 0-10 y «punzante», o fase «al día siguiente» con «peor sí/no»), idempotente por `clientId`, sin texto libre ni gravedad.
- Reglas puras antes de la progresión: ≤ 2 → normal; 3-5 o peor al día siguiente → mantener; peor al día siguiente dos veces → bajar un 5 %; > 5 o punzante → parar ese ejercicio hoy y ofrecer alternativas que eviten la zona, con texto de derivación; > 5 dos sesiones → proponer (no imponer) la limitación; ≤ 2 durante ≥ 4 semanas con ≥ 3 registros → sugerir quitar la limitación.
- Fuente: modelo de monitorización del dolor de Silbernagel et al. 2007 (tendinopatía aquílea), con umbrales más prudentes y marcados como heurística (confianza baja fuera de ese contexto).
- `403 HEALTH_CONSENT_REQUIRED` sin consentimiento; exportar y borrar; retirada del consentimiento borra los registros.

### Rechazadas (resumen; motivos en `docs/IDEAS_EL_PLAN.md` §3 y §5)
- **Rutinas manuales:** saltarían los invariantes del motor; el caso real lo cubre la idea 3.
- **Gamificación (rachas, XP, logros):** la racha castiga el descanso; la adherencia es la medida honesta.
- **Social (pareja, retos, liga):** fuera de alcance y comparte datos de salud de terceros.
- **Subir series con «energía alta» y descanso según el RPE:** sin evidencia; puede superar el techo de volumen.
- **Correlaciones con pocos datos (energía, hora, dolor), «recuperación» por músculo a 24/48 h, predicciones:** causalidad espuria o falsa precisión («nada falso»).
- **Categorías de % de grasa (rangos tipo ACE) y ratio cintura/altura con etiquetas clínicas:** sin una fuente con la solidez de la OMS para el IMC; se muestra el valor estimado sin categoría.
- **Fotos de progreso, dictado por voz, varios perfiles en un móvil, coach IA, sincronización por código o QR:** riesgo de privacidad sin uso en el plan, o ya cubierto mejor.
- **LATER:** ejercicios por tiempo, exportar CSV, modo foco, mapa de calor, calentamiento general por tipo de sesión, zona cervical, medios de técnica curados, pasos de carga propios (microdiscos).

## Consecuencias
- **Más fácil:** cargas que existen, sesiones que caben en el día sin saltárselas, adherencia sin 0 % falsos en vacaciones, seguimiento corporal con los límites explicados.
- **Más difícil:** el consentimiento de salud deja de ser «sí/no» y pasa a tener ámbitos por versión; la sesión de hoy tiene más campos (todos con valor por defecto en los contratos para no romper clientes anteriores).
- Nueva deuda anotada en `docs/DEUDA_TECNICA.md` (series previstas de una sesión ajustada en la adherencia, anclar la descarga tras una pausa, pasos de carga propios, DPIA con medidas y notas).
- La decisión de no contar los días de pausa planificada como ausencia (no baja la carga al volver) es de producto, sin evidencia que la respalde frente a la alternativa (confianza baja, PROGRAMACION §16.18).

## Alternativas
- **Implementar también la idea 5 ahora.** Contra: tratar dolor sin texto de consentimiento, DPIA ni revisión legal incumpliría el art. 9 y ADR-0011. Rechazada por ahora.
- **Paso de carga como campo del catálogo (`loadImplement`).** Contra: duplica lo que ya dice `equipment`; se deduce con una prioridad fija y un test exige que todo ejercicio con peso tenga material de carga. Se puede pasar a campo explícito si aparece una excepción.
- **Guardar el cambio fijado dentro de la versión del plan.** Contra: las versiones son inmutables y la progresión debe seguir al ejercicio realmente hecho. Rechazada.
- **No incluir IMC ni % de grasa.** Era la propuesta inicial por minimización; el responsable de producto decidió incluirlos con sus límites explícitos y sin categorías de grasa.
