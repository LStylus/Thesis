import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/testing_defaults.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/ocean_auth_scaffold.dart';
import '../../widgets/primary_button.dart';
import 'auth_gate.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Production behavior:
    // _emailController.text = '';
    // _passwordController.text = '';
    // Testing only: the production behavior leaves these controllers empty.
    _emailController.text = TestingDefaults.authEmail;
    _passwordController.text = TestingDefaults.authPassword;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login(AuthController authController) async {
    if (!_formKey.currentState!.validate()) return;

    final ok = await authController.login(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted || !ok) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, authController, _) {
        return OceanAuthScaffold(
          topSpacing: AppSpacing.authTopSpacing,
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  const Text(
                    'Login',
                    textAlign: TextAlign.center,
                    style: OceanAuthTextStyles.title,
                  ),
                  const SizedBox(height: AppSpacing.gapXs),
                  const Text(
                    'to continue your journey',
                    textAlign: TextAlign.center,
                    style: OceanAuthTextStyles.subtitle,
                  ),
                  const SizedBox(height: AppSpacing.gapXl),
                  CustomTextField(
                    controller: _emailController,
                    hintText: 'Email',
                    onChanged: (_) => authController.clearError(),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.gapSm),
                  CustomTextField(
                    controller: _passwordController,
                    hintText: 'Password',
                    obscureText: true,
                    onChanged: (_) => authController.clearError(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.gapMd),
                  PrimaryButton(
                    text: 'Login',
                    onPressed: authController.isLoading
                        ? null
                        : () => _login(authController),
                    isLoading: authController.isLoading,
                  ),
                  if (authController.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      authController.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.gapLg),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: const TextStyle(
                        color: AppColors.textGray,
                        fontSize: 14,
                        letterSpacing: 0,
                      ),
                      children: [
                        const TextSpan(text: "Don't have an account? "),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SignupPage(),
                                ),
                              );
                            },
                            child: const Text(
                              'Sign up here',
                              style: OceanAuthTextStyles.link,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
