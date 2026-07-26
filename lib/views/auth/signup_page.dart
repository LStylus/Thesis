import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/testing_defaults.dart';
import '../../widgets/credentials_auth_scaffold.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';
import 'existing_parent_confirmation_page.dart';
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
        MaterialPageRoute(
          builder: (_) =>
              authController.isExistingParentSession &&
                  authController.draft.parentName.isNotEmpty
              ? const ExistingParentConfirmationPage()
              : const ParentInfoPage(),
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
        return PopScope(
          canPop: _allowPop,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) {
              _goToLogin(authController);
            }
          },
          child: CredentialsAuthScaffold(
            mode: CredentialsAuthMode.signup,
            title: 'Create Your Account',
            subtitle: "Start your family's Voice Voyage.",
            onLoginSelected: () => _goToLogin(authController),
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
                        autofillHints: const [AutofillHints.newUsername],
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
                        hintText: 'Create a secure password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.newPassword],
                        autocorrect: false,
                        enableSuggestions: false,
                        onChanged: (_) => authController.clearError(),
                        onFieldSubmitted: (_) {
                          if (!authController.isLoading) {
                            _goNext(authController);
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
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      footer: Text(
                        'Use at least 6 characters.',
                        style: AppTextStyles.helper.copyWith(
                          color: const Color(0xFF6E8995),
                        ),
                      ),
                    ),
                    if (authController.errorMessage != null) ...[
                      const SizedBox(height: 14),
                      CredentialsErrorBanner(
                        message: authController.errorMessage!,
                      ),
                    ],
                    SizedBox(
                      height: MediaQuery.sizeOf(context).height < 420 ? 10 : 18,
                    ),
                    PrimaryButton(
                      text: 'Sign up',
                      onPressed: authController.isLoading
                          ? null
                          : () => _goNext(authController),
                      isLoading: authController.isLoading,
                      height: MediaQuery.sizeOf(context).height < 420 ? 48 : 56,
                      borderRadius: 8,
                      trailingIcon: Icons.arrow_forward_rounded,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
