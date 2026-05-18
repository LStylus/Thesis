import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/testing_defaults.dart';
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
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
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

    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _returnToSignup();
        }
      },
      child: OceanAuthScaffold(
        topSpacing: 82,
        leading: IconButton(
          onPressed: _returnToSignup,
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: const Color(0xFFC3C3C3),
        ),
        children: [
          Form(
            key: _formKey,
            child: Column(
              children: [
                const Text(
                  'Please tell us about\nyourself',
                  textAlign: TextAlign.center,
                  style: OceanAuthTextStyles.title,
                ),
                const SizedBox(height: 8),
                const Text(
                  'person completing the screening form',
                  textAlign: TextAlign.center,
                  style: OceanAuthTextStyles.subtitle,
                ),
                const SizedBox(height: 30),
                CustomTextField(
                  controller: _nameController,
                  hintText: 'Name',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 11),
                DropdownButtonFormField<String>(
                  initialValue: _selectedRelationship,
                  decoration: OceanFormStyles.inputDecoration(
                    'Relationship to the Child',
                  ),
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.borderGray,
                  ),
                  items: _relationships
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(
                            value,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
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
                const SizedBox(height: 16),
                PrimaryButton(
                  text: 'Next',
                  onPressed: () => _goNext(authController),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
