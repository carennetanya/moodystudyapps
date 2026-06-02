// Widget test for Moody Study startup screen.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moody_study/main.dart';

void main() {
  testWidgets('Theme selector screen loads', (WidgetTester tester) async {
    await tester.pumpWidget(const MoodyStudyApp());
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('Light Mode'), findsOneWidget);
    expect(find.text('Dark Mode'), findsOneWidget);
    expect(find.text('Choose your\nTheme'), findsNWidgets(2));
  });
}
