import 'dart:ui';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame_svg/flame_svg.dart';

import '../game_scene.dart';
import '../game_scene_state.dart';

class BackgroundComponent extends PositionComponent
    with HasGameReference<GameScene> {
  late final Svg _sky;
  late final Svg _island;
  late final Svg _schoolhouse;
  late final Svg _cloud;
  double _time = 0;

  BackgroundComponent() : super(priority: 0);

  @override
  Future<void> onLoad() async {
    _sky = await game.loadSvg('game/adventure/game_sky_background.svg');
    _island = await game.loadSvg('game/adventure/floating_school_island.svg');
    _schoolhouse = await game.loadSvg('game/adventure/schoolhouse.svg');
    _cloud = await game.loadSvg('game/adventure/passing_cloud.svg');
  }

  void sync(GameSceneState state) {}

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    _sky.render(canvas, size);

    final islandWidth = math
        .min(size.x * .72, size.y * 1.55)
        .clamp(340.0, 900.0)
        .toDouble();
    final islandSize = Vector2(islandWidth, islandWidth * 520 / 900);
    _renderAt(
      canvas,
      _island,
      Vector2(size.x * 0.55 - islandSize.x / 2, size.y * 0.26),
      islandSize,
    );

    final schoolHeight = (size.y * 0.29).clamp(84.0, 172.0).toDouble();
    final schoolSize = Vector2(schoolHeight * 320 / 280, schoolHeight);
    _renderAt(
      canvas,
      _schoolhouse,
      Vector2(size.x * 0.21, size.y * 0.39),
      schoolSize,
    );

    _drawPassingCloud(canvas, lane: 0, speed: 13, scale: 0.9);
    _drawPassingCloud(canvas, lane: 1, speed: 20, scale: 0.62);
  }

  void _drawPassingCloud(
    Canvas canvas, {
    required int lane,
    required double speed,
    required double scale,
  }) {
    final cloudWidth = 132 * scale;
    final cloudHeight = cloudWidth / 3;
    final travel = size.x + cloudWidth * 2;
    final start = lane == 0 ? size.x * 0.08 : size.x * 0.58;
    final x = (start + _time * speed) % travel - cloudWidth;
    final y = lane == 0 ? size.y * 0.25 : size.y * 0.15;
    _renderAt(canvas, _cloud, Vector2(x, y), Vector2(cloudWidth, cloudHeight));
  }

  void _renderAt(Canvas canvas, Svg svg, Vector2 position, Vector2 assetSize) {
    canvas.save();
    canvas.translate(position.x, position.y);
    svg.render(canvas, assetSize);
    canvas.restore();
  }
}
