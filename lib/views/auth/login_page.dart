import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';
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
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login(AuthController authController) async {
    if (!_formKey.currentState!.validate()) return;

    await authController.login(
      email: _emailController.text,
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Form(
                key: _formKey,
                child: Consumer<AuthController>(
                  builder: (context, authController, _) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 24),
                        const Text(
                          'Login',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'to continue your journey',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textGray,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 28),

                        SizedBox(
                          width: 390,
                          child: CustomTextField(
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
                        ),
                        const SizedBox(height: 12),

                        SizedBox(
                          width: 390,
                          child: CustomTextField(
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
                        ),
                        const SizedBox(height: 16),

                        SizedBox(
                          width: 390,
                          child: PrimaryButton(
                            text: 'Login',
                            onPressed: () => _login(authController),
                            isLoading: authController.isLoading,
                          ),
                        ),

                        if (authController.errorMessage != null) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: 390,
                            child: Text(
                              authController.errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: const TextStyle(
                              color: AppColors.textGray,
                              fontSize: 11.5,
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
                                    style: TextStyle(
                                      color: AppColors.textGray,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Terms & Privacy | Privacy Policy',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textGray,
                            fontSize: 11.5,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        const SizedBox(height: 22),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
