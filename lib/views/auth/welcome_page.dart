import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../widgets/ocean_auth_scaffold.dart';
import 'login_page.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  void _continue() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _continue,
      child: const OceanAuthScaffold(
        topSpacing: 82,
        showMascot: false,
        bottomPadding: 118,
        children: [
          _WelcomeHero(),
          SizedBox(height: 40),
          FigmaWhaleMascot(width: 214, height: 118),
          SizedBox(height: 34),
          _DisclaimerCard(),
          SizedBox(height: 82),
          Text(
            'tap anywhere on the screen to continue',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textGray,
              fontFamily: AppFonts.fredoka,
              fontSize: 14,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeHero extends StatelessWidget {
  const _WelcomeHero();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text(
          'welcome to',
          textAlign: TextAlign.center,
          style: OceanAuthTextStyles.subtitle,
        ),
        SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'VOICE VOYAGE',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.primary,
              fontFamily: AppFonts.matemasie,
              fontSize: 44,
              fontWeight: FontWeight.w400,
              height: 1.1,
              letterSpacing: 0,
            ),
          ),
        ),
        SizedBox(height: 2),
        Text(
          'your learning experience is ready.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textGray,
            fontFamily: AppFonts.fredoka,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            height: 1.1,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _DisclaimerCard extends StatelessWidget {
  const _DisclaimerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 13, 18, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF66D4F1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned(
            left: -7,
            bottom: -8,
            child: _DisclaimerBubble(size: 36, opacity: 0.18),
          ),
          const Positioned(
            left: 19,
            top: -3,
            child: _DisclaimerBubble(size: 10, opacity: 0.24),
          ),
          const Column(
            children: [
              Text(
                'DISCLAIMER',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF206F91),
                  fontFamily: AppFonts.fredokaOne,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Voice Voyage is only an assistive application for speech practice. '
                'Any existing and underlying health conditions affecting child\'s '
                'speech must be consulted with domain experts.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF2B7897),
                  fontFamily: AppFonts.fredoka,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DisclaimerBubble extends StatelessWidget {
  final double size;
  final double opacity;

  const _DisclaimerBubble({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}
