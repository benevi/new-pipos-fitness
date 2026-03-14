import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipos_fitness/app/theme.dart';
import 'package:pipos_fitness/features/ai_coach/ai_coach_screen.dart';
import 'package:pipos_fitness/features/ai_coach/ai_coach_provider.dart';

void main() {
  group('AiCoachScreen', () {
    testWidgets('has AppBar with title AI Coach', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.dark,
            home: const AiCoachScreen(),
          ),
        ),
      );
      expect(find.text('AI Coach'), findsOneWidget);
    });

    testWidgets('has input field and send button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.dark,
            home: const AiCoachScreen(),
          ),
        ),
      );
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);
    });
  });
}
