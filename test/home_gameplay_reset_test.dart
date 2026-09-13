import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:thesis/controllers/home_controller.dart';
import 'package:thesis/models/learning_report_model.dart';
import 'package:thesis/models/profile_model.dart';
import 'package:thesis/views/home/home_page.dart';
import 'package:thesis/features/game/presentation/gameplay_gallery_page.dart';

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
  testWidgets('standalone gallery Back returns through the main app callback', (
    tester,
  ) async {
    var returnedToMain = false;
    await tester.pumpWidget(
      MaterialApp(
        home: GameplayGalleryPage(onBackToMain: () => returnedToMain = true),
      ),
    );
    await tester.tap(find.byTooltip('Back to main screen'));
    await tester.pump();
    expect(returnedToMain, isTrue);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'home map and template gallery navigation do not save legacy progress',
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
      await tester.tap(find.bySemanticsLabel('Customize'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Gameplay Templates'), findsOneWidget);
      final availableTile = tester.widget<ListTile>(
        find.ancestor(
          of: find.text('Find the Word'),
          matching: find.byType(ListTile),
        ),
      );
      expect(availableTile.enabled, isTrue);
      expect(availableTile.onTap, isNotNull);
      await tester.tap(find.text('Find the Word'));
      await tester.pumpAndSettle();
      expect(find.text('Find the ball.'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Falling Sound Bubbles'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Watch the sound bubbles'), findsOneWidget);
      for (var i = 1; i <= 3; i++) {
        expect(find.byKey(ValueKey('sound-bubble-$i')), findsOneWidget);
      }
      await tester.pageBack();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('Sound Emphasis'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Notice the sound'), findsOneWidget);
      expect(find.text('Picture placeholder'), findsOneWidget);
      await tester.pageBack();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('Picture Listen'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      for (var i = 1; i <= 3; i++) {
        expect(find.text('Image $i'), findsOneWidget);
      }
      await tester.pageBack();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.scrollUntilVisible(
        find.text('Story Adventure'),
        350,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Story Adventure'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Find the Sound'),
        -350,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Find the Sound'));
      await tester.pumpAndSettle();
      expect(find.text('Which picture starts with /b/?'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Gameplay Templates'), findsOneWidget);
      await tester.tap(find.byTooltip('Back to main screen'));
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
