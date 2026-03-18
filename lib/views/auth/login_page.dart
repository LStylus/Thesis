import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
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

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    await _controller.login(
      email: _emailController.text,
      password: _passwordController.text,
    );
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
    return Scaffold(
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
                          'Login',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _primaryBlue,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'to continue your journey',
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
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        SizedBox(
                          width: 390,
                          child: _buildPrimaryButton(
                            text: 'Login',
                            onPressed: _controller.isLoading ? null : _login,
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
    );
  }
}
