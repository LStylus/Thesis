import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Shared, replaceable presentation assets; no game services or saved state.
class TemplatePicture extends StatelessWidget {
  const TemplatePicture(this.assetPath, {super.key});
  final String assetPath;
  @override
  Widget build(BuildContext context) => assetPath.endsWith('.svg')
      ? SvgPicture.asset(assetPath, fit: BoxFit.contain)
      : Image.asset(assetPath, fit: BoxFit.contain);
}

class TemplateCaption extends StatelessWidget {
  const TemplateCaption(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFFF0F8FA),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Semantics(
      liveRegion: true,
      child: Column(
        children: [
          const Text(
            'TEMPORARY CAPTION',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1.4,
              color: Color(0xFF677D86),
            ),
          ),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Color(0xFF244653),
            ),
          ),
        ],
      ),
    ),
  );
}

class TemplateSurface extends StatelessWidget {
  const TemplateSurface({
    super.key,
    required this.builder,
    this.backgroundColor = Colors.white,
    this.backgroundImage,
  });
  final Widget Function(BuildContext, bool, Size) builder;
  final Color backgroundColor;
  final ImageProvider? backgroundImage;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: backgroundColor,
    body: DecoratedBox(
      decoration: BoxDecoration(
        image: backgroundImage == null
            ? null
            : DecorationImage(image: backgroundImage!, fit: BoxFit.cover),
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, bounds) {
            final wide = bounds.maxWidth > bounds.maxHeight;
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: bounds.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: builder(context, wide, bounds.biggest),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}
