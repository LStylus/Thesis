import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../models/profile_model.dart';
import '../../services/dynamic_modules_service.dart';
import '../../services/learning_module_store.dart';
import '../../widgets/practice_module_section.dart';
import '../../widgets/profile_avatar.dart';

/// Child profile panel — shows the child's identity, the phoneme errors
/// found during the last screening, and the generated practice module.
class ChildProfilePage extends StatefulWidget {
  final ProfileModel profile;

  /// Overridable data source (injectable for tests); defaults to the
  /// persisted learning store.
  final Future<StoredLearningData> Function()? dataLoader;

  const ChildProfilePage({
    super.key,
    required this.profile,
    this.dataLoader,
  });

  @override
  State<ChildProfilePage> createState() => _ChildProfilePageState();
}

class _ChildProfilePageState extends State<ChildProfilePage> {
  StoredLearningData? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final store = LearningModuleStore();
    var data = await (widget.dataLoader ?? store.load)();

    // Fetch the module live when the child has assessment findings but no
    // module yet (e.g. the module service was down during screening) — the
    // panel always shows the actual produced module, never a placeholder.
    if (data.hasInputs && data.module == null) {
      try {
        final module = await DynamicModulesService().buildModule(
          age: data.age!,
          processes: data.processes,
        );
        await store.save(module);
        data = StoredLearningData(
          age: data.age,
          processes: data.processes,
          module: module,
        );
        debugPrint(
          '[child-profile] module_fetched module_id=${module.moduleId} '
          'generated_by=${module.generatedBy}',
        );
      } catch (error) {
        debugPrint('[child-profile] module_fetch_failed error=$error');
      }
    }

    if (mounted) setState(() => _data = data);
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final data = _data;

    return Scaffold(
      backgroundColor: const Color(0xFFF2FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF124B63)),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Child Profile',
          style: TextStyle(
            color: AppColors.primary,
            fontFamily: AppFonts.fredokaOne,
            fontSize: 20,
            fontWeight: FontWeight.w400,
            letterSpacing: 0,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ProfilePanel(profile: profile),
              const SizedBox(height: 14),
              if (data == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.6,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                )
              else ...[
                _PhonemeErrorsPanel(
                  processes: data.processes,
                ),
                const SizedBox(height: 14),
                if (data.module != null)
                  PracticeModuleSection(module: data.module!)
                else
                  const _NoModuleMessage(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfilePanel extends StatelessWidget {
  final ProfileModel profile;

  const _ProfilePanel({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDCE8EC)),
      ),
      child: Row(
        children: [
          ProfileAvatar(
            assetPath: profile.profileAssetPath,
            fallbackSeed: profile.profileId,
            size: 62,
            borderWidth: 1.5,
            borderRadius: 31,
            borderColor: Colors.white,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.childName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF124B63),
                    fontFamily: AppFonts.fredokaOne,
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Age: ${profile.age} yrs old',
                  style: const TextStyle(
                    color: Color(0xFF66818D),
                    fontFamily: AppFonts.fredoka,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhonemeErrorsPanel extends StatelessWidget {
  final List<Map<String, dynamic>> processes;

  const _PhonemeErrorsPanel({required this.processes});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDCE8EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Phoneme errors',
            style: TextStyle(
              color: Color(0xFF124B63),
              fontFamily: AppFonts.fredokaOne,
              fontSize: 15,
              fontWeight: FontWeight.w400,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 10),
          if (processes.isEmpty)
            const Text(
              'No errors recorded yet. Complete a screening to see the '
              'child\'s phoneme errors here.',
              style: TextStyle(
                color: Color(0xFF8D9BA3),
                fontFamily: AppFonts.fredoka,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.4,
                letterSpacing: 0,
              ),
            )
          else
            for (final process in processes) ...[
              _PhonemeErrorRow(process: process),
              if (process != processes.last) const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}

class _PhonemeErrorRow extends StatelessWidget {
  final Map<String, dynamic> process;

  const _PhonemeErrorRow({required this.process});

  @override
  Widget build(BuildContext context) {
    final name = process['process']?.toString() ?? 'Unknown process';
    final position = process['position']?.toString() ?? '';
    final detail = process['detail']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE4EEF1)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFFF15D77),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  [name, if (position.isNotEmpty) position].join(' - '),
                  style: const TextStyle(
                    color: Color(0xFF124B63),
                    fontFamily: AppFonts.fredoka,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
                if (detail.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    style: const TextStyle(
                      color: Color(0xFF66818D),
                      fontFamily: AppFonts.fredoka,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoModuleMessage extends StatelessWidget {
  const _NoModuleMessage();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FAF5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFCBE6D6)),
      ),
      child: const Text(
        'No practice module yet. Complete a screening to generate a '
        'personalized practice module for this child.',
        style: TextStyle(
          color: Color(0xFF2E7D5B),
          fontFamily: AppFonts.fredoka,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          height: 1.4,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
