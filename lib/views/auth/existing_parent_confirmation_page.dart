import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../core/constants/app_fonts.dart';
import '../../widgets/credentials_auth_scaffold.dart';
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
        final dense = MediaQuery.sizeOf(context).height < 420;

        return PopScope(
          canPop: _allowPop,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) {
              _returnToSignup();
            }
          },
          child: VoyageFlowScaffold(
            eyebrow: 'Existing account',
            onBack: _returnToSignup,
            title: guardianName.isEmpty
                ? 'Welcome back'
                : 'Welcome back, $guardianName',
            subtitle: relationship.isEmpty
                ? 'We found an existing guardian account.'
                : 'We found an existing $relationship account.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(dense ? 12 : 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFCFE8EE)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.person_add_alt_1_rounded,
                        color: Color(0xFF168DB5),
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'The guardian information will stay the same. A new child profile will be added to this account.',
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
                    ],
                  ),
                ),
                SizedBox(height: dense ? 10 : 20),
                PrimaryButton(
                  text: 'Add child profile',
                  onPressed: authController.isLoading
                      ? null
                      : _continueToChildInfo,
                  isLoading: authController.isLoading,
                  height: dense ? 48 : 56,
                  borderRadius: 8,
                  trailingIcon: Icons.arrow_forward_rounded,
                ),
                SizedBox(height: dense ? 4 : 10),
                TextButton(
                  onPressed: _returnToSignup,
                  child: const Text(
                    'Use a different email address',
                    style: TextStyle(
                      color: Color(0xFF52717E),
                      fontFamily: AppFonts.fredoka,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
