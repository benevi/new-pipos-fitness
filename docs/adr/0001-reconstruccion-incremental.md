# ADR-0001: Reconstrucción incremental sobre el repositorio actual

**Estado**: Propuesto · **Fecha**: 2026-11-09 · **Decisores**: Victor (producto), equipo de reconstrucción

## Contexto
El análisis de noviembre 2026 (`docs/ANALISIS_ESTADO_2026-11.md`) muestra una base de capas sana (contracts → engine-rules → API), auth razonable y una app Flutter con piezas que funcionan, junto con fallos graves: CI roto, `/admin` abierto, motor con errores de dominio, worker y coach falsos. No hay datos de producción conocidos.

## Decisión
Reconstruiremos **sobre el repositorio actual**, por fases con PRs pequeños, conservando la arquitectura de capas y reescribiendo por dentro los módulos defectuosos (motor, persistencia de planes, auth de la app). Se trabaja en una rama por fase.

El factor decisivo: lo que está mal está **localizado** (módulos concretos), mientras que lo que está bien es **transversal** (estructura, contratos, tooling). Reescribir desde cero tiraría lo transversal para arreglar lo local.

## Consecuencias
- **Más fácil:** conservar historial, tooling, tests útiles y piezas Flutter ya probadas (refresh deduplicado, secure storage).
- **Más difícil:** convivir temporalmente con código viejo; hay que borrar con disciplina lo que se sustituye.
- **Deuda aceptada:** algunos nombres y estructuras heredados se mantienen si no dañan.

## Alternativas
- **Reescritura desde cero en repo nuevo.** Pro: sin lastre. Contra: pierde lo que funciona, más tiempo hasta el primer verde. Rechazada.
- **No hacer nada / parchear solo lo crítico.** Contra: el motor seguiría generando planes incorrectos, que es el núcleo del producto. Rechazada.

## Revisión
- Si en Fase 2 la reescritura del motor toca más del 80 % de `engine-rules`, se acepta como reescritura de ese paquete sin cambiar esta decisión para el resto.
