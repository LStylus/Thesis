import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../features/screening/application/screening_results_controller.dart';
import '../../models/screening_word_model.dart';
import '../../services/phoneme_assessment_service.dart';
import '../../widgets/credentials_auth_scaffold.dart';
import '../../widgets/glow_asset_button.dart';
import '../../widgets/practice_module_section.dart';
import '../../widgets/primary_button.dart';
import '../auth/auth_gate.dart';

part 'screening_results_widgets.dart';

class ScreeningAccuracyResultsPage extends StatefulWidget {
  final List<ScreeningWordModel> words;
  final Map<String, String> recordingsByWordId;
  final Map<String, PhonemeAssessmentResult> assessmentResultsByWordId;

  const ScreeningAccuracyResultsPage({
    super.key,
    required this.words,
    required this.recordingsByWordId,
    required this.assessmentResultsByWordId,
  });

  @override
  State<ScreeningAccuracyResultsPage> createState() =>
      _ScreeningAccuracyResultsPageState();
}

class _ScreeningAccuracyResultsPageState
    extends State<ScreeningAccuracyResultsPage> {
  late final ScreeningResultsController _resultsController;
  bool _isSavingProfile = false;
  String? _profileSaveError;

  @override
  void initState() {
    super.initState();
    _resultsController = ScreeningResultsController.createDefault(
      words: widget.words,
      recordingsByWordId: widget.recordingsByWordId,
      assessmentResultsByWordId: widget.assessmentResultsByWordId,
    );
    _resultsController.addListener(_handleResultsChanged);
    _resultsController.start();
  }

  void _handleResultsChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _discardAndGoHome() async {
    final authController = context.read<AuthController>();
    final isExisting = authController.isExistingParentSession;

    await authController.discardPendingProfile();
    if (!mounted) return;

    if (isExisting) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (route) => false,
      );
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (route) => false,
      );
    }
  }

  Future<void> _proceedToHome() async {
    if (_isSavingProfile) return;

    setState(() {
      _isSavingProfile = true;
      _profileSaveError = null;
    });

    final authController = context.read<AuthController>();
    final saved = await authController.completeSignup();
    if (!mounted) return;

    if (!saved) {
      setState(() {
        _isSavingProfile = false;
        _profileSaveError =
            authController.errorMessage ?? 'Could not save profile data.';
      });
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _resultsController.removeListener(_handleResultsChanged);
    _resultsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_resultsController.isRunning) {
      return _LandscapeLoadingView(
        processedCount: _resultsController.processedCount,
        totalCount: widget.words.length,
      );
    }

    final dense = MediaQuery.sizeOf(context).height < 420;

    return VoyageFlowScaffold(
      eyebrow: 'Assessment complete',
      onClose: _discardAndGoHome,
      title: 'Screening results',
      subtitle: 'Review the detected speech patterns before continuing.',
      contentMaxWidth: 560,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_resultsController.results.isEmpty)
            const _EmptyResultsMessage()
          else
            ..._resultsController.results.map(
              (result) => _FigmaResultTile(
                result: result,
                isPlaying: _resultsController.playingWordId == result.wordId,
                onPlay: () => _resultsController.playRecording(result),
              ),
            ),
          if (_resultsController.learningModule != null) ...[
            const SizedBox(height: 6),
            PracticeModuleSection(
              module: _resultsController.learningModule!,
            ),
          ],
          if (_profileSaveError != null) ...[
            const SizedBox(height: 10),
            CredentialsErrorBanner(message: _profileSaveError!),
          ],
          SizedBox(height: dense ? 10 : 18),
          PrimaryButton(
            text: 'Finish setup',
            onPressed: _isSavingProfile ? null : _proceedToHome,
            isLoading: _isSavingProfile,
            height: dense ? 48 : 56,
            borderRadius: 8,
            trailingIcon: Icons.arrow_forward_rounded,
          ),
        ],
      ),
    );
  }
}
