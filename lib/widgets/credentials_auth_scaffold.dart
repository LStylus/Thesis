import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_fonts.dart';
import '../core/constants/app_text_styles.dart';

enum CredentialsAuthMode { login, signup }

const _voyageOverlayStyle = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.dark,
  statusBarBrightness: Brightness.light,
  systemNavigationBarColor: Colors.white,
  systemNavigationBarIconBrightness: Brightness.dark,
  systemNavigationBarDividerColor: Colors.white,
  systemNavigationBarContrastEnforced: false,
);

typedef _VoyagePaneBuilder =
    Widget Function(BuildContext context, bool compact, bool dense);

class CredentialsAuthScaffold extends StatelessWidget {
  final CredentialsAuthMode mode;
  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback? onLoginSelected;
  final VoidCallback? onSignupSelected;

  const CredentialsAuthScaffold({
    super.key,
    required this.mode,
    required this.title,
    required this.subtitle,
    required this.child,
    this.onLoginSelected,
    this.onSignupSelected,
  });

  @override
  Widget build(BuildContext context) {
    return _VoyageSplitFrame(
      paneBuilder: (context, compact, dense) => _CredentialsPane(
        compact: compact,
        dense: dense,
        mode: mode,
        title: title,
        subtitle: subtitle,
        onLoginSelected: onLoginSelected,
        onSignupSelected: onSignupSelected,
        child: child,
      ),
    );
  }
}

class VoyageFlowScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final String? eyebrow;
  final int? currentStep;
  final int? totalSteps;
  final VoidCallback? onBack;
  final VoidCallback? onClose;
  final double contentMaxWidth;

  const VoyageFlowScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.eyebrow,
    this.currentStep,
    this.totalSteps,
    this.onBack,
    this.onClose,
    this.contentMaxWidth = 500,
  }) : assert(onBack == null || onClose == null),
       assert(
         (currentStep == null && totalSteps == null) ||
             (currentStep != null && totalSteps != null),
       );

  @override
  Widget build(BuildContext context) {
    return _VoyageSplitFrame(
      paneBuilder: (context, compact, dense) => _VoyageFlowPane(
        compact: compact,
        dense: dense,
        title: title,
        subtitle: subtitle,
        eyebrow: eyebrow,
        currentStep: currentStep,
        totalSteps: totalSteps,
        onBack: onBack,
        onClose: onClose,
        contentMaxWidth: contentMaxWidth,
        child: child,
      ),
    );
  }
}

class _VoyageSplitFrame extends StatelessWidget {
  final _VoyagePaneBuilder paneBuilder;

