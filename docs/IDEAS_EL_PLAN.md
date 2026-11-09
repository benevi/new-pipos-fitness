# Ideas recuperadas de una app previa

**Fecha:** 2026-11-09 · **Decisión:** [ADR-0013](adr/0013-ideas-recuperadas.md) · **Estado:** ideas 1, 2, 3, 4, 6 y 7 implementadas en motor, contratos y API; idea 5 aplazada; app móvil pendiente.

Versión condensada y anonimizada del análisis de una app de entrenamiento previa (una sola página web, sin generador de planes, centrada en el registro y el seguimiento). Su código se leyó como datos y no se ejecutó. Este documento no contiene datos de ninguna persona.

Principios con los que se evaluó: utilidad real (solo lo que mejora el plan, la ejecución o el progreso), «nada falso», evidencia, art. 9 del RGPD, sin coach de IA (ADR-0003), sin panel de administración (ADR-0005) y nutrición limitada a objetivos diarios (ADR-0004).

Clasificación: **ADOPT** (tal cual), **ADAPT** (la idea sí, la implementación no), **LATER** (útil, no ahora), **REJECT**.

---

## 1. Evaluación (resumen de la sección 3 del análisis)

| Función de la app previa | Clasificación | Motivo |
|---|---|---|
| Rutinas y ejercicios propios | REJECT | Se saltaría los invariantes del motor (material, limitaciones, volumen, tiempo). Lo que se quiere de verdad lo cubre la idea 3. |
| Plan semanal por días | ADAPT (idea 6) | El motor sigue el orden del microciclo (CUJ-5); los días sirven para el recordatorio local y para «hoy toca». |
| Modo vacaciones | ADAPT (idea 6) | Sin rachas no hay nada que congelar, pero la pausa debe excluirse de la adherencia («nada falso»). |
| Racha, XP, niveles, logros, avatar | REJECT | No mejoran el plan; la racha castiga el descanso. La adherencia es la medida honesta. |
| Pareja, retos, liga, duelos | REJECT | Fuera de alcance; además compartía datos de salud de terceros. |
| Sincronización por código o QR, copia JSON | REJECT (ya existe) | Hay sincronización con servidor (ADR-0007) y `GET /me/export`. |
| Exportar a CSV | LATER | Útil para usuarios avanzados; no mejora el plan. |
| Niveles de tiempo | ADAPT (idea 4) | Recortar ejercicios enteros del final, sí; con cortes fijos (66 %, 50 %) y minutos inventados, no. |
| Energía de la sesión (×0,6-1,15) | ADAPT (idea 4, solo hacia abajo) | Subir series con «energía alta» no tiene evidencia y puede pasar el techo de volumen. |
| Correlaciones de energía, hora o dolor | REJECT | Pocos datos presentados como causa. |
| Calentamiento y vuelta a la calma | LATER | El estiramiento posterior no reduce las agujetas (Cochrane, Herbert 2011); no se vende como recuperación. |
| Cambio de ejercicio | REJECT (ya existe) | El nuestro calcula 3 alternativas por patrón, músculos, material y limitaciones (CUJ-4). |
| Cambio permanente | ADAPT (idea 3) | Debe vivir en el plan y heredarse, sin copiar la prescripción (rompía la progresión). |
| RPE por serie, descanso automático, precarga | REJECT (ya existe) | RIR, temporizador del motor y precarga ya existen. |
| Descanso según el RPE | REJECT | Sin fuente. |
| Aviso en los últimos 5 s y pantalla encendida | ADOPT (mejora rápida, app) | Mejora la ejecución sin riesgo. |
| Ejercicios por tiempo | LATER | Requiere catálogo y registro por segundos. |
| Intervalos (Tabata, EMOM) y metrónomo | REJECT | Fuera de v1; el tempo de repetición entre 0,5 y 8 s da hipertrofia similar (Schoenfeld 2015). |
| Nota fija por ejercicio | ADOPT (idea 2) | Ajustes de máquina, agarre o asiento: ayuda en cada sesión. |
| Nota de sesión y nota en vivo | LATER | Menos valor; el texto libre puede contener datos de salud. |
| Dictado por voz | REJECT | Envía audio a un tercero. |
| Valoración final fácil/justo/difícil | REJECT (ya existe) | El RIR por serie es más preciso. |
| Sugerencias de progresión propias | REJECT | Reglas sin fuente y peores que las del motor. |
| Calculadora de discos | ADAPT (idea 1) | Junto al redondeo de la carga al material. |
| Calculadora de 1RM | REJECT (ya existe) | e1RM calculado al escribir. |
| Guía deducida del nombre, búsqueda en vídeo | REJECT | Heurística frágil y contenido no revisado; hay `cuesEs` revisados. |
| Registro de dolor y tendencia | ADAPT (idea 5, aplazada) | Mucho valor para entrenar sin agravar una molestia (historia 4), pero es una finalidad nueva del art. 9. |
| Lesiones con gravedad | ADAPT (en la idea 5) | Se toma «sugerir quitar la limitación»; la gravedad no la usa el motor (minimización). |
| Consejos clínicos y predicciones | REJECT | Fuera de alcance; causalidad espuria. |
| Recuperación por músculo a 24/48 h | REJECT | Falsa precisión. |
| Peso corporal y medidas | ADAPT (idea 7) | Decisión de producto: tendencia de peso frente a §11.5 y perímetros de seguimiento, con consentimiento. |
| IMC y % de grasa (Marina) | ADAPT (idea 7) | Decisión de producto: como estimación, con sus límites y sin etiquetas de grasa; IMC con las categorías de la OMS. |
| Ratio cintura/altura con etiquetas clínicas | REJECT | El corte usado no tenía fuente; etiquetas clínicas sin diagnóstico. |
| Fotos de progreso | REJECT | Muy sensibles y sin uso en el plan. |
| Coach IA, nutrición completa, varios perfiles en un móvil | REJECT | ADR-0003, ADR-0004 y consentimiento individual. |

