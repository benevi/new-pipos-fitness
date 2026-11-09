# Despliegue de la API en Vercel + Neon

La API corre como una función de Vercel en Fráncfort (`fra1`) contra Postgres 16 en Neon (`aws-eu-central-1`). Los datos se quedan en la UE.

## Cómo está montado
- **Proyecto de Vercel** con *Root Directory* `apps/api`, sin framework. `vercel.json` reescribe todas las rutas a `api/index.js`.
- `api/index.js` carga `dist/serverless.js`. Ese fichero crea la app Nest una vez por instancia, con la misma `configureApp` que `main.ts`.
- **Build:** el script `vercel-build` de `apps/api/package.json`:
  1. Compila los paquetes del workspace.
  2. Ejecuta `prisma generate`.
  3. Aplica las migraciones (`prisma migrate deploy`).
  4. Siembra el catálogo, que es idempotente.
  5. Ejecuta `nest build`.

  Las migraciones van por `DATABASE_URL_DIRECT` (conexión directa) porque el *pooler* de Neon no admite los bloqueos de `migrate`.

## Variables de entorno (solo en Production)
| Variable | Valor |
|---|---|
| `NODE_ENV` | `production` |
| `DATABASE_URL` | URL del *pooler* de Neon con `sslmode=require&pgbouncer=true&connection_limit=1` |
| `DATABASE_URL_DIRECT` | URL directa de Neon (`sslmode=require`), solo para migrar en el build |
| `JWT_ACCESS_SECRET` | Aleatorio de 64 bytes, generado al desplegar y sin copia en el repo |
| `TRUST_PROXY_HOPS` | `1`: Vercel pone la IP real del cliente en `X-Forwarded-For` |
| `THROTTLE_STORE` | `postgres`: el rate limiting se comparte entre instancias |
| `CORS_ORIGINS` | Vacío: la app móvil no usa CORS |

Las previews están desactivadas: cada build migra la base de datos de producción.

## Comprobar
```bash
curl -s https://<dominio>/health/ready
```
