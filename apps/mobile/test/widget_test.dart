import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pipos_fitness/main.dart';

void main() {
  testWidgets('App pumps without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: PiposApp()));
    await tester.pumpAndSettle();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
