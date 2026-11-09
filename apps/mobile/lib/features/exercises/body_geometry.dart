/// Figura del cuerpo de la biblioteca por músculo y del mapa de calor
/// (ADR-0014, Fase 3): dibujo propio y estilizado, sin derechos de terceros.
///
/// La geometría está escrita como datos de trazado SVG (`d` de `<path>`) en
/// un lienzo de [bodyViewBox] (200 × 460), con el eje del cuerpo en x = 100.
/// Cada región muscular se define una vez para el lado izquierdo de la
/// pantalla y se refleja para el otro (salvo las centrales). Hay una vista
/// de frente y otra de espaldas; entre las dos están los 19 músculos del
/// catálogo (los que no se ven de un lado se muestran en el otro).
library;

import 'dart:typed_data';
import 'dart:ui';

import '../../models/enums.dart';

/// Tamaño del lienzo de la figura (unidades SVG).
const bodyViewBox = Size(200, 460);

enum BodySide { front, back }

/// Una región tocable: un músculo en una vista.
class BodyRegion {
  const BodyRegion({
    required this.muscle,
    required this.side,
    required this.d,
    this.mirrored = true,
  });

  final Muscle muscle;
  final BodySide side;

  /// Trazado SVG del lado izquierdo de la pantalla (o completo si es central).
  final String d;

  /// Si se refleja en el eje del cuerpo (músculos pares).
  final bool mirrored;

  /// Clave estable para tests y semántica: `front-chest`, `back-calves`…
  String get id => '${side.name}-${muscle.wire}';

  /// Parte principal (lado izquierdo o central): ancla del área táctil.
  Path get anchorPath => parseSvgPath(d);

  /// Trazado completo (con el reflejo si es par).
  Path get path {
    final p = parseSvgPath(d);
    if (!mirrored) return p;
    return Path()
      ..addPath(p, Offset.zero)
      ..addPath(_mirror(p), Offset.zero);
  }
}

Path _mirror(Path p) => p.transform(
  Float64List.fromList([
    -1, 0, 0, 0, //
    0, 1, 0, 0, //
    0, 0, 1, 0, //
    bodyViewBox.width, 0, 0, 1,
  ]),
);

/// Silueta común a las dos vistas (cabeza, cuello, tronco, brazos, piernas).
final List<String> bodySilhouette = [
  // Cabeza y cuello (centrales).
  'M100 12 C114 12 123 24 123 40 C123 56 113 66 100 66 C87 66 77 56 77 40 C77 24 86 12 100 12 Z',
  'M89 60 L111 60 L113 82 L87 82 Z',
  // Tronco (central).
  'M62 84 C78 76 122 76 138 84 C144 88 146 96 142 104 C138 132 134 166 132 196 '
      'C134 210 140 224 140 242 L60 242 C60 224 66 210 68 196 C66 166 62 132 58 104 '
      'C54 96 56 88 62 84 Z',
];

/// Partes pares de la silueta (se reflejan).
final List<String> bodySilhouetteMirrored = [
  // Brazo, antebrazo y mano.
  'M44 94 C48 86 58 84 62 90 L62 162 C58 170 46 170 42 162 C40 140 40 112 44 94 Z',
  'M41 170 C45 165 59 165 61 171 L55 234 C51 240 43 240 39 234 C38 210 38 190 41 170 Z',
  'M47 238 C53 238 56 246 55 254 C54 262 50 266 46 266 C41 266 38 260 38 252 C38 244 41 238 47 238 Z',
  // Muslo, pierna y pie.
  'M62 238 L99 238 L98 340 C92 348 78 348 72 340 C66 304 60 270 62 238 Z',
  'M72 346 C80 340 94 340 98 346 L95 432 C91 440 81 440 78 432 C73 400 70 370 72 346 Z',
  'M78 438 L96 438 C98 446 96 452 88 454 L72 454 C68 452 70 444 78 438 Z',
];

