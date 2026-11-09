# Fases de la reconstrucción

Plan completo en [PLAN_RECONSTRUCCION.md](PLAN_RECONSTRUCCION.md). Cada fase sale de su rama
`reconstruccion/fase-N-*` y se mezcla en `main` por PR con el CI en verde. El orden de los PR no
coincide con el de las fases porque la Fase 2 (paquete puro) y la 4a (base móvil) se hicieron en
paralelo.

| Fase | Nombre | Rama | PR | Contenido |
|---|---|---|---|---|
| 0 | Diagnóstico | `reconstruccion/fase-0-plan` | #1 | Análisis del estado, plan de reconstrucción, ADR-0001…0012, spec v1, CUJ, modelo de datos. |
| 1 | Parar el sangrado | `reconstruccion/fase-1-seguridad-ci` | #2 | CI único, e2e contra Postgres real, fuera `/admin`, entorno validado sin secretos por defecto, throttler, helmet, CORS, rotación de refresh tokens, propiedad de recursos, SECURITY.md. |
| 4a | App móvil: base | `reconstruccion/fase-4a-movil-base` | #3 | Plataformas y Flutter fijado, auth corregida, cola offline con drift. |
| 2 | Motor y catálogo | `reconstruccion/fase-2-motor` | #4 | Motor v2 con constantes citadas, progresión, sustituciones, catálogo seed, propiedades, 10 planes de ejemplo revisados; fuera el worker. |
| 3 | API y datos | `reconstruccion/fase-3-api` | #5 | Esquema y migración únicos, módulos v1, idempotencia, analítica al escribir, consentimiento/exportar/borrar, OpenAPI desde Zod, e2e de los CUJ-1..8. |
| 4b | App móvil v1 | `reconstruccion/fase-4b-movil-v1` | #6 | Pantallas de v1, i18n, accesibilidad, sincronización, integration test headless y APK en CI. |
| 5 | Cierre | `reconstruccion/fase-5-*` | este PR | Revisiones independientes y correcciones (RGPD, motor, analítica, catálogo), docs coherentes, archivo histórico, [checklist de despliegue](DEPLOY_CHECKLIST.md) y [deuda técnica](DEUDA_TECNICA.md). |

Los documentos de las «fases 1–16» del proyecto original están en [archivo/](archivo/README.md).
