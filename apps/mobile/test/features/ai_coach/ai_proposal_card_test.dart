import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipos_fitness/app/theme.dart';
import 'package:pipos_fitness/features/ai_coach/widgets/ai_proposal_card.dart';

void main() {
  group('AiProposalCard', () {
    testWidgets('shows proposal type and valid badge', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: AiProposalCard(
              proposal: {
                'type': 'exercise_swap',
                'fromExerciseId': 'a',
                'toExerciseId': 'b',
              },
              status: 'valid',
            ),
          ),
        ),
      );
      expect(find.text('Exercise swap'), findsOneWidget);
      expect(find.text('Valid'), findsOneWidget);
    });

    testWidgets('shows rejected badge', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: AiProposalCard(
              proposal: {'type': 'nutrition_swap', 'fromFoodId': 'f1', 'toFoodId': 'f2'},
              status: 'rejected',
            ),
          ),
        ),
      );
      expect(find.text('Food swap'), findsOneWidget);
      expect(find.text('Rejected'), findsOneWidget);
    });
  });
}
