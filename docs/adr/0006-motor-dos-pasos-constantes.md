# ADR-0006: Motor en dos pasos con constantes en tabla configurable y citada

**Estado**: Propuesto · **Fecha**: 2026-11-09

## Contexto
El motor actual mezcla constantes en el código (`WEEKLY_SETS_FLOOR` sin usar, versión `'0.0.1'` en 3 sitios), ordena por UUID y tiene errores de dominio (`.some` en material, «compuesto» mal definido, scoring incompleto).

## Decisión
- Mantener el enfoque: **solución inicial por reglas → búsqueda local acotada** (iteraciones y tiempo máximos), determinista, sin aleatoriedad, desempate estable por clave explícita (no por UUID ni `localeCompare` dependiente de locale).
- **Todas las constantes en `engine-rules/src/config/programming.ts`**, tipadas, con un campo `source` que referencia `docs/engine/PROGRAMACION.md`. Un test falla si una constante no tiene fuente.
- `ENGINE_VERSION` único, exportado y guardado en cada versión de plan.
- Restricciones duras (material `.every`, limitaciones, vetados) se filtran antes; nunca se negocian en el scoring.
- Cada decisión produce un `rationale` con plantilla en castellano.
- Tests de propiedades con fast-check sobre los invariantes y casos límite enumerados; objetivo < 200 ms por plan.

## Consecuencias
- **Más fácil:** ajustar reglas sin tocar algoritmos; auditar cada número; explicar el plan.
- **Más difícil:** cada cambio de constante exige actualizar su fuente.
- **Deuda aceptada:** las reglas de tiempo por serie son heurísticas documentadas como tal.

## Alternativas
- **Solo reglas, sin búsqueda local** (propuesto en la revisión de alcance). Pro: más simple y explicable. Contra: la asignación de ejercicios a días con presupuesto de tiempo y volumen a la vez es un problema de optimización donde las reglas solas dejan huecos. Se mantiene la búsqueda local, pero acotada y con explicación de cada mejora.
- **Solver de programación lineal entera.** Contra: dependencia pesada y menos explicable. Rechazada para v1.

## Revisión
- Si la búsqueda local no mejora el score más de un 2 % en los 10 perfiles de ejemplo, eliminarla.
