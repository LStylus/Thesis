import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_fonts.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
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
        topSpacing: AppSpacing.welcomeTopSpacing,
        showMascot: false,
        bottomPadding: AppSpacing.bottomContentPadding,
        children: [
          _WelcomeHero(),
          SizedBox(height: AppSpacing.gap2xl),
          FigmaWhaleMascot(
            width: AppSpacing.welcomeMascotWidth,
            height: AppSpacing.welcomeMascotHeight,
          ),
          SizedBox(height: 34),
          _DisclaimerCard(),
          SizedBox(height: 56),
          Text(
            'tap anywhere on the screen to continue',
            textAlign: TextAlign.center,
            style: AppTextStyles.subtitle,
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
          style: AppTextStyles.subtitle,
        ),
        SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'VOICE VOYAGE',
            textAlign: TextAlign.center,
            style: AppTextStyles.appTitle,
          ),
        ),
        SizedBox(height: 2),
        Text(
          'your learning experience is ready.',
          textAlign: TextAlign.center,
          style: AppTextStyles.helper,
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
      constraints: const BoxConstraints(minHeight: 148),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 22),
      decoration: BoxDecoration(
        color: const Color(0xFF66D4F1),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned(
            left: -7,
            bottom: -8,
            child: _DisclaimerBubble(size: 48, opacity: 0.18),
          ),
          const Positioned(
            left: 22,
            top: -5,
            child: _DisclaimerBubble(size: 14, opacity: 0.24),
          ),
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'DISCLAIMER',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF206F91),
                  fontFamily: AppFonts.fredokaOne,
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Voice Voyage is only an assistive application for speech practice. '
                'Any existing and underlying health conditions affecting child\'s '
                'speech must be consulted with domain experts.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF2B7897),
                  fontFamily: AppFonts.fredoka,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w500,
                  height: 1.24,
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
