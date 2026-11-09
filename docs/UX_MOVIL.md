# UX móvil de v1 (Fase 4b)

**Fecha:** 2026-11-09 · **Alcance:** `apps/mobile` · Base: SPEC_V1, CUJS, ADR-0007 (offline) y ADR-0011 (salud).

## 1. Mapa de navegación

```
/splash ── auth sin resolver o comprobando si hay plan
/login, /register ── sin sesión
/onboarding ── con sesión y sin plan (puerta: GET /plans/current → 404)
│  objetivo y nivel → días y minutos → material → consentimiento de salud
│  → [limitaciones, solo con consentimiento] → preferencias → datos corporales
│  → revisión → «Generar mi plan» → plan con su porqué → «Ver la sesión de hoy»
StatefulShellRoute (barra inferior; cada pestaña conserva su pila)
├── /today ─────────── Hoy (sesión de hoy, registro, descanso, cambio de ejercicio)
├── /plan ──────────── Plan (reparto y porqué, volumen, sesiones)
│   └── history ── :id ── historial de versiones → versión
├── /progress ──────── Progreso (e1RM, volumen semanal, adherencia)
└── /settings ──────── Ajustes
    └── profile ────── editar perfil (mismo cuestionario, sin consentimiento)
/workout-complete ── pantalla completa, sin barra
```

- Cuatro destinos, etiquetados con texto e icono (Material `NavigationBar`). Pulsar el destino activo vuelve a su raíz.
- Sin plan en caché y sin red, la puerta deja pasar: las pestañas muestran su estado sin conexión en vez de encerrar al usuario en el cuestionario.
- La barra de sincronización (pendientes, fallidas con «Reintentar», sin conexión) va sobre la navegación en todas las pestañas.

## 2. Estados por pantalla

| Pantalla | Carga | Vacío | Error | Sin red |
|---|---|---|---|---|
| Cuestionario | spinner con etiqueta «Generando tu plan…» en el botón | — | 422 → error en el campo y vuelta a su paso; aviso general arriba | aviso «Sin conexión»; no se pierde lo rellenado |
| Hoy | spinner | «Aún no tienes plan» + «Empezar el cuestionario» | mensaje + Reintentar | abre la última sesión guardada con el aviso «Sin conexión. Datos guardados el …»; si nunca se descargó, lo explica |
| Serie | — | — | «No se pudo enviar» por serie + Reintentar | icono «Pendiente de sincronizar»; la cola sobrevive al cierre |
| Cambiar ejercicio | spinner en la hoja | «No hay alternativas compatibles…» | mensaje + Reintentar | «Necesitas conexión para hacer esto.» |
| Fin | — | — | — | «Se sincronizará cuando haya conexión. No se perderá nada.» |
| Plan | spinner | igual que Hoy | mensaje + Reintentar | plan en caché con aviso |
| Historial | spinner | «Solo tienes una versión del plan.» | mensaje + Reintentar | error con Reintentar |
| Progreso | spinner | un único estado vacío si no hay nada; vacío por bloque si falta uno | mensaje + Reintentar | error con Reintentar |
| Nutrición | barra lineal | 422 `NUTRITION_INPUT_INCOMPLETE` → «Completa estos datos para calcularlos:» + campos + «Completar mis datos» | mensaje + Reintentar | idem |

## 3. Decisiones de interacción

- **Registro en 1 toque.** Cada serie llega precargada (reps = mínimo del rango o lo de la serie anterior; carga = sugerida o la anterior; RIR = objetivo). Confirmar es un botón de 56 dp. Cambiar reps o kg abre el teclado numérico; el RIR se elige en una hoja con 6 botones grandes. Con «estimación inicial» se escribe el peso una vez y las siguientes series lo heredan.
- **El entrenamiento empieza al confirmar la primera serie**, sin pantalla intermedia («El entrenamiento empieza al confirmar la primera serie»).
- **Descanso automático** al confirmar: barra inferior con cuenta atrás, «+15 s» y «Saltar». Vibración al terminar. Solo se anuncia por lector de pantalla al terminar, no cada segundo.
- **Movimiento reducido:** con `disableAnimations` la cuenta atrás es solo texto (sin barra de progreso). No hay animaciones decorativas; las transiciones son las de Material.
- **Cambio de ejercicio:** hoja con las 3 alternativas ordenadas y su porqué; un botón «Usar …» por opción. Necesita red (el servidor valida material y limitaciones).
- **Terminar** pide confirmación y dice cuántas series faltan; lo registrado se guarda siempre.
- **Consentimiento de salud** en un paso propio, con el texto versionado (`health-2026-11`), «Acepto» y «Continuar sin datos de salud» con el mismo peso visual. Si se salta, no se piden limitaciones ni peso/altura y la revisión explica la consecuencia. Retirarlo en Ajustes pide confirmación y explica qué se borra.
- **Borrar cuenta:** diálogo con icono de aviso, consecuencias en una frase, contraseña obligatoria y botón destructivo con el color de error. Contraseña incorrecta (403) → error en el campo; la sesión sigue abierta.
- **Cambiar el perfil** reutiliza el cuestionario. Si la API crea versión nueva, un diálogo lo explica («hemos creado la versión N… tu historial se conserva») y ofrece «Ver el plan».

