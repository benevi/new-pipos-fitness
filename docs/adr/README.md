# Architecture Decision Records

Registro de decisiones de la reconstrucción (noviembre 2026). Sustituye a `docs/DECISIONS.md`, que queda como histórico. Los ADR antiguos que siguen vigentes (monorepo pnpm, lógica en funciones puras, contratos Zod, NestJS monolito modular, JWT con refresh rotativo) se dan por aceptados y no se repiten aquí.

Estado de todos: **Propuesto**, pendiente de «APRUEBO fase 0».

| ADR | Decisión |
|---|---|
| [0001](0001-reconstruccion-incremental.md) | Reconstrucción incremental sobre el repo actual, no reescritura desde cero |
| [0002](0002-eliminar-worker.md) | Eliminar el worker BullMQ/Redis de v1 |
| [0003](0003-retirar-coach-ia.md) | Retirar el coach de IA; explicabilidad del motor; interfaz `AiProvider` vacía |
| [0004](0004-nutricion-objetivos-diarios.md) | Nutrición reducida a objetivos diarios, sin catálogo de alimentos |
| [0005](0005-catalogo-seed-sin-panel-admin.md) | Catálogo como seed versionado; panel admin fuera de v1 |
| [0006](0006-motor-dos-pasos-constantes.md) | Motor por reglas con constantes en tabla configurable y citada (búsqueda local retirada tras medir) |
| [0007](0007-offline-first-idempotencia.md) | Registro offline-first con cola local e idempotencia por UUID de cliente |
| [0008](0008-analytics-al-escribir.md) | Analytics calculados al escribir, en tablas resumen |
| [0009](0009-migraciones-desde-cero.md) | Regenerar las migraciones en una única migración inicial |
| [0010](0010-e2e-postgres-real.md) | e2e contra Postgres real en CI, sin mocks de Prisma |
| [0011](0011-datos-salud-gdpr.md) | Datos de salud como categoría especial: consentimiento explícito, exportar y borrar |
| [0012](0012-flutter-version-fijada.md) | Versión de Flutter fijada en un único sitio y Android como objetivo primario |
