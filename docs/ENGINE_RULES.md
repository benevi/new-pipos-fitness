# Reglas del motor

Este documento ya no describe el motor; se mantiene como puntero.

- **Reglas, constantes y fuentes:** [engine/PROGRAMACION.md](engine/PROGRAMACION.md). Es la única fuente de los números; las heurísticas de diseño del motor v2 están en su §16.
- **Invariantes, casos límite y modos de fallo:** [engine/INVARIANTES.md](engine/INVARIANTES.md).
- **Implementación:** `packages/engine-rules` (constantes en `src/config/programming.ts`, `ENGINE_VERSION = 2.0.0`), catálogo en `packages/catalog`, contratos en `packages/contracts` (`engineV2`).
- **Planes de ejemplo y revisión:** [engine/ejemplos/](engine/ejemplos/README.md).
- **Decisión de diseño:** [ADR-0006](adr/0006-motor-dos-pasos-constantes.md).
