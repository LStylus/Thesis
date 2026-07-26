import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../features/game/domain/game_level_kind.dart';
import '../game_scene.dart';
import '../game_scene_state.dart';

class BackgroundComponent extends PositionComponent
    with HasGameReference<GameScene> {
  final Map<GameLevelKind, Sprite> _backgrounds = {};
  GameLevelKind _levelKind = GameLevelKind.bubbleBay;

  @override
  Future<void> onLoad() async {
    for (final entry in _paths.entries) {
      _backgrounds[entry.key] = Sprite(await game.images.load(entry.value));
    }
  }

  void sync(GameSceneState state) {
    _levelKind = state.levelKind;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
  }

  @override
  void render(Canvas canvas) {
    _backgrounds[_levelKind]?.render(canvas, size: size);
    canvas.drawRect(
      Offset.zero & Size(size.x, size.y),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x0DFFFFFF), Color(0x08000000), Color(0x2600172C)],
        ).createShader(Offset.zero & Size(size.x, size.y)),
    );
  }
}

const _paths = {
  GameLevelKind.bubbleBay: 'game/bubble_bay/bubble_bay_background.png',
  GameLevelKind.coralCargo: 'game/coral_cargo/coral_cargo_background.png',
  GameLevelKind.reefRoute: 'game/reef_route/reef_route_background.png',
  GameLevelKind.captainsCall: 'game/captains_call/captains_call_background.png',
};