---

## 2. Diseño de las ideas (resumen de la sección 4, con lo implementado)

### Idea 1. Carga real según el material y discos · ADAPT · M · implementada
- **Problema:** redondear a 1 kg proponía pesos inexistentes (23 kg en mancuernas de 2 en 2; 47 kg en una máquina de 5 en 5).
- **Motor:** `PROGRAMMING.load` (paso por material en kg totales: barra, trap bar, EZ, multipower y polea 2,5; mancuernas 2; kettlebell 4; máquina 5; barras de 20/25/10 kg; discos 25-1,25). `loadImplement` deduce el material de `equipment` con prioridad fija. `roundLoad` y `plateBreakdown` (voraz por lado, con `remainderKg`). Carga inicial y aproximaciones hacia abajo; subida hacia arriba al siguiente peso; bajadas hacia abajo sin llegar a 0; aviso si el salto supera el 10 %. PROGRAMACION §16.16.
- **API:** `TodayExercise.loadImplement`, `loadStepKg` y `plates` (solo barras). `PlanExerciseResponse.loadImplement`.
- **Desviación:** el material no es un campo del catálogo sino una deducción (un test exige que todo ejercicio con peso lo tenga).
- **Tests:** propiedad «toda carga propuesta es múltiplo del paso»; los discos reconstruyen el total; mancuernas 8 → 10 kg con aviso.

### Idea 2. Nota fija por ejercicio · ADOPT · S · implementada
- `UserExerciseNote` (usuario × ejercicio, ≤ 280, última escritura gana por `clientUpdatedAt`).
- `PUT/DELETE /exercises/:id/note`, `GET /me/exercise-notes`, `TodayExercise.note`. Se mantiene al sustituir y entre versiones.
- RGPD: texto libre que podría contener datos de salud → exportación, borrado y nunca en logs; riesgo residual en la DPIA.

### Idea 3. Cambio de ejercicio permanente · ADAPT · M · implementada
- `PlanExerciseOverride` aparte de la versión (inmutable). `PUT/DELETE /plans/current/exercises/:planExerciseId/override` valida con las alternativas del motor y aplica a todos los huecos del mismo ejercicio; no crea versión.
- Al generar una versión nueva, el motor (`resolvePins`) mantiene los cambios que siguen siendo válidos (material, limitaciones, vetados, nivel, misma familia o patrón) y descarta el resto con el aviso `PINNED_SUBSTITUTION_DROPPED`. El plan elegido por el motor no cambia.
- `today`: cambio puntual > cambio fijado > plan (`TodayExercise.pinned`); las series aceptan el ejercicio fijado; hoy se puede volver puntualmente al original.