  const _VoyageSplitFrame({required this.paneBuilder});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _voyageOverlayStyle,
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final dense = constraints.maxHeight < 420;
            final compact =
                constraints.maxWidth < 980 || constraints.maxHeight < 520;
            final artWidthFactor = compact ? 0.41 : 0.52;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: constraints.maxWidth * artWidthFactor,
                  child: _VoyageArtPanel(compact: compact, dense: dense),
                ),
                Expanded(child: paneBuilder(context, compact, dense)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _VoyageFlowPane extends StatelessWidget {
  final bool compact;
  final bool dense;
  final String title;
  final String subtitle;
  final Widget child;
  final String? eyebrow;
  final int? currentStep;
  final int? totalSteps;
  final VoidCallback? onBack;
  final VoidCallback? onClose;
  final double contentMaxWidth;

  const _VoyageFlowPane({
    required this.compact,
    required this.dense,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.eyebrow,
    required this.currentStep,
    required this.totalSteps,
    required this.onBack,
    required this.onClose,
    required this.contentMaxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final horizontalPadding = dense ? 24.0 : (compact ? 28.0 : 52.0);
    final verticalPadding = dense ? 8.0 : (compact ? 14.0 : 30.0);
    final action = onBack ?? onClose;
    final actionIcon = onBack != null
        ? Icons.arrow_back_rounded
        : Icons.close_rounded;
    final actionLabel = onBack != null ? 'Back' : 'Close';

    return SafeArea(
      left: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final minimumHeight = math.max(
            0.0,
            constraints.maxHeight -
                (verticalPadding * 2) -
                mediaQuery.viewInsets.bottom,
          );

          return SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              verticalPadding,
              horizontalPadding,
              verticalPadding + mediaQuery.viewInsets.bottom,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: minimumHeight),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: contentMaxWidth),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (action != null)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Semantics(
                            label: actionLabel,
                            button: true,
                            child: IconButton(
                              tooltip: actionLabel,
                              onPressed: action,
                              icon: Icon(actionIcon),
                              color: const Color(0xFF52717E),
                              iconSize: dense ? 22 : 24,
                              style: IconButton.styleFrom(
                                backgroundColor: const Color(0xFFF0F6F8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (action != null)
                        SizedBox(height: dense ? 6 : (compact ? 10 : 18)),
                      if (currentStep != null && totalSteps != null) ...[
                        _FlowProgress(
                          currentStep: currentStep!,
                          totalSteps: totalSteps!,
                        ),
                        SizedBox(height: dense ? 8 : 14),
                      ] else if (eyebrow != null) ...[
                        Text(
                          eyebrow!.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.primaryShadow,
                            fontFamily: AppFonts.fredoka,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0,
                          ),
                        ),
                        SizedBox(height: dense ? 4 : 8),
                      ],
                      Text(
                        title,
                        style: AppTextStyles.pageTitle.copyWith(
                          color: const Color(0xFF124B63),
                          fontSize: dense ? 25 : (compact ? 27 : 34),
                        ),
                      ),
                      SizedBox(height: dense ? 2 : 6),
                      Text(
                        subtitle,
                        style: AppTextStyles.subtitle.copyWith(
                          color: const Color(0xFF66818D),
                          fontSize: dense ? 13 : (compact ? 14 : 15.5),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: dense ? 12 : (compact ? 18 : 26)),
                      child,
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FlowProgress extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const _FlowProgress({required this.currentStep, required this.totalSteps});

  @override
  Widget build(BuildContext context) {
    final value = totalSteps <= 0
        ? 0.0
        : (currentStep / totalSteps).clamp(0.0, 1.0);

    return Row(
      children: [
        Text(
          'STEP $currentStep OF $totalSteps',
          style: const TextStyle(
            color: Color(0xFF66818D),
            fontFamily: AppFonts.fredoka,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 6,
              color: AppColors.primary,
              backgroundColor: const Color(0xFFDCECF1),
            ),
          ),
        ),
      ],
    );
  }
}

class _CredentialsPane extends StatelessWidget {
  final bool compact;
  final bool dense;
  final CredentialsAuthMode mode;
  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback? onLoginSelected;
  final VoidCallback? onSignupSelected;

  const _CredentialsPane({
    required this.compact,
    required this.dense,
    required this.mode,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.onLoginSelected,
    required this.onSignupSelected,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final horizontalPadding = dense ? 24.0 : (compact ? 28.0 : 52.0);
    final verticalPadding = dense ? 8.0 : (compact ? 14.0 : 30.0);

    return SafeArea(
      left: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final minimumHeight = math.max(
            0.0,
            constraints.maxHeight -
                (verticalPadding * 2) -
                mediaQuery.viewInsets.bottom,
          );

          return SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              verticalPadding,
              horizontalPadding,
              verticalPadding + mediaQuery.viewInsets.bottom,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: minimumHeight),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 470),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _AuthModeSwitcher(
                        dense: dense,
                        mode: mode,
                        onLoginSelected: onLoginSelected,
                        onSignupSelected: onSignupSelected,
                      ),
                      SizedBox(height: dense ? 10 : (compact ? 18 : 30)),
                      Text(
                        title,
                        style: AppTextStyles.pageTitle.copyWith(
                          color: const Color(0xFF124B63),
                          fontSize: dense ? 25 : (compact ? 27 : 34),
                        ),
                      ),
                      SizedBox(height: dense ? 2 : 6),
                      Text(
                        subtitle,
                        style: AppTextStyles.subtitle.copyWith(
                          color: const Color(0xFF66818D),
                          fontSize: dense ? 13 : (compact ? 14 : 15.5),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: dense ? 12 : (compact ? 18 : 28)),
                      child,
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _VoyageArtPanel extends StatelessWidget {
  final bool compact;
  final bool dense;

  const _VoyageArtPanel({required this.compact, required this.dense});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/game/bubble_bay/bubble_bay_background.png',
          fit: BoxFit.cover,
          alignment: const Alignment(0.08, 0),
        ),
        const ColoredBox(color: Color(0x24004E68)),
        SafeArea(
          right: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              dense ? 20 : (compact ? 24 : 40),
              dense ? 8 : (compact ? 14 : 28),
              dense ? 16 : (compact ? 20 : 32),
              dense ? 10 : (compact ? 16 : 28),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'VOICE VOYAGE',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: AppFonts.matemasie,
                        fontSize: dense ? 30 : (compact ? 34 : 48),
                        fontWeight: FontWeight.w400,
                        height: 1.12,
                        letterSpacing: 0,
                        shadows: const [
                          Shadow(
                            color: Color(0x66004D67),
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Text(
                  'Every sound is a step forward.',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: AppFonts.fredoka,
                    fontSize: dense ? 12 : (compact ? 13 : 16),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                    shadows: const [
                      Shadow(
                        color: Color(0x80004D67),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: dense ? 138 : (compact ? 170 : 245),
                    height: dense ? 96 : (compact ? 122 : 176),
                    child: SvgPicture.asset(
                      'assets/game/shared/whale_happy.svg',
                      fit: BoxFit.contain,
                      semanticsLabel: 'Voice Voyage whale mascot',
                    ),
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    for (final color in const [
                      Color(0xFFFFD85E),
                      Color(0xFFFF8DA7),
                      Color(0xFF8BE1C3),
                    ]) ...[
                      Container(
                        width: compact ? 8 : 10,
                        height: compact ? 8 : 10,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AuthModeSwitcher extends StatelessWidget {
  final bool dense;
  final CredentialsAuthMode mode;
  final VoidCallback? onLoginSelected;
  final VoidCallback? onSignupSelected;

  const _AuthModeSwitcher({
    required this.dense,
    required this.mode,
    required this.onLoginSelected,
    required this.onSignupSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: dense ? 42 : 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F6F8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDCE9ED)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _AuthModeButton(
              dense: dense,
              label: 'Log in',
              selected: mode == CredentialsAuthMode.login,
              onPressed: onLoginSelected,
            ),
          ),
          Expanded(
            child: _AuthModeButton(
              dense: dense,
              label: 'Sign up',
              selected: mode == CredentialsAuthMode.signup,
              onPressed: onSignupSelected,
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthModeButton extends StatelessWidget {
  final bool dense;
  final String label;
  final bool selected;
  final VoidCallback? onPressed;

  const _AuthModeButton({
    required this.dense,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x160D516B),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ]
              : const [],
        ),
        child: TextButton(
          onPressed: selected ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: selected
                ? AppColors.primaryShadow
                : const Color(0xFF708791),
            disabledForegroundColor: AppColors.primaryShadow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            textStyle: TextStyle(
              fontFamily: AppFonts.fredoka,
              fontSize: dense ? 14 : 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
          child: Text(label),
        ),
      ),
    );
  }
}

class CredentialFieldsLayout extends StatelessWidget {
  final Widget firstField;
  final Widget secondField;
  final Widget? footer;

  const CredentialFieldsLayout({
    super.key,
    required this.firstField,
    required this.secondField,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final dense = MediaQuery.sizeOf(context).height < 420;

    if (!dense) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          firstField,
          const SizedBox(height: 14),
          secondField,
          if (footer != null) ...[const SizedBox(height: 8), footer!],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: firstField),
            const SizedBox(width: 10),
            Expanded(child: secondField),
          ],
        ),
        if (footer != null) ...[const SizedBox(height: 6), footer!],
      ],
    );
  }
}

class CredentialsErrorBanner extends StatelessWidget {
  final String message;

  const CredentialsErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3F1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFFFCFC6)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFC94C3C),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Color(0xFF8B3D33),
                  fontFamily: AppFonts.fredoka,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
