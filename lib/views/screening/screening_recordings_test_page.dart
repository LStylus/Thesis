import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/screening_word_model.dart';
import '../auth/auth_gate.dart';

class ScreeningRecordingsTestPage extends StatefulWidget {
  final List<ScreeningWordModel> words;
  final Map<String, String> recordingsByWordId;

  const ScreeningRecordingsTestPage({
    super.key,
    required this.words,
    required this.recordingsByWordId,
  });

  @override
  State<ScreeningRecordingsTestPage> createState() =>
      _ScreeningRecordingsTestPageState();
}

class _ScreeningRecordingsTestPageState
    extends State<ScreeningRecordingsTestPage> {
  final AudioPlayer _player = AudioPlayer();

  String? _playingWordId;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _playingWordId = null;
      });
    });

    _player.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      if (state != PlayerState.playing) {
        setState(() {
          _playingWordId = null;
        });
      }
    });
  }

  Future<void> _togglePlay(String wordId, String path) async {
    try {
      setState(() {
        _errorMessage = null;
      });

      if (_playingWordId == wordId) {
        await _player.stop();
        setState(() {
          _playingWordId = null;
        });
        return;
      }

      final file = File(path);
      if (!await file.exists()) {
        setState(() {
          _errorMessage = 'Audio file not found for $wordId';
        });
        return;
      }

      await _player.stop();
      await _player.play(DeviceFileSource(path));

      setState(() {
        _playingWordId = wordId;
      });
    } catch (e) {
      setState(() {
        _playingWordId = null;
        _errorMessage = 'Could not play recording: $e';
      });
    }
  }

  Widget _buildRecordingCard(ScreeningWordModel word) {
    final path = widget.recordingsByWordId[word.id];
    final hasFile = path != null && path.isNotEmpty;
    final isPlaying = _playingWordId == word.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Icon(
              isPlaying ? Icons.graphic_eq_rounded : Icons.mic_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  word.displayWord,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${word.position.label} • ${word.phonemeProcess}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textGray,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  hasFile
                      ? 'Saved: ${path!.split(Platform.pathSeparator).last}'
                      : 'No recording found',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: hasFile ? Colors.green : AppColors.error,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: hasFile ? () => _togglePlay(word.id, path!) : null,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(80, 36),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
            ),
            icon: Icon(
              isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
              size: 18,
            ),
            label: Text(
              isPlaying ? 'Stop' : 'Play',
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _finishTesting() async {
    await _player.stop();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recordedCount = widget.recordingsByWordId.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recording Test'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 650),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Temporary Playback Checker',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Recorded files found: $recordedCount / ${widget.words.length}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textGray,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_errorMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ],

                  ...widget.words.map(_buildRecordingCard),

                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _finishTesting,
                      child: const Text('Done Testing'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
