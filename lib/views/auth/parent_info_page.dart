import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/auth_header.dart';
import '../../widgets/custom_text_field.dart';
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
    _nameController.text = authController.draft.parentName;
    if (authController.draft.relationshipToChild.isNotEmpty) {
      _selectedRelationship = authController.draft.relationshipToChild;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<bool> _returnToSignup() async {
    final authController = context.read<AuthController>();
    await authController.cancelPendingSignup();

    if (!mounted) return false;
    Navigator.pop(context, true);
    return false;
  }

  void _goNext(AuthController authController) {
    if (!_formKey.currentState!.validate()) return;

    authController.saveParentInfo(
      parentName: _nameController.text,
      relationshipToChild: _selectedRelationship ?? '',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ChildInfoPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.read<AuthController>();

    return WillPopScope(
      onWillPop: _returnToSignup,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      AuthHeader(
                        title: 'Please tell us about yourself',
                        onBack: _returnToSignup,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'person completing the pre-assessment questions',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textGray,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 28),

                      SizedBox(
                        width: 390,
                        child: CustomTextField(
                          controller: _nameController,
                          hintText: 'Name',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 12),

                      SizedBox(
                        width: 390,
                        child: DropdownButtonFormField<String>(
                          value: _selectedRelationship,
                          decoration: const InputDecoration(
                            hintText: 'Relationship to the child',
                          ),
                          items: _relationships
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(
                                    value,
                                    style: const TextStyle(fontSize: 14),
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
                      ),
                      const SizedBox(height: 16),

                      SizedBox(
                        width: 390,
                        child: PrimaryButton(
                          text: 'Next',
                          onPressed: () => _goNext(authController),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
