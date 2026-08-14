import 'package:flutter/material.dart';

import '../core/constants/app_fonts.dart';
import '../models/learning_module_model.dart';

/// Text-only display of a personalized practice module.
///
/// Renders the outline title, focus sounds, target processes, the LLM
/// rationale, and the four level groups (syllable / word / phrase /
/// sentence) as simple text chips — no assets, no audio.
class PracticeModuleSection extends StatelessWidget {
  final LearningModuleModel module;

  const PracticeModuleSection({super.key, required this.module});

  static const Map<String, String> _levelLabels = {
    'syllable': 'Syllables',
    'word': 'Words',
    'phrase': 'Phrases',
    'sentence': 'Sentences',
  };

  @override
  Widget build(BuildContext context) {
    final focus = module.focusSounds.isEmpty
        ? ''
        : ' / ${module.focusSounds.join(', ')}';
    final processText =
        module.focusProcesses.isEmpty ? '' : module.focusProcesses.join(', ');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FAF5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCBE6D6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Practice module',
            style: TextStyle(
              color: Color(0xFF2E7D5B),
              fontFamily: AppFonts.fredokaOne,
              fontSize: 13,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            module.outlineTitle.isEmpty
                ? 'Personalized practice plan'
                : module.outlineTitle,
            style: const TextStyle(
              color: Color(0xFF124B63),
              fontFamily: AppFonts.fredokaOne,
              fontSize: 16,
              fontWeight: FontWeight.w400,
              letterSpacing: 0,
            ),
          ),
          if (focus.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Focus sounds:$focus',
              style: const TextStyle(
                color: Color(0xFF426674),
                fontFamily: AppFonts.fredoka,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
          ],
          if (processText.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              'Targets: $processText',
              style: const TextStyle(
                color: Color(0xFF426674),
                fontFamily: AppFonts.fredoka,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
          ],
          if (module.rationale.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              module.rationale,
              style: const TextStyle(
                color: Color(0xFF66818D),
                fontFamily: AppFonts.fredoka,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.3,
                letterSpacing: 0,
              ),
            ),
          ],
          for (final level in module.levels) ...[
            if (level.items.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                _levelLabels[level.level] ?? level.level,
                style: const TextStyle(
                  color: Color(0xFF2E7D5B),
                  fontFamily: AppFonts.fredokaOne,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: level.items
                    .map((item) => _ItemChip(text: item.text))
                    .toList(),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ItemChip extends StatelessWidget {
  final String text;

  const _ItemChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2E9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF2E7D5B),
          fontFamily: AppFonts.fredoka,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
