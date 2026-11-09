# ADR-0014: Guía de ejercicios (músculos, ficha, mapa muscular y vídeos)

**Estado**: Aceptado · **Fecha**: 2026-11-09 · **Decisores**: Victor (producto)

## Contexto
El usuario ve el nombre y las claves técnicas de cada ejercicio, pero no qué músculos trabaja ni una descripción de cómo se hace. El catálogo ya tiene los músculos de cada ejercicio (principales y secundarios, los usa el motor), y la base de datos tiene columnas de descripción y una tabla `ExerciseMedia` sin usar. El plan detallado está en [PLAN_GUIA_EJERCICIOS.md](../PLAN_GUIA_EJERCICIOS.md).

La app previa analizada en [IDEAS_EL_PLAN.md](../IDEAS_EL_PLAN.md) tenía estas funciones, pero con contenido deducido del nombre del ejercicio y enlaces a búsquedas de YouTube. ADR-0013 rechazó esas dos formas y dejó como «más adelante» los medios de técnica curados y el mapa de calor.

## Decisión
Se aceptan las cuatro funciones del plan, por fases, con las condiciones de su sección 3:

1. **Músculos visibles** en Hoy, Plan y al cambiar ejercicio, a partir de los datos del catálogo.
2. **Ficha del ejercicio** con descripción, músculos, claves técnicas, errores comunes, material y nivel, disponible sin conexión para el plan vigente.
3. **Biblioteca por músculo** con figura del cuerpo y vista de lista equivalente, más **mapa de calor** de las series de la semana en Progreso.
4. **Vídeos concretos y revisados**, abiertos fuera de la app.

Pasan de «más adelante» a aceptados (actualiza ADR-0013): medios de técnica curados y mapa de calor. Siguen rechazados la guía deducida del nombre y los enlaces a búsquedas.

### Respuestas a las preguntas abiertas del plan (sección 6)
| Pregunta | Decisión |
|---|---|
| Quién escribe las 144 descripciones | Las redacta el equipo de desarrollo, ejercicio a ejercicio, y entran por PR. Un entrenador titulado las revisa antes del lanzamiento público (ya era requisito del catálogo, SPEC_V1). No bloquea el desarrollo. |
| Vídeos propios o de terceros | **De terceros, enlazados** (YouTube), abiertos fuera de la app. Cada vídeo concreto lo elige y aprueba una persona; la Fase 4 publica vídeos solo cuando haya esa selección revisada. El código puede prepararse antes. |
| Criterio de selección de canales | Autor con titulación o entidad reconocida (federaciones, universidades, colegios profesionales); sin publicidad de suplementos ni promesas de resultados en el propio vídeo; preferencia por castellano; con segundo de inicio y fin si el vídeo es largo. |
| Imágenes propias o GIF | No en esta iteración. La Fase 4 puede salir solo con vídeos. |
| Figura del cuerpo | **Dibujo propio en SVG**, estilizado, delante y detrás, con una región por cada uno de los 19 músculos del catálogo. Sin derechos de terceros. |
| Inglés del contenido nuevo | Aparte, junto con la deuda «explicaciones del motor solo en español» (#29). |

## Consecuencias
- **Más fácil:** el usuario entiende por qué hace cada ejercicio y cómo hacerlo, sin salir de la app; el mapa de calor hace visible el volumen semanal.
- **Más difícil:** hay que mantener contenido (descripciones y vídeos) además de código; un vídeo de terceros puede desaparecer (se mitiga con `media:check` antes de cada release y sin botón si no hay vídeo).
- **Privacidad:** no se embebe reproductor de terceros; abrir YouTube fuera de la app no envía datos del usuario. Si algún día se embebe, se usará `youtube-nocookie.com` y se actualizarán la política de privacidad y la DPIA.

## Alternativas
- **Contenido deducido del nombre del ejercicio (como la app previa):** falla en silencio y no es contenido por ejercicio. Rechazada.
- **Enlace a una búsqueda de YouTube:** contenido sin revisar que cambia cada día. Rechazada.
- **Vídeos propios grabados:** mejor control, pero coste alto. Se puede reconsiderar más adelante.

## Revisión
- Reabrir si los vídeos de terceros desaparecen con frecuencia (más de un 10 % en un `media:check`) o si se decide grabar vídeos propios.
