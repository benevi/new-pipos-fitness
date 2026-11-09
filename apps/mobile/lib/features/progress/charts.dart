/// Gráficas mínimas con `CustomPainter` (sin dependencias): línea de
/// tendencia con contexto de ejes (fechas primera/última, mínimo/máximo con
/// unidad) y barra de volumen con la banda del rango objetivo. Los colores
/// salen del tema; el significado se da también en texto (etiquetas
/// visibles, iconos y un resumen para el lector de pantalla) para no
/// depender del color.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/tokens.dart';
import '../../models/enums.dart';

/// Línea de tendencia con contexto mínimo: a la izquierda el máximo (arriba)
/// y el mínimo (abajo) con su unidad; debajo, la primera y la última fecha.
/// Para el lector de pantalla es una sola imagen con [semanticLabel] (p. ej.
/// «Peso: de 83,4 a 81,8 kg en 4 semanas»); las etiquetas visibles se
/// excluyen para no leerlo dos veces.
class Sparkline extends StatelessWidget {
  const Sparkline({
    super.key,
    required this.values,
    required this.semanticLabel,
    required this.minLabel,
    required this.maxLabel,
    required this.firstLabel,
    required this.lastLabel,
    this.height = AppSpacing.xxl,
  });

  final List<double> values;
  final String semanticLabel;

  /// Valor mínimo y máximo de lo dibujado, ya con unidad («78 kg»).
  final String minLabel;
  final String maxLabel;

  /// Fecha del primer y del último punto.
  final String firstLabel;
  final String lastLabel;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    final axis = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Semantics(
      label: semanticLabel,
      image: true,
      container: true,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Alto mínimo [height]; con texto grande crece lo que pidan las
          // etiquetas del eje (sin desbordar).
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: height),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(maxLabel, key: const Key('chart-max'), style: axis),
                      Text(minLabel, key: const Key('chart-min'), style: axis),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: CustomPaint(
                      painter: _SparklinePainter(
                        values,
                        color,
                        theme.colorScheme.outline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: Text(
                  firstLabel,
                  key: const Key('chart-first'),
                  style: axis,
                ),
              ),
              Text(lastLabel, key: const Key('chart-last'), style: axis),
            ],
          ),
        ],
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter(this.values, this.color, this.grid);

  final List<double> values;
  final Color color;
  final Color grid;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    // Líneas guía del máximo y el mínimo (alineadas con sus etiquetas).
    final guide = Paint()
      ..color = grid
      ..strokeWidth = 1;
    canvas.drawLine(const Offset(0, 1), Offset(size.width, 1), guide);
    canvas.drawLine(
      Offset(0, size.height - 1),
      Offset(size.width, size.height - 1),
      guide,
    );
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
      return Offset(x, y.clamp(2, size.height - 2));
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
      old.values != values || old.color != color || old.grid != grid;
}

/// Color e icono de cada estado del volumen semanal frente al rango. El
/// mismo color se usa en la barra y en la leyenda, y siempre va con icono y
/// texto (no solo color). Todos ≥ 3:1 sobre la pista.
({Color color, IconData icon}) volumeStatusStyle(
  VolumeStatus status,
  ColorScheme scheme,
) => switch (status) {
  VolumeStatus.below => (
    color: scheme.onSurfaceVariant,
    icon: Icons.arrow_downward,
  ),
  VolumeStatus.within => (color: scheme.primary, icon: Icons.check),
  VolumeStatus.above => (color: scheme.error, icon: Icons.arrow_upward),
  VolumeStatus.noTarget => (color: scheme.onSurfaceVariant, icon: Icons.remove),
};

/// Barra horizontal: relleno = series hechas (color del estado); banda =
/// rango objetivo.
class VolumeRangeBar extends StatelessWidget {
  const VolumeRangeBar({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.scaleMax,
    required this.status,
    this.semanticLabel,
  });

  final double value;
  final double? min;
  final double? max;
  final double scaleMax;
  final VolumeStatus status;

  /// Null si el contenedor ya da el resumen (p. ej. la fila de Progreso).
  final String? semanticLabel;

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
            fill: volumeStatusStyle(status, scheme).color,
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
