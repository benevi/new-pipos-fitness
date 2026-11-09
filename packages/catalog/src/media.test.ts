import { mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { afterAll, describe, expect, it } from 'vitest';
import {
  CatalogValidationError,
  MEDIA_DIR,
  MEDIA_IMAGE_MAX_BYTES,
  catalogVideos,
  checkVideo,
  checkVideos,
  loadCatalog,
  parseCatalog,
  summarizeMediaCheck,
  youtubeOembedUrl,
  type FetchLike,
} from './index';

/**
 * Medios de técnica (ADR-0014, Fase 4). Los vídeos e imágenes de este fichero son FICTICIOS:
 * el catálogo real (`data/exercises.json`) no lleva ninguno hasta que una persona lo elija y lo
 * apruebe por PR siguiendo los criterios de ADR-0014.
 */
const FAKE_VIDEO = {
  kind: 'youtube',
  videoId: 'AAAAAAAAAA1',
  startSeconds: 20,
  endSeconds: 80,
  channelName: 'Canal de prueba',
  locale: 'es',
  isPrimary: true,
} as const;
const FAKE_IMAGE = {
  kind: 'image',
  file: 'prueba-tecnica.webp',
  credit: 'Equipo Pipos',
  licence: 'own-work',
  isPrimary: false,
} as const;

const tmp = mkdtempSync(join(tmpdir(), 'pipos-media-'));
writeFileSync(join(tmp, FAKE_IMAGE.file), Buffer.alloc(1024));
writeFileSync(join(tmp, 'enorme.webp'), Buffer.alloc(MEDIA_IMAGE_MAX_BYTES + 1));
afterAll(() => rmSync(tmp, { recursive: true, force: true }));

const withMedia = (media: unknown[]) => [{ ...loadCatalog()[0], media }];

describe('medios del catálogo (ADR-0014, Fase 4)', () => {
  it('ningún medio del catálogo real queda sin crédito, licencia o canal, y cada vídeo es válido', () => {
    const list = loadCatalog();
    const media = list.flatMap((e) => e.media);
    console.info(`Medios en el catálogo: ${media.length} (${catalogVideos(list).length} vídeos)`);
    for (const e of list) {
      if (e.media.length > 0) expect(e.media.filter((m) => m.isPrimary), e.slug).toHaveLength(1);
      for (const m of e.media) {
        if (m.kind === 'image') {
          expect(m.credit.trim().length, e.slug).toBeGreaterThan(1);
          expect(m.licence, e.slug).toBeTruthy();
        } else {
          expect(m.channelName.trim().length, e.slug).toBeGreaterThan(1);
          expect(m.videoId, e.slug).toMatch(/^[A-Za-z0-9_-]{11}$/);
        }
      }
    }
  });

  it('las imágenes viven en la carpeta media/ del paquete', () => {
    expect(MEDIA_DIR.replace(/\\/g, '/')).toMatch(/packages\/catalog\/media$/);
  });

  it('acepta un vídeo y una imagen existente con crédito y licencia', () => {
    const [ex] = parseCatalog(withMedia([FAKE_VIDEO, FAKE_IMAGE]), { mediaDir: tmp });
    expect(ex.media).toEqual([FAKE_VIDEO, FAKE_IMAGE]);
    expect(catalogVideos([ex])).toEqual([{ slug: ex.slug, video: FAKE_VIDEO }]);
  });

  it.each([
    ['videoId con formato inválido', [{ ...FAKE_VIDEO, videoId: 'no es un id' }]],
    ['fin no posterior al inicio', [{ ...FAKE_VIDEO, startSeconds: 80, endSeconds: 80 }]],
    ['más de 2 medios', [FAKE_VIDEO, FAKE_IMAGE, { ...FAKE_VIDEO, videoId: 'BBBBBBBBBB2', isPrimary: false }]],
    ['ninguno principal', [{ ...FAKE_VIDEO, isPrimary: false }]],
    ['dos principales', [FAKE_VIDEO, { ...FAKE_IMAGE, isPrimary: true }]],
    ['imagen sin licencia', [FAKE_VIDEO, { ...FAKE_IMAGE, licence: undefined }]],
    ['imagen sin crédito', [FAKE_VIDEO, { ...FAKE_IMAGE, credit: '' }]],
    ['imagen que no existe en el paquete', [FAKE_VIDEO, { ...FAKE_IMAGE, file: 'no-existe.webp' }]],
    ['imagen demasiado grande', [FAKE_VIDEO, { ...FAKE_IMAGE, file: 'enorme.webp' }]],
  ])('rechaza %s', (_name, media) => {
    expect(() => parseCatalog(withMedia(media), { mediaDir: tmp })).toThrow(CatalogValidationError);
  });

  it('una imagen que no está en el paquete real se rechaza con un mensaje claro', () => {
    expect(() => parseCatalog(withMedia([{ ...FAKE_IMAGE, isPrimary: true }]))).toThrow(/no existe en el paquete/);
  });
});

/** fetch falso: responde según el videoId que aparece en la URL de oEmbed. */
function fakeFetch(byId: Record<string, number | { author: string } | 'network'>): FetchLike {
  return async (url) => {
    const id = new URL(new URL(url).searchParams.get('url') ?? '').searchParams.get('v') ?? '';
    const answer = byId[id];
    if (answer === 'network' || answer === undefined) throw new Error('sin red');
    if (typeof answer === 'number') return { status: answer, json: async () => ({}) };
    return { status: 200, json: async () => ({ author_name: answer.author }) };
  };
}

describe('media:check por oEmbed (ADR-0014, Fase 4)', () => {
  it('pregunta al oEmbed público de YouTube solo por el id del vídeo', () => {
    const url = new URL(youtubeOembedUrl('AAAAAAAAAA1'));
    expect(url.origin + url.pathname).toBe('https://www.youtube.com/oembed');
    expect(url.searchParams.get('url')).toBe('https://www.youtube.com/watch?v=AAAAAAAAAA1');
    expect(url.searchParams.get('format')).toBe('json');
  });

  it('clasifica disponible, no disponible, sin respuesta y canal distinto', async () => {
    const fetchFn = fakeFetch({
      AAAAAAAAAA1: { author: 'canal de PRUEBA ' },
      BBBBBBBBBB2: 404,
      CCCCCCCCCC3: 401,
      DDDDDDDDDD4: 'network',
      EEEEEEEEEE5: { author: 'Otro canal' },
      FFFFFFFFFF6: 503,
    });
    const v = (videoId: string) => ({ videoId, channelName: 'Canal de prueba' });
    const results = await checkVideos(
      ['AAAAAAAAAA1', 'BBBBBBBBBB2', 'CCCCCCCCCC3', 'DDDDDDDDDD4', 'EEEEEEEEEE5', 'FFFFFFFFFF6'].map((id) => ({
        slug: 'sentadilla',
        video: v(id),
      })),
      fetchFn,
    );
    expect(results.map((r) => [r.videoId, r.status, r.channelMismatch])).toEqual([
      ['AAAAAAAAAA1', 'ok', false],
      ['BBBBBBBBBB2', 'unavailable', false],
      ['CCCCCCCCCC3', 'unavailable', false],
      ['DDDDDDDDDD4', 'error', false],
      ['EEEEEEEEEE5', 'ok', true],
      ['FFFFFFFFFF6', 'error', false],
    ]);
    const summary = summarizeMediaCheck(results);
    expect(summary).toMatchObject({ total: 6, ok: 2, unavailable: 2, errors: 2, channelMismatches: 1, passed: false });
    expect(summary.reopenAdr).toBe(true);
    expect(summary.lines.join('\n')).toMatch(/NO DISPONIBLE\s+sentadilla BBBBBBBBBB2 \(HTTP 404\)/);
    expect(summary.lines.join('\n')).toMatch(/reabrir/);
  });

  it('pasa si todos los vídeos responden y no reabre el ADR por debajo del 10 %', async () => {
    const fetchFn = fakeFetch({ AAAAAAAAAA1: { author: 'Canal' } });
    const ok = await checkVideo('press', { videoId: 'AAAAAAAAAA1', channelName: 'Canal' }, fetchFn);
    expect(summarizeMediaCheck([ok])).toMatchObject({ passed: true, reopenAdr: false, unavailableRatio: 0 });
    const many = [...Array(10)].map(() => ok);
    const one = { ...ok, status: 'unavailable' as const, httpStatus: 404 };
    expect(summarizeMediaCheck([...many, one]).reopenAdr).toBe(false);
  });

  it('sin vídeos no hay nada que comprobar y pasa', () => {
    expect(summarizeMediaCheck([])).toMatchObject({ total: 0, passed: true, reopenAdr: false });
    expect(summarizeMediaCheck([]).lines).toEqual(['El catálogo no tiene vídeos: nada que comprobar.']);
  });
});
