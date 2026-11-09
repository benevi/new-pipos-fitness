# PROGRAMACION.md — Base de evidencia para el generador determinista de planes (Pipos Fitness)

Fecha de la investigación: 2026-11-08. Idioma: español.

## 0. Cómo leer este documento

- Cada sección da una **regla** para el motor y una **tabla de constantes configurables** con estas columnas: `nombre`, `valor/rango`, `unidad`, `aplica a`, `fuente`, `confianza`.
- **Confianza**:
  - **alta**: meta-análisis o position stand revisado por pares, con la cifra confirmada en abstract o registro bibliográfico.
  - **media**: un estudio aislado, una revisión narrativa, o una cifra que solo pude confirmar en resúmenes secundarios.
  - **baja**: heurística de práctica o decisión de diseño.
- **"Heurística de práctica"** marca una constante sin respaldo directo revisado por pares. Se indica su origen.
- **Limitación de método (importante)**: en esta sesión solo pude usar un buscador web. La red bloqueaba la lectura directa de PubMed, PMC, Springer, MDPI, ACSM y SportRxiv. Por eso, las cifras proceden de abstracts indexados, registros de bibliotecas y repositorios, y resúmenes secundarios. No leí los textos completos. Cuando una cifra no se pudo confirmar se dice explícitamente con **[NO VERIFICADO]**. Antes de producción conviene que una persona compruebe las cifras marcadas como "media" contra el PDF original.
- **Novedad relevante**: el ACSM publicó en 2026 un nuevo position stand que **sustituye al de 2009** (Currier et al., 2026, MSSE 58(4):851-872, doi 10.1249/MSS.0000000000003897). Es una revisión de revisiones con 137 revisiones sistemáticas y más de 30.000 participantes. Se usa como fuente principal donde aplica, y ACSM 2009 queda como referencia histórica.

---

## 1. Volumen semanal de series por grupo muscular

### Evidencia

- **Schoenfeld, Ogborn & Krieger (2017)**, J Sports Sci 35(11):1073-1082, doi 10.1080/02640414.2016.1210197 (online en 2016).
  - Diseño: 15 estudios y 34 grupos de tratamiento.
  - Resultado: dosis-respuesta graduada, con más volumen asociado a más hipertrofia.
  - Por categorías: <5 series/semana dio 5,4 % de ganancia y ≥10 series/semana dio 9,8 %.
  - Limitación: solo se pudo evaluar la dosis-respuesta hasta unas 10 series/semana, por falta de estudios con más volumen.
- **Ralston et al. (2017)**, Sports Med 47(12):2585-2601, doi 10.1007/s40279-017-0762-7.
  - Para fuerza, el volumen medio y el alto superaron al bajo, aunque la diferencia fue pequeña (ES 0,15 entre medio y bajo).
  - Los cortes de categoría (<5, 5-9, ≥10) quedan **[NO VERIFICADOS]**.
- **Baz-Valle et al. (2022)**, J Hum Kinet 81:199-210, doi 10.2478/hukin-2022-0017.
  - Población: hombres jóvenes entrenados, con ≥1 año de experiencia. 7 ECA en la revisión y 6 en el meta-análisis.
  - Categorías comparadas: bajo (<12), moderado (12-20) y alto (>20) series/semana.
  - No hubo diferencia entre moderado y alto en cuádriceps ni en bíceps. El volumen alto fue mejor en tríceps.
  - Conclusión de los autores: **12-20 series/semana por grupo muscular** puede ser un estándar óptimo para esta población.
- **Schoenfeld et al. (2019)**, MSSE 51(1):94-103, doi 10.1249/MSS.0000000000001764.
  - Diseño: 34 hombres entrenados con 1, 3 o 5 series por ejercicio y sesión, 3 sesiones/semana durante 8 semanas.
  - Resultado: más hipertrofia con más volumen, pero la fuerza fue similar entre grupos.
- **Pelland, Remmert, Robinson, Hinson & Zourdos**, "The Resistance Training Dose Response: Meta-Regressions Exploring the Effects of Weekly Volume and Frequency on Muscle Hypertrophy and Strength Gain", Sports Med 2026; 56(2):481-505, doi 10.1007/s40279-025-02344-w (online en diciembre de 2025). Lo precedieron preprints en SportRxiv.
  - El volumen tiene dosis-respuesta positiva con la hipertrofia y con la fuerza.
  - En fuerza, los rendimientos decrecientes son **más pronunciados** que en hipertrofia.
  - El tamaño de muestra difiere entre fuentes secundarias: 67 estudios y 2.058 participantes en total, frente a 35 estudios y 220 efectos solo de hipertrofia.
  - **[NO VERIFICADO]**: las estimaciones numéricas exactas, es decir, el umbral sin superioridad detectable en series/semana. Las fuentes secundarias dan cifras dispares, desde unas 12-20 hasta unas 31 series fraccionales/semana según la versión y el modelo. No uses ninguna como techo duro.
- **Remmert et al. (2025, preprint SportRxiv, doi 10.51224/SRXIV.537)**, "Is There Too Much of a Good Thing?". Trata el volumen **por sesión**.
  - El punto sin superioridad detectable estaría en unas **2 series directas por sesión para fuerza** y unas **11 series fraccionales por sesión para hipertrofia**.
  - Es un preprint: **no está revisado por pares** (confianza baja-media).
- **Currier et al. (ACSM 2026)**: los materiales de prensa del ACSM hablan de buscar un volumen semanal alto, de unas 10 series por grupo muscular, para hipertrofia. La cifra procede de la nota de prensa; no la vi en el abstract (confianza media).

### Conteo fraccional de músculos secundarios

- En Pelland et al. (2026), cada serie se clasifica como directa o indirecta:
  - **directa = 1**;
  - **indirecta = 0,5** (método "fraccional").
- Se compararon tres métodos de conteo: directo, fraccional y total. El fraccional tuvo la evidencia relativa más fuerte y por eso se usó en los modelos principales (confirmado en el registro bibliográfico de sponet.de y en resúmenes secundarios).
- Ejemplo: un remo cuenta como 1 serie para dorsal y espalda alta, y 0,5 series para bíceps.
- **Decisión de diseño sin evidencia directa**: qué músculo es "indirecto" en cada ejercicio. Requiere una tabla de mapeo ejercicio→músculo, que es una heurística propia.

### Volumen máximo útil (MEV/MAV/MRV)

Las marcas de volumen de Renaissance Periodization (MEV, MAV, MRV; Israetel, Hoffmann y Smith, libro *Scientific Principles of Hypertrophy Training*, ~2019, año no verificado) son una **heurística de práctica**. No están revisadas por pares ni validadas empíricamente como umbrales individuales, así que **no se usan como constantes**. Como mucho sirven como vocabulario.

### Regla para el motor

1. Calcula el volumen semanal de cada grupo muscular como `Σ series_directas×1 + Σ series_indirectas×0,5`.
2. Mantén ese volumen dentro de `[VOL_MIN_nivel, VOL_MAX_nivel]`.
3. Por sesión, no programes más de `VOL_SESION_MAX` series fraccionales por músculo. El excedente se reparte en otro día.
4. Si el objetivo es salud general o fuerza, se acepta volumen bajo o moderado: en fuerza los rendimientos decrecientes llegan antes.

### Constantes

| nombre | valor/rango | unidad | aplica a | fuente | confianza |
|---|---|---|---|---|---|
| `PESO_SERIE_DIRECTA` | 1,0 | serie | todos | Pelland et al. 2026 | alta |
| `PESO_SERIE_INDIRECTA` | 0,5 | serie | músculo sinergista/secundario | Pelland et al. 2026 (método fraccional) | media-alta (definición confirmada; mapeo ejercicio→músculo propio) |
| `VOL_MIN_PRINCIPIANTE` | 4-6 (por defecto 6) | series fraccionales/sem/músculo | principiante | Schoenfeld 2017 (incluso <5 produce ganancias); WHO/ACSM mínimo 2 días/sem. El valor exacto es una decisión de diseño | media |
| `VOL_MAX_PRINCIPIANTE` | 10-12 | series fraccionales/sem/músculo | principiante | Schoenfeld 2017 (≥10 dio la mayor ganancia en su rango de datos). El techo es una decisión de diseño para limitar la fatiga y el tiempo | baja-media |
| `VOL_MIN_INTERMEDIO` | 10 | series fraccionales/sem/músculo | intermedio | Schoenfeld 2017 (≥10); ACSM 2026 (nota de prensa, ~10) | media |
| `VOL_MAX_INTERMEDIO` | 16-20 | series fraccionales/sem/músculo | intermedio | Baz-Valle 2022 (12-20 en entrenados) | media |
| `VOL_MIN_AVANZADO` | 12 | series fraccionales/sem/músculo | avanzado | Baz-Valle 2022 | media |
| `VOL_MAX_AVANZADO` | 20 (opcional hasta 24 en músculos prioritarios) | series fraccionales/sem/músculo | avanzado | Baz-Valle 2022 (>20 sin beneficio claro salvo en tríceps); Pelland 2026 (rendimientos decrecientes; techo exacto no verificado) | media |
| `VOL_SESION_MAX` | 10-11 | series fraccionales/sesión/músculo | hipertrofia | Remmert et al. 2025 (preprint) | baja-media |
| `VOL_SESION_MAX_FUERZA` | sin límite estricto; el beneficio adicional cae muy pronto (unas 2 series directas) | series/sesión/ejercicio | fuerza | Remmert et al. 2025 (preprint) | baja |

---

## 2. Frecuencia por músculo y selección de split

### Evidencia

- **Schoenfeld, Ogborn & Krieger (2016)**, Sports Med 46(11):1689-1697, doi 10.1007/s40279-016-0543-8.
  - Diseño: 10 estudios.
  - Con frecuencia como variable binaria, entrenar más a menudo dio más hipertrofia: ES 0,49 frente a 0,30 (p = 0,002).
  - Los autores concluyen que entrenar cada músculo **al menos 2 veces/semana** parece superior a 1 vez.
  - Hay comentarios secundarios según los cuales el efecto desaparece cuando el volumen está igualado. Esto **no lo verifiqué** en el texto completo.
- **Grgic, Schoenfeld, Davies et al. (2018)**, "Effect of Resistance Training Frequency on Gains in Muscular Strength", Sports Med 48(5):1207-1220. No obtuve el DOI en la búsqueda; la referencia probable es 10.1007/s40279-018-0872-x **[DOI NO VERIFICADO]**.
  - Hubo efecto de la frecuencia sobre la fuerza: ES 0,74, 0,82, 0,93 y 1,08 para 1, 2, 3 y ≥4 veces/semana.
  - **Con volumen igualado no hubo efecto significativo.**
