# ADR-0008: Analytics de progreso calculados al escribir

**Estado**: Aceptado, implementado (Fase 3; e2e comprueba que ningún GET escribe) · **Fecha**: 2026-11-09

## Contexto
`GET /analytics/progress` hace un upsert por ejercicio en cada lectura. Un GET no debe escribir.

## Decisión
Al guardar una serie o cerrar una sesión, dentro de la misma transacción se actualizan las tablas resumen `ExerciseE1rm`, `WeeklyMuscleVolume` y la adherencia semanal. Los GET solo leen. Las funciones de cálculo son puras y viven en `engine-rules`.

## Consecuencias
- **Más fácil:** lecturas baratas y predecibles; los cálculos se testean como funciones puras.
- **Más difícil:** una corrección de fórmula exige un script de recálculo (se incluye `pnpm analytics:rebuild`).

## Alternativas
- **Calcular en cada lectura con una consulta** (propuesto en la revisión de alcance). Pro: sin tablas extra. Contra: crece con el historial y mezcla lógica en SQL. Válida para v1 si se mide que es rápida; se mantiene on-write porque el prompt lo fija y el coste es bajo.
- **Estado actual.** Rechazada.

## Revisión
- Si el recálculo en escritura supera 50 ms en p95, mover a un job.
