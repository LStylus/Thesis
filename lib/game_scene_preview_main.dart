import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'features/game/domain/game_level_kind.dart';
import 'gamescene/game_scene.dart';
import 'gamescene/game_scene_state.dart';

void main() {
  runApp(const GameScenePreviewApp());
}

class GameScenePreviewApp extends StatelessWidget {
  const GameScenePreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DefaultTabController(
        length: GameLevelKind.values.length,
        child: Scaffold(
          appBar: AppBar(
            toolbarHeight: 0,
            backgroundColor: const Color(0xFF075274),
            bottom: TabBar(
              labelColor: const Color(0xFFFFE477),
              unselectedLabelColor: Colors.white70,
              indicatorColor: const Color(0xFFFFE477),
              tabs: [
                for (final kind in GameLevelKind.values) Tab(text: kind.title),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              for (final kind in GameLevelKind.values)
                GameWidget<GameScene>(
                  game: GameScene(initialState: _state(kind)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  GameSceneState _state(GameLevelKind kind) {
    return GameSceneState(
      levelKind: kind,
      phase: GamePhase.recording,
      childName: 'Kai',
      levelTitle: kind.title,
      speechText: 'Say: PIG',
      targetText: 'PIG',
      focusText: 'PIG',
      targetAssetPath: 'assets/game/words/pig.svg',
      progressText: '1 / 4',
      currentTarget: 1,
      targetCount: 4,
      completedTargetCount: 0,
      micProgress: 0.55,
      countdown: 2,
    );
  }
}
