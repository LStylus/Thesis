import 'dart:async';

import 'package:flame/game.dart' show GameWidget;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../gamescene/game_scene.dart';
import '../../../gamescene/game_scene_state.dart';
import '../application/game_session_controller.dart';
import '../domain/game_level_config.dart';
import '../domain/game_result.dart';
import '../../../models/speech_profile_model.dart';
import 'widgets/game_hud_overlay.dart';

export '../domain/game_result.dart';

class GameScreen extends StatefulWidget {
  final String childProfileId;
  final String childName;
  final int childAge;
  final int levelIndex;
  final SpeechProfileModel? speechProfile;

  const GameScreen({
    super.key,
    required this.childProfileId,
    required this.childName,
    required this.childAge,
    required this.levelIndex,
    this.speechProfile,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late final GameSessionController _controller;
  late final GameScene _game;
  late final Widget _gameWidget;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    final config = GameLevelConfig(
      childProfileId: widget.childProfileId,
      childName: widget.childName,
      childAge: widget.childAge,
      levelIndex: widget.levelIndex,
      speechProfile: widget.speechProfile,
    );
    _controller = GameSessionController.createDefault(config);
    _game = GameScene(
      initialState: GameSceneState.initial(
        childName: widget.childName,
        template: config.template,
      ),
      onInteractionCompleted: _controller.completeInteraction,
    );
    _gameWidget = GameWidget<GameScene>(
      game: _game,
      initialActiveOverlays: const ['GameHud'],
      overlayBuilderMap: {
        'GameHud': (context, game) => GameHudOverlay(
          game: game,
          controller: _controller,
          onClose: _closeGameplay,
        ),
      },
    );

    _controller.addListener(_syncScene);
    _controller.completionResult.addListener(_handleCompletionResult);
    _syncScene();
    _controller.start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_syncScene);
    _controller.completionResult.removeListener(_handleCompletionResult);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _controller.resume();
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        unawaited(_controller.pause());
    }
  }

  void _syncScene() {
    _game.updateScene(_controller.toSceneState());
  }

  void _handleCompletionResult() {
    final result = _controller.completionResult.value;
    if (!mounted || result == null || _hasNavigated) return;

    _hasNavigated = true;
    Navigator.of(context).pop<GameResult>(result);
  }

  Future<void> _closeGameplay() async {
    await _controller.cancel();
    if (!mounted || _hasNavigated) return;

    _hasNavigated = true;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          unawaited(_controller.cancel());
        }
      },
      child: Scaffold(body: ClipRect(child: _gameWidget)),
    );
  }
}