- **Pelland et al. (2026)**: solo la **fuerza** muestra efectos de la frecuencia identificables de forma consistente. En hipertrofia, con el volumen ajustado, el efecto de la frecuencia es pequeño o incierto.
- **ACSM 2026 (Currier et al.)**: la fuerza mejora con **≥2 sesiones/semana**, y los materiales del ACSM insisten en entrenar todos los grupos musculares principales al menos 2 veces por semana.
- **ACSM 2009**: recomienda 2-3 días/semana para principiantes, 3-4 para intermedios y 4-5 para avanzados.
- **WHO 2020 (Bull et al.)**: actividades de fortalecimiento muscular de intensidad moderada o mayor, para todos los grupos musculares principales, **≥2 días/semana**.

### Qué es evidencia y qué es convención

- **Evidencia**:
  - frecuencia ≥2 veces/semana por músculo, como mínimo de salud y de fuerza;
  - con volumen igualado, la frecuencia importa poco para la hipertrofia; su utilidad principal es **repartir el volumen** para respetar `VOL_SESION_MAX`.
- **Convención (heurística de práctica, sin ECA que compare splits como tales)**: qué split corresponde a cada número de días:
  - 2-3 días: cuerpo completo (full body);
  - 4 días: torso/pierna;
  - 5-6 días: empuje/tirón/pierna (PPL) o híbridos.
- La regla operativa es: **elige el split que alcance la frecuencia ≥2 por músculo y el volumen objetivo sin superar `VOL_SESION_MAX`**.

### Constantes

| nombre | valor/rango | unidad | aplica a | fuente | confianza |
|---|---|---|---|---|---|
| `FREC_MIN_MUSCULO` | 2 | sesiones/sem/músculo | todos | Schoenfeld 2016; WHO 2020; ACSM 2026 | alta |
| `FREC_MAX_MUSCULO` | 3 (4 opcional en avanzados) | sesiones/sem/músculo | todos | Grgic 2018 (sin beneficio claro con volumen igualado). El valor es una decisión de diseño | baja-media |
| `DIAS_PRINCIPIANTE` | 2-3 | días/sem | principiante | ACSM 2009 | alta |
| `DIAS_INTERMEDIO` | 3-4 | días/sem | intermedio | ACSM 2009 | alta |
| `DIAS_AVANZADO` | 4-5 (hasta 6) | días/sem | avanzado | ACSM 2009 (4-5); 6 es convención | media |
| `SPLIT_2_3_DIAS` | full body | — | 2-3 días | convención (heurística de práctica) | baja |
| `SPLIT_4_DIAS` | torso/pierna ×2 | — | 4 días | convención | baja |
| `SPLIT_5_6_DIAS` | PPL o híbrido (p. ej., torso/pierna + PPL) | — | 5-6 días | convención | baja |

---

## 3. Rangos de repeticiones y carga por objetivo

### Evidencia

- **Schoenfeld, Grgic, Ogborn & Krieger (2017)**, JSCR 31(12):3508-3523, doi 10.1519/JSC.0000000000002200.
  - Diseño: 21 estudios en los que todas las series se llevaban al fallo.
  - La **hipertrofia fue similar** con cargas bajas y altas.
  - La **fuerza máxima (1RM) mejoró más con cargas altas**. En fuerza isométrica no hubo diferencia.
  - El umbral de "carga baja" (≤60 % 1RM) procede de mi memoria del abstract **[NO VERIFICADO]**.
- **Schoenfeld, Grgic, Van Every & Plotkin (2021)**, Sports 9(2):32, doi 10.3390/sports9020032.
  - Cuestionan el "continuo de repeticiones" clásico (fuerza con cargas altas, hipertrofia con moderadas, resistencia con ligeras).
  - Proponen que las adaptaciones se pueden obtener, y a veces optimizar, en un **amplio espectro de cargas**.
  - Las cifras concretas (p. ej., ">30 % 1RM" para hipertrofia) solo aparecen en resúmenes secundarios **[NO VERIFICADO]**.
- **ACSM 2026 (Currier et al.)**: la fuerza mejora con **cargas ≥80 % 1RM**, **2-3 series**, rango completo de movimiento, ejercicios al inicio de la sesión y ≥2 sesiones/semana.
- **ACSM 2009**:
  - principiantes: 8-12 RM;
  - intermedios y avanzados: 1-12 RM periodizado, con énfasis final en cargas pesadas (1-6 RM) y ≥3 min de descanso;
  - cerca del 70-100 % 1RM con la mayor parte del trabajo en 6-12 RM.
  - Las cifras para resistencia muscular (40-60 % 1RM, >15 reps, <90 s de descanso) son de memoria **[NO VERIFICADO textualmente]**.

### Regla para el motor

| Objetivo | Rango de reps | Carga orientativa | Comentario |
|---|---|---|---|
| Fuerza | 3-6 en compuestos principales (+ trabajo accesorio 6-12) | ≥80 % 1RM | ACSM 2026, Schoenfeld 2017 |
| Hipertrofia | 6-15 (por defecto 8-12), aceptable 5-30 si se trabaja cerca del fallo | ~30-85 % 1RM | Schoenfeld 2017/2021. El rango por defecto es convención práctica por eficiencia de tiempo |
| Resistencia muscular | 15-25+ | cargas ligeras | Schoenfeld 2021 (cifras no verificadas) |
| Salud general | 8-12 (principiantes), 1-3 series por ejercicio | moderada | ACSM 2009 (8-12 RM); WHO 2020 (intensidad moderada o mayor) |

### Constantes

| nombre | valor/rango | unidad | aplica a | fuente | confianza |
|---|---|---|---|---|---|
| `REPS_FUERZA` | 3-6 | reps | compuestos, objetivo fuerza | ACSM 2009 (1-6 RM avanzados); ACSM 2026 (≥80 %) | alta |
| `CARGA_FUERZA_MIN` | 80 | %1RM | objetivo fuerza | ACSM 2026 | alta |
| `SERIES_EJERCICIO_FUERZA` | 2-3 | series/ejercicio | objetivo fuerza | ACSM 2026 | alta |
| `REPS_HIPERTROFIA_DEF` | 8-12 | reps | objetivo hipertrofia | convención; respaldada por la equivalencia de cargas (Schoenfeld 2017) | media |
| `REPS_HIPERTROFIA_RANGO` | 5-30 | reps | aislamiento/máquinas | Schoenfeld 2017, 2021 (hipertrofia similar en un amplio rango si hay proximidad al fallo) | media-alta |
| `REPS_RESISTENCIA` | 15-25 | reps | objetivo resistencia | Schoenfeld 2021; ACSM 2009 (>15, no verificado) | media |
| `REPS_SALUD` | 8-12 | reps | salud general / principiante | ACSM 2009 (8-12 RM principiantes) | alta |

---

## 4. Proximidad al fallo y RIR

### Evidencia

- **Zourdos et al. (2016)**, JSCR 30(1):267-275, doi 10.1519/JSC.0000000000001049.
  - Escala RPE basada en RIR: RPE 10 = 0 RIR, RPE 9 = 1 RIR, y así sucesivamente.
  - Los novatos calibran peor: en el 1RM puntuaron un RPE más bajo que los experimentados.
- **Helms, Cronin, Storey & Zourdos (2016)**, Strength Cond J 38(4):42-49, doi 10.1519/SSC.0000000000000218. Explica cómo aplicar la escala RIR-RPE en la programación.
- **Refalo et al. (2023)**, Sports Med 53(3):649-665, doi 10.1007/s40279-022-01784-y.
  - Diseño: 15 estudios.
  - El fallo momentáneo frente al no fallo **no difirió** en hipertrofia.
  - Con otras definiciones de fallo hubo una ventaja trivial: ES 0,19 (IC 0,00-0,37).
  - Los autores proponen una relación no lineal entre proximidad al fallo e hipertrofia.
- **Refalo et al. (2024)**, J Sports Sci 42(1):85-101, doi 10.1080/02640414.2024.2321021.
  - Entrenados, 8 semanas, diseño intra-sujeto por pierna.
  - Fallo frente a 1-2 RIR dio **hipertrofia de cuádriceps similar**.
  - El fallo provocó más fatiga neuromuscular aguda.
- **Robinson et al. (2024)**, Sports Med 54(9):2209-2231, doi 10.1007/s40279-024-02069-2.
  - La **fuerza** fue similar en un amplio rango de RIR.
  - La **hipertrofia mejora** a medida que las series terminan más cerca del fallo.
  - El RIR de cada estudio fue *estimado*, y los autores piden cautela porque el análisis es exploratorio.
- **ACSM 2026**: entrenar hasta la fatiga muscular momentánea no tuvo un impacto consistente en los resultados del adulto sano medio.

### Regla para el motor

1. **Hipertrofia**: usa 0-3 RIR. Por defecto, 1-2 RIR en compuestos y 0-1 RIR en aislamiento o máquinas, donde el fallo es más seguro.
2. **Fuerza**: usa 1-3 RIR. Nunca programes fallo en compuestos pesados con barra libre.
3. **Salud general y principiantes**: usa 2-4 RIR. Los principiantes calibran mal el RIR (Zourdos 2016), así que conviene empezar más conservador y reducirlo a medida que ganan experiencia.
4. **Fallo (0 RIR)**: solo en la última serie de ejercicios de aislamiento o máquina.
5. Las cifras exactas por tipo de ejercicio son una **decisión de diseño** apoyada en la evidencia anterior, no extraídas de un estudio concreto.

### Constantes

| nombre | valor/rango | unidad | aplica a | fuente | confianza |
|---|---|---|---|---|---|
| `RIR_HIPERTROFIA_COMPUESTO` | 1-2 | RIR | compuestos, hipertrofia | Refalo 2024; Robinson 2024 | media-alta |
| `RIR_HIPERTROFIA_AISLAMIENTO` | 0-1 | RIR | aislamiento/máquina | Robinson 2024 (más cerca del fallo implica más hipertrofia) | media |
| `RIR_FUERZA` | 1-3 | RIR | fuerza | Robinson 2024 (fuerza similar en un amplio rango de RIR) | media-alta |
| `RIR_PRINCIPIANTE` | 2-4 | RIR | principiantes / salud | Zourdos 2016 (calibración pobre en novatos); ACSM 2026 (fallo no necesario) | media |
| `RIR_FALLO_PERMITIDO` | solo aislamiento/máquina, última serie | — | todos | decisión de diseño (seguridad) | baja |
| `ESCALA_RPE_RIR` | RPE = 10 − RIR | — | todos | Zourdos 2016; Helms 2016 | alta |

