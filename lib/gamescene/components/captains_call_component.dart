import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/animation.dart';

import '../../features/game/domain/game_level_kind.dart';
import '../game_scene_state.dart';
import 'illustrated_asset_component.dart';
import 'level_mechanic_component.dart';

class CaptainsCallComponent extends LevelMechanicComponent {
  late final IllustratedAssetComponent _submarine;
  late final IllustratedAssetComponent _sonar;
  late final IllustratedAssetComponent _ping;
  late final IllustratedAssetComponent _fuzzy;
  late final IllustratedAssetComponent _arm;
  late final IllustratedAssetComponent _treasure;
  late final IllustratedAssetComponent _success;
  late final IllustratedAssetComponent _rescue;
  late final IllustratedAssetComponent _panel;
  late final List<IllustratedAssetComponent> _assets;
  bool _loaded = false;

  CaptainsCallComponent() : super(levelKind: GameLevelKind.captainsCall);

  @override
  Future<void> onLoad() async {
    _submarine = _asset('submarine_main.svg', 5);
    _sonar = _asset('sonar_visual.svg', 3);
    _ping = _asset('sonar_ping_effect.svg', 4);
    _fuzzy = _asset('fuzzy_sonar_retry.svg', 4);
    _arm = _asset('rescue_arm.svg', 6);
    _treasure = _asset('treasure_chest.svg', 3);
    _success = _asset('submarine_success_effect.svg', 7);
    _rescue = _asset('rescue_effect.svg', 7);
    _panel = _asset('command_panel.svg', 2);
    _assets = [
      _submarine,
      _sonar,
      _ping,
      _fuzzy,
      _arm,
      _treasure,
      _success,
      _rescue,
      _panel,
    ];
    await addAll(_assets);
    _loaded = true;
    onStateSynced();
  }

  IllustratedAssetComponent _asset(String name, int priority) {
    return IllustratedAssetComponent(
      assetPath: 'game/captains_call/$name',
      priority: priority,
    );
  }

  @override
  void layoutFor(Vector2 gameSize) {
    super.layoutFor(gameSize);
    final unit = (gameSize.y * 0.27).clamp(112.0, 166.0).toDouble();
    _submarine.size = Vector2.all(unit * 1.08);
    for (final sonar in [_sonar, _ping, _fuzzy]) {
      sonar
        ..size = Vector2.all(unit * 0.92)
        ..position = Vector2(gameSize.x * 0.65, gameSize.y * 0.48);
    }
    _arm
      ..size = Vector2.all(unit * 0.76)
      ..position = Vector2(gameSize.x * 0.60, gameSize.y * 0.64);
    _treasure
      ..size = Vector2.all(unit * 0.70)
      ..position = Vector2(gameSize.x * 0.74, gameSize.y * 0.66);
    for (final effect in [_success, _rescue]) {
      effect
        ..size = Vector2.all(unit * 1.0)
        ..position = Vector2(gameSize.x * 0.60, gameSize.y * 0.49);
    }
    _panel
      ..size = Vector2.all(unit * 0.46)
      ..position = Vector2(gameSize.x * 0.32, gameSize.y * 0.68);
  }

  @override
  void onStateSynced() {
    if (!_hasAssets) return;
    for (final asset in _assets) {
      asset.visible = isActive;
    }
    _sonar.visible = isActive && state.phase == GamePhase.processing;
    _ping.visible = isActive && state.isCorrect;
    _fuzzy.visible = isActive && state.isRetry;
    _arm.visible = isActive && state.currentTarget >= 3;
    _success.visible = isActive && state.isCorrect;
    _rescue.visible = isActive && state.isCorrect && state.currentTarget >= 3;
  }

  bool get _hasAssets => _loaded;

  @override
  void update(double dt) {
    super.update(dt);
    if (!isActive || !_hasAssets) return;
    final start = Vector2(size.x * 0.42, size.y * 0.50);
    final end = Vector2(size.x * 0.61, size.y * 0.50);
    final action = state.isCorrect
        ? Curves.easeInOut.transform((phaseTime / 1.1).clamp(0.0, 1.0))
        : 0.0;
    final shake = state.isRetry ? math.sin(phaseTime * 18) * 5 : 0.0;
    _submarine.position = start + (end - start) * action + Vector2(shake, 0);
    _ping.scale = Vector2.all(0.88 + math.sin(phaseTime * 4).abs() * 0.14);
    _success.angle = phaseTime * 0.16;
  }
}
