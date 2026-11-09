# ADR-0006: Motor en dos pasos con constantes en tabla configurable y citada

**Estado**: Aceptado (búsqueda local retirada tras medir: +1,83 % medio en 10 perfiles, umbral 2 %) · **Fecha**: 2026-11-09

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

## Resultado de la medición (Fase 2, 2026-11-09)
Score de la solución por reglas frente al score tras la búsqueda local (60 iteraciones, 40.000 evaluaciones como máximo), en los 10 perfiles de `docs/engine/ejemplos/`:

| Perfil | Inicial | Tras búsqueda local | Mejora |
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

Mejora media **1,83 %** (< 2 %): se aplica el criterio de revisión y **se elimina la búsqueda local** (código, constantes, tests y opción `enabled`). El generador es la solución determinista por reglas; el scoring se conserva para medir y explicar la calidad del plan. Durante la revisión de los ejemplos, la búsqueda local además tendía a degradar ejercicios o volumen para ganar balance o variedad, lo que obligó a ponerle salvaguardas: otro argumento para retirarla.