---

## 5. Descanso entre series

### Evidencia

- **Schoenfeld et al. (2016)**, "Longer interset rest periods enhance muscle strength and hypertrophy in resistance-trained men", JSCR 30(7):1805-1812.
  - Diseño: 21 hombres entrenados, 8 semanas.
  - 3 min de descanso dieron más fuerza y más hipertrofia (en muslo) que 1 min.
  - DOI probable 10.1519/JSC.0000000000001272 **[DOI NO VERIFICADO]**.
- **Grgic et al. (2017)**, Eur J Sport Sci 17(8):983-993, doi 10.1080/17461391.2017.1340524.
  - Revisión sistemática de 6 estudios, con descanso corto ≤60 s frente a largo >60 s.
  - Ambos pueden servir, pero en entrenados podría haber ventaja para los descansos largos.
- **Singer et al. (2024)**, "Give it a rest", Front Sports Act Living 6:1429789, doi 10.3389/fspor.2024.1429789.
  - Meta-análisis bayesiano de 9 estudios y 19 mediciones.
  - Hay un pequeño beneficio para la hipertrofia con **>60 s**, probablemente porque se preserva el volumen de carga.
  - **Más allá de ~90 s no se detectaron diferencias apreciables.**
  - La mayoría de los participantes no estaban entrenados.
- **ACSM 2009**: 2-3 min entre series en ejercicios principales y ≥3 min en cargas pesadas.

### Regla para el motor

- Compuestos pesados (1-6 reps o ≥80 % 1RM): 2-3 min, y hasta 3-5 min en fuerza máxima.
- Compuestos de hipertrofia: 2 min por defecto (rango 1,5-3).
- Aislamiento: 90 s por defecto (rango 60-120).
- Nunca programes menos de 60 s, salvo en circuitos de resistencia o salud con objetivo explícito.

### Constantes

| nombre | valor/rango | unidad | aplica a | fuente | confianza |
|---|---|---|---|---|---|
| `DESCANSO_COMPUESTO_PESADO` | 180 (120-300) | s | compuestos ≥80 % 1RM | Schoenfeld 2016; ACSM 2009 (≥3 min en cargas pesadas) | media-alta |
| `DESCANSO_COMPUESTO_HIPERTROFIA` | 120 (90-180) | s | compuestos 6-12 reps | Singer 2024 (>60 s; meseta en ~90 s); Schoenfeld 2016 | media |
| `DESCANSO_AISLAMIENTO` | 90 (60-120) | s | aislamiento | Singer 2024 | media |
| `DESCANSO_MIN` | 60 | s | todos (salvo circuito) | Grgic 2017; Singer 2024 | media |

---

## 6. Orden de los ejercicios

### Evidencia

- **Simão et al. (2012)**, "Exercise Order in Resistance Training", Sports Med 42(3):251-265, doi 10.2165/11597240-000000000-00000.
  - El ejercicio que va primero acumula más repeticiones y volumen, sea cual sea el tamaño del grupo muscular.
  - Recomiendan ordenar según las prioridades del cliente.
- **Nunes et al. (2021)**, Eur J Sport Sci 21(2):149-157, doi 10.1080/17461391.2020.1733672. Ojo: se publicó en **Eur J Sport Sci, no en Sports Med**.
  - La fuerza mejora más en los ejercicios que se hacen al principio. Empezar por multiarticulares favorece la fuerza en esos multiarticulares.
  - **La hipertrofia es similar con cualquier orden** (ES 0,03).
- **ACSM 2026**: la fuerza mejora más cuando el ejercicio se hace al principio de la sesión.

### Regla para el motor

1. Ordena la sesión así: compuestos prioritarios (los ligados al objetivo de fuerza o al músculo prioritario del usuario), después otros compuestos, después aislamiento y al final core.
2. Si un músculo es prioridad de hipertrofia, su ejercicio puede ir primero aunque sea de aislamiento. Esto está justificado porque el orden no cambia la hipertrofia (Nunes 2021), mientras que el ejercicio inicial acumula más volumen (Simão 2012).

### Constantes

| nombre | valor/rango | unidad | aplica a | fuente | confianza |
|---|---|---|---|---|---|
| `ORDEN_PRIORIDAD` | [compuesto_prioritario, compuesto, aislamiento, core] | — | todos | Simão 2012; Nunes 2021; ACSM 2026 | alta (fuerza) / media (resto) |
| `ORDEN_PERMITE_AISLAMIENTO_PRIMERO` | true si el músculo es prioritario para hipertrofia | — | hipertrofia | Nunes 2021 | media |

---

## 7. Progresión, autorregulación y descargas (deload)

### Evidencia

- **Doble progresión**: se suben repeticiones dentro de un rango y, al llegar al tope, se sube la carga. Es un **método de práctica**: no encontré un ECA que valide la doble progresión como tal.
  - ACSM 2009 describe aumentos de carga de 2-10 % cuando se superan en 1-2 repeticiones las repeticiones objetivo. Esta regla aparece en resúmenes de ACSM 2009, pero no pude confirmar textualmente el "2-10 %" ni la condición "1-2 repeticiones por encima" **[NO VERIFICADO]**.
- **Autorregulación por RIR/RPE**:
  - Graham & Cleather (2021), JSCR 35(9):2451-2456, doi 10.1519/JSC.0000000000003164. En 31 hombres entrenados, la sentadilla autorregulada por RIR mejoró más que la de carga fija: frontal +11,7 % frente a +8,3 %, trasera +10,8 % frente a +7,1 %.
  - Helms et al. (2018), Front Physiol 9:247, doi 10.3389/fphys.2018.00247. RPE frente a %1RM con series y repeticiones igualadas: ambos son eficaces, con una ventaja pequeña y no significativa para RPE.
  - Ambos estudios son pequeños: confianza media.
- **Descargas**:
  - Bell et al. (2023), "Integrating Deloading into Strength and Physique Sports Training Programmes: An International Delphi Consensus Approach", Sports Med Open 9:87, doi 10.1186/s40798-023-00633-0. Es consenso de entrenadores, no evidencia experimental. No pude extraer sus recomendaciones de frecuencia.
  - Rogerson, ..., Bell (2024), "Deloading Practices in Strength and Physique Sports: A Cross-sectional Survey", Sports Med Open 10:26. En 246 atletas, el deload duraba de media unos **6,4 días** y se hacía unas **cada 5,6 semanas**. Se reducían el volumen (series y reps) y la carga, y se aumentaba el RIR; la frecuencia se mantenía. **Esto describe la práctica, no demuestra eficacia.**
  - Coleman et al. (2024), PeerJ 12:e16777, doi 10.7717/peerj.16777. Una semana **sin entrenar** a mitad de un programa de 9 semanas **empeoró algo la fuerza** del tren inferior frente a entrenar sin pausa, y **no cambió la hipertrofia**. Ojo: lo que se probó fue el cese total, no una descarga con volumen reducido.
- **Conclusión sobre "deload cada 4-6 semanas"**: **no hay evidencia experimental** de que una descarga programada mejore la hipertrofia o la fuerza. El intervalo de 4-6 semanas coincide con la práctica declarada (unas 5,6 semanas; Rogerson 2024), pero es una **heurística de práctica**. Lo más defendible es:
  1. hacer descargas reactivas o autorreguladas cuando el rendimiento se estanca o empeora, o aumentan la fatiga y las molestias;
  2. como alternativa, una descarga programada cada 5-8 semanas, reduciendo el volumen en vez de cesar por completo, porque el cese total mostró peor fuerza (Coleman 2024).

### Regla para el motor (doble progresión + RIR)

1. Cada ejercicio tiene un rango de reps `[r_min, r_max]` y un RIR objetivo.
2. Si **todas** las series alcanzan `r_max` con RIR ≥ objetivo, la siguiente sesión sube la carga en `INCREMENTO`.
3. Si alguna serie queda por debajo de `r_min`, o el RIR registrado es menor que objetivo − 1 durante 2 sesiones seguidas, mantén la carga o bájala un 5-10 %.
4. Programa una descarga si se cumple cualquiera de estas condiciones:
   - hay estancamiento o regresión en `N_SESIONES_ESTANCAMIENTO` sesiones seguidas, comparando solo lo comparable: a igual carga, reps + RIR de la mejor serie; si la carga bajó, el e1RM; si subió, no cuenta (Epley no es comparable entre rangos de reps: 60×12 → 62×8 no es una regresión);
   - han pasado `DELOAD_CADA_SEMANAS`.
5. Durante la descarga, aplica `DELOAD_REDUCCION_VOLUMEN` a las series, aumenta el RIR en 2 y mantén la frecuencia.

### Constantes

| nombre | valor/rango | unidad | aplica a | fuente | confianza |
|---|---|---|---|---|---|
| `INCREMENTO_CARGA_PCT` | 2-10 (por defecto: 2,5 % en tren superior y 5 % en tren inferior) | % | doble progresión | ACSM 2009 (cifra 2-10 % **no verificada textualmente**); el reparto superior/inferior es convención | baja-media |
| `INCREMENTO_MIN_KG` | 1,0 (mancuernas: el siguiente peso disponible) | kg | todos | decisión de diseño (discos y material disponibles) | baja |
| `CRITERIO_SUBIDA` | todas las series en r_max con RIR ≥ objetivo | — | doble progresión | heurística de práctica | baja |
| `AUTORREG_RIR` | true | — | intermedios/avanzados | Graham & Cleather 2021; Helms 2018 | media |
| `DELOAD_CADA_SEMANAS` | 6 (rango 4-8), o reactivo | semanas | todos | Rogerson et al. 2024 (práctica media ~5,6 sem); sin evidencia de eficacia | baja |
| `DELOAD_DURACION` | 7 | días | todos | Rogerson et al. 2024 (~6,4 días de media) | baja-media |
| `DELOAD_REDUCCION_VOLUMEN` | 40-50 | % menos series | todos | heurística de práctica. Rogerson 2024 confirma reducir volumen y carga, pero **no da porcentaje verificado** | baja |
| `DELOAD_RIR_EXTRA` | +2 | RIR | todos | Rogerson 2024 (más RIR en el deload; la magnitud es una decisión de diseño) | baja |
| `DELOAD_CESE_TOTAL` | false | — | todos | Coleman 2024 (el cese total perjudicó la fuerza) | media |
| `N_SESIONES_ESTANCAMIENTO` | 2-3 | sesiones | todos | heurística de práctica | baja |

---

## 8. Estimación del tiempo de sesión

