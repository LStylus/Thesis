import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../core/constants/testing_defaults.dart';
import '../../widgets/credentials_auth_scaffold.dart';
import '../../widgets/custom_text_field.dart';
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
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();

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

  void _openSignup(AuthController authController) {
    authController.clearError();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SignupPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, authController, _) {
        return CredentialsAuthScaffold(
          mode: CredentialsAuthMode.login,
          title: 'Welcome back',
          subtitle: "Continue your child's Voice Voyage.",
          onSignupSelected: () => _openSignup(authController),
          child: AutofillGroup(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CredentialFieldsLayout(
                    firstField: CustomTextField(
                      controller: _emailController,
                      labelText: 'Email address',
                      hintText: 'name@example.com',
                      prefixIcon: const Icon(Icons.mail_outline_rounded),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.username],
                      autocorrect: false,
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
                    secondField: CustomTextField(
                      controller: _passwordController,
                      labelText: 'Password',
                      hintText: 'Enter your password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      autocorrect: false,
                      enableSuggestions: false,
                      onChanged: (_) => authController.clearError(),
                      onFieldSubmitted: (_) {
                        if (!authController.isLoading) {
                          _login(authController);
                        }
                      },
                      suffixIcon: IconButton(
                        tooltip: _obscurePassword
                            ? 'Show password'
                            : 'Hide password',
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                  ),
                  if (authController.errorMessage != null) ...[
                    const SizedBox(height: 14),
                    CredentialsErrorBanner(
                      message: authController.errorMessage!,
                    ),
                  ],
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height < 420 ? 10 : 20,
                  ),
                  PrimaryButton(
                    text: 'Log in',
                    onPressed: authController.isLoading
                        ? null
                        : () => _login(authController),
                    isLoading: authController.isLoading,
                    height: MediaQuery.sizeOf(context).height < 420 ? 48 : 56,
                    borderRadius: 8,
                    trailingIcon: Icons.arrow_forward_rounded,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
