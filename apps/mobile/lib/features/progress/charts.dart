/// Gráficas mínimas con `CustomPainter` (sin dependencias): sparkline de
/// e1RM y barra de volumen con la banda del rango objetivo. Los colores
/// salen del tema; el significado se da también en texto (Semantics) para
/// no depender del color.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/tokens.dart';

class Sparkline extends StatelessWidget {
  const Sparkline({
    super.key,
    required this.values,
    required this.semanticLabel,
  });

  final List<double> values;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Semantics(
      label: semanticLabel,
      image: true,
      child: SizedBox(
        height: AppSpacing.xl,
        width: AppSpacing.xxl * 2,
        child: CustomPaint(painter: _SparklinePainter(values, color)),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter(this.values, this.color);

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final minV = values.reduce(math.min);
    final maxV = values.reduce(math.max);
    final span = maxV - minV == 0 ? 1.0 : maxV - minV;
    final stroke = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    Offset at(int i) {
      final x = values.length == 1
          ? size.width / 2
          : size.width * i / (values.length - 1);
      final y = size.height - (values[i] - minV) / span * size.height;
      return Offset(x, y.clamp(1, size.height - 1));
    }

    final path = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < values.length; i++) {
      path.lineTo(at(i).dx, at(i).dy);
    }
    canvas.drawPath(path, stroke);
    canvas.drawCircle(at(values.length - 1), 3, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.values != values || old.color != color;
}

/// Línea de tendencia a todo el ancho (media de 7 días del peso). El
/// significado se da también en texto ([semanticLabel]).
class TrendChart extends StatelessWidget {
  const TrendChart({
    super.key,
    required this.values,
    required this.semanticLabel,
  });

  final List<double> values;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Semantics(
      label: semanticLabel,
      image: true,
      child: SizedBox(
        height: AppSpacing.xxl * 2,
        width: double.infinity,
        child: CustomPaint(painter: _SparklinePainter(values, color)),
      ),
    );
  }
}

/// Barra horizontal: relleno = series hechas; banda = rango objetivo.

class VolumeRangeBar extends StatelessWidget {
  const VolumeRangeBar({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.scaleMax,
    required this.semanticLabel,
    required this.inRange,
  });

  final double value;
  final double? min;
  final double? max;
  final double scaleMax;
  final String semanticLabel;
  final bool inRange;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: semanticLabel,
      child: SizedBox(
        height: AppSpacing.ms,
        width: double.infinity,
        child: CustomPaint(
          painter: _RangeBarPainter(
            value: value,
            min: min,
            max: max,
            scaleMax: scaleMax,
            track: scheme.surfaceContainerHighest,
            band: scheme.outline,
            fill: inRange ? scheme.primary : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _RangeBarPainter extends CustomPainter {
  _RangeBarPainter({
    required this.value,
    required this.min,
    required this.max,
    required this.scaleMax,
    required this.track,
    required this.band,
    required this.fill,
  });

  final double value;
  final double? min;
  final double? max;
  final double scaleMax;
  final Color track;
  final Color band;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Radius.circular(size.height / 2);
    double x(double v) => (v / scaleMax).clamp(0, 1) * size.width;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, r),
      Paint()..color = track,
    );
    if (min != null && max != null) {
      canvas.drawRect(
        Rect.fromLTRB(x(min!), 0, x(max!), size.height),
        Paint()..color = band,
      );
    }
    final w = x(value);
    if (w > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, size.height * 0.25, w, size.height * 0.5),
          r,
        ),
        Paint()..color = fill,
      );
    }
  }

  @override
  bool shouldRepaint(_RangeBarPainter old) =>
      old.value != value ||
      old.min != min ||
      old.max != max ||
      old.fill != fill;
}
