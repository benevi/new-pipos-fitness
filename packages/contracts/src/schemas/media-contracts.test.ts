import { describe, expect, it } from 'vitest';
import { engineV2, ExerciseDetailSchema, ExerciseMediaSchema, TodayExerciseSchema } from '../index.js';

/**
 * Medios de técnica (ADR-0014, Fase 4). Los vídeos de estos tests son FICTICIOS: el catálogo real
 * no lleva ninguno hasta que una persona lo elija y lo apruebe por PR.
 */
const FAKE_VIDEO = {
  kind: 'youtube',
  videoId: 'AAAAAAAAAA1',
  startSeconds: 30,
  endSeconds: 95,
  channelName: 'Canal de prueba',
  locale: 'es',
  isPrimary: true,
} as const;
const FAKE_IMAGE = {
  kind: 'image',
  file: 'sentadilla-prueba.webp',
  credit: 'Equipo Pipos',
  licence: 'own-work',
  isPrimary: false,
} as const;

const ID = '11111111-1111-4111-8111-111111111111';
const OLD_TODAY = {
  planExerciseId: ID,
  order: 1,
  exercise: { id: ID, slug: 'back-squat', nameEs: 'Sentadilla trasera' },
  substitutedFrom: null,
  cuesEs: [],
  movementPattern: 'squat',
  loadType: 'weighted',
  role: 'main',
  restSeconds: 150,
  prescription: { action: 'hold', sets: 3, repMin: 6, repMax: 10, targetRir: 2, loadKg: 60, isDeload: false, rationale: [] },
  warmupSets: [],
  loggedSets: [],
};

describe('medios del catálogo (ADR-0014, Fase 4)', () => {
  const media = (m: unknown) => engineV2.CatalogMediaSchema.safeParse(m);

  it('acepta un vídeo con inicio y fin y una imagen con crédito y licencia', () => {
    expect(media(FAKE_VIDEO).success).toBe(true);
    expect(media({ ...FAKE_VIDEO, startSeconds: undefined, endSeconds: undefined }).success).toBe(true);
    expect(media(FAKE_IMAGE).success).toBe(true);
  });

  it.each([
    ['videoId corto', { ...FAKE_VIDEO, videoId: 'abc' }],
    ['videoId con caracteres no válidos', { ...FAKE_VIDEO, videoId: 'AAAAAAAAA/1' }],
    ['una URL en lugar del videoId', { ...FAKE_VIDEO, videoId: 'https://youtu.be/AAAAAAAAAA1' }],
    ['fin igual al inicio', { ...FAKE_VIDEO, startSeconds: 30, endSeconds: 30 }],
    ['fin antes del inicio', { ...FAKE_VIDEO, startSeconds: 30, endSeconds: 10 }],
    ['inicio negativo', { ...FAKE_VIDEO, startSeconds: -1 }],
    ['segundos con decimales', { ...FAKE_VIDEO, startSeconds: 1.5 }],
    ['sin canal', { ...FAKE_VIDEO, channelName: ' ' }],
    ['idioma desconocido', { ...FAKE_VIDEO, locale: 'fr' }],
    ['sin isPrimary', { ...FAKE_VIDEO, isPrimary: undefined }],
    ['un enlace a una búsqueda', { kind: 'youtube_search', query: 'sentadilla' }],
    ['imagen sin licencia', { ...FAKE_IMAGE, licence: undefined }],
    ['imagen con licencia no aceptada', { ...FAKE_IMAGE, licence: 'all-rights-reserved' }],
    ['imagen sin crédito', { ...FAKE_IMAGE, credit: '' }],
    ['imagen con ruta', { ...FAKE_IMAGE, file: '../secreto.webp' }],
    ['imagen GIF', { ...FAKE_IMAGE, file: 'animada.gif' }],
    ['campo extra', { ...FAKE_VIDEO, url: 'https://example.com' }],
  ])('rechaza %s', (_name, value) => {
    expect(media(value).success).toBe(false);
  });

  it('el fin sin inicio cuenta desde el segundo 0', () => {
    expect(media({ ...FAKE_VIDEO, startSeconds: undefined, endSeconds: 40 }).success).toBe(true);
  });
});

describe('medios en la API (ADR-0014, Fase 4)', () => {
  it('el detalle acepta los medios aprobados y una respuesta antigua sin `media` queda vacía', () => {
    const api = { ...FAKE_VIDEO, startSeconds: 30, endSeconds: null };
    expect(ExerciseMediaSchema.safeParse(api).success).toBe(true);
    expect(ExerciseMediaSchema.safeParse({ ...FAKE_IMAGE }).success).toBe(true);
    expect(ExerciseDetailSchema.shape.media.parse(undefined)).toEqual([]);
    expect(ExerciseDetailSchema.shape.media.safeParse([api, api, api]).success).toBe(false);
  });

  it('`hasVideo` en Hoy es false si la respuesta es anterior a la Fase 4', () => {
    expect(TodayExerciseSchema.parse(OLD_TODAY).hasVideo).toBe(false);
    expect(TodayExerciseSchema.parse({ ...OLD_TODAY, hasVideo: true }).hasVideo).toBe(true);
    expect(TodayExerciseSchema.safeParse({ ...OLD_TODAY, hasVideo: 'yes' }).success).toBe(false);
  });
});
