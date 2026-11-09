# Spec de producto: Pipos Fitness v1

**Estado:** propuesta de Fase 0 · **Fecha:** 2026-11-09 · **Responsable de producto:** Victor

## Problema
La mayoría de quienes entrenan fuerza sin entrenador siguen rutinas genéricas que no encajan con su material, su tiempo o sus molestias, y no saben cuándo ni cuánto subir la carga. El resultado es estancamiento, sesiones que no caben en su día y abandono en las primeras semanas. Las apps existentes o dan plantillas fijas o piden decidirlo todo al usuario.

## Objetivos (medibles)
1. **Plan útil en el primer uso:** el 90 % de quienes empiezan el onboarding reciben un plan en menos de 3 minutos.
2. **Planes correctos por construcción:** el 100 % de los planes generados cumplen los invariantes del motor (material, limitaciones, volumen mínimo, presupuesto de tiempo). Lo verifican tests de propiedades en CI.
3. **Registro sin fricción:** registrar una serie cuesta 2 toques o menos con los valores precargados; 0 series perdidas o duplicadas en sincronización (tests de offline e idempotencia).
4. **Progreso visible:** a las 4 semanas el usuario ve su e1RM y su volumen semanal por grupo frente al objetivo.
5. **Adherencia (indicador de producto):** el 40 % de los usuarios activos en la semana 1 siguen entrenando en la semana 4. Es una hipótesis, sin dato de partida.

## No-objetivos
- **Coach de IA conversacional:** sustituido por explicaciones deterministas (ADR-0003).
- **Menús y alimentos:** solo objetivos diarios de energía y macros (ADR-0004).
- **Panel web de administración:** el catálogo es un seed revisado en git (ADR-0005).
- **Contenido social, retos o wearables:** no mejoran el plan ni la progresión.
- **Poblaciones clínicas, menores, embarazo, rehabilitación:** la app asume un adulto sano y deriva a un profesional ante dolor.
- **iOS publicado:** se genera la plataforma, pero la QA y la tienda se posponen (ADR-0012).

## Personas
- **Laura, principiante (28):** 3 días, 45 min, gimnasio de barrio. Quiere saber qué hacer y que sea seguro.
- **Andrés, intermedio en casa (35):** mancuernas ajustables, banco y barra de dominadas; 4 días, 40 min; molestia de hombro. Quiere progresar sin agravarla.
- **Marta, avanzada (31):** 5–6 días, 75 min, gimnasio completo, historial largo. Quiere un volumen bien repartido y autorregulación.

## Historias de usuario (por prioridad)
1. Como principiante, quiero responder unas pocas preguntas y recibir un plan explicado, para empezar sin investigar.
2. Como usuario en el gimnasio, quiero ver qué toca hoy y registrar cada serie en segundos, también sin cobertura, para no interrumpir el entreno.
3. Como usuario, quiero que la app me diga cuándo subir peso o repeticiones y por qué, para progresar sin adivinar.
4. Como usuario con una molestia de hombro, quiero que el plan evite los patrones que me afectan y me ofrezca variantes, para entrenar sin agravarla.
5. Como usuario sin un aparato hoy, quiero cambiar un ejercicio por una alternativa equivalente, para no saltarme el trabajo de ese músculo.
6. Como usuario que ha faltado dos semanas, quiero que el plan se reajuste solo, para volver sin lesionarme ni frustrarme.
7. Como usuario que cambia de gimnasio, quiero actualizar mi material y recibir un plan nuevo sin perder mi historial.
8. Como usuario, quiero ver mi e1RM y mis series por grupo muscular, para saber si progreso.
9. Como usuario, quiero exportar o borrar todos mis datos, para mantener el control de mi información de salud.

## Requisitos

