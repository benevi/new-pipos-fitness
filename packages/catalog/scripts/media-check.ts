/**
 * `pnpm --filter @pipos/catalog media:check`: comprueba por oEmbed que cada vídeo del catálogo
 * sigue disponible (ADR-0014, Fase 4). Necesita red; no corre en CI. Sale con código 1 si algún
 * vídeo no está disponible, no responde o ha cambiado de canal.
 */
import { catalogVideos, checkVideos, summarizeMediaCheck } from '../src/index.js';

async function main(): Promise<void> {
  const videos = catalogVideos();
  console.log(`Comprobando ${videos.length} vídeos del catálogo por oEmbed…`);
  const summary = summarizeMediaCheck(await checkVideos(videos, (url, init) => fetch(url, init)));
  for (const line of summary.lines) console.log(line);
  if (!summary.passed) process.exitCode = 1;
}

void main();
