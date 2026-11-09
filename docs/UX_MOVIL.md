# UX móvil de v1 (Fase 4b)

**Fecha:** 2026-11-09 · **Alcance:** `apps/mobile` · Base: SPEC_V1, CUJS, ADR-0007 (offline), ADR-0011 (salud) y ADR-0013 (ideas recuperadas).


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
├── /progress ──────── Progreso: pestañas «Entreno» (e1RM, volumen, adherencia) y «Cuerpo» (medidas, ADR-0013)
│   └── (pantalla completa) añadir medidas
└── /settings ──────── Ajustes
    ├── profile ────── editar perfil (mismo cuestionario, sin consentimiento)
    └── schedule ───── días de entreno, pausas y recordatorio local (ADR-0013)
/workout-complete ── pantalla completa, sin barra
```

- Cuatro destinos, etiquetados con texto e icono (Material `NavigationBar`). Pulsar el destino activo vuelve a su raíz.
- Sin plan en caché y sin red, la puerta deja pasar: las pestañas muestran su estado sin conexión en vez de encerrar al usuario en el cuestionario.
- La barra de sincronización (pendientes, fallidas con «Reintentar», sin conexión) va sobre la navegación en todas las pestañas.
- Entrar sin red usa el usuario guardado (id y correo, también junto a los tokens). Si de una sesión antigua solo queda el id, Ajustes muestra «Sin conexión: tu correo aparecerá al recuperar la red» en lugar del correo, hasta revalidar la sesión (#26).

## 2. Estados por pantalla

| Pantalla | Carga | Vacío | Error | Sin red |
|---|---|---|---|---|
| Cuestionario | spinner con etiqueta «Generando tu plan…» en el botón | — | 422 → error en el campo y vuelta a su paso; aviso general arriba | aviso «Sin conexión»; no se pierde lo rellenado |
| Hoy | spinner | «Aún no tienes plan» + «Empezar el cuestionario» | mensaje + Reintentar | abre la última sesión guardada con el aviso «Sin conexión. Datos guardados el …»; si nunca se descargó, lo explica |
| Serie | — | — | «No se pudo enviar» por serie con el motivo («La API no la acepta: …») + «Reintentar» y «Descartar» (con confirmación) | icono «Pendiente de sincronizar»; la cola sobrevive al cierre |
| Cambiar ejercicio | spinner en la hoja | «No hay alternativas compatibles…» | mensaje + Reintentar | alternativas guardadas con la sesión de hoy y aviso; el cambio de hoy va a la cola («Cambio a … guardado. Se enviará al recuperar la conexión.»); fijarlo: «Fijar el cambio en el plan necesita conexión…»; sin copia guardada: «Necesitas conexión para hacer esto.» |
| Fin | — | — | — | «Se sincronizará cuando haya conexión. No se perderá nada.» |
| Plan | spinner | igual que Hoy | mensaje + Reintentar | plan en caché con aviso |
| Historial | spinner | «Solo tienes una versión del plan.» | mensaje + Reintentar | error con Reintentar |
| Progreso | spinner | un único estado vacío si no hay nada; vacío por bloque si falta uno | mensaje + Reintentar | error con Reintentar |
| Nutrición | barra lineal | 422 `NUTRITION_INPUT_INCOMPLETE` → «Completa estos datos para calcularlos:» + campos + «Completar mis datos» | mensaje + Reintentar | idem |
| Nota fija (Hoy) | — | «Añadir nota» | — | se guarda en la cola y se ve con el icono «Pendiente de sincronizar» |
| ¿Poco tiempo hoy? | spinner en el botón «Ver cómo queda» | sin elegir nada: «Elige un tiempo o activa el volumen reducido.» | mensaje en la hoja | «Necesitas conexión para hacer esto.»; una vez aceptada, la sesión ajustada queda en caché |
| Días y pausas | barra lineal | «No tienes pausas planificadas.» | snackbar con el error (422 → «elige N como mucho») | «Necesitas conexión para hacer esto.»; el recordatorio usa las pausas en caché |
| Cuerpo | spinner | sin consentimiento: explicación + «Leer y aceptar»; sin medidas: cómo pesarse | mensaje + Reintentar | última copia en caché; las medidas nuevas van a la cola |

## 3. Decisiones de interacción

- **Registro en 1 toque.** Cada serie llega precargada (reps = mínimo del rango o lo de la serie anterior; carga = sugerida o la anterior; RIR = objetivo). Confirmar es un botón de 56 dp. Cambiar reps o kg abre el teclado numérico; el RIR se elige en una hoja con 6 botones grandes. Con «estimación inicial» se escribe el peso una vez y las siguientes series lo heredan.
- **El entrenamiento empieza al confirmar la primera serie**, sin pantalla intermedia («El entrenamiento empieza al confirmar la primera serie»).
- **Descanso automático** al confirmar: barra inferior con cuenta atrás, «+15 s» y «Saltar». Vibración al terminar. Solo se anuncia por lector de pantalla al terminar, no cada segundo. Si la app pasa a segundo plano, una notificación local «Descanso terminado» avisa al acabar (solo con el permiso de notificaciones ya concedido; no se pide aquí) y se cancela al volver o al saltar el descanso (#24).
- **Movimiento reducido:** con `disableAnimations` la cuenta atrás es solo texto (sin barra de progreso). No hay animaciones decorativas; las transiciones son las de Material.
- **Cambio de ejercicio:** hoja con las 3 alternativas ordenadas y su porqué; un botón «Usar …» por opción. Las alternativas se guardan con la sesión de hoy, así que funciona sin red (#23): el cambio va a la cola offline, Hoy lo muestra al momento con «Cambio pendiente de enviar» (sin la carga sugerida del original, que no vale para el sustituto) y se envía antes que las series del sustituto. Fijarlo en el plan necesita red.
- **Terminar** pide confirmación y dice cuántas series faltan; lo registrado se guarda siempre.
- **Abandonar entrenamiento.** Bajo «Terminar», «Abandonar entrenamiento» (en color de error, 48 dp) pide confirmación y explica que lo registrado no contará; funciona sin red (la cola envía el abandono). Si el servidor cerró el entrenamiento por su cuenta (abandono automático tras 12 h sin actividad), Hoy lo explica con cuántas series no se subieron y «Entendido».
- **Plan cambiado con un entrenamiento en cola.** Si el plan cambió mientras un entrenamiento esperaba para empezar en el servidor, la app lo reapunta a la sesión vigente; si ya tenía series, Hoy avisa de que son de la sesión anterior y ofrece descartarlo (se conserva en el móvil hasta entonces).
- **Serie rechazada (#21).** Si la API rechaza una serie de forma permanente (400/422, p. ej. un ejercicio que no es el del hueco), la fila muestra el motivo bajo el resumen y dos acciones de 48 dp: «Reintentar» y «Descartar». Descartar pide confirmación («Se quitará de este móvil y no contará en el entrenamiento») y la quita de la cola; si pudo llegar al servidor (confirmada o con un intento de resultado desconocido) se envía además `DELETE`. Después, Terminar ya no la espera.
- **Corregir o borrar una serie (#22).** Cada serie registrada tiene un menú «Opciones de la serie N» (48 dp, con tooltip) con «Editar» y «Borrar». Editar abre una hoja con reps, kg (coma o punto, como al registrar) y RIR en chips; «Guardar cambios» se ve al instante con el icono «Pendiente de sincronizar». Borrar pide confirmación y la oculta al momento. Las dos pasan por la cola offline: si la serie aún no se había enviado, la edición viaja en el propio `POST` (o se quita sin petición); si ya estaba en el servidor, `PATCH` con `clientUpdatedAt` (gana la última escritura; si gana otra edición, la fila adopta la del servidor) o `DELETE`.
- **Consentimiento de salud** en un paso propio, con el texto versionado (`health-2026-11-v2` desde ADR-0013; quien aceptó `health-2026-11` conserva sus ámbitos y Ajustes le ofrece la versión nueva), «Acepto» y «Continuar sin datos de salud» con el mismo peso visual. Si se salta, no se piden limitaciones ni peso/altura y la revisión explica la consecuencia. Retirarlo en Ajustes pide confirmación y explica qué se borra.
- **Borrar cuenta:** diálogo con icono de aviso, consecuencias en una frase, contraseña obligatoria y botón destructivo con el color de error. Contraseña incorrecta (403) → error en el campo; la sesión sigue abierta.
- **Cambiar el perfil** reutiliza el cuestionario. Si la API crea versión nueva, un diálogo lo explica («hemos creado la versión N… tu historial se conserva») y ofrece «Ver el plan».
- **Tipografía.** Fuente del sistema de cada plataforma (Roboto en Android, San Francisco en iOS) vía `Typography.material2021`, sin fuentes empaquetadas. `AppTheme` fusiona la escala de `AppTypography` (tamaños, pesos, colores) sobre esa base, de modo que todos los estilos llevan `fontFamily`, y los estilos de botones, AppBar, pestañas y barra de navegación salen de ese `TextTheme` fusionado (nunca de `AppTypography` en crudo). Así no hay mezcla de familias en iOS. Lo comprueba `test/app/tokens_contrast_test.dart` (Android e iOS).

### Ideas recuperadas (ADR-0013)

- **Carga real y discos (idea 1).** Cada ejercicio con peso muestra su material y su paso («Barra · de 2,5 kg en 2,5 kg»). En las barras con peso conocido, «Discos» abre una hoja con la barra, los discos por lado y lo que no cuadra; al editar la carga, «−» y «+» la mueven un paso real y «Discos» recalcula sin red con la misma regla voraz que el motor.
- **Nota fija (idea 2).** Bajo el nombre del ejercicio: la nota o «Añadir nota». La hoja (≤ 280 caracteres) recuerda que una molestia se consulta con un profesional, no se apunta. Se guarda primero en la cola offline (gana la última escritura por `clientUpdatedAt`).
- **Cambio fijado (idea 3).** En la hoja de cambio, el interruptor «Usar siempre este cambio» fija el ejercicio en el plan en vez de cambiarlo solo hoy. Hoy y Plan lo marcan con una chincheta («Cambio fijado: en lugar de …»); Plan ofrece «Volver a …» y destaca el aviso `PINNED_SUBSTITUTION_DROPPED`. Necesita red.
- **¿Poco tiempo hoy? (idea 4, CUJ-9).** Solo antes de empezar. Chips de 20/30/45/60 min y/o «Volumen reducido»; vista previa con la duración estimada, los ejercicios quitados y su porqué (y aviso si ni lo esencial cabe) antes de «Empezar con este ajuste». Hoy muestra el aviso del ajuste y «Volver a la sesión completa» mientras no haya series. El ajuste viaja en `POST /workouts` al confirmar la primera serie, también sin red.
- **Días, pausas y recordatorio (idea 6).** Chips de lunes a domingo (como mucho los días por semana del plan; sin elegir, los del plan), lista de pausas con alta por rango de fechas (1-60 días) y borrado confirmado. Recordatorio **local** (sin push): interruptor + hora; antes del permiso del sistema (Android 13+) un diálogo explica para qué es; avisos inexactos para los próximos 14 días que se saltan las pausas y se reprograman al abrir la app y al cambiar algo. Hoy avisa de la pausa activa o del día de descanso (se puede entrenar igualmente).
- **Medidas (idea 7, CUJ-10).** Datos de salud con consentimiento por ámbitos: sin él, la pestaña solo explica y ofrece el texto vigente; con la versión anterior, solo el peso, y los perímetros piden aceptar `health-2026-11-v2`. Formulario con todas las medidas opcionales (al menos una), unidad, rango y «cómo medir» por campo; precarga el día porque el `PUT` lo sustituye entero. IMC y % de grasa llevan siempre «Estimación — no es un diagnóstico» y sus límites; el % de grasa no tiene categorías.

## 4. Tono del texto

- Castellano de España, tuteo, frases cortas y verbos concretos: «Generar mi plan», «Confirmar serie 2», «Reintentar».
- Los errores dicen qué pasó y qué hacer: «Sin conexión y sin datos guardados. Conéctate una vez para descargar tu sesión.»
- Nada de culpa ni alarma; el aviso médico es neutro y está en Hoy, en el cuestionario, en la revisión y en Ajustes: «Pipos Fitness no da consejo médico. Si tienes dolor, una lesión o una condición de salud, consulta a un profesional antes de entrenar.»
- Las explicaciones del motor (rationale) vienen de la API en castellano; la UI las muestra plegadas tras «Por qué».

## 5. i18n

- Todo el texto de la UI está en `lib/l10n/app_es.arb` (plantilla) y `app_en.arb` (inglés completo, mismas claves; lo comprueba `flutter gen-l10n`).
- Los enums (objetivo, material, zonas, músculos, grupos, reparto, acciones de progresión…) se traducen con mensajes ICU `select` por su valor de cable.
- Números y fechas con `intl` según el idioma (`62,5 kg` / `62.5 kg`; miles con punto: `2.350 kcal`), también dentro de los campos (kg en Hoy, medidas); al escribir se acepta coma o punto (`lib/shared/decimal_input.dart`).
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
| Contraste no textual ≥ 3:1: interruptores encendidos y apagados (borde y pulgar en `onSurfaceVariant`), iconos de estado | ✓ | `test/app/tokens_contrast_test.dart` |
| Cabeceras semánticas | ✓ | títulos de pantalla, sección y ejercicio con `Semantics(header: true)` |
| Cambios anunciados | ✓ | errores de campo, estado de sync, fin del descanso y resultados en `liveRegion` |
| El color no es el único portador de significado | ✓ | barras de volumen y sparkline con etiqueta semántica textual; estado de cada serie con icono + texto |
| Opciones excluyentes | ✓ | `inMutuallyExclusiveGroup` + `selected` en objetivo y nivel |
| Lector de pantalla en dispositivo real (TalkBack) | pendiente | no hay SDK de Android en este entorno; queda para la QA de la Fase 5 |
| Pantallas y hojas de ADR-0013 al 200 % (discos, nota, ajuste de hoy, días y pausas, Cuerpo, formulario de medidas) | ✓ | `test/a11y/text_scale_test.dart` |
| Recordatorio: permiso explicado antes de pedirlo | ✓ | `test/features/settings/schedule_test.dart` |

## 7. Skills consultadas

`anthropic-skills:mobile-native` (orientado a web móvil; de él se aplican la respuesta inmediata al toque y los teclados numéricos). El resto de pautas (formularios, errores, estados vacíos, cargas, movimiento reducido, navegación, i18n y a11y) se aplicaron con criterio propio para no gastar contexto; el resultado verificable está en la tabla de arriba.

ADR-0013 (móvil): no se cargaron skills adicionales (`vectorlab-ux-skills:forms`, `design:ux-copy`) por presupuesto de contexto; se siguieron los mismos patrones: error junto al campo y junto al botón que lo provoca, verbos concretos («Guardar medidas», «Empezar con este ajuste», «Volver a …»), explicación del permiso antes de pedirlo y «Estimación — no es un diagnóstico» en todo valor derivado.

## 8. Limitaciones conocidas

- Tras terminar sin red, Hoy vuelve a mostrar la sesión en caché hasta que haya conexión y la API dé la siguiente.
- El cambio de ejercicio sin red usa las alternativas guardadas ese día y no trae la carga sugerida del sustituto hasta sincronizar.
- La notificación del descanso en segundo plano es inexacta (Android puede retrasarla en reposo) y no se ha probado en un dispositivo real.
- Días de entreno, pausas y cambio fijado necesitan red (la API valida); la nota, las medidas, el cambio de ejercicio de hoy y las correcciones de series van por la cola offline.
- El recordatorio programa avisos para 14 días: si la app no se abre en ese tiempo, deja de avisar hasta la próxima apertura. No se ha probado en un dispositivo real (sin SDK de Android en este entorno).
- La hora del recordatorio y su interruptor se guardan solo en el dispositivo (no se sincronizan).
