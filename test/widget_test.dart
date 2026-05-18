import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:thesis/controllers/auth_controller.dart';
import 'package:thesis/core/theme/app_theme.dart';
import 'package:thesis/views/auth/signup_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
  });

  testWidgets('Signup page renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthController(),
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const SignupPage(),
        ),
      ),
    );

    expect(find.text('Create Your Account'), findsOneWidget);
    expect(find.text('Sign up'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });
}
