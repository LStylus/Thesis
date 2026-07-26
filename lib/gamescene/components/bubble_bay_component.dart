import 'dart:math' as math;

import 'package:flame/components.dart';

import '../../features/game/domain/game_level_kind.dart';
import '../game_scene_state.dart';
import 'illustrated_asset_component.dart';
import 'level_mechanic_component.dart';

class BubbleBayComponent extends LevelMechanicComponent {
  late final IllustratedAssetComponent _ring;
  late final IllustratedAssetComponent _pearlOff;
  late final IllustratedAssetComponent _pearlOn;
  late final IllustratedAssetComponent _slot;
  late final IllustratedAssetComponent _bubbleIdle;
  late final IllustratedAssetComponent _bubblePartial;
  late final IllustratedAssetComponent _bubbleFull;
  late final IllustratedAssetComponent _success;
  late final IllustratedAssetComponent _retry;
  late final IllustratedAssetComponent _invalid;
  late final List<IllustratedAssetComponent> _assets;
  bool _loaded = false;

  BubbleBayComponent() : super(levelKind: GameLevelKind.bubbleBay);

  @override
  Future<void> onLoad() async {
    _ring = _asset('coral_ring.svg', 2);
    _pearlOff = _asset('glowing_pearl_off.svg', 3);
    _pearlOn = _asset('glowing_pearl_on.svg', 4);
    _slot = _asset('pearl_slot.svg', 2);
    _bubbleIdle = _asset('sound_bubble_idle.svg', 5);
    _bubblePartial = _asset('sound_bubble_partial.svg', 5);
    _bubbleFull = _asset('sound_bubble_full.svg', 6);
    _success = _asset('success_sparkle.svg', 7);
    _retry = _asset('retry_effect.svg', 7);
    _invalid = _asset('invalid_audio_effect.svg', 7);
    _assets = [
      _ring,
      _pearlOff,
      _pearlOn,
      _slot,
      _bubbleIdle,
      _bubblePartial,
      _bubbleFull,
      _success,
      _retry,
      _invalid,
    ];
    await addAll(_assets);
    _loaded = true;
    onStateSynced();
  }

  IllustratedAssetComponent _asset(String name, int priority) {
    return IllustratedAssetComponent(
      assetPath: 'game/bubble_bay/$name',
      priority: priority,
    );
  }

  @override
  void layoutFor(Vector2 gameSize) {
    super.layoutFor(gameSize);
    final unit = (gameSize.y * 0.27).clamp(112.0, 166.0).toDouble();
    _ring
      ..size = Vector2.all(unit * 1.08)
      ..position = Vector2(gameSize.x * 0.62, gameSize.y * 0.49);
    _slot
      ..size = Vector2.all(unit * 0.62)
      ..position = Vector2(gameSize.x * 0.73, gameSize.y * 0.69);
    for (final pearl in [_pearlOff, _pearlOn]) {
      pearl
        ..size = Vector2.all(unit * 0.36)
        ..position = Vector2(gameSize.x * 0.73, gameSize.y * 0.67);
    }
    for (final bubble in [_bubbleIdle, _bubblePartial, _bubbleFull]) {
      bubble.size = Vector2.all(unit * 0.68);
    }
    for (final effect in [_success, _retry, _invalid]) {
      effect
        ..size = Vector2.all(unit * 1.05)
        ..position = Vector2(gameSize.x * 0.54, gameSize.y * 0.49);
    }
  }

  @override
  void onStateSynced() {
    if (!_hasAssets) return;
    for (final asset in _assets) {
      asset.visible = isActive;
    }
    _pearlOff.visible = isActive && !state.isCorrect;
    _pearlOn.visible = isActive && state.isCorrect;
    _bubbleIdle.visible =
        isActive &&
        !state.isRecording &&
        !state.isProcessing &&
        !state.isCorrect &&
        !state.isRetry;
    _bubblePartial.visible =
        isActive &&
        (state.isRetry || (state.isRecording && state.micProgress < 0.68));
    _bubbleFull.visible =
        isActive &&
        (state.isCorrect ||
            state.isProcessing ||
            (state.isRecording && state.micProgress >= 0.68));
    _success.visible = isActive && state.isCorrect;
    _retry.visible = isActive && state.phase == GamePhase.retry;
    _invalid.visible = isActive && state.phase == GamePhase.invalidAudio;
  }

  bool get _hasAssets => _loaded;

  @override
  void update(double dt) {
    super.update(dt);
    if (!isActive || !_hasAssets) return;
    final start = Vector2(size.x * 0.42, size.y * 0.49);
    final end = Vector2(size.x * 0.62, size.y * 0.49);
    final progress = state.isCorrect ? (phaseTime / 1.05).clamp(0.0, 1.0) : 0.0;
    final wobble = state.isRetry ? math.sin(phaseTime * 15) * 7 : 0.0;
    final position = start + (end - start) * progress + Vector2(wobble, 0);
    for (final bubble in [_bubbleIdle, _bubblePartial, _bubbleFull]) {
      bubble.position = position;
    }
    _pearlOn.alpha = (phaseTime / 0.5).clamp(0.15, 1.0);
    _success.angle = phaseTime * 0.22;
  }
}
