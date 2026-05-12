import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';
import 'parent_info_page.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _goToLogin(AuthController authController) async {
    await authController.cancelPendingSignup();
    _emailController.clear();
    _passwordController.clear();

    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<bool> _handleSystemBack() async {
    final authController = context.read<AuthController>();
    await authController.cancelPendingSignup();
    _emailController.clear();
    _passwordController.clear();
    return true;
  }

  Future<void> _goNext(AuthController authController) async {
    if (!_formKey.currentState!.validate()) return;

    final ok = await authController.registerAccountStep1(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (ok) {
      final shouldReset = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => const ParentInfoPage(),
        ),
      );

      if (!mounted) return;

      if (shouldReset == true) {
        _emailController.clear();
        _passwordController.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, authController, _) {
        return WillPopScope(
          onWillPop: _handleSystemBack,
          child: Scaffold(
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 24),
                          const Text(
                            'Create Your Account',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'to begin a journey in Voice Voyage',
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
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 16),

                          SizedBox(
                            width: 390,
                            child: PrimaryButton(
                              text: 'Sign up',
                              onPressed: authController.isLoading
                                  ? null
                                  : () => _goNext(authController),
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
                                const TextSpan(
                                  text: 'Already have an account? ',
                                ),
                                WidgetSpan(
                                  alignment: PlaceholderAlignment.middle,
                                  child: GestureDetector(
                                    onTap: () => _goToLogin(authController),
                                    child: const Text(
                                      'Login here',
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
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
