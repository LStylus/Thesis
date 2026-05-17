import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/ocean_auth_scaffold.dart';
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

  bool _allowPop = false;
  bool _isLeaving = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _goToLogin(AuthController authController) async {
    if (_isLeaving) return;
    _isLeaving = true;

    await authController.cancelPendingSignup();
    _emailController.clear();
    _passwordController.clear();

    if (!mounted) return;
    setState(() {
      _allowPop = true;
    });
    Navigator.pop(context);
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
        MaterialPageRoute(builder: (_) => const ParentInfoPage()),
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
        return PopScope(
          canPop: _allowPop,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) {
              _goToLogin(authController);
            }
          },
          child: OceanAuthScaffold(
            topSpacing: 132,
            children: [
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    const Text(
                      'Create Your Account',
                      textAlign: TextAlign.center,
                      style: OceanAuthTextStyles.title,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'to begin a journey in Voice Voyage',
                      textAlign: TextAlign.center,
                      style: OceanAuthTextStyles.subtitle,
                    ),
                    const SizedBox(height: 30),
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
                    const SizedBox(height: 11),
                    CustomTextField(
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
                    const SizedBox(height: 16),
                    PrimaryButton(
                      text: 'Sign up',
                      onPressed: authController.isLoading
                          ? null
                          : () => _goNext(authController),
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
                    const SizedBox(height: 26),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: const TextStyle(
                          color: AppColors.textGray,
                          fontSize: 14,
                          letterSpacing: 0,
                        ),
                        children: [
                          const TextSpan(text: 'Already have an account? '),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: GestureDetector(
                              onTap: () => _goToLogin(authController),
                              child: const Text(
                                'Login here',
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
          ),
        );
      },
    );
  }
}