**No hay evidencia revisada por pares sobre esto: toda la sección es heurística de práctica o decisión de diseño.** Un dato útil de contexto: en Schoenfeld et al. (2019), el grupo de bajo volumen entrenó unos 13 min por sesión.

Fórmula propuesta:

```
t_sesion = t_calentamiento_general
         + Σ_ejercicios [ n_series × (t_serie + t_descanso) − t_descanso
                          + n_series_aprox × t_aprox
                          + t_transicion ]
```

donde:

- `t_serie = reps × t_rep`;
- `n_series_aprox` es el número de series de aproximación;
- el descanso se resta una vez por ejercicio porque no hay descanso tras la última serie.

| nombre | valor/rango | unidad | aplica a | fuente | confianza |
|---|---|---|---|---|---|
| `T_REP` | 3-4 (por defecto 3,5) | s/rep | todos | heurística (la fase concéntrica y excéntrica de ~1-2 s cada una se suele atribuir a ACSM 2009, **no verificado**) | baja |
| `T_CALENTAMIENTO_GENERAL` | 5 | min | todos | heurística | baja |
| `N_SERIES_APROX_COMPUESTO_PESADO` | 2-3 | series | primer compuesto pesado | heurística | baja |
| `N_SERIES_APROX_OTROS` | 0-1 | series | resto | heurística | baja |
| `T_APROX` | 60 | s/serie (incluye descanso corto) | aproximación | heurística | baja |
| `T_TRANSICION` | 60-120 | s/ejercicio | todos | heurística | baja |

---

## 9. e1RM (1RM estimado)

### Evidencia

- **Epley (1985)**: `e1RM = carga × (1 + reps/30)`, es decir, carga × (1 + 0,0333·reps).
  - Procede de una **tabla de cargas en un manual de entrenamiento**: Epley B., *Boyd Epley Workout*, Lincoln, NE: Body Enterprises, 1985, p. 86.
  - **No procede de un estudio revisado por pares.**
- **LeSuer, McCormick, Mayhew, Wasserstein & Arnold (1997)**, "The accuracy of prediction equations for estimating 1-RM performance in the bench press, squat, and deadlift", JSCR 11(4):211-213.
  - Compararon 7 ecuaciones.
  - Según resúmenes secundarios, todas infraestimaron el 1RM en peso muerto en unos 9-14 %.
  - El rango de validez de "≤10 reps" es convención habitual en la literatura de predicción, apoyada en que estas ecuaciones se validaron con series hasta el fallo de ~10 o menos repeticiones. La cifra exacta de LeSuer **no está verificada en el texto completo**.

### Regla para el motor

1. Calcula el e1RM solo con series de **1-10 reps**. Si la serie se hizo a RIR > 0, usa reps efectivas = reps + RIR (decisión de diseño). Con 1 rep, e1RM = carga.
2. Ignora las series con más de 10 reps efectivas para la estimación.
3. No uses el e1RM de peso muerto como dato fiable para prescribir cargas %1RM: la ecuación tiende a infraestimarlo.

| nombre | valor/rango | unidad | aplica a | fuente | confianza |
|---|---|---|---|---|---|
| `E1RM_FORMULA` | carga × (1 + reps/30) | kg | todos | Epley 1985 (manual, no revisado por pares) | media |
| `E1RM_REPS_MAX` | 10 | reps | todos | LeSuer 1997 + convención | media |
| `E1RM_USA_RIR` | reps_efectivas = reps + RIR | — | todos | decisión de diseño (inspirada en Zourdos 2016 y Helms 2016) | baja |

---

## 10. Equilibrio empuje/tirón y mínimos de salud

### Evidencia

- **WHO 2020** (Bull et al., Br J Sports Med 54(24):1451-1462, doi 10.1136/bjsports-2020-102955):
  - adultos: fortalecimiento muscular de intensidad moderada o mayor, de **todos los grupos musculares principales**, **≥2 días/semana**, además de 150-300 min/semana de actividad aeróbica moderada o 75-150 min de vigorosa;
  - mayores: actividad multicomponente con énfasis en equilibrio y fuerza **≥3 días/semana**.
- **ACSM 2026**: ≥2 sesiones/semana para todos los grupos musculares principales.
- **Equilibrio empuje/tirón 1:1**: **no encontré evidencia directa** revisada por pares de que una proporción concreta reduzca lesiones o mejore resultados en población general. Es una **heurística de práctica**: aquí se adopta para garantizar cobertura de los patrones de movimiento.

### Regla para el motor

1. Cada semana debe cubrir los patrones de empuje horizontal y vertical, tirón horizontal y vertical, dominante de rodilla, dominante de cadera y core.
2. La relación entre series de tirón y de empuje debe estar dentro de `[RATIO_TIRON_EMPUJE_MIN, RATIO_TIRON_EMPUJE_MAX]`.
3. El mínimo absoluto es 2 días/semana con todos los grupos principales.

| nombre | valor/rango | unidad | aplica a | fuente | confianza |
|---|---|---|---|---|---|
| `DIAS_FUERZA_MIN_SALUD` | 2 | días/sem | adultos | WHO 2020; ACSM 2026 | alta |
| `DIAS_FUERZA_MIN_MAYORES` | 3 (multicomponente: equilibrio + fuerza) | días/sem | ≥65 años | WHO 2020 | alta |
| `GRUPOS_PRINCIPALES_OBLIGATORIOS` | piernas, cadera, espalda, pecho, hombros, brazos, core | — | todos | WHO 2020 ("todos los grupos principales"; la lista concreta es convención) | media |
| `RATIO_TIRON_EMPUJE_MIN` | 1,0 | series tirón / series empuje | todos | heurística de práctica | baja |
| `RATIO_TIRON_EMPUJE_MAX` | 1,5 | series tirón / series empuje | todos | heurística de práctica | baja |
| `PATRONES_SEMANALES` | empuje H/V, tirón H/V, rodilla, cadera, core | — | todos | convención | baja |

---

## 11. Objetivos nutricionales diarios

### 11.1 Gasto en reposo: Mifflin-St Jeor (1990)

- Fuente: Mifflin MD, St Jeor ST, Hill LA, Scott BJ, Daugherty SA, Koh YO. *Am J Clin Nutr* 1990;51(2):241-247, doi 10.1093/ajcn/51.2.241. Población: 498 adultos sanos de 19-78 años, con normopeso y obesidad; el gasto en reposo se midió por calorimetría indirecta.
- Ecuación general (peso en kg, talla en cm, edad en años; sexo = 1 en hombre y 0 en mujer):
  `REE = 9,99·peso + 6,25·talla − 4,92·edad + 166·sexo − 161` (R² = 0,71).
- Forma simplificada, que según los autores no pierde valor predictivo:
  - Hombre: `REE = 10·peso + 6,25·talla − 5·edad + 5`
  - Mujer: `REE = 10·peso + 6,25·talla − 5·edad − 161`

### 11.2 Factores de actividad

- **FAO/WHO/UNU (2004)**, *Human energy requirements: report of a joint FAO/WHO/UNU expert consultation*, Roma (FAO Food and Nutrition Technical Report Series 1). Expresa la actividad como PAL (gasto total ÷ metabolismo basal), en tres categorías:
  - sedentario/ligero: 1,40-1,69;
  - activo/moderadamente activo: 1,70-1,99;
  - vigoroso: 2,00-2,39 (un PAL ≥2,40 es difícil de mantener).
  - Lo confirmé en un resumen de FAO de los hallazgos del borrador. **No pude confirmar las mismas cifras en el informe final** (confianza media).
- **Multiplicadores 1,2 / 1,375 / 1,55 / 1,725 / 1,9**: son muy usados, pero **no encontré su fuente primaria**. Una web comercial los atribuye a McArdle et al., *Exercise Physiology* (1996), **sin verificar**. Son una **heurística de práctica**. Se recomienda usar los PAL de FAO/WHO/UNU como base citada.
- Nota: el PAL se definió sobre metabolismo basal (BMR). Aplicarlo al REE de Mifflin es una aproximación aceptada en la práctica (decisión de diseño).

### 11.3 Proteína

- **Morton et al. (2018)**, Br J Sports Med 52(6):376-384, doi 10.1136/bjsports-2017-097608.
  - Diseño: 49 ECA con 1.863 participantes.
  - El beneficio sobre la masa libre de grasa se estabiliza en torno a **1,6 g/kg/día** (1,62 en el texto, con IC 95 % de 1,03 a 2,20 según una fuente secundaria). De ahí sale el rango práctico de 1,6-2,2.
- **Jäger et al. (2017)**, ISSN position stand, J Int Soc Sports Nutr 14:20, doi 10.1186/s12970-017-0177-8.
  - **1,4-2,0 g/kg/día** basta para la mayoría de personas que hacen ejercicio.
  - En déficit calórico y entrenando fuerza, **2,3-3,1 g/kg/día** puede maximizar la retención de masa magra.
  - Recomienda repartir la proteína cada 3-4 h.
- **Helms, Aragon & Fitschen (2014)**, J Int Soc Sports Nutr 11:20, doi 10.1186/1550-2783-11-20.
  - En preparación de culturismo natural: **2,3-3,1 g/kg de masa magra**/día y 15-30 % de la energía en grasa.
  - Ojo: la referencia es **masa magra**, no peso total.
  - Es una revisión narrativa en una población específica.

### 11.4 Grasa

- **IOM (2002/2005), rango AMDR** para adultos: grasa **20-35 %** de la energía, proteína 10-35 % e hidratos de carbono 45-65 %.
- **EFSA (2010)**, Scientific Opinion on Dietary Reference Values for fats, EFSA Journal 8(3):1461, doi 10.2903/j.efsa.2010.1461: grasa total **20-35 %** de la energía en adultos.
- **"0,8-1 g/kg de grasa"**: **no encontré fuente revisada por pares**. Es una **heurística de práctica**. Usa como regla el % de energía (20-35 %, que tiene fuente) y, si acaso, un suelo en g/kg como guarda secundaria (decisión de diseño).

### 11.5 Déficit y superávit

- **Pérdida de grasa**:
  - Helms 2014: perder **0,5-1 % del peso corporal por semana**.
  - Garthe et al. (2011), IJSNEM 21(2):97-104. Atletas de élite: perder un 0,7 %/semana conservó y aumentó la masa magra y mejoró más la fuerza que perder un 1,4 %/semana. El DOI no se verificó en la búsqueda.
