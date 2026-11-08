# ADR-0002: Eliminar el worker BullMQ/Redis de v1

**Estado**: Propuesto · **Fecha**: 2026-11-09

## Contexto
`apps/worker` es una cola `pipos:placeholder` con un `console.log` y un test `expect(true)`. La API no le envía ningún trabajo. ADR-005 (histórico) lo describía como real. Generar un plan tarda (objetivo) menos de 200 ms en proceso, así que no necesita cola. v1 no tiene subida de vídeo de usuarios (ADR-0005), que sería el único trabajo asíncrono candidato.

## Decisión
**Eliminar `apps/worker`, BullMQ, ioredis y Redis** de v1. ADR-005 pasa a «Sustituido por ADR-0002». El README lo indica como pospuesto.

Factor decisivo: no existe ningún trabajo asíncrono real en v1; mantener la pieza solo añade infraestructura que operar y un test falso.

## Consecuencias
- **Más fácil:** despliegue con un solo proceso más Postgres; CI más rápido; sin Redis.
- **Más difícil:** si aparece un trabajo asíncrono (notificaciones push, procesado de media), hay que reintroducir una cola.
- **Requiere confirmación:** borra un módulo (principio 7). Queda cubierto por «APRUEBO fase 0».

## Alternativas
- **Mantenerlo con un job real** (p. ej. recalcular analytics). Contra: el recálculo cabe en la transacción de guardado (ADR-0008). Rechazada.
- **Sustituirlo por `pg-boss` sobre Postgres** cuando haga falta. Se deja como opción futura.
- **No hacer nada.** Contra: viola «nada falso». Rechazada.

## Revisión
- Reintroducir cola si un trabajo supera 1 s en p95 o necesita reintentos fuera de la petición.
