import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';
import 'parent_info_page.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final AuthController _controller = AuthController();

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  static const Color _primaryBlue = Color(0xFF12B5EA);
  static const Color _textGray = Color(0xFF8D8D8D);
  static const Color _borderGray = Color(0xFFD9D9D9);
  static const Color _bgColor = Color(0xFFF3F3F3);

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFFA6A6A6), fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _borderGray),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _borderGray),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _primaryBlue, width: 1.3),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red, width: 1.3),
      ),
    );
  }

  Future<void> _goToLogin() async {
    await _controller.cancelPendingSignup();
    _emailController.clear();
    _passwordController.clear();

    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<bool> _handleSystemBack() async {
    await _controller.cancelPendingSignup();
    _emailController.clear();
    _passwordController.clear();
    return true;
  }

  Future<void> _goNext() async {
    if (!_formKey.currentState!.validate()) return;

    final ok = await _controller.registerAccountStep1(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (ok) {
      final shouldReset = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => ParentInfoPage(controller: _controller),
        ),
      );

      if (!mounted) return;

      if (shouldReset == true) {
        _emailController.clear();
        _passwordController.clear();
      }
    }
  }

  Widget _buildPrimaryButton({
    required String text,
    required VoidCallback? onPressed,
    required bool isLoading,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleSystemBack,
      child: Scaffold(
        backgroundColor: _bgColor,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Form(
                  key: _formKey,
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 24),
                          const Text(
                            'Create Your Account',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _primaryBlue,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'to begin a journey in Voice Voyage',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: _textGray, fontSize: 13),
                          ),
                          const SizedBox(height: 28),

                          SizedBox(
                            width: 390,
                            child: TextFormField(
                              controller: _emailController,
                              onChanged: (_) => _controller.clearError(),
                              decoration: _inputDecoration('Username'),
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
                            child: TextFormField(
                              controller: _passwordController,
                              onChanged: (_) => _controller.clearError(),
                              obscureText: true,
                              decoration: _inputDecoration('Password'),
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
                            child: _buildPrimaryButton(
                              text: 'Sign up',
                              onPressed: _controller.isLoading ? null : _goNext,
                              isLoading: _controller.isLoading,
                            ),
                          ),

                          if (_controller.errorMessage != null) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: 390,
                              child: Text(
                                _controller.errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.red,
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
                                color: _textGray,
                                fontSize: 11.5,
                              ),
                              children: [
                                const TextSpan(
                                  text: 'Already have an account? ',
                                ),
                                WidgetSpan(
                                  alignment: PlaceholderAlignment.middle,
                                  child: GestureDetector(
                                    onTap: _goToLogin,
                                    child: const Text(
                                      'Login here',
                                      style: TextStyle(
                                        color: _textGray,
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
                              color: _textGray,
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
      ),
    );
  }
}