- **Ganancia muscular**:
  - Iraki, Fitschen, Espinar & Helms (2019), Sports 7(7):154, doi 10.3390/sports7070154.
  - Superávit de ~**10-20 %** sobre mantenimiento y ganancia de ~**0,25-0,5 % del peso/semana**, más conservador en avanzados.
  - Estas cifras proceden de resúmenes secundarios del artículo **[NO VERIFICADO textualmente]**. Además, es una revisión narrativa en culturistas.

### Regla para el motor

1. Calcula `TDEE = REE_Mifflin × PAL`.
2. Calcula las kcal objetivo según la meta:
   - pérdida de grasa: `TDEE − déficit`, con un déficit que dé `RITMO_PERDIDA` del peso por semana (1 kg de tejido ≈ 7.700 kcal; ese factor es una aproximación clásica que no verifiqué en esta sesión);
   - ganancia: `TDEE × (1 + SUPERAVIT)`;
   - mantenimiento: `TDEE`.
3. Calcula la proteína como `PROT_g_kg × peso`. Si hay déficit, usa `PROT_DEFICIT`.
4. Calcula la grasa como `GRASA_PCT × kcal / 9`, con un mínimo del 20 %.
5. Los hidratos de carbono cubren el resto.
6. Recalibra con la tendencia de peso real cada 2-3 semanas (decisión de diseño). Las ecuaciones son estimaciones poblacionales.

### Constantes

| nombre | valor/rango | unidad | aplica a | fuente | confianza |
|---|---|---|---|---|---|
| `MSJ_COEF_PESO` | 10 (exacto 9,99) | kcal/kg | todos | Mifflin 1990 | alta |
| `MSJ_COEF_TALLA` | 6,25 | kcal/cm | todos | Mifflin 1990 | alta |
| `MSJ_COEF_EDAD` | −5 (exacto −4,92) | kcal/año | todos | Mifflin 1990 | alta |
| `MSJ_CONST_HOMBRE` | +5 | kcal | hombres | Mifflin 1990 | alta |
| `MSJ_CONST_MUJER` | −161 | kcal | mujeres | Mifflin 1990 | alta |
| `PAL_SEDENTARIO_LIGERO` | 1,40-1,69 (por defecto 1,55) | ×BMR | estilo de vida | FAO/WHO/UNU 2004 | media |
| `PAL_ACTIVO` | 1,70-1,99 (por defecto 1,85) | ×BMR | estilo de vida | FAO/WHO/UNU 2004 | media |
| `PAL_VIGOROSO` | 2,00-2,39 (por defecto 2,1) | ×BMR | estilo de vida | FAO/WHO/UNU 2004 | media |
| `PAL_MULTIPLICADORES_CLASICOS` | 1,2 / 1,375 / 1,55 / 1,725 / 1,9 | ×REE | alternativa | heurística de práctica; fuente primaria no localizada | baja |
| `PROT_MIN` | 1,6 | g/kg/día | entrenamiento de fuerza | Morton 2018 | alta |
| `PROT_MAX` | 2,2 | g/kg/día | entrenamiento de fuerza | Morton 2018 (límite superior del IC 95 %) | media-alta |
| `PROT_ISSN` | 1,4-2,0 | g/kg/día | personas activas | Jäger 2017 | alta |
| `PROT_DEFICIT` | 2,3-3,1 | g/kg de **masa magra**/día (o 2,2-2,6 g/kg de peso total como aproximación) | déficit + fuerza | Helms 2014; Jäger 2017. La conversión a peso total es una decisión de diseño | media |
| `GRASA_PCT_MIN` | 20 | % energía | todos | IOM AMDR; EFSA 2010 | alta |
| `GRASA_PCT_MAX` | 35 | % energía | todos | IOM AMDR; EFSA 2010 | alta |
| `GRASA_PCT_DEFICIT_ATLETA` | 15-30 | % energía | preparación de culturismo | Helms 2014 (por debajo del 20 % sale del AMDR: no se usa por defecto) | media |
| `GRASA_G_KG` | 0,8-1,0 | g/kg/día | — | **heurística de práctica, sin fuente revisada**; solo guarda secundaria | baja |
| `RITMO_PERDIDA` | 0,5-1,0 (por defecto 0,7) | % peso/semana | pérdida de grasa | Helms 2014; Garthe 2011 | media-alta |
| `SUPERAVIT` | 10-20 (5-10 en avanzados) | % sobre TDEE | ganancia muscular | Iraki 2019 (no verificado textualmente) | baja-media |
| `RITMO_GANANCIA` | 0,25-0,5 | % peso/semana | ganancia muscular | Iraki 2019 (no verificado textualmente) | baja-media |

---

## 12. Seguridad y derivación a profesionales (no médico)

### Evidencia

- **Riebe et al. (2015)**, "Updating ACSM's Recommendations for Exercise Preparticipation Health Screening", MSSE 47(11):2473-2479, doi 10.1249/MSS.0000000000000664. El cribado se basa en tres factores:
  1. el nivel actual de actividad física;
  2. la presencia de signos o síntomas, o de enfermedad cardiovascular, metabólica o renal conocida;
  3. la intensidad de ejercicio deseada.
- El modelo eliminó el recuento de factores de riesgo cardiovascular como criterio.
- Se considera "activo" a quien hace actividad estructurada moderada ≥30 min, ≥3 días/semana, durante ≥3 meses.
- No pude ver el diagrama de flujo completo.

### Regla para el motor (la app no diagnostica)

1. **Cuestionario inicial**:
   - ¿Hace ejercicio regularmente (≥30 min, ≥3 días/semana, ≥3 meses)?
   - ¿Tiene enfermedad cardiovascular, metabólica o renal diagnosticada?
   - ¿Tiene síntomas como dolor u opresión en el pecho, falta de aire desproporcionada, mareos o desmayos, palpitaciones o hinchazón de tobillos?
   - Si hay enfermedad o síntomas: muestra el mensaje "consulta con un profesional sanitario antes de empezar o aumentar la intensidad". Además, limita el plan a intensidad baja o moderada (RIR ≥3) hasta que el usuario confirme que tiene autorización.
2. **Durante el uso**:
   - Si el usuario reporta dolor articular agudo o punzante, o dolor que persiste o empeora, retira ese ejercicio y sugiere consultar a un fisioterapeuta o médico.
   - Si reporta síntomas cardiovasculares durante el ejercicio, recomienda parar y buscar atención médica.
   - Los umbrales concretos (p. ej., "dolor > X/10" o "persistencia > N sesiones") son **decisión de diseño sin evidencia directa**.
3. **Embarazo, posparto y enfermedades crónicas**: WHO 2020 incluye recomendaciones específicas para estos grupos. La app debe derivar a un profesional y no ajustar el plan por su cuenta.
4. Ningún texto de la app debe presentarse como consejo médico.

| nombre | valor/rango | unidad | aplica a | fuente | confianza |
|---|---|---|---|---|---|
| `CRIBADO_FACTORES` | actividad actual, enfermedad o síntomas, intensidad deseada | — | onboarding | Riebe 2015 | alta |
| `DEF_ACTIVO` | ≥30 min, ≥3 días/sem, ≥3 meses, moderada | — | onboarding | Riebe 2015 | alta |
| `RIR_SIN_AUTORIZACION` | ≥3 | RIR | usuarios con enfermedad o síntomas sin autorización | decisión de diseño (inspirada en Riebe 2015: intensidad baja o moderada) | baja |
| `DOLOR_UMBRAL_RETIRAR` | dolor agudo/punzante, o dolor que persiste 2 sesiones | — | todos | decisión de diseño | baja |

---

## 13. Tabla resumen de TODAS las constantes

