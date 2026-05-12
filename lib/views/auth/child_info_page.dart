import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../models/profile_model.dart';
import '../../widgets/auth_header.dart';
import '../../widgets/custom_text_field.dart';
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
    _childNameController.text = authController.draft.childName;
    _selectedDate = authController.draft.childBirthDate;

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

    final ok = await authController.completeSignup();
    if (!mounted) return;

    if (ok) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ScreeningPage(childAge: childAge)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Form(
                key: _formKey,
                child: Consumer<AuthController>(
                  builder: (context, authController, _) {
                    final agePreview = _selectedDate != null
                        ? ProfileModel.calculateAge(_selectedDate!)
                        : null;

                    final showAgeWarningInline =
                        agePreview != null && !_isSupportedAge(agePreview);

                    return Column(
                      children: [
                        AuthHeader(
                          title: 'Almost there!',
                          onBack: () => Navigator.pop(context),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "personalize the child's learning experience",
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
                        ),
                        const SizedBox(height: 12),

                        SizedBox(
                          width: 390,
                          child: TextFormField(
                            controller: _birthDateController,
                            readOnly: true,
                            onTap: _pickDate,
                            decoration: InputDecoration(
                              hintText: "Child's Birth Date",
                              suffixIcon: IconButton(
                                onPressed: _pickDate,
                                icon: const Icon(Icons.calendar_today_outlined),
                              ),
                            ),
                            validator: (value) {
                              if (_selectedDate == null) {
                                return "Please select the child's birth date";
                              }

                              final age = ProfileModel.calculateAge(
                                _selectedDate!,
                              );

                              if (age < 4 || age > 8) {
                                return 'Only ages 4 to 8 are allowed.';
                              }

                              return null;
                            },
                          ),
                        ),

                        if (showAgeWarningInline) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            width: 390,
                            child: Text(
                              'Warning: age $agePreview is outside the supported range. '
                              'Only children aged 4 to 8 can proceed.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),

                        SizedBox(
                          width: 390,
                          child: PrimaryButton(
                            text: 'Complete',
                            onPressed: authController.isLoading
                                ? null
                                : () => _complete(authController),
                            isLoading: authController.isLoading,
                          ),
                        ),

                        if (authController.errorMessage != null) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: 390,
                            child: Text(
                              authController.errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
