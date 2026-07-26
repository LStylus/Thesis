import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame_svg/flame_svg.dart';

import '../game_scene.dart';
import '../game_scene_state.dart';

class MascotComponent extends SvgComponent with HasGameReference<GameScene> {
  final Map<String, Svg> _variants = {};
  GamePhase _phase = GamePhase.loading;
  double _time = 0;
  Vector2 _basePosition = Vector2.zero();

  MascotComponent() : super(anchor: Anchor.center, priority: 15);

  @override
  Future<void> onLoad() async {
    for (final name in _variantNames) {
      _variants[name] = await game.loadSvg('game/shared/whale_$name.svg');
    }
    svg = _variants['idle'];
  }

  void sync(GameSceneState state) {
    _phase = state.phase;
    svg = _variants[_variantFor(state.phase)] ?? _variants['idle'];
  }

  void layoutFor(Vector2 gameSize) {
    final width = (gameSize.x * 0.15).clamp(108.0, 166.0).toDouble();
    size = Vector2.all(width);
    _basePosition = Vector2(gameSize.x * 0.87, gameSize.y * 0.69);
    position = _basePosition;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    final excited =
        _phase == GamePhase.correct || _phase == GamePhase.completed;
    final recording = _phase == GamePhase.recording;
    final bob = math.sin(_time * math.pi * 1.7) * 4;
    final pulse = excited
        ? 1 + math.sin(_time * math.pi * 5.2) * 0.045
        : recording
        ? 1 + math.sin(_time * math.pi * 2.8) * 0.025
        : 1.0;
    position = _basePosition + Vector2(0, bob);
    scale = Vector2.all(pulse);
    angle = math.sin(_time * math.pi) * (excited ? 0.035 : 0.012);
  }

  String _variantFor(GamePhase phase) {
    return switch (phase) {
      GamePhase.loading => 'thinking',
      GamePhase.instruction => 'encouraging',
      GamePhase.recording => 'listening',
      GamePhase.processing => 'thinking',
      GamePhase.correct => 'happy',
      GamePhase.retry => 'retry',
      GamePhase.invalidAudio => 'encouraging',
      GamePhase.transitioning => 'holding_pearl',
      GamePhase.completed => 'celebrating',
      GamePhase.error => 'encouraging',
    };
  }
}

const _variantNames = [
  'idle',
  'happy',
  'listening',
  'encouraging',
  'thinking',
  'celebrating',
  'speaking',
  'retry',
  'holding_pearl',
];
