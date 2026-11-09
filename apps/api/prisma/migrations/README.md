# Migraciones

Migración inicial (`*_init`) generada desde `schema.prisma` (ADR-0009) y migraciones posteriores
(p. ej. `*_minimizacion_ip_user_agent`, Fase 5). Al final del
`migration.sql` de la inicial hay un bloque `-- RAW:` escrito a mano con lo que Prisma no expresa
(CHECK, índices únicos parciales); ver `docs/MODELO_DATOS.md` §6.

Reglas:

- Nunca editar una migración ya aplicada: cada cambio es una migración nueva
  (`pnpm --filter @pipos/api prisma:migrate --name <cambio>`).
- `migration_lock.toml` se versiona.
- CI comprueba que no hay deriva entre migraciones y schema:

```bash
pnpm --filter @pipos/api prisma:diff   # usa DATABASE_URL_SHADOW
```
