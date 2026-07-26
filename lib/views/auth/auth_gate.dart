import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../services/user_service.dart';
import '../home/home_page.dart';
import 'welcome_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user != null) {
          return _ProfileReadyGate(userId: user.uid);
        }

        return const WelcomePage();
      },
    );
  }
}

class _ProfileReadyGate extends StatelessWidget {
  final String userId;

  const _ProfileReadyGate({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: UserService().streamUserProfileReady(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            !snapshot.hasData) {
          return const _AuthLoadingView();
        }

        if (snapshot.data == true) {
          return const HomePage();
        }

        return const _IncompleteProfileView();
      },
    );
  }
}

class _AuthLoadingView extends StatelessWidget {
  const _AuthLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );
  }
}

class _IncompleteProfileView extends StatelessWidget {
  const _IncompleteProfileView();

  Future<void> _returnToLogin(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomePage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppColors.primary),
                const SizedBox(height: 18),
                const Text(
                  'Profile setup is not complete yet.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.subtitle,
                ),
                const SizedBox(height: 18),
                TextButton(
                  onPressed: () => _returnToLogin(context),
                  child: const Text('Back to start'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
