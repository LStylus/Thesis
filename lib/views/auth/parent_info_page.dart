import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/testing_defaults.dart';
import '../../widgets/credentials_auth_scaffold.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/ocean_auth_scaffold.dart';
import '../../widgets/primary_button.dart';
import 'child_info_page.dart';

class ParentInfoPage extends StatefulWidget {
  const ParentInfoPage({super.key});

  @override
  State<ParentInfoPage> createState() => _ParentInfoPageState();
}

class _ParentInfoPageState extends State<ParentInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  String? _selectedRelationship;
  bool _allowPop = false;
  bool _isReturningToSignup = false;

  final List<String> _relationships = const [
    'Mother',
    'Father',
    'Guardian',
    'Sibling',
    'Relative',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    final authController = context.read<AuthController>();
    // Production behavior:
    // _nameController.text = authController.draft.parentName;
    // if (authController.draft.relationshipToChild.isNotEmpty) {
    //   _selectedRelationship = authController.draft.relationshipToChild;
    // }
    _nameController.text = authController.draft.parentName.isNotEmpty
        ? authController.draft.parentName
        : TestingDefaults.parentName;
    _selectedRelationship = authController.draft.relationshipToChild.isNotEmpty
        ? authController.draft.relationshipToChild
        : TestingDefaults.relationshipToChild;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
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

  void _goNext(AuthController authController) {
    if (!_formKey.currentState!.validate()) return;

    authController.saveParentInfo(
      parentName: _nameController.text,
      relationshipToChild: _selectedRelationship ?? '',
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChildInfoPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.read<AuthController>();
    final dense = MediaQuery.sizeOf(context).height < 420;

    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _returnToSignup();
        }
      },
      child: VoyageFlowScaffold(
        currentStep: 1,
        totalSteps: 2,
        onBack: _returnToSignup,
        title: 'About you',
        subtitle: 'Tell us about the person completing the screening.',
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CredentialFieldsLayout(
                firstField: CustomTextField(
                  controller: _nameController,
                  labelText: 'Your name',
                  hintText: 'Enter your full name',
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                secondField: DropdownButtonFormField<String>(
                  initialValue: _selectedRelationship,
                  decoration: OceanFormStyles.inputDecoration(
                    'Select relationship',
                    labelText: 'Relationship to child',
                    prefixIcon: const Icon(Icons.family_restroom_rounded),
                  ),
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF6E8995),
                  ),
                  items: _relationships
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(value, style: AppTextStyles.field),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedRelationship = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select your relationship';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(height: dense ? 10 : 20),
              PrimaryButton(
                text: 'Continue',
                onPressed: () => _goNext(authController),
                height: dense ? 48 : 56,
                borderRadius: 8,
                trailingIcon: Icons.arrow_forward_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
