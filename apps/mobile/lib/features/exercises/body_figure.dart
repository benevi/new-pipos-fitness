/// Widget de la figura del cuerpo (ADR-0014, Fase 3), en dos usos:
///
/// - **Biblioteca**: cada región es un botón que abre los ejercicios de su
///   músculo. Área táctil ≥ 48 dp y etiqueta para TalkBack en cada región.
/// - **Mapa de calor**: cada región se pinta según las series de la semana
///   de su grupo frente al rango objetivo, con color **y** trama (no solo
///   color), y con la lectura completa en su etiqueta.
library;

import 'package:flutter/material.dart';

import '../../models/enums.dart';
import 'body_geometry.dart';

/// Trama de relleno de una región. En el mapa de calor cada estado tiene la
/// suya para no depender solo del color.
enum RegionPattern { solid, hatch, crossHatch, dots, none }

@immutable
class RegionStyle {
  const RegionStyle({
    required this.fill,
    required this.pattern,
    required this.ink,
  });

  /// Color de fondo de la región.
  final Color fill;
  final RegionPattern pattern;

  /// Color del trazo de la trama y del contorno.
  final Color ink;
}

/// Una vista de la figura (frente o espalda), escalada al ancho disponible.
class BodyFigure extends StatelessWidget {
  const BodyFigure({
    super.key,
    required this.side,
    required this.styleFor,
    required this.labelFor,
    this.onRegionTap,
  });

  final BodySide side;

  /// Estilo de cada región (biblioteca: uno común; mapa de calor: por estado).
  final RegionStyle Function(BodyRegion region) styleFor;

  /// Etiqueta de accesibilidad de cada región.
  final String Function(BodyRegion region) labelFor;

  /// Con valor, las regiones son botones (biblioteca).
  final void Function(BodyRegion region)? onRegionTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final regions = regionsFor(side);
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = constraints.maxWidth / bodyViewBox.width;
        final size = Size(constraints.maxWidth, bodyViewBox.height * scale);
        final tap = onRegionTap;
        return SizedBox.fromSize(
          size: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: ExcludeSemantics(
                  child: CustomPaint(
                    painter: BodyPainter(
                      side: side,
                      silhouetteFill: scheme.surfaceContainerHighest,
                      silhouetteStroke: scheme.outline,
                      styleFor: styleFor,
                    ),
                  ),
                ),
              ),
              // Un nodo semántico por región, con su área táctil (≥ 48 dp).
              for (final r in regions)
                Positioned.fromRect(
                  rect: regionTouchRect(r, scale),
                  child: Semantics(
                    key: Key('body-region-${r.id}'),
                    container: true,
                    button: tap != null,
                    label: labelFor(r),
                    onTap: tap == null ? null : () => tap(r),
                    child: const SizedBox.expand(),
                  ),
                ),
              // Los toques se resuelven por geometría: la región que contiene
              // el punto o, si no, el área de 48 dp más cercana.
              if (tap != null)
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    excludeFromSemantics: true,
                    onTapUp: (d) {
                      final r = hitTestRegion(side, d.localPosition, scale);
                      if (r != null) tap(r);
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class BodyPainter extends CustomPainter {
  BodyPainter({
    required this.side,
    required this.silhouetteFill,
    required this.silhouetteStroke,
    required this.styleFor,
  });

  final BodySide side;
  final Color silhouetteFill;
  final Color silhouetteStroke;
  final RegionStyle Function(BodyRegion region) styleFor;

  static final Path _silhouette = () {
    final p = Path();
    for (final d in bodySilhouette) {
      p.addPath(parseSvgPath(d), Offset.zero);
    }
    for (final d in bodySilhouetteMirrored) {
      p.addPath(
        BodyRegion(muscle: Muscle.chest, side: BodySide.front, d: d).path,
        Offset.zero,
      );
    }
    return p;
  }();

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / bodyViewBox.width;
    canvas.save();
    canvas.scale(scale);
    final stroke = 1.2 / scale.clamp(0.5, 2);
    canvas.drawPath(_silhouette, Paint()..color = silhouetteFill);
    canvas.drawPath(
      _silhouette,
      Paint()
        ..color = silhouetteStroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    for (final r in regionsFor(side)) {
      paintRegion(canvas, r.path, styleFor(r), stroke);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(BodyPainter old) => true;
}

/// Pinta [path] con su estilo: fondo, trama recortada a la región y contorno.
/// También lo usa la leyenda del mapa de calor.
void paintRegion(Canvas canvas, Path path, RegionStyle style, double stroke) {
  canvas.drawPath(path, Paint()..color = style.fill);
  final bounds = path.getBounds();
  final ink = Paint()
    ..color = style.ink
    ..strokeWidth = stroke
    ..style = PaintingStyle.stroke;
  void lines({required bool rising}) {
    const step = 5.0;
    final span = bounds.width + bounds.height;
    for (var t = -span; t < span; t += step) {
      final x0 = bounds.left + t;
      canvas.drawLine(
        Offset(x0, rising ? bounds.bottom : bounds.top),
        Offset(x0 + bounds.height, rising ? bounds.top : bounds.bottom),
        ink,
      );
    }
  }

  switch (style.pattern) {
    case RegionPattern.hatch:
      canvas.save();
      canvas.clipPath(path);
      lines(rising: true);
      canvas.restore();
    case RegionPattern.crossHatch:
      canvas.save();
      canvas.clipPath(path);
      lines(rising: true);
      lines(rising: false);
      canvas.restore();
    case RegionPattern.dots:
      canvas.save();
      canvas.clipPath(path);
      final dot = Paint()..color = style.ink;
      const step = 5.0;
      for (var y = bounds.top + step / 2; y < bounds.bottom; y += step) {
        for (var x = bounds.left + step / 2; x < bounds.right; x += step) {
          canvas.drawCircle(Offset(x, y), stroke * 0.9, dot);
        }
      }
      canvas.restore();
    case RegionPattern.solid:
    case RegionPattern.none:
      break;
  }
  canvas.drawPath(path, ink..strokeWidth = stroke);
}

/// Muestra de un estilo (para la leyenda): un rectángulo redondeado pintado
/// igual que las regiones.
class RegionSwatch extends StatelessWidget {
  const RegionSwatch({super.key, required this.style, this.size = 20});

  final RegionStyle style;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(size: Size.square(size), painter: _SwatchPainter(style)),
  );
}

class _SwatchPainter extends CustomPainter {
  _SwatchPainter(this.style);

  final RegionStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(size.shortestSide / 4),
        ),
      );
    paintRegion(canvas, path, style, 1.2);
  }

  @override
  bool shouldRepaint(_SwatchPainter old) => old.style != style;
}
