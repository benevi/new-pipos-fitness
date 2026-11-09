# ADR-0004: Nutrición reducida a objetivos diarios

**Estado**: Propuesto · **Fecha**: 2026-11-09

## Contexto
La nutrición actual genera comidas que cuadran calorías pero no macros, asume 70 kg si falta el peso y devuelve un plan falso de 2000 kcal ante datos inválidos. Mantiene un catálogo `Food` y plantillas de comidas con cascadas que destruyen versiones antiguas.

## Decisión
Nutrición v1 = **una tarjeta de objetivos diarios**: kcal (Mifflin-St Jeor × factor de actividad ± ajuste por objetivo), proteína, grasa y carbohidratos, con su explicación y fuente. Sin generación de comidas, sin catálogo de alimentos. Datos incompletos o fuera de rango → **error de validación**, nunca valores por defecto. Constantes y fuentes en `docs/engine/PROGRAMACION.md`.

Se eliminan `Food`, `MealTemplate*`, `NutritionMeal*` y sus endpoints y pantallas.

## Consecuencias
- **Más fácil:** un cálculo puro y testeable; menos tablas; menos datos personales.
- **Más difícil:** el usuario que quiera menús tiene que buscarlos fuera.
- **Requiere confirmación:** borra tablas y el seed de alimentos.

## Alternativas
- **Quitar la nutrición por completo de v1.** Pro: menos datos de salud y menos alcance (propuesto por la revisión de alcance). Contra: el usuario con objetivo de pérdida de grasa queda sin orientación energética. Se mantiene como alternativa viable si se prefiere un v1 aún más estrecho.
- **Mantener generación de comidas corregida.** Contra: mucho trabajo sin relación con el objetivo de entrenamiento. Rechazada.

## Revisión
- Revisar tras v1 según uso real de la tarjeta.