## 4. Tono del texto

- Castellano de España, tuteo, frases cortas y verbos concretos: «Generar mi plan», «Confirmar serie 2», «Reintentar».
- Los errores dicen qué pasó y qué hacer: «Sin conexión y sin datos guardados. Conéctate una vez para descargar tu sesión.»
- Nada de culpa ni alarma; el aviso médico es neutro y está en Hoy, en el cuestionario, en la revisión y en Ajustes: «Pipos Fitness no da consejo médico. Si tienes dolor, una lesión o una condición de salud, consulta a un profesional antes de entrenar.»
- Las explicaciones del motor (rationale) vienen de la API en castellano; la UI las muestra plegadas tras «Por qué».

## 5. i18n

- Todo el texto de la UI está en `lib/l10n/app_es.arb` (plantilla) y `app_en.arb` (inglés completo, mismas claves; lo comprueba `flutter gen-l10n`).
- Los enums (objetivo, material, zonas, músculos, grupos, reparto, acciones de progresión…) se traducen con mensajes ICU `select` por su valor de cable.
- Números y fechas con `intl` según el idioma (`62,5 kg` / `62.5 kg`).
- **Limitación:** los nombres de ejercicio de la sesión y las explicaciones del motor solo existen en castellano en la API v1 (`nameEs`, `rationale`); en inglés se muestran en castellano. El buscador de ejercicios sí usa `nameEn`.

## 6. Accesibilidad: checklist y resultado

| Comprobación | Resultado | Cómo se verifica |
|---|---|---|
| Texto al 200 % sin desbordes en Hoy, Plan, Progreso, Ajustes y cuestionario (390 dp) | ✓ | `test/a11y/text_scale_test.dart` (un overflow hace fallar el test) |
| Objetivos táctiles ≥ 48 dp | ✓ | `androidTapTargetGuideline` en el mismo test |
| Todo control con etiqueta | ✓ | `labeledTapTargetGuideline` |
| Botones de icono con tooltip | ✓ | el test recorre todos los `IconButton` |
| Movimiento reducido | ✓ | test de descanso con `disableAnimations` |
| Contraste ≥ 4,5:1 (claro y oscuro) | ✓ | `test/app/tokens_contrast_test.dart`; solo colores de tokens/tema |
| Cabeceras semánticas | ✓ | títulos de pantalla, sección y ejercicio con `Semantics(header: true)` |
| Cambios anunciados | ✓ | errores de campo, estado de sync, fin del descanso y resultados en `liveRegion` |
| El color no es el único portador de significado | ✓ | barras de volumen y sparkline con etiqueta semántica textual; estado de cada serie con icono + texto |
| Opciones excluyentes | ✓ | `inMutuallyExclusiveGroup` + `selected` en objetivo y nivel |
| Lector de pantalla en dispositivo real (TalkBack) | pendiente | no hay SDK de Android en este entorno; queda para la QA de la Fase 5 |

## 7. Skills consultadas

`anthropic-skills:mobile-native` (orientado a web móvil; de él se aplican la respuesta inmediata al toque y los teclados numéricos). El resto de pautas (formularios, errores, estados vacíos, cargas, movimiento reducido, navegación, i18n y a11y) se aplicaron con criterio propio para no gastar contexto; el resultado verificable está en la tabla de arriba.

## 8. Limitaciones conocidas

- Editar o borrar una serie ya registrada no tiene UI (la API sí: `PATCH/DELETE /workouts/:id/sets/:clientId`).
- Tras terminar sin red, Hoy vuelve a mostrar la sesión en caché hasta que haya conexión y la API dé la siguiente.
- El cambio de ejercicio requiere red.
- Sin notificaciones del descanso con la app en segundo plano.
