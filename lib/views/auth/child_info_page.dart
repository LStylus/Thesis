import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../controllers/auth_controller.dart';
import '../screening/screening_page.dart';

class ChildInfoPage extends StatefulWidget {
  final AuthController controller;

  const ChildInfoPage({super.key, required this.controller});

  @override
  State<ChildInfoPage> createState() => _ChildInfoPageState();
}

class _ChildInfoPageState extends State<ChildInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final _childNameController = TextEditingController();
  final _birthDateController = TextEditingController();

  DateTime? _selectedDate;

  static const Color _primaryBlue = Color(0xFF12B5EA);
  static const Color _textGray = Color(0xFF8D8D8D);
  static const Color _borderGray = Color(0xFFD9D9D9);
  static const Color _bgColor = Color(0xFFF3F3F3);

  @override
  void initState() {
    super.initState();
    _childNameController.text = widget.controller.draft.childName;
    _selectedDate = widget.controller.draft.childBirthDate;

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

  int _calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;

    final hasHadBirthdayThisYear =
        (today.month > birthDate.month) ||
        (today.month == birthDate.month && today.day >= birthDate.day);

    if (!hasHadBirthdayThisYear) {
      age--;
    }

    return age;
  }

  InputDecoration _inputDecoration(String hintText, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFFA6A6A6), fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _borderGray),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _borderGray),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _primaryBlue, width: 1.3),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red, width: 1.3),
      ),
    );
  }

  Widget _buildHeader({
    required String title,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 390,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: onPressed,
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              color: const Color(0xFFC3C3C3),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _primaryBlue,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
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

  Future<void> _complete() async {
    if (!_formKey.currentState!.validate()) return;

    widget.controller.saveChildInfo(
      childName: _childNameController.text,
      childBirthDate: _selectedDate,
    );

    final ok = await widget.controller.completeSignup();
    if (!mounted) return;

    if (ok) {
      final childAge = _calculateAge(_selectedDate!);

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ScreeningPage(childAge: childAge)),
      );
    }
  }

  Widget _buildPrimaryButton({
    required String text,
    required VoidCallback? onPressed,
    required bool isLoading,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Form(
                key: _formKey,
                child: AnimatedBuilder(
                  animation: widget.controller,
                  builder: (context, _) {
                    return Column(
                      children: [
                        _buildHeader(
                          title: 'Almost there!',
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "personalize the child's learning experience",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: _textGray, fontSize: 13),
                        ),
                        const SizedBox(height: 28),

                        SizedBox(
                          width: 390,
                          child: TextFormField(
                            controller: _childNameController,
                            onChanged: (_) => widget.controller.clearError(),
                            decoration: _inputDecoration("Child's Name"),
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
                            decoration: _inputDecoration(
                              "Child's Birth Date",
                              suffixIcon: IconButton(
                                onPressed: _pickDate,
                                icon: const Icon(Icons.calendar_today_outlined),
                              ),
                            ),
                            validator: (value) {
                              if (_selectedDate == null) {
                                return "Please select the child's birth date";
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        SizedBox(
                          width: 390,
                          child: _buildPrimaryButton(
                            text: 'Complete',
                            onPressed: widget.controller.isLoading
                                ? null
                                : _complete,
                            isLoading: widget.controller.isLoading,
                          ),
                        ),

                        if (widget.controller.errorMessage != null) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: 390,
                            child: Text(
                              widget.controller.errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.red,
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
