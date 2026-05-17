import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
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
      child: OceanAuthScaffold(
        topSpacing: 82,
        showMascot: false,
        bottomPadding: 118,
        children: const [
          Text(
            'welcome to',
            textAlign: TextAlign.center,
            style: OceanAuthTextStyles.subtitle,
          ),
          SizedBox(height: 2),
          Text(
            'VOICE VOYAGE',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 44,
              fontWeight: FontWeight.w900,
              height: 1.1,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: 66),
          FigmaWhaleMascot(width: 304, height: 170),
          SizedBox(height: 16),
          Text(
            'DISCLAIMER',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textGray,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Voice Voyage is only an assistive application for speech practice. '
            'Any existing and underlying health conditions affecting child\'s '
            'speech must be consulted with domain experts.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textGray,
              fontSize: 14,
              height: 1.36,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: 88),
          Text(
            'tap anywhere on the screen to continue',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textGray,
              fontSize: 14,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}
