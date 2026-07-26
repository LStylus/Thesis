import 'package:flutter/material.dart';

import '../../core/constants/app_fonts.dart';
import '../../widgets/credentials_auth_scaffold.dart';
import '../../widgets/primary_button.dart';
import 'login_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  void _continue(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dense = MediaQuery.sizeOf(context).height < 420;

    return VoyageFlowScaffold(
      eyebrow: 'Assistive speech practice',
      title: 'Welcome aboard',
      subtitle: 'A playful space for children to practice speech sounds.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _DisclaimerNotice(),
          SizedBox(height: dense ? 10 : 20),
          PrimaryButton(
            text: 'Continue',
            onPressed: () => _continue(context),
            height: dense ? 48 : 56,
            borderRadius: 8,
            trailingIcon: Icons.arrow_forward_rounded,
          ),
        ],
      ),
    );
  }
}

class _DisclaimerNotice extends StatelessWidget {
  const _DisclaimerNotice();

  @override
  Widget build(BuildContext context) {
    final dense = MediaQuery.sizeOf(context).height < 420;

    return Container(
      padding: EdgeInsets.all(dense ? 12 : 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF2FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCFE8EE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: dense ? 36 : 42,
            height: dense ? 36 : 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFDFF5FA),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.health_and_safety_outlined,
              color: const Color(0xFF168DB5),
              size: dense ? 21 : 24,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DISCLAIMER',
                  style: TextStyle(
                    color: Color(0xFF176D8B),
                    fontFamily: AppFonts.fredokaOne,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Voice Voyage is an assistive speech-practice application, '
                  'not a medical diagnosis. Concerns about a child\'s speech or '
                  'underlying health conditions should be discussed with a '
                  'qualified professional.',
                  style: TextStyle(
                    color: Color(0xFF426674),
                    fontFamily: AppFonts.fredoka,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    height: 1.28,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