| # | nombre | valor | unidad | fuente | confianza |
|---|---|---|---|---|---|
| 1 | PESO_SERIE_DIRECTA | 1,0 | serie | Pelland 2026 | alta |
| 2 | PESO_SERIE_INDIRECTA | 0,5 | serie | Pelland 2026 | media-alta |
| 3 | VOL_MIN_PRINCIPIANTE | 6 (4-6) | series/sem/músculo | Schoenfeld 2017 + diseño | media |
| 4 | VOL_MAX_PRINCIPIANTE | 10-12 | series/sem/músculo | Schoenfeld 2017 + diseño | baja-media |
| 5 | VOL_MIN_INTERMEDIO | 10 | series/sem/músculo | Schoenfeld 2017; ACSM 2026 (prensa) | media |
| 6 | VOL_MAX_INTERMEDIO | 16-20 | series/sem/músculo | Baz-Valle 2022 | media |
| 7 | VOL_MIN_AVANZADO | 12 | series/sem/músculo | Baz-Valle 2022 | media |
| 8 | VOL_MAX_AVANZADO | 20 (≤24 prioritarios) | series/sem/músculo | Baz-Valle 2022; Pelland 2026 | media |
| 9 | VOL_SESION_MAX | 10-11 | series fraccionales/sesión/músculo | Remmert 2025 (preprint) | baja-media |
| 10 | VOL_SESION_MAX_FUERZA | ~2 series directas (beneficio marginal después) | series/sesión | Remmert 2025 (preprint) | baja |
| 11 | FREC_MIN_MUSCULO | 2 | ses/sem/músculo | Schoenfeld 2016; WHO 2020; ACSM 2026 | alta |
| 12 | FREC_MAX_MUSCULO | 3 (4) | ses/sem/músculo | Grgic 2018 + diseño | baja-media |
| 13 | DIAS_PRINCIPIANTE | 2-3 | días/sem | ACSM 2009 | alta |
| 14 | DIAS_INTERMEDIO | 3-4 | días/sem | ACSM 2009 | alta |
| 15 | DIAS_AVANZADO | 4-5 (6) | días/sem | ACSM 2009 | media |
| 16 | SPLIT_2_3_DIAS | full body | — | convención | baja |
| 17 | SPLIT_4_DIAS | torso/pierna | — | convención | baja |
| 18 | SPLIT_5_6_DIAS | PPL/híbrido | — | convención | baja |
| 19 | REPS_FUERZA | 3-6 | reps | ACSM 2009/2026 | alta |
| 20 | CARGA_FUERZA_MIN | 80 | %1RM | ACSM 2026 | alta |
| 21 | SERIES_EJERCICIO_FUERZA | 2-3 | series/ejercicio | ACSM 2026 | alta |
| 22 | REPS_HIPERTROFIA_DEF | 8-12 | reps | convención + Schoenfeld 2017 | media |
| 23 | REPS_HIPERTROFIA_RANGO | 5-30 | reps | Schoenfeld 2017, 2021 | media-alta |
| 24 | REPS_RESISTENCIA | 15-25 | reps | Schoenfeld 2021; ACSM 2009 | media |
| 25 | REPS_SALUD | 8-12 | reps | ACSM 2009 | alta |
| 26 | RIR_HIPERTROFIA_COMPUESTO | 1-2 | RIR | Refalo 2024; Robinson 2024 | media-alta |
| 27 | RIR_HIPERTROFIA_AISLAMIENTO | 0-1 | RIR | Robinson 2024 | media |
| 28 | RIR_FUERZA | 1-3 | RIR | Robinson 2024 | media-alta |
| 29 | RIR_PRINCIPIANTE | 2-4 | RIR | Zourdos 2016; ACSM 2026 | media |
| 30 | RIR_FALLO_PERMITIDO | aislamiento, última serie | — | diseño | baja |
| 31 | ESCALA_RPE_RIR | RPE = 10 − RIR | — | Zourdos 2016; Helms 2016 | alta |
| 32 | DESCANSO_COMPUESTO_PESADO | 180 (120-300) | s | Schoenfeld 2016; ACSM 2009 | media-alta |
| 33 | DESCANSO_COMPUESTO_HIPERTROFIA | 120 (90-180) | s | Singer 2024; Schoenfeld 2016 | media |
| 34 | DESCANSO_AISLAMIENTO | 90 (60-120) | s | Singer 2024 | media |
| 35 | DESCANSO_MIN | 60 | s | Grgic 2017; Singer 2024 | media |
| 36 | ORDEN_PRIORIDAD | compuesto prioritario → compuesto → aislamiento → core | — | Simão 2012; Nunes 2021; ACSM 2026 | alta/media |
| 37 | ORDEN_PERMITE_AISLAMIENTO_PRIMERO | sí, si el músculo es prioritario | — | Nunes 2021 | media |
| 38 | INCREMENTO_CARGA_PCT | 2-10 (2,5 superior / 5 inferior) | % | ACSM 2009 (no verificado) + convención | baja-media |
| 39 | INCREMENTO_MIN_KG | 1,0 | kg | diseño | baja |
| 40 | CRITERIO_SUBIDA | todas las series en r_max con RIR ≥ objetivo | — | heurística | baja |
| 41 | AUTORREG_RIR | true | — | Graham & Cleather 2021; Helms 2018 | media |
| 42 | DELOAD_CADA_SEMANAS | 6 (4-8) o reactivo | semanas | Rogerson 2024 (práctica) | baja |
| 43 | DELOAD_DURACION | 7 | días | Rogerson 2024 | baja-media |
| 44 | DELOAD_REDUCCION_VOLUMEN | 40-50 | % | heurística | baja |
| 45 | DELOAD_RIR_EXTRA | +2 | RIR | Rogerson 2024 + diseño | baja |
| 46 | DELOAD_CESE_TOTAL | false | — | Coleman 2024 | media |
| 47 | N_SESIONES_ESTANCAMIENTO | 2-3 | sesiones | heurística | baja |
| 48 | T_REP | 3,5 (3-4) | s/rep | heurística | baja |
| 49 | T_CALENTAMIENTO_GENERAL | 5 | min | heurística | baja |
| 50 | N_SERIES_APROX_COMPUESTO_PESADO | 2-3 | series | heurística | baja |
| 51 | N_SERIES_APROX_OTROS | 0-1 | series | heurística | baja |
| 52 | T_APROX | 60 | s/serie | heurística | baja |
| 53 | T_TRANSICION | 60-120 | s/ejercicio | heurística | baja |
| 54 | E1RM_FORMULA | carga × (1 + reps/30) | kg | Epley 1985 | media |
| 55 | E1RM_REPS_MAX | 10 | reps | LeSuer 1997 + convención | media |
| 56 | E1RM_USA_RIR | reps + RIR | — | diseño | baja |
| 57 | DIAS_FUERZA_MIN_SALUD | 2 | días/sem | WHO 2020; ACSM 2026 | alta |
| 58 | DIAS_FUERZA_MIN_MAYORES | 3 (multicomponente) | días/sem | WHO 2020 | alta |
| 59 | GRUPOS_PRINCIPALES_OBLIGATORIOS | lista de 7 grupos | — | WHO 2020 + convención | media |
| 60 | RATIO_TIRON_EMPUJE_MIN | 1,0 | ratio | heurística | baja |
| 61 | RATIO_TIRON_EMPUJE_MAX | 1,5 | ratio | heurística | baja |
| 62 | PATRONES_SEMANALES | empuje H/V, tirón H/V, rodilla, cadera, core | — | convención | baja |
| 63 | MSJ_COEF_PESO | 10 (9,99) | kcal/kg | Mifflin 1990 | alta |
| 64 | MSJ_COEF_TALLA | 6,25 | kcal/cm | Mifflin 1990 | alta |
| 65 | MSJ_COEF_EDAD | −5 (−4,92) | kcal/año | Mifflin 1990 | alta |
| 66 | MSJ_CONST_HOMBRE | +5 | kcal | Mifflin 1990 | alta |
| 67 | MSJ_CONST_MUJER | −161 | kcal | Mifflin 1990 | alta |
| 68 | PAL_SEDENTARIO_LIGERO | 1,40-1,69 | ×BMR | FAO/WHO/UNU 2004 | media |
| 69 | PAL_ACTIVO | 1,70-1,99 | ×BMR | FAO/WHO/UNU 2004 | media |
| 70 | PAL_VIGOROSO | 2,00-2,39 | ×BMR | FAO/WHO/UNU 2004 | media |
| 71 | PAL_MULTIPLICADORES_CLASICOS | 1,2-1,9 | ×REE | heurística (fuente no localizada) | baja |
| 72 | PROT_MIN | 1,6 | g/kg/día | Morton 2018 | alta |
| 73 | PROT_MAX | 2,2 | g/kg/día | Morton 2018 | media-alta |
| 74 | PROT_ISSN | 1,4-2,0 | g/kg/día | Jäger 2017 | alta |
| 75 | PROT_DEFICIT | 2,3-3,1 | g/kg de masa magra/día | Helms 2014; Jäger 2017 | media |
| 76 | GRASA_PCT_MIN | 20 | % energía | IOM; EFSA 2010 | alta |
| 77 | GRASA_PCT_MAX | 35 | % energía | IOM; EFSA 2010 | alta |
| 78 | GRASA_PCT_DEFICIT_ATLETA | 15-30 | % energía | Helms 2014 | media |
| 79 | GRASA_G_KG | 0,8-1,0 | g/kg/día | heurística sin fuente | baja |
| 80 | RITMO_PERDIDA | 0,5-1,0 (0,7) | % peso/sem | Helms 2014; Garthe 2011 | media-alta |
| 81 | SUPERAVIT | 10-20 (5-10 avanzados) | % TDEE | Iraki 2019 (no verificado textualmente) | baja-media |
| 82 | RITMO_GANANCIA | 0,25-0,5 | % peso/sem | Iraki 2019 (no verificado textualmente) | baja-media |
| 83 | CRIBADO_FACTORES | 3 factores | — | Riebe 2015 | alta |
| 84 | DEF_ACTIVO | ≥30 min, ≥3 d/sem, ≥3 meses | — | Riebe 2015 | alta |
| 85 | RIR_SIN_AUTORIZACION | ≥3 | RIR | diseño | baja |
| 86 | DOLOR_UMBRAL_RETIRAR | agudo, o persistente 2 sesiones | — | diseño | baja |

---

## 14. Fuentes

