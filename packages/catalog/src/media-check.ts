/**
 * Comprobación manual de que los vídeos del catálogo siguen disponibles (ADR-0014, Fase 4).
 * Usa el oEmbed público de YouTube: no envía ningún dato de usuarios, solo el id del vídeo.
 * Necesita red, así que no corre en CI: se lanza con `pnpm --filter @pipos/catalog media:check`
 * antes de cada release (docs/DEPLOY_CHECKLIST.md).
 */
import type { engineV2 } from '@pipos/contracts';

export const YOUTUBE_OEMBED_ENDPOINT = 'https://www.youtube.com/oembed';

/** ADR-0014 §Revisión: se reabre la decisión si falla más de un 10 % de los vídeos. */
export const MEDIA_CHECK_REOPEN_RATIO = 0.1;

/** URL pública del vídeo (la misma que abre la app, sin el segundo de inicio). */
export function youtubeWatchUrl(videoId: string): string {
  return `https://www.youtube.com/watch?v=${encodeURIComponent(videoId)}`;
}

export function youtubeOembedUrl(videoId: string): string {
  const url = new URL(YOUTUBE_OEMBED_ENDPOINT);
  url.searchParams.set('url', youtubeWatchUrl(videoId));
  url.searchParams.set('format', 'json');
  return url.toString();
}

export type MediaCheckStatus =
  /** Responde 200: el vídeo existe y es público. */
  | 'ok'
  /** 401/403/404/400: borrado, privado o con la inserción restringida. Hay que revisarlo. */
  | 'unavailable'
  /** Error de red o 5xx: no concluyente; se vuelve a lanzar más tarde. */
  | 'error';

export interface MediaCheckResult {
  slug: string;
  videoId: string;
  status: MediaCheckStatus;
  httpStatus: number | null;
  /** Canal que declara YouTube (si respondió); se compara con `channelName` del catálogo. */
  authorName: string | null;
  /** true si el canal de YouTube ya no coincide con el del catálogo (el vídeo pudo cambiar de dueño). */
  channelMismatch: boolean;
}

export type FetchLike = (url: string, init?: { signal?: AbortSignal }) => Promise<{
  status: number;
  json(): Promise<unknown>;
}>;

function normalize(name: string): string {
  return name.trim().toLocaleLowerCase('es');
}

/** Comprueba un vídeo por oEmbed. Nunca lanza: los fallos de red quedan como `error`. */
export async function checkVideo(
  slug: string,
  video: Pick<engineV2.CatalogYoutubeMedia, 'videoId' | 'channelName'>,
  fetchFn: FetchLike,
  timeoutMs = 10_000,
): Promise<MediaCheckResult> {
  const base = { slug, videoId: video.videoId, authorName: null, channelMismatch: false };
  try {
    const res = await fetchFn(youtubeOembedUrl(video.videoId), { signal: AbortSignal.timeout(timeoutMs) });
    if (res.status === 200) {
      const body = (await res.json()) as { author_name?: unknown };
      const authorName = typeof body.author_name === 'string' ? body.author_name : null;
      return {
        ...base,
        status: 'ok',
        httpStatus: 200,
        authorName,
        channelMismatch: authorName !== null && normalize(authorName) !== normalize(video.channelName),
      };
    }
    const status: MediaCheckStatus = res.status >= 500 ? 'error' : 'unavailable';
    return { ...base, status, httpStatus: res.status };
  } catch {
    return { ...base, status: 'error', httpStatus: null };
  }
}

/** Comprueba los vídeos en serie (son pocos y así no se satura el endpoint). */
export async function checkVideos(
  videos: readonly { slug: string; video: Pick<engineV2.CatalogYoutubeMedia, 'videoId' | 'channelName'> }[],
  fetchFn: FetchLike,
  timeoutMs?: number,
): Promise<MediaCheckResult[]> {
  const results: MediaCheckResult[] = [];
  for (const { slug, video } of videos) results.push(await checkVideo(slug, video, fetchFn, timeoutMs));
  return results;
}

export interface MediaCheckSummary {
  total: number;
  ok: number;
  unavailable: number;
  errors: number;
  channelMismatches: number;
  /** Fracción de vídeos no disponibles sobre el total (0 si no hay vídeos). */
  unavailableRatio: number;
  /** true si supera el umbral de ADR-0014 para reabrir la decisión. */
  reopenAdr: boolean;
  /** true si todo está bien: ningún vídeo no disponible, sin errores y sin cambios de canal. */
  passed: boolean;
  lines: string[];
}

export function summarizeMediaCheck(results: readonly MediaCheckResult[]): MediaCheckSummary {
  const count = (s: MediaCheckStatus) => results.filter((r) => r.status === s).length;
  const total = results.length;
  const unavailable = count('unavailable');
  const errors = count('error');
  const channelMismatches = results.filter((r) => r.channelMismatch).length;
  const unavailableRatio = total === 0 ? 0 : unavailable / total;
  const lines =
    total === 0
      ? ['El catálogo no tiene vídeos: nada que comprobar.']
      : [
          ...results
            .filter((r) => r.status !== 'ok' || r.channelMismatch)
            .map((r) =>
              r.status === 'ok'
                ? `CANAL DISTINTO  ${r.slug} ${r.videoId}: YouTube dice «${r.authorName}»`
                : r.status === 'unavailable'
                  ? `NO DISPONIBLE   ${r.slug} ${r.videoId} (HTTP ${r.httpStatus}): retirarlo del JSON o sustituirlo por PR`
                  : `SIN RESPUESTA   ${r.slug} ${r.videoId}${r.httpStatus ? ` (HTTP ${r.httpStatus})` : ''}: repetir más tarde`,
            ),
          `${total - unavailable - errors}/${total} vídeos disponibles; ${unavailable} no disponibles, ${errors} sin respuesta, ${channelMismatches} con otro canal.`,
          ...(unavailableRatio > MEDIA_CHECK_REOPEN_RATIO
            ? ['Más de un 10 % no disponible: ADR-0014 pide reabrir la decisión sobre vídeos de terceros.']
            : []),
        ];
  return {
    total,
    ok: count('ok'),
    unavailable,
    errors,
    channelMismatches,
    unavailableRatio,
    reopenAdr: unavailableRatio > MEDIA_CHECK_REOPEN_RATIO,
    passed: unavailable === 0 && errors === 0 && channelMismatches === 0,
    lines,
  };
}
