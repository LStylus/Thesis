import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/animation.dart';

import '../../features/game/domain/game_level_kind.dart';
import 'illustrated_asset_component.dart';
import 'level_mechanic_component.dart';

class ReefRouteComponent extends LevelMechanicComponent {
  late final IllustratedAssetComponent _path;
  late final IllustratedAssetComponent _closedGate;
  late final IllustratedAssetComponent _openGate;
  late final IllustratedAssetComponent _fishSchool;
  late final IllustratedAssetComponent _pausedFish;
  late final IllustratedAssetComponent _swimEffect;
  late final IllustratedAssetComponent _glow;
  late final IllustratedAssetComponent _checkpoint;
  late final List<IllustratedAssetComponent> _assets;
  bool _loaded = false;

  ReefRouteComponent() : super(levelKind: GameLevelKind.reefRoute);

  @override
  Future<void> onLoad() async {
    _path = _asset('route_path.svg', 2);
    _closedGate = _asset('reef_gate_closed.svg', 4);
    _openGate = _asset('reef_gate_open.svg', 4);
    _fishSchool = _asset('fish_school.svg', 5);
    _pausedFish = _asset('paused_before_gate.svg', 5);
    _swimEffect = _asset('fish_swim_effect.svg', 6);
    _glow = _asset('gate_success_glow.svg', 7);
    _checkpoint = _asset('coral_checkpoint.svg', 3);
    _assets = [
      _path,
      _closedGate,
      _openGate,
      _fishSchool,
      _pausedFish,
      _swimEffect,
      _glow,
      _checkpoint,
    ];
    await addAll(_assets);
    _loaded = true;
    onStateSynced();
  }

  IllustratedAssetComponent _asset(String name, int priority) {
    return IllustratedAssetComponent(
      assetPath: 'game/reef_route/$name',
      priority: priority,
    );
  }

  @override
  void layoutFor(Vector2 gameSize) {
    super.layoutFor(gameSize);
    final unit = (gameSize.y * 0.26).clamp(110.0, 160.0).toDouble();
    _path
      ..size = Vector2(unit * 1.55, unit * 0.72)
      ..position = Vector2(gameSize.x * 0.50, gameSize.y * 0.59)
      ..angle = -0.11;
    for (final gate in [_closedGate, _openGate]) {
      gate
        ..size = Vector2.all(unit * 1.02)
        ..position = Vector2(gameSize.x * 0.64, gameSize.y * 0.50);
    }
    for (final fish in [_fishSchool, _pausedFish]) {
      fish.size = Vector2.all(unit * 0.72);
    }
    _swimEffect
      ..size = Vector2.all(unit * 0.86)
      ..position = Vector2(gameSize.x * 0.46, gameSize.y * 0.51);
    _glow
      ..size = Vector2.all(unit * 1.10)
      ..position = Vector2(gameSize.x * 0.64, gameSize.y * 0.50);
    _checkpoint
      ..size = Vector2.all(unit * 0.72)
      ..position = Vector2(gameSize.x * 0.75, gameSize.y * 0.66);
  }

  @override
  void onStateSynced() {
    if (!_hasAssets) return;
    for (final asset in _assets) {
      asset.visible = isActive;
    }
    _closedGate.visible = isActive && !state.isCorrect;
    _openGate.visible = isActive && state.isCorrect;
    _fishSchool.visible = isActive && !state.isRetry;
    _pausedFish.visible = isActive && state.isRetry;
    _swimEffect.visible = isActive && state.isCorrect;
    _glow.visible = isActive && state.isCorrect;
  }

  bool get _hasAssets => _loaded;

  @override
  void update(double dt) {
    super.update(dt);
    if (!isActive || !_hasAssets) return;
    final start = Vector2(size.x * 0.35, size.y * 0.50);
    final end = Vector2(size.x * 0.72, size.y * 0.50);
    final travel = state.isCorrect
        ? Curves.easeInOut.transform(((phaseTime - 0.25) / 1.0).clamp(0.0, 1.0))
        : 0.0;
    final pause = state.isRetry ? math.sin(phaseTime * 9) * 4 : 0.0;
    final fishPosition = start + (end - start) * travel + Vector2(pause, 0);
    _fishSchool.position = fishPosition;
    _pausedFish.position = fishPosition;
    _glow.angle = phaseTime * 0.15;
  }
}