1. American College of Sports Medicine. Position stand: Progression models in resistance training for healthy adults. *Med Sci Sports Exerc*. 2009;41(3):687-708. doi:10.1249/MSS.0b013e3181915670
2. Currier BS, D'Souza AC, Fiatarone Singh MA, …, Phillips SM. ACSM Position Stand: Resistance Training Prescription for Muscle Function, Hypertrophy, and Physical Performance in Healthy Adults: An Overview of Reviews. *Med Sci Sports Exerc*. 2026;58(4):851-872. doi:10.1249/MSS.0000000000003897
3. Baz-Valle E, Balsalobre-Fernández C, Alix-Fages C, Santos-Concejero J. A Systematic Review of the Effects of Different Resistance Training Volumes on Muscle Hypertrophy. *J Hum Kinet*. 2022;81:199-210. doi:10.2478/hukin-2022-0017
4. Bell L, Strafford BW, Coleman M, Androulakis Korakakis P, Nolan D. Integrating Deloading into Strength and Physique Sports Training Programmes: An International Delphi Consensus Approach. *Sports Med Open*. 2023;9:87. doi:10.1186/s40798-023-00633-0
5. Bull FC, Al-Ansari SS, Biddle S, et al. World Health Organization 2020 guidelines on physical activity and sedentary behaviour. *Br J Sports Med*. 2020;54(24):1451-1462. doi:10.1136/bjsports-2020-102955
6. Coleman M, Burke R, Augustin F, …, Schoenfeld BJ. Gaining more from doing less? The effects of a one-week deload period during supervised resistance training on muscular adaptations. *PeerJ*. 2024;12:e16777. doi:10.7717/peerj.16777
7. EFSA Panel on Dietetic Products, Nutrition and Allergies (NDA). Scientific Opinion on Dietary Reference Values for fats. *EFSA Journal*. 2010;8(3):1461. doi:10.2903/j.efsa.2010.1461
8. Epley B. *Boyd Epley Workout*. Lincoln, NE: Body Enterprises; 1985. p. 86. (Manual, no revisado por pares.)
9. FAO/WHO/UNU. *Human energy requirements: report of a joint FAO/WHO/UNU expert consultation*. Rome: FAO; 2004 (Food and Nutrition Technical Report Series 1).
10. Garthe I, Raastad T, Refsnes PE, Koivisto A, Sundgot-Borgen J. Effect of two different weight-loss rates on body composition and strength and power-related performance in elite athletes. *Int J Sport Nutr Exerc Metab*. 2011;21(2):97-104. (DOI no verificado en esta sesión.)
11. Graham T, Cleather DJ. Autoregulation by "Repetitions in Reserve" Leads to Greater Improvements in Strength Over a 12-Week Training Program Than Fixed Loading. *J Strength Cond Res*. 2021;35(9):2451-2456. doi:10.1519/JSC.0000000000003164
12. Grgic J, Lazinica B, Mikulic P, Krieger JW, Schoenfeld BJ. The effects of short versus long inter-set rest intervals in resistance training on measures of muscle hypertrophy: A systematic review. *Eur J Sport Sci*. 2017;17(8):983-993. doi:10.1080/17461391.2017.1340524
13. Grgic J, Schoenfeld BJ, Davies TB, Lazinica B, Krieger JW, Pedisic Z. Effect of Resistance Training Frequency on Gains in Muscular Strength: A Systematic Review and Meta-Analysis. *Sports Med*. 2018;48(5):1207-1220. (DOI probable 10.1007/s40279-018-0872-x, NO VERIFICADO; la lista de autores también procede de memoria parcial: el registro consultado listaba a Grgic, Schoenfeld y Pedisic.)
14. Helms ER, Aragon AA, Fitschen PJ. Evidence-based recommendations for natural bodybuilding contest preparation: nutrition and supplementation. *J Int Soc Sports Nutr*. 2014;11:20. doi:10.1186/1550-2783-11-20
15. Helms ER, Cronin J, Storey A, Zourdos MC. Application of the Repetitions in Reserve-Based Rating of Perceived Exertion Scale for Resistance Training. *Strength Cond J*. 2016;38(4):42-49. doi:10.1519/SSC.0000000000000218
16. Helms ER, Byrnes RK, Cooke DM, et al. RPE vs. Percentage 1RM Loading in Periodized Programs Matched for Sets and Repetitions. *Front Physiol*. 2018;9:247. doi:10.3389/fphys.2018.00247
17. Institute of Medicine. *Dietary Reference Intakes for Energy, Carbohydrate, Fiber, Fat, Fatty Acids, Cholesterol, Protein, and Amino Acids*. Washington, DC: National Academies Press; 2002/2005. (AMDR.)
18. Iraki J, Fitschen P, Espinar S, Helms E. Nutrition Recommendations for Bodybuilders in the Off-Season: A Narrative Review. *Sports*. 2019;7(7):154. doi:10.3390/sports7070154
19. Jäger R, Kerksick CM, Campbell BI, et al. International Society of Sports Nutrition Position Stand: protein and exercise. *J Int Soc Sports Nutr*. 2017;14:20. doi:10.1186/s12970-017-0177-8
20. LeSuer DA, McCormick JH, Mayhew JL, Wasserstein RL, Arnold MD. The accuracy of prediction equations for estimating 1-RM performance in the bench press, squat, and deadlift. *J Strength Cond Res*. 1997;11(4):211-213.
21. Mifflin MD, St Jeor ST, Hill LA, Scott BJ, Daugherty SA, Koh YO. A new predictive equation for resting energy expenditure in healthy individuals. *Am J Clin Nutr*. 1990;51(2):241-247. doi:10.1093/ajcn/51.2.241
22. Morton RW, Murphy KT, McKellar SR, et al. A systematic review, meta-analysis and meta-regression of the effect of protein supplementation on resistance training-induced gains in muscle mass and strength in healthy adults. *Br J Sports Med*. 2018;52(6):376-384. doi:10.1136/bjsports-2017-097608
23. Nunes JP, Grgic J, Cunha PM, et al. What influence does resistance exercise order have on muscular strength gains and muscle hypertrophy? A systematic review and meta-analysis. *Eur J Sport Sci*. 2021;21(2):149-157. doi:10.1080/17461391.2020.1733672
24. Pelland JC, Remmert JF, Robinson ZP, Hinson SR, Zourdos MC. The Resistance Training Dose Response: Meta-Regressions Exploring the Effects of Weekly Volume and Frequency on Muscle Hypertrophy and Strength Gain. *Sports Med*. 2026;56(2):481-505. doi:10.1007/s40279-025-02344-w
25. Ralston GW, Kilgore L, Wyatt FB, Baker JS. The Effect of Weekly Set Volume on Strength Gain: A Meta-Analysis. *Sports Med*. 2017;47(12):2585-2601. doi:10.1007/s40279-017-0762-7
26. Refalo MC, Helms ER, Trexler ET, Hamilton DL, Fyfe JJ. Influence of Resistance Training Proximity-to-Failure on Skeletal Muscle Hypertrophy: A Systematic Review with Meta-analysis. *Sports Med*. 2023;53(3):649-665. doi:10.1007/s40279-022-01784-y
27. Refalo MC, Helms ER, Robinson ZP, Hamilton DL, Fyfe JJ. Similar muscle hypertrophy following eight weeks of resistance training to momentary muscular failure or with repetitions-in-reserve in resistance-trained individuals. *J Sports Sci*. 2024;42(1):85-101. doi:10.1080/02640414.2024.2321021
28. Remmert JF, Pelland JC, Robinson ZP, Hinson SR, Zourdos MC. Is There Too Much of a Good Thing? Meta-regressions of per-session set volume (preprint). *SportRxiv*. 2025. doi:10.51224/SRXIV.537 (no revisado por pares).
29. Riebe D, Franklin BA, Thompson PD, et al. Updating ACSM's Recommendations for Exercise Preparticipation Health Screening. *Med Sci Sports Exerc*. 2015;47(11):2473-2479. doi:10.1249/MSS.0000000000000664
30. Robinson ZP, Pelland JC, Remmert JF, Refalo MC, Jukic I, Steele J, Zourdos MC. Exploring the Dose–Response Relationship Between Estimated Resistance Training Proximity to Failure, Strength Gain, and Muscle Hypertrophy: A Series of Meta-Regressions. *Sports Med*. 2024;54(9):2209-2231. doi:10.1007/s40279-024-02069-2
31. Rogerson D, Nolan D, Androulakis Korakakis P, Immonen V, Wolf M, Bell L. Deloading Practices in Strength and Physique Sports: A Cross-sectional Survey. *Sports Med Open*. 2024;10:26. (DOI de esta referencia no recogido en la búsqueda; el PDF del repositorio indica s40798-024-00691-y, por lo que sería 10.1186/s40798-024-00691-y.)
32. Schoenfeld BJ, Ogborn D, Krieger JW. Effects of Resistance Training Frequency on Measures of Muscle Hypertrophy: A Systematic Review and Meta-Analysis. *Sports Med*. 2016;46(11):1689-1697. doi:10.1007/s40279-016-0543-8
33. Schoenfeld BJ, Ogborn D, Krieger JW. Dose-response relationship between weekly resistance training volume and increases in muscle mass: A systematic review and meta-analysis. *J Sports Sci*. 2017;35(11):1073-1082. doi:10.1080/02640414.2016.1210197
34. Schoenfeld BJ, Pope ZK, Benik FM, et al. Longer Interset Rest Periods Enhance Muscle Strength and Hypertrophy in Resistance-Trained Men. *J Strength Cond Res*. 2016;30(7):1805-1812. (DOI probable 10.1519/JSC.0000000000001272, NO VERIFICADO.)
35. Schoenfeld BJ, Grgic J, Ogborn D, Krieger JW. Strength and Hypertrophy Adaptations Between Low- vs. High-Load Resistance Training: A Systematic Review and Meta-analysis. *J Strength Cond Res*. 2017;31(12):3508-3523. doi:10.1519/JSC.0000000000002200
36. Schoenfeld BJ, Contreras B, Krieger J, et al. Resistance Training Volume Enhances Muscle Hypertrophy but Not Strength in Trained Men. *Med Sci Sports Exerc*. 2019;51(1):94-103. doi:10.1249/MSS.0000000000001764
37. Schoenfeld BJ, Grgic J, Van Every DW, Plotkin DL. Loading Recommendations for Muscle Strength, Hypertrophy, and Local Endurance: A Re-Examination of the Repetition Continuum. *Sports*. 2021;9(2):32. doi:10.3390/sports9020032
38. Simão R, de Salles BF, Figueiredo T, Dias I, Willardson JM. Exercise Order in Resistance Training. *Sports Med*. 2012;42(3):251-265. doi:10.2165/11597240-000000000-00000
39. Singer A, Wolf M, Generoso L, et al. Give it a rest: a systematic review with Bayesian meta-analysis on the effect of inter-set rest interval duration on muscle hypertrophy. *Front Sports Act Living*. 2024;6:1429789. doi:10.3389/fspor.2024.1429789
40. Zourdos MC, Klemp A, Dolan C, et al. Novel Resistance Training–Specific Rating of Perceived Exertion Scale Measuring Repetitions in Reserve. *J Strength Cond Res*. 2016;30(1):267-275. doi:10.1519/JSC.0000000000001049
41. (Heurística, no revisada por pares) Israetel M, Hoffmann J, Smith CW. *Scientific Principles of Hypertrophy Training*. Renaissance Periodization (~2019; año no verificado). Marcas MEV/MAV/MRV.

Nota sobre los autores: los nombres de coautores que siguen al primero en algunas entradas (p. ej., 6, 10, 26, 27, 34, 36, 39 y 40) proceden en parte de memoria y de registros parciales. El primer autor, la revista, el año, el volumen y el DOI son los datos verificados en la búsqueda, salvo donde se indica lo contrario.

---

## 15. Lagunas y decisiones de diseño sin evidencia directa

1. **Techos de volumen exactos por nivel.** Ningún estudio define "principiante, intermedio o avanzado" con techos validados. Los valores 10-12, 16-20 y 20-24 son interpolaciones de Schoenfeld 2017, Baz-Valle 2022 y Pelland 2026. Las cifras numéricas de Pelland 2026 (umbral de superioridad no detectable) **no se pudieron verificar**.
2. **Mapeo ejercicio→músculo directo o indirecto.** El peso 0,5 tiene fuente (Pelland 2026), pero la clasificación de cada ejercicio es propia.
3. **Volumen máximo por sesión (~11 series).** Procede de un preprint no revisado (Remmert 2025).
4. **Selección de split por días.** Es convención. La evidencia solo respalda la frecuencia ≥2 y repartir el volumen.
5. **Rango de reps por defecto para hipertrofia (8-12).** Es convención de eficiencia: la evidencia dice que funciona un rango amplio.
6. **RIR por tipo de ejercicio (compuesto frente a aislamiento) y regla de fallo solo en aislamiento.** Es una decisión de seguridad sin ECA específico.
7. **Doble progresión, criterio de subida e incrementos de carga.** La cifra 2-10 % de ACSM 2009 no se verificó textualmente. El reparto 2,5 % superior / 5 % inferior es convención.
8. **Frecuencia y magnitud del deload.** No hay evidencia experimental de beneficio. El intervalo de unas 6 semanas refleja práctica declarada (Rogerson 2024). El porcentaje de reducción de volumen es heurístico. El cese total parece perjudicar la fuerza (Coleman 2024). No pude extraer las recomendaciones concretas del Delphi de Bell 2023.
9. **Estimación del tiempo de sesión.** Es 100 % heurística.
10. **Rango de validez de Epley (≤10 reps) y uso de reps + RIR.** Es convención y decisión de diseño. La fórmula procede de un manual, no de un estudio.
11. **Ratio tirón:empuje.** No encontré evidencia revisada por pares en población general.
12. **Multiplicadores de actividad 1,2-1,9.** Fuente primaria no localizada. Se proponen los PAL de FAO/WHO/UNU 2004, aunque las cifras se confirmaron solo en un resumen del borrador.
13. **Grasa en 0,8-1 g/kg.** No tiene fuente. Se sustituye por el 20-35 % de la energía (IOM, EFSA).
14. **Superávit 10-20 % y ganancia 0,25-0,5 %/semana (Iraki 2019).** No verificados textualmente; proceden de una revisión narrativa en culturistas.
15. **Conversión de proteína en déficit de "por kg de masa magra" a "por kg de peso total".** Es una decisión de diseño.
16. **Umbrales de dolor para retirar un ejercicio o derivar.** Son decisión de diseño. Riebe 2015 solo cubre el cribado previo.
17. **ACSM 2026.** Solo se leyeron el abstract y los materiales de prensa. Las cifras de descanso, volumen y proximidad al fallo del texto completo no se verificaron. Conviene revisarlo completo porque es la guía vigente.
18. **DOIs no verificados**: Grgic 2018, Schoenfeld 2016 (descanso), Garthe 2011 y Rogerson 2024 (este último deducido del nombre del PDF).
19. **Limitación general.** La red de la sesión bloqueó PubMed, PMC, Springer, MDPI, ACSM y SportRxiv. Las cifras proceden de abstracts y registros indexados vistos a través del buscador, no de los textos completos.

