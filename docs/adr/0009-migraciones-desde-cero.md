# ADR-0009: Regenerar las migraciones en una única migración inicial

**Estado**: Propuesto · **Fecha**: 2026-11-09

## Contexto
Las migraciones mezclan fechas de 2024 y 2026, una de ellas recoge de golpe todas las tablas de planes, entrenamientos y nutrición (señal de `db push` previo), borra un índice necesario, y `migration_lock.toml` está ignorado. El modelo de datos cambia mucho (ver `docs/MODELO_DATOS.md`).

## Decisión
Borrar `prisma/migrations/*` y generar **una migración inicial limpia** desde el nuevo `schema.prisma`; versionar `migration_lock.toml`. A partir de ahí, migraciones incrementales normales, y CI comprueba con `prisma migrate diff` que el esquema y las migraciones coinciden.

**Supuesto a confirmar:** no hay base de datos de producción ni datos reales que conservar. Si los hubiera, se sustituye por una migración de transición.

## Consecuencias
- **Más fácil:** historial de esquema limpio y reproducible.
- **Más difícil:** cualquier BD local existente hay que recrearla (`prisma migrate reset`).

## Alternativas
- **Migraciones incrementales sobre las actuales.** Contra: arrastra incoherencias. Rechazada salvo que existan datos reales.
