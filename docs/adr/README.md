# Architecture Decision Records

Registro de decisiones de la reconstrucción (noviembre 2026). Sustituye a [`docs/archivo/DECISIONS.md`](../archivo/DECISIONS.md), que queda como histórico. Los ADR antiguos que siguen vigentes (monorepo pnpm, lógica en funciones puras, contratos Zod, NestJS monolito modular, JWT con refresh rotativo) se dan por aceptados y no se repiten aquí.

Fase 0 aprobada. Estado de cada ADR en su cabecera; resumen en la última columna.

| ADR | Decisión | Estado |
|---|---|---|
| [0001](0001-reconstruccion-incremental.md) | Reconstrucción incremental sobre el repo actual, no reescritura desde cero | Aceptado |
| [0002](0002-eliminar-worker.md) | Eliminar el worker BullMQ/Redis de v1 | Aceptado, implementado |
| [0003](0003-retirar-coach-ia.md) | Retirar el coach de IA; explicabilidad del motor; interfaz `AiProvider` vacía | Aceptado, implementado |
| [0004](0004-nutricion-objetivos-diarios.md) | Nutrición reducida a objetivos diarios, sin catálogo de alimentos | Aceptado, implementado |
| [0005](0005-catalogo-seed-sin-panel-admin.md) | Catálogo como seed versionado; panel admin fuera de v1 | Aceptado |
| [0006](0006-motor-dos-pasos-constantes.md) | Motor por reglas con constantes en tabla configurable y citada (búsqueda local retirada tras medir) | Aceptado, implementado |
| [0007](0007-offline-first-idempotencia.md) | Registro offline-first con cola local e idempotencia por UUID de cliente | Aceptado (servidor implementado; móvil en Fase 4b) |
| [0008](0008-analytics-al-escribir.md) | Analytics calculados al escribir, en tablas resumen | Aceptado, implementado |
| [0009](0009-migraciones-desde-cero.md) | Regenerar las migraciones en una única migración inicial | Aceptado, implementado |
| [0010](0010-e2e-postgres-real.md) | e2e contra Postgres real en CI, sin mocks de Prisma | Aceptado, implementado |
| [0011](0011-datos-salud-gdpr.md) | Datos de salud como categoría especial: consentimiento explícito, exportar y borrar | Aceptado (API implementada; DPIA pendiente) |
| [0012](0012-flutter-version-fijada.md) | Versión de Flutter fijada en un único sitio y Android como objetivo primario | Aceptado |
