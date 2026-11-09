# @pipos/catalog

Catálogo versionado de ejercicios. `data/exercises.json` es la fuente de verdad: se valida con los
esquemas Zod de `@pipos/contracts` (`engineV2.CatalogSchema`) y lo carga en la base de datos el
seed de la API (`pnpm --filter @pipos/api prisma:seed`). No hay panel de administración: **todo
cambio entra por PR** y la revisión del PR es la moderación (ADR-0005).

```bash
pnpm --filter @pipos/catalog test          # esquema, cobertura, ficha y medios
pnpm --filter @pipos/catalog media:check   # manual, necesita red (ver abajo)
```

## Vídeos e imágenes (ADR-0014, Fase 4)

Cada ejercicio tiene una lista `media` con **0, 1 o 2** medios y, si hay alguno, **exactamente uno**
con `"isPrimary": true`. Hoy la lista está vacía en los 144 ejercicios: ningún vídeo se ha elegido
ni aprobado todavía, así que la app no muestra el botón «Ver vídeo» en ninguno.

### Formato

Vídeo de YouTube (lo que se usa en esta iteración):

```json
{
  "kind": "youtube",
  "videoId": "<11 caracteres>",
  "startSeconds": 30,
  "endSeconds": 95,
  "channelName": "<canal tal como aparece en YouTube>",
  "locale": "es",
  "isPrimary": true
}
```

- `videoId`: solo el identificador (11 caracteres de `A-Z a-z 0-9 _ -`), nunca una URL ni una
  búsqueda.
- `startSeconds` / `endSeconds`: opcionales; si van los dos, `endSeconds > startSeconds`. La app
  abre el vídeo en `startSeconds`.
- `locale`: `es` o `en` (preferencia por castellano).

Imagen propia (prevista en el esquema; ADR-0014 decidió no usarlas en esta iteración):

```json
{ "kind": "image", "file": "sentadilla-goblet.webp", "credit": "…", "licence": "own-work", "isPrimary": false }
```

- El fichero tiene que existir en `media/` (minúsculas, `.webp` preferido, ≤ 300 KB).
- `credit` y `licence` son obligatorios; licencias aceptadas: `own-work`, `CC0-1.0`, `CC-BY-4.0`,
  `CC-BY-SA-4.0`.

La validación (`pnpm --filter @pipos/catalog test`, también en CI) rechaza un `videoId` mal formado,
un fin que no sea posterior al inicio, más de 2 medios, ninguno o varios principales, medios
repetidos y cualquier imagen sin fichero, crédito o licencia.

### Cómo proponer un vídeo

1. **Elegirlo con los criterios de ADR-0014**:
   - autor con titulación o entidad reconocida (federaciones, universidades, colegios
     profesionales);
   - sin publicidad de suplementos ni promesas de resultados en el propio vídeo;
   - preferencia por castellano;
   - la técnica coincide con la ficha del ejercicio (descripción, claves y errores comunes) y con
     sus zonas de riesgo; si el vídeo es largo, con segundo de inicio y de fin de la parte útil.
2. **Verlo entero** (al menos la parte entre inicio y fin) y anotar en el PR: título, canal,
   titulación o entidad del autor, idioma, por qué cumple cada criterio y la fecha en que se vio.
3. **Abrir un PR** que solo toque `data/exercises.json`, con el medio en el ejercicio
   correspondiente. Un PR por tanda pequeña (p. ej. un patrón de movimiento) para que la revisión
   sea real. Antes de abrirlo: `pnpm --filter @pipos/catalog test` y `media:check`.
4. **Aprobación**: el PR lo aprueba **Victor** (producto) y, antes del lanzamiento público, lo
   revisa un **entrenador titulado** (SPEC_V1, ADR-0014). Ningún vídeo entra sin un PR aprobado
   por una persona: un agente o un script no puede elegirlo ni aprobarlo porque no puede verificar
   su contenido.
5. Al desplegar, el seed lo escribe como aprobado y la app muestra el botón. Para **retirar** un
   vídeo basta con quitarlo del JSON por PR: el siguiente seed lo borra de la base de datos.

### `media:check` antes de cada release

```bash
pnpm --filter @pipos/catalog media:check
```

Comprueba por el oEmbed público de YouTube (`https://www.youtube.com/oembed`, solo con el id del
vídeo; sin datos de usuarios) que cada vídeo sigue disponible y que el canal no ha cambiado. Sale
con código 1 si alguno no está disponible (borrado, privado o restringido), no responde o cambió de
canal; en ese caso, retirarlo o sustituirlo por PR. Si falla más de un 10 %, ADR-0014 pide reabrir
la decisión. Necesita red, así que **no corre en CI**; está en `docs/DEPLOY_CHECKLIST.md`. Detrás de
un proxy HTTPS, Node 22 necesita `NODE_USE_ENV_PROXY=1` para que `fetch` use `HTTPS_PROXY`.
