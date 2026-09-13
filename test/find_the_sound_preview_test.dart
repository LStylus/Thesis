import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thesis/features/game/presentation/find_the_sound_preview_page.dart';
import 'package:thesis/features/game/presentation/four_picture_choice_preview.dart';

Widget _app({bool reduced = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduced),
    child: Scaffold(
      appBar: AppBar(title: const Text('Find the Word')),
      body: const FindTheSoundPreviewPage(randomSeed: 42),
    ),
  ),
);

Finder _choice(String word) => find.byKey(ValueKey('sound-choice-$word'));

void main() {
  testWidgets('authored answer keys need not match the round index', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: FindTheSoundPreviewPage(
          rounds: [
            PictureRecognitionRound(
              caption: 'Which picture starts with /p/?',
              answerIndex: 3,
            ),
            PictureRecognitionRound(
              caption: 'Which picture starts with /d/?',
              answerIndex: 2,
            ),
            PictureRecognitionRound(
              caption: 'Which picture starts with /b/?',
              answerIndex: 0,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(_choice('ball'));
    await tester.pumpAndSettle();
    expect(find.text('0 of 3 correct'), findsOneWidget);
    await tester.tap(_choice('pig'));
    await tester.pumpAndSettle();
    expect(find.text('1 of 3 correct'), findsOneWidget);
  });
  testWidgets('wrong choice wiggles and retries without advancing', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    final start = tester.getTopLeft(_choice('pig'));
    await tester.tap(_choice('pig'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(tester.getTopLeft(_choice('pig')).dx, isNot(start.dx));
    expect(find.text('Not quite. Try another picture.'), findsOneWidget);
    expect(find.text('0 of 3 correct'), findsOneWidget);
    expect(find.text('Which picture starts with /b/?'), findsOneWidget);
    await tester.pumpAndSettle();
    await tester.tap(_choice('ball'));
    await tester.pumpAndSettle();
    expect(find.text('1 of 3 correct'), findsOneWidget);
    expect(find.text('Ball starts with /b/!'), findsOneWidget);
  });

  testWidgets('three authored sound rounds complete and replay resets', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    final initial = [
      'ball',
      'key',
      'dog',
      'pig',
    ].map((word) => tester.getTopLeft(_choice(word))).toList();
    for (final word in ['ball', 'key', 'dog']) {
      expect(
        find.text(
          'Which picture starts with /${{'ball': 'b', 'key': 'k', 'dog': 'd'}[word]}/?',
        ),
        findsOneWidget,
      );
      await tester.tap(_choice(word));
      // A duplicate event in the same frame cannot award another round.
      await tester.tap(_choice(word));
      await tester.pumpAndSettle();
      final correct = ['ball', 'key', 'dog'].indexOf(word) + 1;
      expect(find.text('$correct of 3 correct'), findsOneWidget);
      if (word != 'dog') {
        await tester.tap(find.text('Next sound'));
        await tester.pumpAndSettle();
      }
    }
    expect(find.text('Three sounds found!'), findsOneWidget);
    expect(_choice('dog'), findsNothing);
    await tester.tap(find.text('Play again'));
    await tester.pumpAndSettle();
    expect(find.text('0 of 3 correct'), findsOneWidget);
    expect(find.text('Which picture starts with /b/?'), findsOneWidget);
    final replay = [
      'ball',
      'key',
      'dog',
      'pig',
    ].map((word) => tester.getTopLeft(_choice(word))).toList();
    expect(replay, isNot(initial));
  });

  testWidgets(
    'reduced motion remains playable and disposal cancels animation',
    (tester) async {
      await tester.pumpWidget(_app(reduced: true));
      await tester.pumpAndSettle();
      final start = tester.getTopLeft(_choice('pig'));
      await tester.tap(_choice('pig'));
      await tester.pump();
      expect(tester.getTopLeft(_choice('pig')), start);
      await tester.tap(_choice('ball'));
      await tester.pump();
      expect(find.text('1 of 3 correct'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();
      await tester.tap(_choice('pig'));
      await tester.pump(const Duration(milliseconds: 80));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
    },
  );

  for (final size in [
    const Size(1280, 720),
    const Size(844, 390),
    const Size(568, 320),
    const Size(390, 844),
  ]) {
    testWidgets('all four square choices fit at $size', (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();
      final rects = <Rect>[];
      for (final word in ['ball', 'key', 'dog', 'pig']) {
        final rect = tester.getRect(_choice(word));
        expect(rect.width, closeTo(rect.height, 0.01));
        expect(rect.width, greaterThanOrEqualTo(48));
        expect((Offset.zero & size).contains(rect.topLeft), isTrue);
        expect((Offset.zero & size).contains(rect.bottomRight), isTrue);
        expect(rects.any((other) => other.overlaps(rect)), isFalse);
        rects.add(rect);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
