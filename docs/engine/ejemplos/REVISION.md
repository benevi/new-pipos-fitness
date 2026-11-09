# Revisión como entrenador de los 10 planes de ejemplo

Revisión hecha sobre los ficheros de esta carpeta (motor 2.0.0), con criterio de entrenador de fuerza basado en evidencia y las reglas de [PROGRAMACION.md](../PROGRAMACION.md). **No sustituye** la revisión por un entrenador titulado prevista antes del lanzamiento público (PLAN §7).

## Veredicto

**Sin problemas graves.** Los 10 planes son seguros para su perfil, respetan material y limitaciones, ordenan bien los ejercicios, entrenan cada grupo ≥ 2 veces por semana cuando hay material para ello y explican cada decisión con datos del usuario. Donde el material o el tiempo no permiten cumplir un mínimo, el plan lo dice con un aviso concreto en lugar de dejar un hueco silencioso.

## Lo que está bien

- **Split y frecuencia.** 2-3 días cuerpo completo, 4 torso/pierna, 5 híbrido y 6 PPL; todos los grupos aparecen en ≥ 2 sesiones (excepto donde no hay ningún ejercicio posible, que se avisa: tirón sin material en el perfil 1).
- **Selección.** Básicos con barra para intermedios y avanzados en gimnasio (sentadilla, peso muerto, press de banca, remo, press militar); variantes de mancuerna o banda en casa; nada de material que el usuario no tenga (I1 comprobado con fast-check en 200 perfiles aleatorios).
- **Lesiones.** Hombro (perfil 7): fuera press militar con barra, fondos, remo al mentón y press tras nuca; el empuje vertical se cubre con press de mancuernas marcado con precaución; el press principal pasa a ser el press en el suelo (menos rango, sin tag de hombro). Rodilla (perfil 9): fuera la sissy squat; las zancadas y la búlgara llevan nota de precaución y el cuádriceps se queda algo por debajo del suelo, con aviso: conservador, como debe ser. Lumbar (perfil 10): se prefiere el peso muerto rumano a una pierna y con banda frente al swing.
- **Prescripción.** Fuerza: 3-6 reps a RIR 2 con 3 min en los principales, 2-3 series, 3 series de aproximación en el primero y 1 en el resto de pesados; accesorios a 6-12. Hipertrofia: 8-12 / 10-15 a RIR 2 / 1. Principiantes: 8-12 a RIR 3 (ACSM 2009, Zourdos 2016). Resistencia: 15-25 con 60 s. Salud general: ≤ 3 series por ejercicio.
- **Cargas.** Con historial, la carga sale del e1RM (p. ej., press de banca 96 kg desde un e1RM de 112 kg para 3 reps a RIR 2); el peso muerto se marca como estimación (Epley lo infraestima); sin historial, «elige un peso con el que hagas N repeticiones dejando M en reserva».
- **Prioridades y favoritos.** Glúteos prioritarios (perfil 3) llegan al techo (16) y el hip thrust favorito se mantiene; deltoides lateral y bíceps (perfil 6) a 24 y 21 series, con un único aislamiento por delante del multiarticular.
- **Tiempo.** Todas las sesiones caben en el presupuesto ± 10 %; cuando sobra mucho tiempo (avanzados con 90 min) se avisa y se explica por qué no se rellena: más series superarían el techo de volumen útil.

## Problemas encontrados en la revisión y corregidos en el motor

