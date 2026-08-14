import 'dart:async';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_svg/flame_svg.dart';
import 'package:flutter/material.dart';

import '../../features/game/domain/game_template_kind.dart';
import '../../core/constants/app_fonts.dart';
import '../game_scene.dart';
import '../game_scene_state.dart';

class TemplateMechanicComponent extends PositionComponent
    with HasGameReference<GameScene>, TapCallbacks, DragCallbacks {
  final VoidCallback onInteractionCompleted;

  Svg? _soundTile;
  Svg? _blueBin;
  Svg? _greenBin;
  Svg? _popTarget;
  Svg? _pairCard;
  Svg? _echoCrystal;
  Svg? _steppingStone;
  Svg? _bridgeSegment;
  Svg? _soundOrb;
  Svg? _meterFrame;
  GameTemplateKind? _loadedTemplate;
  Svg? _targetVisual;
  String? _targetVisualPath;
  int _targetLoadToken = 0;

  GameSceneState _state = GameSceneState.initial();
  GamePhase _previousPhase = GamePhase.loading;
  int _previousTarget = 0;
  int? _dragIndex;
  Offset? _dragPosition;
  final Set<int> _placedPieces = {};
  int _sequenceProgress = 0;
  bool _completedInteraction = false;
  double _time = 0;
  double _shakeTime = 0;

  TemplateMechanicComponent({required this.onInteractionCompleted})
    : super(priority: 18);

  @override
  Future<void> onLoad() async {
    await _ensureAssetsFor(game.sceneState.template);
  }

  Future<void> _ensureAssetsFor(GameTemplateKind template) async {
    switch (template) {
      case GameTemplateKind.soundBuilder:
        _soundTile ??= await game.loadSvg('game/adventure/sound_tile.svg');
        break;
      case GameTemplateKind.bucketSort:
        _soundTile ??= await game.loadSvg('game/adventure/sound_tile.svg');
        _blueBin ??= await game.loadSvg('game/adventure/sorting_bin_blue.svg');
        _greenBin ??= await game.loadSvg(
          'game/adventure/sorting_bin_green.svg',
        );
        break;
      case GameTemplateKind.tapAndPop:
        _popTarget ??= await game.loadSvg('game/adventure/pop_target.svg');
        break;
      case GameTemplateKind.minimalPairMatch:
        _pairCard ??= await game.loadSvg('game/adventure/pair_card.svg');
        break;
      case GameTemplateKind.echoCave:
        _echoCrystal ??= await game.loadSvg('game/adventure/echo_crystal.svg');
        break;
      case GameTemplateKind.sequenceJumper:
        _steppingStone ??= await game.loadSvg(
          'game/adventure/stepping_stone.svg',
        );
        break;
      case GameTemplateKind.voicePoweredJourney:
        _bridgeSegment ??= await game.loadSvg(
          'game/adventure/bridge_segment.svg',
        );
        _soundOrb ??= await game.loadSvg('game/adventure/sound_orb.svg');
        break;
      case GameTemplateKind.soundMeterChallenge:
        _meterFrame ??= await game.loadSvg('game/adventure/meter_frame.svg');
        _soundOrb ??= await game.loadSvg('game/adventure/sound_orb.svg');
        break;
    }
    _loadedTemplate = template;
  }

  void sync(GameSceneState state) {
    if (state.template != _loadedTemplate) {
      unawaited(_ensureAssetsFor(state.template));
    }
    final enteringInteraction =
        state.phase == GamePhase.interaction &&
        (_previousPhase != GamePhase.interaction ||
            state.currentTarget != _previousTarget);
    _state = state;
    if (state.targetAssetPath != _targetVisualPath) {
      _targetVisualPath = state.targetAssetPath;
      _targetVisual = null;
      final token = ++_targetLoadToken;
      final path = state.targetAssetPath;
      if (path != null && path.isNotEmpty) {
        unawaited(_loadTargetVisual(path, token));
      }
    }
    if (enteringInteraction) _resetInteraction();
    _previousPhase = state.phase;
    _previousTarget = state.currentTarget;
  }

  Future<void> _loadTargetVisual(String path, int token) async {
    final assetPath = path.startsWith('assets/')
        ? path.substring('assets/'.length)
        : path;
    try {
      final visual = await game.loadSvg(assetPath);
      if (token == _targetLoadToken) _targetVisual = visual;
    } catch (_) {
      if (token == _targetLoadToken) _targetVisual = null;
    }
  }

  void layoutFor(Vector2 gameSize) {
    size = gameSize;
  }

  void _resetInteraction() {
    _dragIndex = null;
    _dragPosition = null;
    _placedPieces.clear();
    _sequenceProgress = 0;
    _completedInteraction = false;
    _shakeTime = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    _shakeTime = math.max(0, _shakeTime - dt);
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (!_state.isAwaitingInteraction || _completedInteraction) return;
    final point = Offset(event.localPosition.x, event.localPosition.y);

    switch (_state.template) {
      case GameTemplateKind.soundBuilder:
      case GameTemplateKind.bucketSort:
        return;
      case GameTemplateKind.tapAndPop:
        _handleOptionTap(point, _popRects());
        return;
      case GameTemplateKind.minimalPairMatch:
        _handleOptionTap(point, _pairRects());
        return;
      case GameTemplateKind.echoCave:
        if (_echoRect().contains(point)) _complete();
        return;
      case GameTemplateKind.sequenceJumper:
        final stones = _stoneRects();
        final tapped = stones.indexWhere((rect) => rect.contains(point));
        if (tapped == _sequenceProgress) {
          _sequenceProgress++;
          if (_sequenceProgress >= stones.length) _complete();
        } else if (tapped >= 0) {
          _sequenceProgress = 0;
          _shakeTime = .35;
        }
        return;
      case GameTemplateKind.voicePoweredJourney:
        if (_orbRect().contains(point)) _complete();
        return;
      case GameTemplateKind.soundMeterChallenge:
        if (_meterOrbRect().contains(point)) _complete();
        return;
    }
  }

  void _handleOptionTap(Offset point, List<Rect> rects) {
    final tapped = rects.indexWhere((rect) => rect.contains(point));
    if (tapped < 0) return;
    if (tapped == _state.correctOptionIndex) {
      _complete();
    } else {
      _shakeTime = .42;
    }
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (!_state.isAwaitingInteraction || _completedInteraction) return;
    final point = Offset(event.localPosition.x, event.localPosition.y);

    if (_state.template == GameTemplateKind.bucketSort) {
      final token = _bucketTokenRect();
      if (token.contains(point)) {
        _dragIndex = 0;
        _dragPosition = token.center;
      }
      return;
    }

    if (_state.template == GameTemplateKind.soundBuilder) {
      final pieceCount = _builderPieceCount;
      for (var index = 0; index < pieceCount; index++) {
        if (_placedPieces.contains(index)) continue;
        final tile = _builderTileRect(index);
        if (tile.contains(point)) {
          _dragIndex = index;
          _dragPosition = tile.center;
          return;
        }
      }
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (_dragIndex == null || _dragPosition == null) return;
    final next =
        _dragPosition! + Offset(event.localDelta.x, event.localDelta.y);
    _dragPosition = Offset(
      next.dx.clamp(40.0, size.x - 40).toDouble(),
      next.dy.clamp(40.0, size.y - 40).toDouble(),
    );
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    final dragIndex = _dragIndex;
    final dragPosition = _dragPosition;
    if (dragIndex == null || dragPosition == null) return;

    if (_state.template == GameTemplateKind.bucketSort) {
      final bins = _binRects();
      if (bins[_state.correctOptionIndex].contains(dragPosition)) {
        _complete();
      } else {
        _shakeTime = .42;
      }
    } else if (_state.template == GameTemplateKind.soundBuilder) {
      final slot = _builderSlotRect(dragIndex);
      if (slot.inflate(18).contains(dragPosition)) {
        _placedPieces.add(dragIndex);
        if (_placedPieces.length == _builderPieceCount) _complete();
      } else {
        _shakeTime = .35;
      }
    }

    _dragIndex = null;
    _dragPosition = null;
  }

  void _complete() {
    if (_completedInteraction) return;
    _completedInteraction = true;
    onInteractionCompleted();
  }

  @override
  void render(Canvas canvas) {
    if (_state.targetText.isEmpty || _state.phase == GamePhase.loading) return;
    final shake = _shakeTime <= 0
        ? 0.0
        : math.sin(_shakeTime * math.pi * 32) * 6;
    canvas.save();
    canvas.translate(shake, 0);
    switch (_state.template) {
      case GameTemplateKind.soundBuilder:
        _renderSoundBuilder(canvas);
        break;
      case GameTemplateKind.bucketSort:
        _renderBucketSort(canvas);
        break;
      case GameTemplateKind.tapAndPop:
        _renderTapAndPop(canvas);
        break;
      case GameTemplateKind.minimalPairMatch:
        _renderPairMatch(canvas);
        break;
      case GameTemplateKind.echoCave:
        _renderEchoCave(canvas);
        break;
      case GameTemplateKind.sequenceJumper:
        _renderSequence(canvas);
        break;
      case GameTemplateKind.voicePoweredJourney:
        _renderJourney(canvas);
        break;
      case GameTemplateKind.soundMeterChallenge:
        _renderMeter(canvas);
        break;
    }
    canvas.restore();
  }

  void _renderSoundBuilder(Canvas canvas) {
    final count = _builderPieceCount;
    for (var index = 0; index < count; index++) {
      final slot = _builderSlotRect(index);
      _drawSlot(canvas, slot, filled: _placedPieces.contains(index));
      if (!_placedPieces.contains(index) &&
          index == _nextBuilderPiece &&
          _state.hintLevel == GameHintLevel.full) {
        _drawHint(canvas, slot.inflate(4));
      }
      if (_placedPieces.contains(index)) {
        _drawLabel(
          canvas,
          _pieceAt(index),
          slot,
          color: const Color(0xFF31566B),
        );
      }
    }

    for (var index = 0; index < count; index++) {
      if (_placedPieces.contains(index)) continue;
      final tile = _builderTileRect(index);
      _renderSvg(canvas, _soundTile, tile);
      _drawLabel(canvas, _pieceAt(index), tile, color: const Color(0xFF31566B));
    }
  }

  void _renderBucketSort(Canvas canvas) {
    final bins = _binRects();
    _renderSvg(canvas, _blueBin, bins[0]);
    _renderSvg(canvas, _greenBin, bins[1]);
    if (_state.hintLevel == GameHintLevel.full) {
      _drawHint(canvas, bins[_state.correctOptionIndex].deflate(5));
    }
    final options = _options;
    _drawLabel(
      canvas,
      options[0],
      Rect.fromLTWH(bins[0].left, bins[0].bottom - 38, bins[0].width, 28),
      color: const Color(0xFFFEFDFA),
      fontSize: 13,
    );
    _drawLabel(
      canvas,
      options[1],
      Rect.fromLTWH(bins[1].left, bins[1].bottom - 38, bins[1].width, 28),
      color: const Color(0xFFFEFDFA),
      fontSize: 13,
    );
    final token = _bucketTokenRect();
    _renderSvg(canvas, _soundTile, token);
    _renderTargetVisual(
      canvas,
      Rect.fromCenter(
        center: token.center.translate(0, -7),
        width: token.height * .44,
        height: token.height * .44,
      ),
    );
    _drawLabel(
      canvas,
      _state.targetText,
      Rect.fromLTWH(token.left + 5, token.bottom - 21, token.width - 10, 18),
      color: const Color(0xFF31566B),
      fontSize: 11,
    );
  }

  void _renderTapAndPop(Canvas canvas) {
    final rects = _popRects();
    final options = _options;
    for (var index = 0; index < rects.length; index++) {
      _renderSvg(canvas, _popTarget, rects[index]);
      if (index == _state.correctOptionIndex &&
          _state.hintLevel == GameHintLevel.full) {
        _drawHint(canvas, rects[index].deflate(3));
      }
      if (index == _state.correctOptionIndex) {
        _renderTargetVisual(
          canvas,
          Rect.fromCenter(
            center: rects[index].center.translate(0, -8),
            width: rects[index].width * .32,
            height: rects[index].height * .32,
          ),
        );
      }
      _drawLabel(
        canvas,
        options[index],
        Rect.fromLTWH(
          rects[index].left + 12,
          rects[index].bottom - 47,
          rects[index].width - 24,
          28,
        ),
        color: const Color(0xFF31566B),
        fontSize: 13,
      );
    }
  }

  void _renderPairMatch(Canvas canvas) {
    final rects = _pairRects();
    final options = _options;
    for (var index = 0; index < rects.length; index++) {
      _renderSvg(canvas, _pairCard, rects[index]);
      if (index == _state.correctOptionIndex &&
          _state.hintLevel == GameHintLevel.full) {
        _drawHint(canvas, rects[index].deflate(3));
      }
      if (index == _state.correctOptionIndex) {
        _renderTargetVisual(
          canvas,
          Rect.fromCenter(
            center: rects[index].center.translate(0, -24),
            width: rects[index].width * .46,
            height: rects[index].width * .46,
          ),
        );
      }
      _drawLabel(
        canvas,
        options[index],
        Rect.fromLTWH(
          rects[index].left + 14,
          rects[index].bottom - 73,
          rects[index].width - 28,
          42,
        ),
        color: const Color(0xFF31566B),
        fontSize: 17,
      );
    }
  }

  void _renderEchoCave(Canvas canvas) {
    final rect = _echoRect();
    final pulse = _state.isAwaitingInteraction
        ? 1 + math.sin(_time * math.pi * 2) * .055
        : 1.0;
    final scaled = Rect.fromCenter(
      center: rect.center,
      width: rect.width * pulse,
      height: rect.height * pulse,
    );
    _renderSvg(canvas, _echoCrystal, scaled);
    _drawLabel(
      canvas,
      _state.targetText,
      Rect.fromLTWH(rect.left - 15, rect.bottom - 54, rect.width + 30, 40),
      color: const Color(0xFF31566B),
      fontSize: 17,
    );
  }

  void _renderSequence(Canvas canvas) {
    final stones = _stoneRects();
    final pieces = _sequencePieces(stones.length);
    for (var index = 0; index < stones.length; index++) {
      final raised = index < _sequenceProgress ? -12.0 : 0.0;
      final rect = stones[index].shift(Offset(0, raised));
      _renderSvg(canvas, _steppingStone, rect);
      if (index == _sequenceProgress &&
          _state.hintLevel == GameHintLevel.full) {
        _drawHint(canvas, rect.inflate(3));
      }
      _drawLabel(
        canvas,
        pieces[index],
        Rect.fromLTWH(rect.left + 12, rect.top + 15, rect.width - 24, 35),
        color: const Color(0xFF31566B),
        fontSize: 15,
      );
    }
  }

  void _renderJourney(Canvas canvas) {
    final bridges = _bridgeRects();
    for (var index = 0; index < bridges.length; index++) {
      final visible =
          _state.phase == GamePhase.correct ||
          _state.phase == GamePhase.completed ||
          index == 0;
      if (visible) _renderSvg(canvas, _bridgeSegment, bridges[index]);
    }
    final orb = _orbRect();
    _renderSvg(canvas, _soundOrb, orb);
    _drawLabel(
      canvas,
      _state.targetText,
      Rect.fromLTWH(orb.left - 15, orb.bottom - 48, orb.width + 30, 35),
      color: const Color(0xFF31566B),
      fontSize: 15,
    );
  }

  void _renderMeter(Canvas canvas) {
    final frame = _meterRect();
    _renderSvg(canvas, _meterFrame, frame);
    final channel = Rect.fromLTWH(
      frame.left + frame.width * .18,
      frame.top + frame.height * .27,
      frame.width * .64,
      frame.height * .24,
    );
    final progress = _state.isRecording
        ? _state.micLevel
        : _state.phase == GamePhase.processing ||
              _state.phase == GamePhase.correct
        ? 1.0
        : 0.0;
    final channelShape = RRect.fromRectAndRadius(
      channel,
      const Radius.circular(8),
    );
    canvas.drawRRect(channelShape, Paint()..color = const Color(0xFFFFF1BD));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          channel.left,
          channel.top,
          channel.width * progress.clamp(0.0, 1.0),
          channel.height,
        ),
        const Radius.circular(8),
      ),
      Paint()..color = const Color(0xFF52B788),
    );
    final orb = _meterOrbRect();
    _renderSvg(canvas, _soundOrb, orb);
    _drawLabel(
      canvas,
      _state.targetText,
      Rect.fromLTWH(frame.left, frame.bottom - 46, frame.width, 36),
      color: const Color(0xFF31566B),
      fontSize: 16,
    );
  }

  int get _builderPieceCount => _state.targetPieces.isEmpty
      ? math.min(4, _state.targetText.length)
      : math.min(5, _state.targetPieces.length);

  int get _nextBuilderPiece {
    for (var index = 0; index < _builderPieceCount; index++) {
      if (!_placedPieces.contains(index)) return index;
    }
    return -1;
  }

  String _pieceAt(int index) {
    final pieces = _state.targetPieces.isEmpty
        ? _state.targetText.split('')
        : _state.targetPieces;
    return index < pieces.length ? pieces[index] : '';
  }

  List<String> get _options {
    if (_state.targetOptions.length >= 2) {
      return _state.targetOptions.take(2).toList(growable: false);
    }
    return [_state.targetText, 'OTHER'];
  }

  Rect _playArea() {
    final left = size.x * .33;
    final right = size.x * .79;
    final top = size.y * .31;
    final bottom = size.y * .84;
    return Rect.fromLTRB(left, top, right, bottom);
  }

  Rect _builderSlotRect(int index) {
    final area = _playArea();
    final count = math.max(1, _builderPieceCount);
    final width = math.min(80.0, (area.width - 12 * (count - 1)) / count);
    final totalWidth = width * count + 12 * (count - 1);
    return Rect.fromLTWH(
      area.center.dx - totalWidth / 2 + index * (width + 12),
      area.top + 4,
      width,
      width * .72,
    );
  }

  Rect _builderTileRect(int index) {
    final dragged = _dragIndex == index ? _dragPosition : null;
    final slot = _builderSlotRect(_builderPieceCount - index - 1);
    final base = Rect.fromCenter(
      center: Offset(slot.center.dx, _playArea().bottom - slot.height * .55),
      width: slot.width,
      height: slot.height,
    );
    return dragged == null
        ? base
        : Rect.fromCenter(
            center: dragged,
            width: base.width,
            height: base.height,
          );
  }

  List<Rect> _binRects() {
    final area = _playArea();
    final h = math.min(128.0, area.height * .60);
    final w = h * 260 / 230;
    return [
      Rect.fromCenter(
        center: Offset(area.center.dx - w * .68, area.center.dy + 15),
        width: w,
        height: h,
      ),
      Rect.fromCenter(
        center: Offset(area.center.dx + w * .68, area.center.dy + 15),
        width: w,
        height: h,
      ),
    ];
  }

  Rect _bucketTokenRect() {
    final base = Rect.fromCenter(
      center: Offset(_playArea().center.dx, _playArea().top + 20),
      width: 82,
      height: 60,
    );
    return _dragPosition == null
        ? base
        : Rect.fromCenter(center: _dragPosition!, width: 82, height: 60);
  }

  List<Rect> _popRects() {
    final area = _playArea();
    final targetSize = math.min(112.0, area.height * .48);
    final y1 = area.center.dy + math.sin(_time * 1.5) * 18;
    final y2 = area.center.dy + math.sin(_time * 1.5 + math.pi) * 18;
    return [
      Rect.fromCenter(
        center: Offset(area.center.dx - targetSize * .72, y1),
        width: targetSize,
        height: targetSize,
      ),
      Rect.fromCenter(
        center: Offset(area.center.dx + targetSize * .72, y2),
        width: targetSize,
        height: targetSize,
      ),
    ];
  }

  List<Rect> _pairRects() {
    final area = _playArea();
    final h = math.min(165.0, area.height * .73);
    final w = h * 250 / 310;
    return [
      Rect.fromCenter(
        center: Offset(area.center.dx - w * .70, area.center.dy),
        width: w,
        height: h,
      ),
      Rect.fromCenter(
        center: Offset(area.center.dx + w * .70, area.center.dy),
        width: w,
        height: h,
      ),
    ];
  }

  Rect _echoRect() {
    final area = _playArea();
    final h = math.min(180.0, area.height * .80);
    return Rect.fromCenter(
      center: area.center,
      width: h * 240 / 300,
      height: h,
    );
  }

  List<Rect> _stoneRects() {
    final area = _playArea();
    final w = math.min(112.0, area.width / 3.6);
    final h = w * 150 / 260;
    return List.generate(3, (index) {
      return Rect.fromCenter(
        center: Offset(
          area.left + area.width * (.22 + index * .28),
          area.center.dy + (index.isOdd ? -24 : 24),
        ),
        width: w,
        height: h,
      );
    });
  }

  List<String> _sequencePieces(int count) {
    final pieces = _state.targetPieces.isEmpty
        ? _state.targetText.split('')
        : _state.targetPieces;
    if (pieces.length >= count) return pieces.take(count).toList();
    return List.generate(count, (index) {
      return index < pieces.length ? pieces[index] : '${index + 1}';
    });
  }

  List<Rect> _bridgeRects() {
    final area = _playArea();
    final w = math.min(128.0, area.width / 2.8);
    final h = w * 150 / 280;
    return List.generate(3, (index) {
      return Rect.fromCenter(
        center: Offset(
          area.left + area.width * (.34 + index * .24),
          area.center.dy + 24,
        ),
        width: w,
        height: h,
      );
    });
  }

  Rect _orbRect() {
    final area = _playArea();
    final d = math.min(118.0, area.height * .52);
    return Rect.fromCenter(
      center: Offset(area.left + d * .82, area.center.dy - 22),
      width: d,
      height: d,
    );
  }

  Rect _meterRect() {
    final area = _playArea();
    final w = math.min(290.0, area.width * .78);
    return Rect.fromCenter(
      center: Offset(area.center.dx + 20, area.center.dy),
      width: w,
      height: w * 180 / 420,
    );
  }

  Rect _meterOrbRect() {
    final frame = _meterRect();
    final d = frame.height * .62;
    return Rect.fromCenter(
      center: Offset(frame.left - d * .22, frame.center.dy),
      width: d,
      height: d,
    );
  }

  void _drawSlot(Canvas canvas, Rect rect, {required bool filled}) {
    final shape = RRect.fromRectAndRadius(rect, const Radius.circular(8));
    canvas.drawRRect(
      shape,
      Paint()
        ..color = filled
            ? const Color(0xFFFEFDFA)
            : const Color(0xFF815037).withValues(alpha: .22)
        ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  void _renderSvg(Canvas canvas, Svg? svg, Rect rect) {
    if (svg == null) return;
    canvas.save();
    canvas.translate(rect.left, rect.top);
    svg.render(canvas, Vector2(rect.width, rect.height));
    canvas.restore();
  }

  void _renderTargetVisual(Canvas canvas, Rect rect) {
    final visual = _targetVisual;
    if (visual != null && _state.hintLevel != GameHintLevel.minimal) {
      _renderSvg(canvas, visual, rect);
    }
  }

  void _drawHint(Canvas canvas, Rect rect) {
    if (!_state.isAwaitingInteraction) return;
    final alpha = .48 + math.sin(_time * math.pi * 2).abs() * .34;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      Paint()
        ..color = const Color(0xFFFFD45A).withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
  }

  void _drawLabel(
    Canvas canvas,
    String text,
    Rect bounds, {
    required Color color,
    double fontSize = 16,
  }) {
    var resolvedSize = fontSize;
    late TextPainter painter;
    do {
      painter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: color,
            fontFamily: AppFonts.fredoka,
            fontSize: resolvedSize,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '...',
      )..layout(maxWidth: bounds.width);
      if (painter.didExceedMaxLines && resolvedSize > 10) {
        resolvedSize -= 1;
      } else {
        break;
      }
    } while (resolvedSize > 10);
    painter.paint(
      canvas,
      Offset(
        bounds.left + (bounds.width - painter.width) / 2,
        bounds.top + (bounds.height - painter.height) / 2,
      ),
    );
  }
}