/// Regiones de las dos vistas. El orden es el de pintado: las de encima van
/// después (y ganan al tocar si se solapan).
final List<BodyRegion> bodyRegions = [
  // ── Frente ──
  const BodyRegion(
    muscle: Muscle.traps,
    side: BodySide.front,
    d: 'M88 72 L91 84 C82 86 72 87 66 88 C72 82 80 76 88 72 Z',
  ),
  const BodyRegion(
    muscle: Muscle.sideDelts,
    side: BodySide.front,
    d: 'M44 96 C46 88 52 86 58 88 L54 114 C50 116 46 114 44 110 C43 104 43 100 44 96 Z',
  ),
  const BodyRegion(
    muscle: Muscle.frontDelts,
    side: BodySide.front,
    d: 'M60 88 C66 86 72 88 76 92 L72 112 C66 116 60 116 56 114 L59 92 Z',
  ),
  const BodyRegion(
    muscle: Muscle.chest,
    side: BodySide.front,
    d: 'M78 92 L98 92 L98 132 C90 138 80 136 72 128 L75 112 Z',
  ),
  const BodyRegion(
    muscle: Muscle.biceps,
    side: BodySide.front,
    d: 'M47 118 C50 114 57 114 59 118 L58 156 C55 162 48 162 46 156 Z',
  ),
  const BodyRegion(
    muscle: Muscle.forearms,
    side: BodySide.front,
    d: 'M43 174 C47 170 56 170 58 175 L53 226 C50 231 44 231 42 226 C41 208 41 190 43 174 Z',
  ),
  const BodyRegion(
    muscle: Muscle.abs,
    side: BodySide.front,
    mirrored: false,
    d: 'M90 140 L110 140 L109 212 C105 220 95 220 91 212 Z',
  ),
  const BodyRegion(
    muscle: Muscle.obliques,
    side: BodySide.front,
    d: 'M72 136 C78 140 84 142 87 144 L89 210 C82 212 76 208 71 202 C69 180 69 158 72 136 Z',
  ),
  const BodyRegion(
    muscle: Muscle.abductors,
    side: BodySide.front,
    d: 'M64 222 C68 218 74 220 76 226 L72 262 C68 262 65 256 63 248 C62 238 62 230 64 222 Z',
  ),
  const BodyRegion(
    muscle: Muscle.quads,
    side: BodySide.front,
    d: 'M78 232 L90 236 L93 330 C88 340 79 339 75 330 C71 306 72 282 75 264 Z',
  ),
  const BodyRegion(
    muscle: Muscle.adductors,
    side: BodySide.front,
    d: 'M92 238 L98 241 L97 294 Z',
  ),
  // ── Espalda ──
  const BodyRegion(
    muscle: Muscle.traps,
    side: BodySide.back,
    mirrored: false,
    d: 'M100 70 L111 74 L138 88 L112 100 L100 148 L88 100 L62 88 L89 74 Z',
  ),
  const BodyRegion(
    muscle: Muscle.rearDelts,
    side: BodySide.back,
    d: 'M45 96 C48 88 56 86 62 90 L60 112 C54 116 48 114 45 108 C44 104 44 100 45 96 Z',
  ),
  const BodyRegion(
    muscle: Muscle.upperBack,
    side: BodySide.back,
    d: 'M66 94 L86 102 L95 138 L80 136 L68 112 Z',
  ),
  const BodyRegion(
    muscle: Muscle.lats,
    side: BodySide.back,
    d: 'M66 118 L78 142 L96 150 L96 184 C86 188 78 194 72 200 C68 172 66 146 66 118 Z',
  ),
  const BodyRegion(
    muscle: Muscle.lowerBack,
    side: BodySide.back,
    mirrored: false,
    d: 'M86 192 L114 192 L112 222 L88 222 Z',
  ),
  const BodyRegion(
    muscle: Muscle.triceps,
    side: BodySide.back,
    d: 'M46 118 C49 114 57 114 60 118 L59 156 C56 162 48 162 45 156 Z',
  ),
  const BodyRegion(
    muscle: Muscle.forearms,
    side: BodySide.back,
    d: 'M43 174 C47 170 56 170 58 175 L53 226 C50 231 44 231 42 226 C41 208 41 190 43 174 Z',
  ),
  const BodyRegion(
    muscle: Muscle.abductors,
    side: BodySide.back,
    d: 'M64 220 C67 214 74 212 80 214 L75 228 C72 236 70 244 68 250 C63 242 62 230 64 220 Z',
  ),
  const BodyRegion(
    muscle: Muscle.glutes,
    side: BodySide.back,
    d: 'M78 228 L98 228 L98 266 C90 272 80 270 74 262 C72 250 73 238 78 228 Z',
  ),
  const BodyRegion(
    muscle: Muscle.hamstrings,
    side: BodySide.back,
    d: 'M72 278 C80 282 90 282 96 278 L94 332 C88 340 80 340 76 332 C72 314 71 296 72 278 Z',
  ),
  const BodyRegion(
    muscle: Muscle.calves,
    side: BodySide.back,
    d: 'M74 352 C80 346 92 346 96 352 L94 398 C88 408 80 408 76 398 C72 384 72 366 74 352 Z',
  ),
];

