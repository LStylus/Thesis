import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/constants/app_assets.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_fonts.dart';

class VoyageLoadingScreen extends StatefulWidget {
  final String message;

  const VoyageLoadingScreen({
    super.key,
    this.message = 'Generating personalized\nlearning content...',
  });

  @override
  State<VoyageLoadingScreen> createState() => _VoyageLoadingScreenState();
}

class _VoyageLoadingScreenState extends State<VoyageLoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1450),
    )..repeat();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final mascotWidth = (size.width * 0.24).clamp(118.0, 160.0);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: ColoredBox(
          color: Colors.white,
          child: SafeArea(
            child: SizedBox.expand(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    AppAssets.whaleMascot,
                    width: mascotWidth,
                    height: mascotWidth * 0.6,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontFamily: AppFonts.fredokaOne,
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      height: 1.12,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 22),
                  _LoadingLine(animation: _progressController),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingLine extends StatelessWidget {
  final Animation<double> animation;

  const _LoadingLine({required this.animation});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 270,
      height: 4,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          final progress = Curves.easeInOut.transform(animation.value);

          return Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: 3,
                decoration: BoxDecoration(
                  color: const Color(0xFFD9D9D9),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress.clamp(0.08, 1.0),
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
