import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'template_preview_widgets.dart';

enum _BuildStep { build, model, speak }

/// Construction and speaking visuals only. Taps never award accepted speech.
class BuildAndSayPreviewPage extends StatefulWidget {
  const BuildAndSayPreviewPage({
    super.key,
    this.word = 'BALL',
    this.pictureAsset = 'assets/game/words/ball.svg',
    this.backgroundColor = Colors.white,
    this.backgroundImage,
    this.randomSeed,
  });
  static const routeName = '/dev/build-and-say';
  final String word;
  final String pictureAsset;
  final Color backgroundColor;
  final ImageProvider? backgroundImage;
  final int? randomSeed;
  @override
  State<BuildAndSayPreviewPage> createState() => _BuildAndSayState();
}

class _BuildAndSayState extends State<BuildAndSayPreviewPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final _random = math.Random(widget.randomSeed);
  late final List<String> _letters = widget.word.toUpperCase().split('');
  late List<int> _order;
  final _used = <int>[];
  _BuildStep _step = _BuildStep.build;
  bool _wrong = false;
  late final AnimationController _voice;
  bool get _assembled => _used.length == _letters.length;
  bool get _reduced => MediaQuery.disableAnimationsOf(context);
  @override
  void initState() {
    super.initState();
    _voice =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..addStatusListener((_) {
            if (mounted) setState(() {});
          });
    assert(_letters.isNotEmpty && _letters.length <= 6);
    _order = List.generate(_letters.length, (i) => i)..shuffle(_random);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _voice.stop();
      if (mounted) setState(() {});
    }
  }

  void _place(int piece, [int? slot]) {
    if (_step != _BuildStep.build || _assembled || _used.contains(piece)) {
      return;
    }
    final correct =
        (slot == null || slot == _used.length) &&
        _letters[piece] == _letters[_used.length];
    setState(() {
      _wrong = !correct;
      if (correct) _used.add(piece);
    });
  }

  void _reset() {
    _voice.reset();
    setState(() {
      _used.clear();
      _wrong = false;
      _step = _BuildStep.build;
      _order.shuffle(_random);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _voice.dispose();
    super.dispose();
  }

  String get _caption => switch (_step) {
    _BuildStep.build =>
      _assembled
          ? 'Word built! Now see its word caption.'
          : 'Build ${widget.word.toUpperCase()}. Tap or drag the letters in order.',
    _BuildStep.model => 'This is a ${widget.word.toLowerCase()}.',
    _BuildStep.speak => 'Your turn: say ${widget.word.toLowerCase()}.',
  };
  @override
  Widget build(BuildContext context) => TemplateSurface(
    backgroundColor: widget.backgroundColor,
    backgroundImage: widget.backgroundImage,
    builder: (context, wide, viewport) {
      final compact = wide && viewport.height < 400;
      final pictureSize = compact ? 88.0 : 160.0;
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final step in _BuildStep.values)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: AnimatedDefaultTextStyle(
                    duration: Duration(milliseconds: _reduced ? 0 : 250),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: step == _step
                          ? const Color(0xFF238B91)
                          : const Color(0xFF8A9BA2),
                    ),
                    child: Text(switch (step) {
                      _BuildStep.build => '1 · BUILD',
                      _BuildStep.model => '2 · WORD',
                      _BuildStep.speak => '3 · SAY',
                    }),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TemplateCaption(_caption),
          const SizedBox(height: 12),
          if (wide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _picture(pictureSize),
                const SizedBox(width: 20),
                Expanded(child: _workbench(compact)),
              ],
            )
          else ...[
            _picture(pictureSize),
            const SizedBox(height: 16),
            _workbench(false),
          ],
          const SizedBox(height: 8),
          Semantics(
            liveRegion: true,
            child: Text(
              _step == _BuildStep.speak
                  ? 'Animation only · No recording or pronunciation checking.'
                  : _wrong
                  ? 'Try a different piece. Keep building!'
                  : 'Template preview · Speech practice is not scored.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Color(0xFF677D86)),
            ),
          ),
        ],
      );
    },
  );
  Widget _picture(double size) => AnimatedContainer(
    duration: Duration(milliseconds: _reduced ? 0 : 400),
    width: size,
    height: size,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: _assembled ? const Color(0xFFE7F7F0) : const Color(0xFFF4F6F7),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFD3E3E6), width: 2),
    ),
    child: TemplatePicture(widget.pictureAsset),
  );
  Widget _workbench(bool compact) => LayoutBuilder(
    builder: (context, bounds) {
      final tile = math.min(
        compact ? 46.0 : 64.0,
        (bounds.maxWidth - (_letters.length - 1) * 8) / _letters.length,
      );
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < _letters.length; i++)
                Padding(
                  padding: EdgeInsets.only(
                    right: i == _letters.length - 1 ? 0 : 8,
                  ),
                  child: DragTarget<int>(
                    onWillAcceptWithDetails: (_) =>
                        _step == _BuildStep.build && i >= _used.length,
                    onAcceptWithDetails: (details) => _place(details.data, i),
                    builder: (_, candidates, rejected) => Semantics(
                      label:
                          'Letter slot ${i + 1}${i < _used.length ? ', ${_letters[i]}' : ', empty'}',
                      child: AnimatedContainer(
                        key: ValueKey('build-slot-$i'),
                        duration: Duration(milliseconds: _reduced ? 0 : 300),
                        width: tile,
                        height: tile,
                        decoration: BoxDecoration(
                          color: i < _used.length
                              ? const Color(0xFFD9F2E8)
                              : const Color(0xFFF1F5F7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            width: 2,
                            color: candidates.isNotEmpty
                                ? const Color(0xFF44AFC0)
                                : const Color(0xFFB9D2D9),
                          ),
                        ),
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: Duration(
                              milliseconds: _reduced ? 0 : 300,
                            ),
                            transitionBuilder: (child, animation) =>
                                ScaleTransition(
                                  scale: CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOutBack,
                                  ),
                                  child: child,
                                ),
                            child: Text(
                              i < _used.length ? _letters[i] : '·',
                              key: ValueKey(i < _used.length),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_step == _BuildStep.build && !_assembled)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final id in _order)
                  if (!_used.contains(id))
                    Draggable<int>(
                      data: id,
                      maxSimultaneousDrags: 1,
                      feedback: Material(
                        color: Colors.transparent,
                        child: _piece(id, tile),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.2,
                        child: _piece(id, tile),
                      ),
                      child: _piece(id, tile),
                    ),
              ],
            )
          else if (_step == _BuildStep.build)
            FilledButton(
              onPressed: () => setState(() => _step = _BuildStep.model),
              child: const Text('Show word caption'),
            )
          else if (_step == _BuildStep.model)
            FilledButton.icon(
              onPressed: () => setState(() => _step = _BuildStep.speak),
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Your turn'),
            )
          else ...[
            SizedBox(
              height: compact ? 34 : 60,
              child: AnimatedBuilder(
                animation: _voice,
                builder: (_, _) => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    for (var i = 0; i < 13; i++)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: 6,
                        height: _voice.isAnimating && !_reduced
                            ? 8 +
                                  (compact ? 22 : 42) *
                                      math
                                          .sin(
                                            _voice.value * math.pi * 10 +
                                                i * 0.65,
                                          )
                                          .abs()
                            : 8,
                        decoration: BoxDecoration(
                          color: const Color(0xFF55B8B5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: [
                FilledButton.icon(
                  key: const ValueKey('speech-animation-preview'),
                  onPressed: _voice.isAnimating
                      ? null
                      : () {
                          _voice.forward(from: 0);
                        },
                  icon: const Icon(Icons.graphic_eq),
                  label: Text(
                    _voice.isAnimating
                        ? 'Animating…'
                        : 'Preview speaking animation',
                  ),
                ),
                TextButton(onPressed: _reset, child: const Text('Build again')),
              ],
            ),
          ],
        ],
      );
    },
  );
  Widget _piece(int id, double size) => Semantics(
    label: 'Place ${_letters[id]} piece ${id + 1}',
    button: true,
    excludeSemantics: true,
    onTap: () => _place(id),
    child: SizedBox(
      width: size,
      height: size,
      child: Material(
        color: const Color(0xFFFFF0CE),
        elevation: 2,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          key: ValueKey('build-piece-$id'),
          borderRadius: BorderRadius.circular(12),
          onTap: () => _place(id),
          child: Center(
            child: Text(
              _letters[id],
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Color(0xFF725824),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
