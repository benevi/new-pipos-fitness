# ADR-0005: Catálogo de ejercicios como seed versionado; panel admin fuera de v1

**Estado**: Propuesto (cambia una decisión de alcance del prompt maestro) · **Fecha**: 2026-11-09

## Contexto
El prompt maestro mantiene «un panel admin mínimo para el catálogo y moderar media, protegido con roles». Hoy `/admin` está abierto a cualquiera. En v1 no hay contenido subido por usuarios, así que no hay nada que moderar, y el catálogo (80–150 ejercicios) lo mantiene el equipo.

## Decisión
- El catálogo vive como **seed versionado en git** (`apps/api/prisma/catalog/*.json`), validado con Zod en CI, con un test que detecta huecos de cobertura (patrón × material). Los cambios de catálogo son PRs revisados.
- Media en v1: imágenes o vídeos propios referenciados desde el seed; sin subida ni moderación.
- **Se eliminan los endpoints `/admin` en Fase 1.** Aun así se añade `role` (USER, ADMIN) a `User` y un `RolesGuard` reutilizable, para que la primera ruta admin futura nazca protegida.

Factor decisivo: un PR revisado es mejor control de calidad del catálogo que un formulario web, y elimina por completo la superficie de ataque crítica detectada.

## Consecuencias
- **Más fácil:** catálogo auditable con historial; cero endpoints de escritura administrativos.
- **Más difícil:** editar el catálogo exige un desarrollador y un despliegue.
- **Requiere confirmación:** elimina un módulo y contradice el alcance del prompt. Decisión de producto → la confirma Victor.

## Alternativas
- **Panel admin mínimo con roles (prompt original).** Pro: edición sin despliegue. Contra: UI, auth de roles, tests y superficie de ataque para un catálogo que cambia poco. Alternativa válida si Victor la prefiere.
- **No hacer nada.** Contra: `/admin` abierto es crítico. Rechazada.

## Revisión
- Reintroducir panel si el catálogo cambia más de una vez por semana o lo editan personas no técnicas.
