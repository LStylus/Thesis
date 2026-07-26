import 'package:flame/components.dart';

import '../../features/game/domain/game_level_kind.dart';
import '../game_scene.dart';
import '../game_scene_state.dart';

abstract class LevelMechanicComponent extends PositionComponent
    with HasGameReference<GameScene> {
  final GameLevelKind levelKind;
  GameSceneState state;
  double phaseTime = 0;
  GamePhase _lastPhase;
  int _lastTarget;

  LevelMechanicComponent({required this.levelKind})
    : state = GameSceneState.initial(levelKind: levelKind),
      _lastPhase = GamePhase.loading,
      _lastTarget = 0,
      super(priority: 10);

  bool get isActive => state.levelKind == levelKind;

  void sync(GameSceneState nextState) {
    state = nextState;
    if (_lastPhase != nextState.phase ||
        _lastTarget != nextState.currentTarget) {
      _lastPhase = nextState.phase;
      _lastTarget = nextState.currentTarget;
      phaseTime = 0;
    }
    onStateSynced();
  }

  void onStateSynced() {}

  void layoutFor(Vector2 gameSize) {
    size = gameSize;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isActive) phaseTime += dt;
  }
}
