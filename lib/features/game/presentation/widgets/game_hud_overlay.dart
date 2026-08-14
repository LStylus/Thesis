import 'package:flutter/material.dart';

import '../../../../gamescene/game_scene.dart';
import '../../../../gamescene/game_scene_state.dart';
import '../../application/game_session_controller.dart';
import 'game_result_panel.dart';

class GameHudOverlay extends StatelessWidget {
  final GameScene game;
  final GameSessionController controller;
  final VoidCallback onClose;

  const GameHudOverlay({
    super.key,
    required this.game,
    required this.controller,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final safePadding = MediaQuery.paddingOf(context);
    return ValueListenableBuilder<GameSceneState>(
      valueListenable: game.sceneStateNotifier,
      builder: (context, sceneState, _) {
        final showPanel =
            sceneState.phase == GamePhase.completed ||
            sceneState.phase == GamePhase.invalidAudio ||
            sceneState.phase == GamePhase.error;
        return Stack(
          children: [
            Positioned(
              top: safePadding.top + 10,
              left: 14,
              child: _SquareIconButton(
                icon: Icons.close_rounded,
                onTap: onClose,
              ),
            ),
            if (showPanel)
              Positioned.fill(
                child: Center(
                  child: AnimatedBuilder(
                    animation: controller,
                    builder: (context, _) {
                      return GameResultPanel(
                        state: controller.state,
                        onRetry: controller.retryCurrent,
                        onFinish: controller.finishLevel,
                      );
                    },
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SquareIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SquareIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Close level',
      button: true,
      child: IconButton.filled(
        tooltip: 'Close level',
        onPressed: onTap,
        icon: Icon(icon),
        style: IconButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.88),
          foregroundColor: const Color(0xFF6C7B85),
          minimumSize: const Size(38, 38),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
    );
  }
}
