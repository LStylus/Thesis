import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../widgets/ocean_auth_scaffold.dart';
import '../../widgets/primary_button.dart';
import 'child_info_page.dart';

class ExistingParentConfirmationPage extends StatefulWidget {
  const ExistingParentConfirmationPage({super.key});

  @override
  State<ExistingParentConfirmationPage> createState() =>
      _ExistingParentConfirmationPageState();
}

class _ExistingParentConfirmationPageState
    extends State<ExistingParentConfirmationPage> {
  bool _allowPop = false;
  bool _isReturningToSignup = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  Future<void> _returnToSignup() async {
    if (_isReturningToSignup) return;
    _isReturningToSignup = true;

    final authController = context.read<AuthController>();
    await authController.cancelPendingSignup();

    if (!mounted) return;
    setState(() {
      _allowPop = true;
    });
    Navigator.pop(context, true);
  }

  void _continueToChildInfo() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChildInfoPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, authController, _) {
        final guardianName = authController.draft.parentName;
        final relationship = authController.draft.relationshipToChild;

        return PopScope(
          canPop: _allowPop,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) {
              _returnToSignup();
            }
          },
          child: OceanAuthScaffold(
            topSpacing: 88,
            leading: IconButton(
              onPressed: _returnToSignup,
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              color: const Color(0xFFC3C3C3),
            ),
            children: [
              const Text(
                'Continue with',
                textAlign: TextAlign.center,
                style: OceanAuthTextStyles.subtitle,
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  guardianName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontFamily: AppFonts.fredokaOne,
                    fontSize: 32,
                    fontWeight: FontWeight.w400,
                    height: 1.08,
                    letterSpacing: 0,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                relationship.isEmpty
                    ? 'guardian account already found'
                    : '$relationship account already found',
                textAlign: TextAlign.center,
                style: OceanAuthTextStyles.subtitle,
              ),
              const SizedBox(height: 30),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFFBFF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.18),
                  ),
                ),
                child: const Text(
                  'We will keep the guardian information the same and add a new child profile to this account.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF3F5F73),
                    fontFamily: AppFonts.fredoka,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.25,
                    letterSpacing: 0,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              PrimaryButton(
                text: 'Continue',
                onPressed: authController.isLoading
                    ? null
                    : _continueToChildInfo,
                isLoading: authController.isLoading,
              ),
              const SizedBox(height: 18),
              GestureDetector(
                onTap: _returnToSignup,
                child: const Text(
                  'Use a different email',
                  textAlign: TextAlign.center,
                  style: OceanAuthTextStyles.link,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
