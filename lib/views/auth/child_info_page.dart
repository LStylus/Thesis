import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/testing_defaults.dart';
import '../../models/profile_model.dart';
import '../../widgets/credentials_auth_scaffold.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/ocean_auth_scaffold.dart';
import '../../widgets/primary_button.dart';
import '../screening/screening_page.dart';

class ChildInfoPage extends StatefulWidget {
  const ChildInfoPage({super.key});

  @override
  State<ChildInfoPage> createState() => _ChildInfoPageState();
}

class _ChildInfoPageState extends State<ChildInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final _childNameController = TextEditingController();
  final _birthDateController = TextEditingController();

  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    final authController = context.read<AuthController>();
    // Production behavior:
    // _childNameController.text = authController.draft.childName;
    // _selectedDate = authController.draft.childBirthDate;
    _childNameController.text = authController.draft.childName.isNotEmpty
        ? authController.draft.childName
        : TestingDefaults.childName;
    _selectedDate =
        authController.draft.childBirthDate ?? TestingDefaults.childBirthDate;

    if (_selectedDate != null) {
      _birthDateController.text = DateFormat(
        'MMM d, yyyy',
      ).format(_selectedDate!);
    }
  }

  @override
  void dispose() {
    _childNameController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  bool _isSupportedAge(int age) {
    return age >= 4 && age <= 8;
  }

  Future<void> _showAgeWarning(int age) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Age not supported'),
        content: Text(
          'The child is $age years old.\n\n'
          'Voice Voyage screening is currently available only for ages 4 to 8.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(now.year - 5),
      firstDate: DateTime(2000),
      lastDate: now,
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _birthDateController.text = DateFormat('MMM d, yyyy').format(picked);
      });
    }
  }

  Future<void> _complete(AuthController authController) async {
    if (!_formKey.currentState!.validate()) return;

    final childAge = ProfileModel.calculateAge(_selectedDate!);

    if (!_isSupportedAge(childAge)) {
      await _showAgeWarning(childAge);
      return;
    }

    authController.saveChildInfo(
      childName: _childNameController.text,
      childBirthDate: _selectedDate,
    );

    final ok = await authController.validatePendingChildProfile();
    if (!mounted) return;

    if (ok) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StartScreeningPage(childAge: childAge),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, authController, _) {
        final dense = MediaQuery.sizeOf(context).height < 420;
        final agePreview = _selectedDate != null
            ? ProfileModel.calculateAge(_selectedDate!)
            : null;

        final showAgeWarningInline =
            agePreview != null && !_isSupportedAge(agePreview);

        return VoyageFlowScaffold(
          currentStep: 2,
          totalSteps: 2,
          onBack: () => Navigator.pop(context),
          title: 'About the child',
          subtitle:
              'Add the details used to prepare an age-appropriate screening.',
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CredentialFieldsLayout(
                  firstField: CustomTextField(
                    controller: _childNameController,
                    labelText: "Child's name",
                    hintText: 'Enter the child\'s name',
                    prefixIcon: const Icon(Icons.child_care_rounded),
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => authController.clearError(),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Please enter the child's name";
                      }
                      return null;
                    },
                  ),
                  secondField: TextFormField(
                    controller: _birthDateController,
                    readOnly: true,
                    onTap: _pickDate,
                    style: AppTextStyles.field,
                    decoration: OceanFormStyles.inputDecoration(
                      'Select date',
                      labelText: "Child's birthdate",
                      prefixIcon: dense
                          ? null
                          : const Icon(Icons.calendar_month_outlined),
                      suffixIcon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFF6E8995),
                      ),
                    ),
                    validator: (value) {
                      if (_selectedDate == null) {
                        return "Please select the child's birth date";
                      }

                      final age = ProfileModel.calculateAge(_selectedDate!);

                      if (age < 4 || age > 8) {
                        return 'Only ages 4 to 8 are allowed.';
                      }

                      return null;
                    },
                  ),
                ),
                if (showAgeWarningInline) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7E8),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFFD79B)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: Color(0xFFB76B00),
                          size: 19,
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            'Age $agePreview is outside the supported 4-8 year range.',
                            style: const TextStyle(
                              color: Color(0xFF8B560A),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (authController.errorMessage != null) ...[
                  const SizedBox(height: 10),
                  CredentialsErrorBanner(message: authController.errorMessage!),
                ],
                SizedBox(height: dense ? 10 : 20),
                PrimaryButton(
                  text: 'Continue to screening',
                  onPressed: authController.isLoading
                      ? null
                      : () => _complete(authController),
                  isLoading: authController.isLoading,
                  height: dense ? 48 : 56,
                  borderRadius: 8,
                  trailingIcon: Icons.arrow_forward_rounded,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
