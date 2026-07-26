import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thesis/features/game/domain/game_level_kind.dart';
import 'package:thesis/gamescene/game_scene.dart';
import 'package:thesis/gamescene/game_scene_state.dart';

void main() {
  testWidgets('all four Flame level mechanics load and render', (tester) async {
    for (final kind in GameLevelKind.values) {
      final game = GameScene(
        initialState: GameSceneState(
          levelKind: kind,
          phase: GamePhase.recording,
          childName: 'Kai',
          levelTitle: kind.title,
          speechText: 'Your turn',
          targetText: 'PIG',
          focusText: 'PIG',
          targetAssetPath: 'assets/game/words/pig.svg',
          progressText: '1 / 4',
          currentTarget: 1,
          targetCount: 4,
          completedTargetCount: 0,
          micProgress: 0.5,
          countdown: 2,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 900,
            height: 520,
            child: GameWidget<GameScene>(game: game),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull, reason: '${kind.title} failed');
      game.pauseEngine();
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}
