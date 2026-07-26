import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/animation.dart';

import '../../features/game/domain/game_level_kind.dart';
import '../game_scene_state.dart';
import 'illustrated_asset_component.dart';
import 'level_mechanic_component.dart';

class CoralCargoComponent extends LevelMechanicComponent {
  late final IllustratedAssetComponent _tube;
  late final IllustratedAssetComponent _platform;
  late final IllustratedAssetComponent _box;
  late final IllustratedAssetComponent _turtle;
  late final IllustratedAssetComponent _octopus;
  late final IllustratedAssetComponent _success;
  late final IllustratedAssetComponent _mixUp;
  late final IllustratedAssetComponent _retry;
  late final IllustratedAssetComponent _complete;
  late final List<IllustratedAssetComponent> _assets;
  bool _loaded = false;

  CoralCargoComponent() : super(levelKind: GameLevelKind.coralCargo);

  @override
  Future<void> onLoad() async {
    _tube = _asset('cargo_tube.svg', 2);
    _platform = _asset('cargo_platform.svg', 3);
    _box = _asset('cargo_box.svg', 5);
    _turtle = _asset('receiver_turtle.svg', 4);
    _octopus = _asset('receiver_octopus.svg', 4);
    _success = _asset('success_delivery_effect.svg', 7);
    _mixUp = _asset('mix_up_effect.svg', 6);
    _retry = _asset('retry_state.svg', 7);
    _complete = _asset('completed_delivery_effect.svg', 8);
    _assets = [
      _tube,
      _platform,
      _box,
      _turtle,
      _octopus,
      _success,
      _mixUp,
      _retry,
      _complete,
    ];
    await addAll(_assets);
    _loaded = true;
    onStateSynced();
  }

  IllustratedAssetComponent _asset(String name, int priority) {
    return IllustratedAssetComponent(
      assetPath: 'game/coral_cargo/$name',
      priority: priority,
    );
  }

  @override
  void layoutFor(Vector2 gameSize) {
    super.layoutFor(gameSize);
    final unit = (gameSize.y * 0.26).clamp(110.0, 160.0).toDouble();
    _tube
      ..size = Vector2(unit * 2.0, unit * 0.64)
      ..position = Vector2(gameSize.x * 0.53, gameSize.y * 0.50);
    _platform
      ..size = Vector2.all(unit * 0.82)
      ..position = Vector2(gameSize.x * 0.36, gameSize.y * 0.64);
    _box.size = Vector2.all(unit * 0.54);
    for (final receiver in [_turtle, _octopus]) {
      receiver
        ..size = Vector2.all(unit * 0.78)
        ..position = Vector2(gameSize.x * 0.73, gameSize.y * 0.50);
    }
    for (final effect in [_success, _retry, _complete]) {
      effect
        ..size = Vector2.all(unit * 1.0)
        ..position = Vector2(gameSize.x * 0.62, gameSize.y * 0.49);
    }
    _mixUp
      ..size = Vector2.all(unit * 0.72)
      ..position = Vector2(gameSize.x * 0.54, gameSize.y * 0.48);
  }

  @override
  void onStateSynced() {
    if (!_hasAssets) return;
    for (final asset in _assets) {
      asset.visible = isActive;
    }
    final turtleTurn = state.currentTarget.isOdd;
    _turtle.visible = isActive && turtleTurn;
    _octopus.visible = isActive && !turtleTurn;
    _success.visible = isActive && state.isCorrect;
    _mixUp.visible = isActive && state.phase == GamePhase.retry;
    _retry.visible = isActive && state.phase == GamePhase.invalidAudio;
    _complete.visible = isActive && state.phase == GamePhase.completed;
  }

  bool get _hasAssets => _loaded;

  @override
  void update(double dt) {
    super.update(dt);
    if (!isActive || !_hasAssets) return;
    final start = Vector2(size.x * 0.37, size.y * 0.49);
    final end = Vector2(size.x * 0.68, size.y * 0.49);
    final travel = state.isCorrect
        ? Curves.easeInOut.transform((phaseTime / 1.05).clamp(0.0, 1.0))
        : 0.05;
    final shake = state.isRetry ? math.sin(phaseTime * 14) * 6 : 0.0;
    _box.position = start + (end - start) * travel + Vector2(shake, 0);
    _complete.angle = phaseTime * 0.18;
  }
}
