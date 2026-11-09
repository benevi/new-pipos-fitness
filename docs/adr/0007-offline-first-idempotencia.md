# ADR-0007: Registro de entrenamientos offline-first con idempotencia por UUID de cliente

**Estado**: Aceptado; parte servidor implementada en la Fase 3 (idempotencia por clientId, última escritura gana); cola móvil en la Fase 4b · **Fecha**: 2026-11-09

## Contexto
En el gimnasio la cobertura falla. Hoy, si se mata la app o no hay red, se pierden series. El riesgo de producto más dañino es perder o duplicar series al sincronizar.

## Decisión
- La app guarda cada serie primero en una **cola local persistente con drift (SQLite)**, con un UUID v4 generado en el cliente.
- Un sincronizador envía la cola en orden cuando hay red, con reintentos exponenciales.
- La API trata el UUID como **clave de idempotencia** (`SetLog.clientId @unique`): reenviar la misma serie devuelve la existente, no crea otra.
- Conflicto de edición: gana la última escritura con `updatedAt` del cliente; borrado = marca lógica.

Se elige drift frente a hive por tener SQL, migraciones y tipado, útiles para la cola y para cachear el plan.

## Consecuencias
- **Más fácil:** registrar sin red; resistir el cierre de la app.
- **Más difícil:** dos fuentes de verdad temporales; hay que testear la sincronización (widget test offline → sync).

## Alternativas
- **hive.** Más simple, pero sin consultas ni migraciones robustas. Rechazada.
- **Solo online (estado actual).** Contra: pérdida de datos. Rechazada.

## Revisión
- Si aparecen conflictos multi-dispositivo reales, pasar a resolución por campo.
