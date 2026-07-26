import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:thesis/controllers/auth_controller.dart';
import 'package:thesis/core/theme/app_theme.dart';
import 'package:thesis/views/auth/child_info_page.dart';
import 'package:thesis/views/auth/existing_parent_confirmation_page.dart';
import 'package:thesis/views/auth/login_page.dart';
import 'package:thesis/views/auth/parent_info_page.dart';
import 'package:thesis/views/auth/signup_page.dart';
import 'package:thesis/views/auth/welcome_page.dart';
import 'package:thesis/views/screening/screening_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
  });

  testWidgets('Signup page renders correctly', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

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
    expect(find.text('Sign up'), findsNWidgets(2));
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Login page fits compact landscape', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 360));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthController(),
        child: MaterialApp(theme: AppTheme.lightTheme, home: const LoginPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Log in'), findsNWidgets(2));
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Onboarding flow fits compact landscape', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 360));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const screens = <(Widget, String)>[
      (WelcomePage(), 'Welcome aboard'),
      (ParentInfoPage(), 'About you'),
      (ChildInfoPage(), 'About the child'),
      (StartScreeningPage(childAge: 5), 'Speech sound screening'),
    ];

    for (final (screen, expectedTitle) in screens) {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AuthController(),
          child: MaterialApp(theme: AppTheme.lightTheme, home: screen),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text(expectedTitle), findsOneWidget);
      expect(tester.takeException(), isNull, reason: expectedTitle);
    }
  });

  testWidgets('Existing parent confirmation fits compact landscape', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 360));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final authController = AuthController()
      ..saveParentInfo(
        parentName: 'Maria Santos',
        relationshipToChild: 'Mother',
      );

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: authController,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ExistingParentConfirmationPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome back, Maria Santos'), findsOneWidget);
    expect(find.text('Add child profile'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
