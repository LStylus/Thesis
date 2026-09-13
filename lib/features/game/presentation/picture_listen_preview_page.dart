import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Interactive visual prototype; captions substitute for audio, not exposure credit.
class PictureListenPreviewPage extends StatefulWidget {
  const PictureListenPreviewPage({
    super.key,
    this.backgroundColor = Colors.white,
    this.backgroundImage,
    this.firstImage,
    this.secondImage,
    this.thirdImage,
    this.firstCaption = 'Sun',
    this.secondCaption = 'Cat',
    this.thirdCaption = 'Ball',
  });

  static const routeName = '/dev/picture-listen';

  final Color backgroundColor;
  final ImageProvider? backgroundImage;
  final ImageProvider? firstImage;
  final ImageProvider? secondImage;
  final ImageProvider? thirdImage;
  final String firstCaption;
  final String secondCaption;
  final String thirdCaption;

  @override
  State<PictureListenPreviewPage> createState() =>
      _PictureListenPreviewPageState();
}

class _PictureListenPreviewPageState extends State<PictureListenPreviewPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _reaction = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  int? _selected;

  void _select(int index) {
    setState(() => _selected = index);
    if (MediaQuery.disableAnimationsOf(context)) {
      _reaction.stop();
      _reaction.value = 1;
    } else {
      // Restart one reaction, including replays; rapid taps never queue effects.
      _reaction.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _reaction.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.backgroundColor,
      body: DecoratedBox(
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
              final margin = math.min(48.0, constraints.maxWidth * 0.06);
              final gap = math.min(32.0, constraints.maxWidth * 0.03);
              final images = [
                widget.firstImage,
                widget.secondImage,
                widget.thirdImage,
              ];
              final captions = [
                widget.firstCaption,
                widget.secondCaption,
                widget.thirdCaption,
              ];
              final reducedMotion = MediaQuery.disableAnimationsOf(context);

              return SingleChildScrollView(
                child: SizedBox(
                  height: math.max(280, constraints.maxHeight),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: margin,
                      vertical: 16,
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Tap a picture',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF244653),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, field) {
                              final size = math.max(
                                0.0,
                                math.min(
                                  280.0,
                                  math.min(
                                    (field.maxWidth - gap * 2) / 3.1,
                                    field.maxHeight / 1.12,
                                  ),
                                ),
                              );
                              return Center(
                                child: AnimatedBuilder(
                                  animation: _reaction,
                                  builder: (context, _) => Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      for (
                                        var index = 0;
                                        index < images.length;
                                        index++
                                      ) ...[
                                        if (index > 0) SizedBox(width: gap),
                                        Transform.scale(
                                          key: ValueKey(
                                            'picture-reaction-$index',
                                          ),
                                          scale:
                                              _selected == index &&
                                                  !reducedMotion
                                              ? 1 +
                                                    0.07 *
                                                        math.sin(
                                                          math.pi *
                                                              _reaction.value,
                                                        )
                                              : 1,
                                          child: _PictureFrame(
                                            size: size,
                                            label: 'Image ${index + 1}',
                                            image: images[index],
                                            selected: _selected == index,
                                            reducedMotion: reducedMotion,
                                            onTap: () => _select(index),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxWidth: 620),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F8FA),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Semantics(
                            liveRegion: true,
                            child: AnimatedSwitcher(
                              duration: Duration(
                                milliseconds: reducedMotion ? 0 : 180,
                              ),
                              child: Text(
                                _selected == null
                                    ? 'Choose any picture.'
                                    : captions[_selected!],
                                key: ValueKey(_selected),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 24,
                                  color: Color(0xFF244653),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Temporary captions · Voice-over coming later',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF677D86),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PictureFrame extends StatelessWidget {
  const _PictureFrame({
    required this.size,
    required this.label,
    required this.image,
    required this.selected,
    required this.reducedMotion,
    required this.onTap,
  });

  final double size;
  final String label;
  final ImageProvider? image;
  final bool selected;
  final bool reducedMotion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final placeholder = Center(
      child: Text(
        label,
        style: const TextStyle(fontSize: 14, color: Colors.white),
      ),
    );

    return Semantics(
      label: label,
      button: true,
      selected: selected,
      onTap: onTap,
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: Duration(milliseconds: reducedMotion ? 0 : 180),
        width: size,
        height: size,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(
            color: selected ? const Color(0xFF00B8DE) : const Color(0xFF353535),
            width: 3,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x4400B8DE),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(17),
            child: image == null
                ? placeholder
                : Padding(
                    padding: const EdgeInsets.all(12),
                    child: Image(
                      image: image!,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => placeholder,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