1. **Sesgo hacia variantes difíciles.** La afinidad premiaba que el nivel mínimo del ejercicio coincidiera con el del usuario: un intermedio recibía press con agarre cerrado en vez de press de banca, y un avanzado buenos días como bisagra principal o sissy squat como extensión de rodilla. Se elimina ese bonus y se premia el músculo «natural» del patrón y la carga en kg.
2. **La búsqueda local degradaba ejercicios.** Cambiaba peso muerto por peso muerto rumano a una pierna sin carga para ganar variedad o balance. Se le pusieron salvaguardas y después se retiró (ver abajo).
3. **Redundancia.** Dos curls o tres elevaciones de talones en la misma sesión. Ahora un grupo de sustitución por sesión (dos si es para un músculo prioritario).
4. **Orden con prioridades.** Con bíceps y deltoides prioritarios salían tres curls antes del remo. Ahora solo un aislamiento prioritario puede adelantarse, y solo si no hay un multiarticular que ya trabaje ese músculo.
5. **Relleno de tiempo con core y gemelos.** Con tiempo libre se acumulaban hasta 20 series de core. Ahora core y gemelos solo se llevan al suelo (salvo prioridad) y como mucho 2 ejercicios de core por sesión.
6. **El balance tirón/empuje recortaba pecho por debajo del suelo** (vía búsqueda local). El ratio ya no penaliza empujar si la espalda está en su techo, y la búsqueda local se retiró.
7. **Deltoides anterior inflaba «hombros».** Contaba como hombro en cada press y saturaba el techo. Ahora el grupo hombros es deltoides lateral + posterior (el anterior recibe de sobra en los press).
8. **Carga mal tipada.** El remo invertido en barra y las dominadas asistidas en máquina se trataban como ejercicios con carga en kg (en la máquina, más kg = más fácil). El catálogo lleva ahora `loadType` explícito.
9. **Favorito eliminado.** El ajuste de techos quitaba el hip thrust favorito con glúteos prioritarios. Ahora primero se recortan series y los favoritos y el trabajo prioritario se quitan los últimos.
10. **Sin aproximación en pesados.** En fuerza, press de banca y remo a 3-6 reps iban sin serie de aproximación. Ahora llevan una (N_SERIES_APROX_OTROS 0-1, §8).
11. **Suelo de volumen para fuerza y salud.** PROGRAMACION.md §1 (regla 4) acepta volumen bajo o moderado en estos objetivos: el suelo baja al de principiante (6) y el tiempo libre se usa para subir hacia el rango alto.
12. **Avisos más útiles.** Las sugerencias de material empiezan por lo barato (banda, barra de dominadas, mancuernas) y el aviso distingue entre falta de material, de nivel o una limitación.

## Puntos abiertos (no graves)

- **Sesiones cortas en avanzados con 90 min** (perfiles 5 y 6: 35-70 min). Es coherente con los techos de §1, pero conviene que la app ofrezca bajar los minutos en vez de mostrar el aviso cada semana.
- **Peso muerto convencional como secundario a 6-12 reps** el día de sentadilla pesada (perfil 4). Aceptable a RIR 2, pero un entrenador probablemente preferiría el rumano ese día; afinable con la afinidad por historial.
- **Dominadas asistidas a 15-20 reps** para un principiante de resistencia (perfil 8): exigente; valorar un tope de repeticiones en tirones verticales con peso corporal.
- **Sin material (perfil 1)** no hay tirón posible: el plan lo avisa y sugiere una banda. Recomendable que el onboarding sugiera una banda elástica a quien marque «sin material».
- **Pequeños déficits bajo el suelo** en perfiles de casa con 45-50 min (hombros, tríceps, isquios a 4,5-5 de 6; cuádriceps a 8 de 10 con lesión de rodilla): avisados y razonables.
- Los porcentajes de aproximación (50/70/85 %), la tolerancia del 10 % y los pesos del scoring son heurísticas de diseño (§16) pendientes de validar con usuarios reales.

## Búsqueda local: medida y retirada (ADR-0006)

| Perfil | Score inicial | Score final | Mejora |
|---|---|---|---|
| 1 | 0,6787 | 0,6959 | +2,54 % |
| 2 | 0,9335 | 0,9356 | +0,22 % |
| 3 | 0,9878 | 0,9990 | +1,14 % |
| 4 | 0,9631 | 0,9975 | +3,57 % |
| 5 | 0,9591 | 0,9639 | +0,50 % |
| 6 | 0,9212 | 0,9394 | +1,97 % |
| 7 | 0,9485 | 0,9830 | +3,64 % |
| 8 | 0,9106 | 0,9169 | +0,69 % |
| 9 | 0,9150 | 0,9506 | +3,89 % |
| 10 | 0,9481 | 0,9494 | +0,14 % |

Mejora media **1,83 %** (4 de 10 perfiles por encima del 2 %; máxima 3,89 %), por debajo del umbral del 2 % de ADR-0006: **se retiró**. Los planes de esta carpeta se regeneraron sin ella, solo con la solución por reglas. Al quitarla, el perfil 6 dejaba los gemelos en 10 de 12; se corrigió permitiendo que el relleno hasta el suelo use otra sesión como último recurso (gemelos al final del día de tirón). Tras la retirada, los perfiles 4, 7 y 9 quedan con déficits pequeños y avisados (isquios, gemelos o core a 9-9,5 de 10; cuádriceps a 8 de 10 con lesión de rodilla) y con avisos de balance tirón/empuje de 0,7-0,8; ninguno es grave.
