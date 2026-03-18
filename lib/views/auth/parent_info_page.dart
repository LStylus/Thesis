import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';
import 'child_info_page.dart';

class ParentInfoPage extends StatefulWidget {
  final AuthController controller;

  const ParentInfoPage({super.key, required this.controller});

  @override
  State<ParentInfoPage> createState() => _ParentInfoPageState();
}

class _ParentInfoPageState extends State<ParentInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  String? _selectedRelationship;

  static const Color _primaryBlue = Color(0xFF12B5EA);
  static const Color _textGray = Color(0xFF8D8D8D);
  static const Color _borderGray = Color(0xFFD9D9D9);
  static const Color _bgColor = Color(0xFFF3F3F3);

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
    _nameController.text = widget.controller.draft.parentName;
    if (widget.controller.draft.relationshipToChild.isNotEmpty) {
      _selectedRelationship = widget.controller.draft.relationshipToChild;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFFA6A6A6), fontSize: 14),
      filled: true,
      fillColor: Colors.white,
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
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _returnToSignup() async {
    await widget.controller.cancelPendingSignup();

    if (!mounted) return false;
    Navigator.pop(context, true);
    return false;
  }

  void _goNext() {
    if (!_formKey.currentState!.validate()) return;

    widget.controller.saveParentInfo(
      parentName: _nameController.text,
      relationshipToChild: _selectedRelationship ?? '',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChildInfoPage(controller: widget.controller),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String text,
    required VoidCallback onPressed,
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
        child: Text(
          text,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _returnToSignup,
      child: Scaffold(
        backgroundColor: _bgColor,
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
                      _buildHeader(
                        title: 'Please tell us about yourself',
                        onPressed: _returnToSignup,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'person completing the pre-assessment questions',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _textGray, fontSize: 13),
                      ),
                      const SizedBox(height: 28),

                      SizedBox(
                        width: 390,
                        child: TextFormField(
                          controller: _nameController,
                          decoration: _inputDecoration('Name'),
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
                          decoration: _inputDecoration(
                            'Relationship to the child',
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
                        child: _buildPrimaryButton(
                          text: 'Next',
                          onPressed: _goNext,
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
