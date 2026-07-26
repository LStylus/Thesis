import 'package:flame/components.dart';
import 'package:flame_svg/flame_svg.dart';
import 'package:flutter/material.dart';

import '../game_scene.dart';

class IllustratedAssetComponent extends SvgComponent
    with HasGameReference<GameScene> {
  final String assetPath;
  double alpha = 1;
  bool visible = true;

  IllustratedAssetComponent({
    required this.assetPath,
    super.anchor = Anchor.center,
    super.priority,
  });

  @override
  Future<void> onLoad() async {
    svg = await game.loadSvg(assetPath);
  }

  @override
  void render(Canvas canvas) {
    if (!visible || alpha <= 0.01) return;
    if (alpha >= 0.999) {
      super.render(canvas);
      return;
    }

    canvas.saveLayer(
      Offset.zero & Size(size.x, size.y),
      Paint()..color = Colors.white.withValues(alpha: alpha),
    );
    super.render(canvas);
    canvas.restore();
  }
}
