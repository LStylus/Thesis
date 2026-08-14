import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thesis/features/game/domain/game_template_kind.dart';
import 'package:thesis/gamescene/game_scene.dart';
import 'package:thesis/gamescene/game_scene_state.dart';

void main() {
  testWidgets('all eight Flame templates load and render', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 520));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final template in GameTemplateKind.values) {
      final game = GameScene(
        initialState: GameSceneState(
          template: template,
          phase: GamePhase.interaction,
          childName: 'Kai',
          levelTitle: template.title,
          speechText: template.instruction,
          targetText: 'PIG',
          focusText: 'PIG',
          targetAssetPath: 'assets/game/words/pig.svg',
          progressText: '1 / 4',
          currentTarget: 1,
          targetCount: 4,
          completedTargetCount: 0,
          targetPieces: const ['P', 'I', 'G'],
          targetOptions: const ['PIG', 'BIG'],
          correctOptionIndex: 0,
        ),
        onInteractionCompleted: () {},
      );

      await tester.pumpWidget(
        MaterialApp(home: GameWidget<GameScene>(game: game)),
      );
      await _waitForGame(tester, game);

      expect(
        tester.takeException(),
        isNull,
        reason: '${template.title} failed',
      );
      game.pauseEngine();
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('tap mechanics complete only on their intended target', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 520));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final targets = <GameTemplateKind, List<Offset>>{
      GameTemplateKind.tapAndPop: const [Offset(423, 310)],
      GameTemplateKind.minimalPairMatch: const [Offset(411, 299)],
      GameTemplateKind.echoCave: const [Offset(504, 299)],
      GameTemplateKind.sequenceJumper: const [
        Offset(388, 323),
        Offset(504, 275),
        Offset(620, 323),
      ],
      GameTemplateKind.voicePoweredJourney: const [Offset(394, 277)],
      GameTemplateKind.soundMeterChallenge: const [Offset(362, 299)],
    };

    for (final entry in targets.entries) {
      var completions = 0;
      final game = _game(entry.key, () => completions++);
      await tester.pumpWidget(
        MaterialApp(home: GameWidget<GameScene>(game: game)),
      );
      await _waitForGame(tester, game);

      for (final point in entry.value) {
        await tester.tapAt(point);
        await tester.pump(const Duration(milliseconds: 40));
      }

      expect(completions, 1, reason: '${entry.key.title} did not complete');
      game.pauseEngine();
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('drag mechanics complete at their correct destinations', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 520));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var sortCompletions = 0;
    final sortGame = _game(
      GameTemplateKind.bucketSort,
      () => sortCompletions++,
    );
    await tester.pumpWidget(
      MaterialApp(home: GameWidget<GameScene>(game: sortGame)),
    );
    await _waitForGame(tester, sortGame);
    await tester.dragFrom(const Offset(504, 181), const Offset(-98, 133));
    await tester.pump(const Duration(milliseconds: 60));
    expect(sortCompletions, 1);
    sortGame.pauseEngine();

    var builderCompletions = 0;
    final builderGame = _game(
      GameTemplateKind.soundBuilder,
      () => builderCompletions++,
    );
    await tester.pumpWidget(
      MaterialApp(home: GameWidget<GameScene>(game: builderGame)),
    );
    await _waitForGame(tester, builderGame);
    for (final drag in const [
      (Offset(596, 405), Offset(-184, -211)),
      (Offset(504, 405), Offset(0, -211)),
      (Offset(412, 405), Offset(184, -211)),
    ]) {
      await tester.dragFrom(drag.$1, drag.$2);
      await tester.pump(const Duration(milliseconds: 60));
    }
    expect(builderCompletions, 1);
    builderGame.pauseEngine();
  });
}

Future<void> _waitForGame(WidgetTester tester, GameScene game) async {
  await tester.pump();
  await tester.runAsync(game.ready);
  await tester.pump(const Duration(milliseconds: 500));
}

GameScene _game(GameTemplateKind template, VoidCallback onComplete) {
  return GameScene(
    initialState: GameSceneState(
      template: template,
      phase: GamePhase.interaction,
      childName: 'Kai',
      levelTitle: template.title,
      speechText: template.instruction,
      targetText: 'PIG',
      focusText: 'PIG',
      targetAssetPath: 'assets/game/words/pig.svg',
      progressText: '1 / 4',
      currentTarget: 1,
      targetCount: 4,
      completedTargetCount: 0,
      targetPieces: const ['P', 'I', 'G'],
      targetOptions: const ['PIG', 'BIG'],
      correctOptionIndex: 0,
    ),
    onInteractionCompleted: onComplete,
  );
}