### P0 (sin esto no hay v1)
| Requisito | Criterio de aceptación |
|---|---|
| Onboarding con perfil completo | Objetivo, nivel, días (2–6), minutos (30–90), material (lista cerrada), limitaciones por zona (con consentimiento explícito), músculos prioritarios, vetados y favoritos; datos corporales opcionales. Datos inválidos → error en el campo, nunca valores por defecto. |
| Generación de plan determinista | Mismo input → mismo plan. Cumple todos los invariantes de `docs/engine/PROGRAMACION.md`. Menos de 200 ms. Explicación por plan, sesión y ejercicio en castellano. |
| Sesión de hoy | Calentamiento, series objetivo (reps, RIR, descanso, carga sugerida o «estimación inicial»), temporizador de descanso, registro de reps, carga y RIR, sustituir ejercicio. |
| Registro offline-first | Cola local persistente; sincronización idempotente por UUID de cliente; sobrevive al cierre de la app. |
| Progresión | Doble progresión, autorregulación por RIR, deload programado y reactivo, ajuste tras ausencia de 14 días o más. Las cargas propuestas son pesos que existen con el material (paso por material y discos por lado; ADR-0013, idea 1). |
| Sustitución | 3 alternativas ordenadas que respetan patrón, músculos, material y limitaciones. |
| Nueva versión de plan | Al cambiar el perfil se crea una versión nueva; la anterior y el historial se conservan. |
| Progreso | e1RM por ejercicio, series semanales por grupo frente al rango objetivo y adherencia, calculados al escribir. |
| Cuenta y privacidad | Registro, login, logout, refresh rotativo; exportar JSON; borrar cuenta con borrado real; aviso de que no es consejo médico. |
| Calidad | CI único en verde con e2e contra Postgres; cobertura de engine-rules ≥ 90 % y de servicios de la API ≥ 80 %. |

### P1 (mejora clara, siguiente iteración)
- Objetivos nutricionales diarios (tarjeta en ajustes), si se confirma ADR-0004.
- Recordatorio local del día de entreno (notificación del dispositivo, sin servidor). La API ya expone los días elegidos (`PATCH /me/profile/schedule`, ADR-0013).
- **Ideas recuperadas (ADR-0013; API hecha, app pendiente):**
  - nota fija por ejercicio (ajustes de máquina, agarre);
  - cambio de ejercicio permanente dentro del plan, heredado en las versiones siguientes;
  - ajuste de hoy: poco tiempo o volumen reducido, sin crear versión del plan (CUJ-9);
  - pausas planificadas que no cuentan en la adherencia ni como ausencia;
  - medidas corporales con tendencia de peso, IMC (OMS) y % de grasa estimado, con el consentimiento que las cubra (CUJ-10; el progreso para pérdida de grasa amplía CUJ-7).
- Monitor de dolor por zona y ejercicio: aplazado hasta tener texto de consentimiento, DPIA y revisión legal (ADR-0013).
- Gráficas de tendencia de e1RM.
- Inglés completo (el castellano es el idioma principal desde el día 1).

### P2 (diseñar para no impedirlo)
- iOS publicado.
- Proveedor de IA tras feature flag (diseño en ADR-0003).
- Panel de administración del catálogo.
- Sincronización multi-dispositivo con resolución por campo.

## Métricas de éxito
- **Adelantadas (semanas 1–2):** finalización del onboarding; tiempo hasta el primer plan; series registradas por sesión; tasa de errores de sincronización.
- **Retrasadas (semanas 4–12):** retención en la semana 4; sesiones completadas frente a planificadas; usuarios con e1RM al alza en su ejercicio principal.
- **Medición:** sin analítica de terceros en v1. Se calculan desde la BD propia con consultas agregadas y anónimas, y se documentan en `docs/METRICAS.md` en la Fase 5.

## Preguntas abiertas
| Pregunta | Quién | ¿Bloquea? |
|---|---|---|
| ¿Panel admin fuera de v1 (ADR-0005)? | Victor | No. Por defecto, fuera. |
| ¿Nutrición reducida o fuera (ADR-0004)? | Victor | No. Por defecto, reducida. |
| ¿Hay datos de producción que conservar? Se asume que no (ADR-0009). | Victor | Sí para la Fase 3. |
| DPIA y textos legales de consentimiento | Legal | Bloquea el lanzamiento público, no el desarrollo. |
| Revisión del catálogo y de los 10 planes de ejemplo por un entrenador titulado | Victor y un profesional externo | Bloquea el lanzamiento público. |
| Medios (vídeos o imágenes) del catálogo con licencia | Victor | No. v1 funciona con cues de texto. |

## Calendario y fases
Ver `docs/PLAN_RECONSTRUCCION.md`. Dependencias: Fase 2 (motor) es independiente de la 1. La Fase 3 depende de las dos. La Fase 4 depende de los contratos de la 3.
