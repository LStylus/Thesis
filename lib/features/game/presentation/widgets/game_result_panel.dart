import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../gamescene/game_scene_state.dart';
import '../../application/game_session_state.dart';

class GameResultPanel extends StatelessWidget {
  final GameSessionState state;
  final VoidCallback onRetry;
  final VoidCallback onFinish;

  const GameResultPanel({
    super.key,
    required this.state,
    required this.onRetry,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    final completed = state.phase == GamePhase.completed;
    final invalidAudio = state.phase == GamePhase.invalidAudio;
    final title = completed
        ? '${state.levelTitle} complete!'
        : invalidAudio
        ? 'Let us try that again'
        : 'A quick pause';
    final message = completed
        ? '${state.completedTargetIds.length} targets completed'
        : state.message ?? 'Please try again.';

    return Container(
      width: 320,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            completed ? Icons.verified_rounded : Icons.graphic_eq_rounded,
            color: completed ? const Color(0xFF20A85B) : AppColors.primary,
            size: 38,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF31566B),
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textGray,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
          if (completed) ...[
            const SizedBox(height: 10),
            Text(
              '${state.averageAccuracy()}% average',
              style: const TextStyle(
                color: Color(0xFF20A85B),
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: completed ? onFinish : onRetry,
              icon: Icon(
                completed ? Icons.map_rounded : Icons.replay_rounded,
                size: 19,
              ),
              label: Text(completed ? 'Back to map' : 'Try again'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
