import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:thesis/controllers/home_controller.dart';
import 'package:thesis/models/learning_report_model.dart';
import 'package:thesis/models/profile_model.dart';
import 'package:thesis/views/home/home_page.dart';

class _HomeController extends Fake implements HomeController {
  final profile = ProfileModel.fromMap(const {
    'profileId': 'p1',
    'userId': 'u1',
    'childName': 'Maya',
    'birthDate': '2020-06-15',
    'profileAssetPath': 'assets/profiles/dolphin.svg',
  });
  final report = const LearningReportData(
    levelScores: [
      LearningReportLevelScore(activityIndex: 0, levelIndex: 0, accuracy: 82),
    ],
  );
  int savedScores = 0;

  @override
  Future<void> ensureCurrentUserProfileAssets() async {}

  @override
  Stream<ProfileModel?> currentUserProfileStream() => Stream.value(profile);

  @override
  Stream<List<ProfileModel>> childProfilesStream() => Stream.value([profile]);

  @override
  Stream<LearningReportData> learningReportStream(ProfileModel profile) =>
      Stream.value(report);

  @override
  Future<void> saveGameplayLevelScore({
    required ProfileModel profile,
    required int levelIndex,
    required int accuracy,
  }) async {
    savedScores++;
  }
}

void main() {
  testWidgets(
    'actual home map opens the notice without saving legacy progress',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 540));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final controller = _HomeController();
      await tester.pumpWidget(
        Provider<HomeController>.value(
          value: controller,
          child: const MaterialApp(home: HomePage()),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('Activity 1: Previous progress'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.bySemanticsLabel('Level 1').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('New gameplay system coming next.'), findsOneWidget);
      await tester.tap(find.text('Back to map'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Activity 1: Previous progress'), findsOneWidget);
      expect(controller.savedScores, 0);
      expect(controller.report.completedLevelCount, 1);
      expect(controller.report.averageAccuracy, 82);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
