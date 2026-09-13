import 'dart:math' as math;

import 'package:flutter/material.dart';

enum SoundEmphasisPosition { beginning, middle, end }

/// Caption-led animation prototype; no audio playback or exposure credit.
class SoundEmphasisPreviewPage extends StatefulWidget {
  const SoundEmphasisPreviewPage({
    super.key,
    this.backgroundColor = Colors.white,
    this.backgroundImage,
    this.pictureImage,
    this.beforeTarget = '',
    this.targetText = 'S',
    this.afterTarget = 'UN',
    this.targetSound = '/s/',
    this.position = SoundEmphasisPosition.beginning,
  });

  static const routeName = '/dev/sound-emphasis';

  final Color backgroundColor;
  final ImageProvider? backgroundImage;
  final ImageProvider? pictureImage;
  final String beforeTarget;
  final String targetText;
  final String afterTarget;
  final String targetSound;
  final SoundEmphasisPosition position;

  @override
  State<SoundEmphasisPreviewPage> createState() =>
      _SoundEmphasisPreviewPageState();
}

class _SoundEmphasisPreviewPageState extends State<SoundEmphasisPreviewPage>
    with SingleTickerProviderStateMixin {
  static const _ink = Color(0xFF244653);
  static const _accent = Color(0xFFFFE49A);
  late final AnimationController _emphasis = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  bool _hasPlayed = false;

  void _play() {
    setState(() => _hasPlayed = true);
    if (MediaQuery.disableAnimationsOf(context)) {
      _emphasis.stop();
      _emphasis.value = 1;
    } else {
      _emphasis.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _emphasis.dispose();
    super.dispose();
  }

  double get _pulse => MediaQuery.disableAnimationsOf(context)
      ? 0
      : math.sin(math.pi * _emphasis.value);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.backgroundColor,
      body: AnimatedBuilder(
        animation: _emphasis,
        builder: (context, _) => DecoratedBox(
          decoration: BoxDecoration(
            image: widget.backgroundImage == null
                ? null
                : DecorationImage(
                    image: widget.backgroundImage!,
                    fit: BoxFit.cover,
                  ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 520;
                final compact = constraints.maxHeight < 440;
                final padding = constraints.maxHeight < 300
                    ? 8.0
                    : compact
                    ? 16.0
                    : 32.0;
                final pictureSize = math.min(
                  wide ? 300.0 : 220.0,
                  math.min(
                    math.max(0.0, constraints.maxWidth - padding * 2),
                    wide ? constraints.maxHeight * 0.56 : 220.0,
                  ),
                );
                final picture = _picture(pictureSize);
                final details = _details(context, compact);

                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(padding),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 960),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Notice the sound',
                                style: TextStyle(
                                  fontSize: compact ? 22 : 28,
                                  fontWeight: FontWeight.w600,
                                  color: _ink,
                                ),
                              ),
                              if (constraints.maxHeight >= 300)
                                const Text(
                                  'Tap the picture to watch the target sound.',
                                  style: TextStyle(color: Color(0xFF677D86)),
                                ),
                              SizedBox(height: compact ? 10 : 28),
                              if (wide)
                                Row(
                                  children: [
                                    picture,
                                    SizedBox(width: compact ? 28 : 48),
                                    Expanded(child: details),
                                  ],
                                )
                              else ...[
                                Center(child: picture),
                                const SizedBox(height: 24),
                                details,
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _picture(double size) {
    final placeholder = FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.image_outlined, size: 42, color: Colors.white),
          SizedBox(height: 12),
          Text('Picture placeholder', style: TextStyle(color: Colors.white)),
        ],
      ),
    );
    return Transform.scale(
      key: const ValueKey('sound-picture-reaction'),
      scale: 1 + _pulse * 0.025,
      child: Semantics(
        label: 'Play sound emphasis preview',
        button: true,
        onTap: _play,
        excludeSemantics: true,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border.all(
              color: _hasPlayed
                  ? const Color(0xFF00B8DE)
                  : const Color(0xFF353535),
              width: 3,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0x3300B8DE),
                blurRadius: 20 * _pulse,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(21),
              onTap: _play,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: widget.pictureImage == null
                    ? placeholder
                    : Image(
                        image: widget.pictureImage!,
                        fit: BoxFit.contain,
                        semanticLabel:
                            '${widget.beforeTarget}${widget.targetText}${widget.afterTarget}',
                        errorBuilder: (_, _, _) => placeholder,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _details(BuildContext context, bool compact) {
    final beforeTarget = widget.beforeTarget;
    final targetText = widget.targetText;
    final afterTarget = widget.afterTarget;
    final targetSound = widget.targetSound;
    final position = widget.position;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Target sound  $targetSound', style: const TextStyle(color: _ink)),
        SizedBox(height: compact ? 6 : 10),
        Semantics(
          label:
              '$beforeTarget$targetText$afterTarget. '
              'Target sound $targetSound at the ${position.name}.',
          excludeSemantics: true,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                if (beforeTarget.isNotEmpty) _wordPart(beforeTarget, compact),
                Transform.scale(
                  key: const ValueKey('target-sound-reaction'),
                  scale: 1 + _pulse * 0.1,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Color.lerp(
                        _accent,
                        const Color(0xFFFFCF52),
                        _pulse,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE7C569)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0x55FFD56B),
                          blurRadius: 12 + 20 * _pulse,
                        ),
                      ],
                    ),
                    child: _wordPart(targetText, compact),
                  ),
                ),
                if (afterTarget.isNotEmpty) _wordPart(afterTarget, compact),
              ],
            ),
          ),
        ),
        SizedBox(height: compact ? 8 : 16),
        Row(
          children: [
            for (final value in SoundEmphasisPosition.values)
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: EdgeInsets.symmetric(vertical: compact ? 6 : 8),
                  decoration: BoxDecoration(
                    color: value == position
                        ? _accent
                        : const Color(0xFFF1F5F6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    value.name[0].toUpperCase() + value.name.substring(1),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: _ink,
                      fontWeight: value == position
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: compact ? 8 : 14),
        Container(
          padding: const EdgeInsets.only(left: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F8FA),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    _hasPlayed
                        ? '$beforeTarget$targetText$afterTarget — notice $targetSound at the ${position.name}.'
                        : 'Tap the picture or play to begin.',
                    key: const ValueKey('sound-caption'),
                    style: TextStyle(fontSize: compact ? 12 : 14, color: _ink),
                  ),
                ),
              ),
              IconButton(
                tooltip: _hasPlayed ? 'Replay emphasis' : 'Play emphasis',
                onPressed: _play,
                icon: Icon(
                  _hasPlayed ? Icons.replay : Icons.play_arrow,
                  color: _ink,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Temporary caption · No voice-over yet',
          style: TextStyle(fontSize: 11, color: Color(0xFF677D86)),
        ),
      ],
    );
  }

  Widget _wordPart(String text, bool compact) => Text(
    text,
    style: TextStyle(
      fontSize: compact ? 36 : 68,
      fontWeight: FontWeight.w600,
      color: _ink,
      letterSpacing: 4,
    ),
  );
}