### Idea 4. Ajuste de hoy: poco tiempo o volumen reducido · ADAPT · M · implementada
- `adjustSession`: con poco tiempo, quitar ejercicios enteros (core → accesorio → secundario, del último al primero; nunca el principal) hasta caber; si no cabe, bajar series a los principales (mínimo 2) y avisar. Volumen reducido: una serie menos, RIR + 1 y sin subir carga. PROGRAMACION §16.17.
- `GET /sessions/today?minutes=15-90&mode=normal|reduced` (solo lectura) y `POST /workouts { adjustment }` (se guarda y se aplica mientras dure el entreno).
- Progresión: las sesiones ajustadas no cuentan para la descarga reactiva ni para la bajada por rendimiento.
- No se pregunta por energía ni sueño: no hay evidencia de que ajustar por una escala de energía mejore los resultados.

### Idea 5. Monitor de dolor por zona y ejercicio · ADAPT · L · **aplazada**
- Finalidad nueva del art. 9: requiere texto de consentimiento nuevo, DPIA y revisión legal (ADR-0013).
- Diseño: `PainReport` (zona, ejercicio opcional, intensidad 0-10 y «punzante» durante el ejercicio, o «peor al día siguiente»), sin texto libre ni gravedad. Reglas antes de la progresión: ≤ 2 normal; 3-5 o peor al día siguiente → mantener; peor dos veces → −5 %; > 5 o punzante → parar ese ejercicio hoy, alternativas que eviten la zona y derivación (§12); > 5 dos sesiones → proponer la limitación; ≤ 2 durante ≥ 4 semanas → sugerir quitarla. Fuente: Silbernagel et al. 2007 (Am J Sports Med 35(6):897-906), umbrales más prudentes marcados como heurística.

### Idea 6. Días de entreno, recordatorio local y pausas · ADAPT · M · implementada
- `TrainingProfile.trainingWeekdays` (ISO 1-7, ≤ días por semana) por `PATCH /me/profile/schedule` (no crea versión). El recordatorio es local en el móvil: no hay push del servidor.
- `TrainingBreak` (1-60 días, sin motivo) por `GET/POST/DELETE /me/breaks`; recalcula la adherencia de las semanas afectadas en la misma transacción.
- Adherencia: las sesiones previstas descuentan los días en pausa (`breakDays`). Progresión: los días en pausa no cuentan como ausencia para la bajada de §16.9 (decisión de producto; confianza baja). PROGRAMACION §16.18.
- `today`: `scheduledToday` y `activeBreak`.

### Idea 7. Medidas corporales · ADAPT · M · implementada (decisión de producto)
- `BodyMeasurement` por día: peso y perímetros (cintura, cuello, cadera, pecho, brazo, muslo) con puntos de medida descritos en el contrato.
- Consentimiento por ámbitos: la versión `health-2026-11-v2` cubre perímetros y estimaciones; la anterior sigue cubriendo peso, altura y limitaciones.
- `GET /progress/body`: tendencia de peso (media móvil de 7 días y ritmo frente a §11.5), IMC con categorías de adultos de la OMS y % de grasa estimado (Hodgdon y Beckett 1984), con sus límites y «no es un diagnóstico». Pecho, brazo y muslo solo muestran evolución. PROGRAMACION §16.19.
- El peso más reciente actualiza el del perfil (objetivos nutricionales). Retirar el consentimiento borra el registro.

---

## 3. Lo que no se adopta (resumen de la sección 5)
- **Fuera de alcance:** pareja, retos, liga; resúmenes para compartir; intervalos; coach IA; nutrición más allá de los objetivos; consejos clínicos.
- **Ya existe y es mejor:** sustitución calculada, precarga, RIR, progresión, e1RM, volumen por series efectivas, exportación, onboarding con consentimiento, limitaciones con etiquetas de riesgo.
- **Sin evidencia o falso:** descanso por RPE; +15 % de series por energía; recuperación a 24/48 h; correlaciones con pocos datos; metrónomo como tempo; etiquetas fijas de minutos; categorías de % de grasa y de ratio cintura/altura como diagnóstico.
- **Privacidad sin uso en el plan:** fotos, dictado por voz, varios perfiles en un móvil.
- **LATER:** ejercicios por tiempo, CSV, modo foco, mapa de calor, calentamiento por tipo de sesión, zona cervical, medios de técnica curados, pasos de carga propios (microdiscos).
- **Mejora rápida de la app (fuera del cupo):** pantalla encendida durante el entreno y vibración en los últimos 5 s del descanso.
