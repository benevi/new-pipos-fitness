# Imágenes del catálogo

Aquí van las imágenes propias que nombra `data/exercises.json` (medios `kind: "image"`,
ADR-0014). Hoy no hay ninguna: la decisión de ADR-0014 es que esta iteración sale solo con vídeos.

Reglas que comprueba la validación del paquete:

- Nombre en minúsculas con guiones y extensión `.webp` (preferida), `.png` o `.jpg`.
- Como mucho 300 KB por imagen.
- Crédito (`credit`) y licencia (`licence`) declarados en el JSON; licencias aceptadas:
  `own-work`, `CC0-1.0`, `CC-BY-4.0`, `CC-BY-SA-4.0`.
