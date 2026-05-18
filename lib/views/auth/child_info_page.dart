import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/testing_defaults.dart';
import '../../models/profile_model.dart';
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
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
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
        'MMMM dd, yyyy',
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
        _birthDateController.text = DateFormat('MMMM dd, yyyy').format(picked);
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
      Navigator.pushReplacement(
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
        final agePreview = _selectedDate != null
            ? ProfileModel.calculateAge(_selectedDate!)
            : null;

        final showAgeWarningInline =
            agePreview != null && !_isSupportedAge(agePreview);

        return OceanAuthScaffold(
          topSpacing: AppSpacing.authTopSpacing,
          leading: OceanBackButton(onPressed: () => Navigator.pop(context)),
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  const Text(
                    'Almost there',
                    textAlign: TextAlign.center,
                    style: OceanAuthTextStyles.title,
                  ),
                  const SizedBox(height: AppSpacing.gapXs),
                  const Text(
                    'tell us about the child',
                    textAlign: TextAlign.center,
                    style: OceanAuthTextStyles.subtitle,
                  ),
                  const SizedBox(height: AppSpacing.gapXl),
                  CustomTextField(
                    controller: _childNameController,
                    hintText: "Child's Name",
                    onChanged: (_) => authController.clearError(),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Please enter the child's name";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.gapSm),
                  TextFormField(
                    controller: _birthDateController,
                    readOnly: true,
                    onTap: _pickDate,
                    style: AppTextStyles.field,
                    decoration: OceanFormStyles.inputDecoration(
                      "Child's Birthdate",
                      suffixIcon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.borderGray,
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
                  if (showAgeWarningInline) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Warning: age $agePreview is outside the supported range. '
                      'Only children aged 4 to 8 can proceed.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.gapMd),
                  PrimaryButton(
                    text: 'Complete',
                    onPressed: authController.isLoading
                        ? null
                        : () => _complete(authController),
                    isLoading: authController.isLoading,
                  ),
                  if (authController.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      authController.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
