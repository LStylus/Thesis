import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame_svg/flame_svg.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_fonts.dart';
import '../game_scene.dart';
import '../game_scene_state.dart';

class TargetDisplayComponent extends SvgComponent
    with HasGameReference<GameScene> {
  String? _assetPath;
  String _targetText = '';
  int _loadToken = 0;

  TargetDisplayComponent() : super(anchor: Anchor.center, priority: 16);

  void sync(GameSceneState state) {
    _targetText = state.targetText;
    if (state.targetAssetPath == _assetPath) return;
    _assetPath = state.targetAssetPath;
    final path = _assetPath;
    if (path == null || path.isEmpty) {
      svg = null;
      return;
    }
    unawaited(_load(path, ++_loadToken));
  }

  Future<void> _load(String path, int token) async {
    final flamePath = path.startsWith('assets/')
        ? path.substring('assets/'.length)
        : path;
    try {
      final loaded = await game.loadSvg(flamePath);
      if (token == _loadToken) svg = loaded;
    } catch (_) {
      if (token == _loadToken) svg = null;
    }
  }

  void layoutFor(Vector2 gameSize) {
    final visualSize = (gameSize.y * 0.25).clamp(105.0, 150.0).toDouble();
    size = Vector2.all(visualSize);
    position = Vector2(gameSize.x * 0.18, gameSize.y * 0.43);
  }

  @override
  void render(Canvas canvas) {
    final panel = RRect.fromRectAndRadius(
      Offset.zero & Size(size.x, size.y),
      const Radius.circular(8),
    );
    canvas.drawRRect(
      panel.shift(const Offset(0, 5)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.16)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );
    canvas.drawRRect(
      panel,
      Paint()..color = Colors.white.withValues(alpha: 0.92),
    );

    canvas.save();
    canvas.translate(size.x * 0.16, size.y * 0.08);
    canvas.scale(0.68);
    super.render(canvas);
    canvas.restore();

    final label = TextPainter(
      text: TextSpan(
        text: _targetText,
        style: const TextStyle(
          color: Color(0xFF31566B),
          fontFamily: AppFonts.fredoka,
          fontSize: 14,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 2,
      ellipsis: '...',
    )..layout(maxWidth: size.x - 12);
    label.paint(
      canvas,
      Offset((size.x - label.width) / 2, size.y - label.height - 7),
    );
  }
}