List<BodyRegion> regionsFor(BodySide side) => [
  for (final r in bodyRegions)
    if (r.side == side) r,
];

/// Lado mínimo del área táctil y semántica de cada región, en dp (Material:
/// 48 dp). Se aplica después de escalar la figura a su tamaño en pantalla.
const minRegionTouchSize = 48.0;

/// Área táctil de [region] en coordenadas de pantalla para una figura
/// escalada por [scale]: el rectángulo de su parte principal, agrandado
/// hasta [minRegionTouchSize] por lado y centrado en ella.
Rect regionTouchRect(BodyRegion region, double scale) {
  final b = region.anchorPath.getBounds();
  final r = Rect.fromLTRB(
    b.left * scale,
    b.top * scale,
    b.right * scale,
    b.bottom * scale,
  );
  // Medio dp de margen: el redondeo de coma flotante no lo deja en 47,99.
  const min = minRegionTouchSize + 0.5;
  final w = r.width < min ? min : r.width;
  final h = r.height < min ? min : r.height;
  return Rect.fromCenter(center: r.center, width: w, height: h);
}

/// Región tocada en [local] (coordenadas de pantalla, figura escalada por
/// [scale]): primero la que contiene el punto (la de encima gana); si no,
/// la de área táctil (≥ 48 dp) más cercana que lo contenga.
BodyRegion? hitTestRegion(BodySide side, Offset local, double scale) {
  final regions = regionsFor(side);
  final p = Offset(local.dx / scale, local.dy / scale);
  for (final r in regions.reversed) {
    if (r.path.contains(p)) return r;
  }
  BodyRegion? best;
  var bestDistance = double.infinity;
  for (final r in regions) {
    final touch = regionTouchRect(r, scale);
    if (!touch.contains(local)) continue;
    final d = (touch.center - local).distanceSquared;
    if (d < bestDistance) {
      bestDistance = d;
      best = r;
    }
  }
  return best;
}

/// Intérprete mínimo de datos de trazado SVG: comandos absolutos M, L, H, V,
/// C, Q y Z (los únicos que usa la figura). Lanza [FormatException] con
/// cualquier otro, para que un error en el dibujo no pase desapercibido.
Path parseSvgPath(String d) {
  final tokens = RegExp(
    r'[MLHVCQZ]|-?\d*\.?\d+',
  ).allMatches(d).map((m) => m.group(0)!).toList();
  final path = Path();
  var i = 0;
  var command = '';
  var x = 0.0;
  var y = 0.0;
  double n() => double.parse(tokens[i++]);
  while (i < tokens.length) {
    final t = tokens[i];
    if (RegExp(r'^[A-Za-z]$').hasMatch(t)) {
      command = t;
      i++;
      if (command == 'Z') {
        path.close();
        continue;
      }
    }
    switch (command) {
      case 'M':
        x = n();
        y = n();
        path.moveTo(x, y);
        command = 'L';
      case 'L':
        x = n();
        y = n();
        path.lineTo(x, y);
      case 'H':
        x = n();
        path.lineTo(x, y);
      case 'V':
        y = n();
        path.lineTo(x, y);
      case 'C':
        final x1 = n(), y1 = n(), x2 = n(), y2 = n();
        x = n();
        y = n();
        path.cubicTo(x1, y1, x2, y2, x, y);
      case 'Q':
        final x1 = n(), y1 = n();
        x = n();
        y = n();
        path.quadraticBezierTo(x1, y1, x, y);
      default:
        throw FormatException('Comando SVG no admitido: $command', d);
    }
  }
  return path;
}
