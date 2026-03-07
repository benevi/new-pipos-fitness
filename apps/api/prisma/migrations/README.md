# Migrations

Run from `apps/api`:

```bash
pnpm prisma:migrate
```

This creates/updates migrations. First time: ensure `DATABASE_URL` is set in `.env`.

Initial migration will create the `User` table. Created in Phase 1; apply when DB is available.
