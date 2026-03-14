import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipos_fitness/app/theme.dart';
import 'package:pipos_fitness/features/exercises/widgets/exercise_list_item.dart';
import 'package:pipos_fitness/models/exercise.dart';

void main() {
  group('ExerciseListItem', () {
    testWidgets('shows exercise name', (tester) async {
      const exercise = Exercise(
        id: 'e1',
        slug: 'bench-press',
        name: 'Bench Press',
        difficulty: 3,
        place: 'gym',
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: ExerciseListItem(
              exercise: exercise,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Bench Press'), findsOneWidget);
    });

    testWidgets('onTap is called when tapped', (tester) async {
      var tapped = false;
      const exercise = Exercise(
        id: 'e1',
        slug: 'e1',
        name: 'Squat',
        difficulty: 1,
        place: 'home',
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: ExerciseListItem(
              exercise: exercise,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ExerciseListItem));
      await tester.pump();

      expect(tapped, true);
    });
  });
}
