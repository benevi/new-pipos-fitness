import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipos_fitness/app/theme.dart';
import 'package:pipos_fitness/features/exercises/body_figure.dart';
import 'package:pipos_fitness/features/exercises/body_geometry.dart';
import 'package:pipos_fitness/features/exercises/exercises_screen.dart';

/// Golden de la figura propia del cuerpo (ADR-0014, Fase 3), delante y
/// detrás, en claro y en oscuro. Sin texto: no depende de las fuentes.
/// Regenerar: `flutter test --update-goldens test/features/exercises`.
void main() {
  Widget figures(ThemeData theme) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: theme,
    home: Builder(
      builder: (context) {
        final style = libraryRegionStyle(Theme.of(context).colorScheme);
        return Scaffold(
          body: Center(
            child: RepaintBoundary(
              key: const Key('figure'),
              child: Container(
                width: 380,
                padding: const EdgeInsets.all(10),
                color: theme.colorScheme.surface,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final side in BodySide.values) ...[
                      if (side == BodySide.back) const SizedBox(width: 20),
                      Expanded(
                        child: BodyFigure(
                          side: side,
                          styleFor: (_) => style,
                          labelFor: (r) => r.id,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );

  for (final (name, theme) in [
    ('light', AppTheme.light),
    ('dark', AppTheme.dark),
  ]) {
    testWidgets('figura del cuerpo en $name', (tester) async {
      tester.view.physicalSize = const Size(400, 460);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(figures(theme));
      await expectLater(
        find.byKey(const Key('figure')),
        matchesGoldenFile('goldens/body_figure_$name.png'),
      );
    });
  }
}