---

## 16. Heurísticas de diseño del motor v2 (añadidas en la Fase 2)

Todo lo de esta sección es **heurística de diseño** (confianza **baja**): decisiones propias necesarias para que el motor funcione, sin evidencia directa. Cada una se apoya, cuando es posible, en una regla citada de las secciones 1-12. Las constantes viven en `packages/engine-rules/src/config/programming.ts` con `source: 'PROGRAMACION.md §16.x'` y `heuristic: true`.

### 16.1 Grupos de volumen

- El motor mide el volumen en 10 grupos: pecho, espalda (dorsal + espalda alta), hombros (deltoides lateral + posterior), bíceps, tríceps, cuádriceps, isquiosurales, glúteos (+ abductores), gemelos y core (abdominales + oblicuos). Cubren los grupos principales de la OMS (§10) con algo más de detalle en piernas y brazos.
- El deltoides anterior, el trapecio, los antebrazos, la zona lumbar y los aductores **no tienen objetivo propio**: reciben mucho trabajo indirecto de los multiarticulares (se informan en `muscleVolume`).
- En cada ejercicio, el grupo suma `series × máxima fracción de sus músculos` (§1): un remo cuenta 1 serie para espalda aunque trabaje dorsal y espalda alta, no 2.

### 16.2 Umbral de frecuencia

Un grupo cuenta como «entrenado» en una sesión si recibe **≥ 1 serie efectiva** (`FREQ_UMBRAL_SERIES = 1`). Así 2 series de press de banca (0,5 × 2 = 1) cuentan como un estímulo de tríceps.

### 16.3 Series y ejercicios por sesión

| nombre | valor | apoyo |
|---|---|---|
| `SERIES_MIN_EJERCICIO` | 2 | por debajo se pierde tiempo en calentamiento y transición |
| `SERIES_DEF_EJERCICIO` | 3 | punto medio habitual; respeta `SERIES_EJERCICIO_FUERZA` 2-3 (§3) |
| `SERIES_MAX_EJERCICIO` | 4 (3 en salud general, §3; 3 en el principal de fuerza, §3) | por encima conviene otro ejercicio (variedad, §1 `VOL_SESION_MAX`) |
| `EJERCICIOS_MAX_SESION` | 8 | sesiones legibles; con 90 min caben ~30 series |

Dos ejercicios del mismo grupo de sustitución no van en la misma sesión, salvo que trabajen un músculo prioritario.

Al rellenar tiempo libre, **core y gemelos solo se llevan hasta el suelo** (salvo que sean prioritarios) y una sesión lleva **como mucho 2 ejercicios de core**: el tiempo sobrante se reparte primero entre los grupos grandes.

### 16.4 Prescripción por objetivo

- Aislamiento en hipertrofia: 10-15 reps (dentro de `REPS_HIPERTROFIA_RANGO` 5-30, §3) a RIR 1 (§4).
- Pérdida de grasa: se entrena como hipertrofia para conservar masa muscular (las kcal se ajustan en nutrición, §11).
- Resistencia muscular: RIR 2 en multiarticulares y 1 en aislamiento (§4: la proximidad al fallo importa para la hipertrofia; nunca fallo en multiarticulares).
- Principiantes: 8-12 reps en todos los objetivos salvo resistencia (ACSM 2009, §3) y RIR ≥ 3 en multiarticulares y ≥ 2 en aislamiento (§4).

### 16.5 Series de aproximación

Primer multiarticular con carga de la sesión: 2 series (3 si el objetivo es fuerza) al **50 % × 8, 70 % × 5 y 85 % × 3** de la carga de trabajo. Los porcentajes son práctica habitual; no hay estudio que los fije.

El resto de multiarticulares pesados (esquema de fuerza a 3-6 reps) llevan **1** serie de aproximación al 50 % (`N_SERIES_APROX_OTROS` 0-1, §8).

### 16.6 Tiempo

- En ejercicios unilaterales el tiempo de serie se multiplica por 2 (se hace cada lado).
- Tolerancia de duración: **±10 %** sobre los minutos elegidos. El motor apunta a no pasarse; si sobra más del 10 % lo avisa (`TIME_UNDERUSED`).
- `T_TRANSICION` se fija en 60 s (extremo bajo de §8) para no penalizar sesiones cortas.

### 16.7 Pesos del scoring

| componente | peso | qué mide |
|---|---|---|
| cobertura | 0,25 | grupos sobre el suelo (60 %) y patrones semanales presentes (40 %) |
| ajuste de volumen | 0,20 | dentro de [suelo, techo]; los prioritarios puntúan más cerca del techo |
| ajuste de tiempo | 0,20 | penaliza pasarse (pendiente 5) y quedarse corto (pendiente 1, fuera de la tolerancia) |
| frecuencia | 0,10 | grupos con ≥ 2 sesiones/semana (§2) |
| balance tirón/empuje | 0,10 | ratio dentro de [1,0; 1,5] (§10); no penaliza empujar si la espalda ya está en su techo |
| variedad | 0,10 | penaliza repetir el mismo ejercicio en la semana |
| preferencias | 0,05 | favoritos incluidos y pocos ejercicios con precaución en zonas limitadas (penalización 0,5) |

### 16.8 Búsqueda local (retirada)

Se implementó (60 iteraciones y 40.000 evaluaciones como máximo) y se midió en los 10 perfiles de ejemplo: mejoraba el score un **1,83 %** de media, por debajo del umbral del 2 % de ADR-0006, así que se retiró. El plan es la solución por reglas; los pesos de §16.7 se usan solo para puntuar y comparar planes.

### 16.9 Progresión: bajadas y pausas

- Bajada reactiva tras 2 sesiones por debajo del rango o del RIR: **−5 %** (extremo bajo de 5-10 %, §7).
- Vuelta tras **≥ 14 días** sin hacer el ejercicio (CUJ-5): **−10 %** de carga (extremo alto de 5-10 %, §7).
- Descarga reactiva: el índice de rendimiento (Epley con reps + RIR, §9) cae en **2 sesiones seguidas** (`N_SESIONES_ESTANCAMIENTO`, §7).
- Descarga programada: series al **50 %** (extremo alto de 40-50 %), RIR + 2, misma frecuencia (§7).

### 16.10 Carga inicial desde el historial

Se usa el e1RM de la **sesión más reciente** con series válidas (1-10 reps efectivas, §9). La carga se calcula para `repMin + RIR` reps efectivas y se redondea **hacia abajo a 1 kg** (`INCREMENTO_MIN_KG`, §7). Si `repMin + RIR > 10`, no se da carga (la fórmula no es fiable) y se marca como estimación.

### 16.11 Nutrición

- Suelo de seguridad: las kcal objetivo **nunca bajan del gasto en reposo** (REE de Mifflin-St Jeor). No es un umbral clínico; evita déficits agresivos sin supervisión.
- Grasa por defecto: **25 %** de la energía (dentro de 20-35 %, §11.4); si no caben los hidratos, se baja al 20 %.
- Proteína en déficit: 2,2 g/kg de peso total por defecto (extremo bajo de la aproximación de §11), o 2,3 g/kg de masa magra si se conoce.
- Superávit: 10 % (5 % en avanzados), extremos bajos de §11.5.
- Factores de Atwater: 4 kcal/g de proteína e hidratos y 9 kcal/g de grasa (convención).

### 16.12 Patrones fuera de la generación automática

Los acarreos (`carry`) se prescriben por tiempo o distancia, no por repeticiones, así que v1 no los genera; siguen en el catálogo para sustituciones manuales. Por lo mismo, el catálogo no incluye isométricos (planchas): el core se cubre con dead bug, bird dog, Pallof, crunch y similares.

### 16.13 Plantillas de sesión y días

- Cuerpo completo A/B/C, torso A/B, pierna A/B, empuje A/B y tirón A/B con huecos de patrón en orden: multiarticular principal → secundarios → accesorios → core (§6). Cada grupo aparece en ≥ 2 sesiones por semana (§2).
- 5 días: torso, pierna, empuje, tirón, pierna. 6 días: empuje, tirón, pierna × 2.
- Días (0 = lunes): 2 → L, J; 3 → L, X, V; 4 → L, M, J, V; 5 → L, M, X, V, S; 6 → L a S.

### 16.14 Mesociclo

El plan se versiona en mesociclos de **6 semanas**, igual a `DELOAD_CADA_SEMANAS` (§7).

### 16.15 Afinidad en la selección de ejercicios

Para cada hueco se elige el candidato con más afinidad; el desempate es por `slug`. Suman: patrón preferido del hueco, músculo preferido, músculo «natural» del patrón como primario (p. ej. pecho en empuje horizontal), favorito (+3), músculo prioritario (+2), historial del ejercicio (+1, permite cargas reales desde el primer día), carga en kg, multiarticular bilateral y barra en el hueco principal para entrenados. Restan: precaución en una zona limitada (−1,5 por zona), repetir el ejercicio en la semana (−0,75 por vez), unilateral en accesorios (−0,25, cuesta el doble de tiempo). Los pesos son heurísticos y se ajustaron revisando los planes de `docs/engine/ejemplos/`. Para llegar al suelo de un grupo, el relleno puede usar como último recurso una sesión de otros grupos (p. ej. gemelos al final del día de tirón).
