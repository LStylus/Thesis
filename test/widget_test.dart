import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:thesis/main.dart';

void main() {
  testWidgets('Signup page renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const VoiceVoyageApp());

    expect(find.text('Create Your Account'), findsOneWidget);
    expect(find.text('Sign up'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });
}
