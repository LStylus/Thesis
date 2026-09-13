import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thesis/features/game/presentation/find_the_word_preview_page.dart';

Widget _app({bool reduced = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduced),
    child: Scaffold(
      appBar: AppBar(title: const Text('Find the Word')),
      body: const FindTheWordPreviewPage(randomSeed: 42),
    ),
  ),
);

Finder _choice(String word) => find.byKey(ValueKey('word-choice-$word'));

void main() {
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
    expect(find.text('Find the ball.'), findsOneWidget);
    await tester.pumpAndSettle();
    await tester.tap(_choice('ball'));
    await tester.pumpAndSettle();
    expect(find.text('1 of 3 correct'), findsOneWidget);
    expect(find.text('You found it!'), findsOneWidget);
  });

  testWidgets('three distinct correct rounds complete and replay resets', (
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
      expect(find.text('Find the $word.'), findsOneWidget);
      await tester.tap(_choice(word));
      // A duplicate event in the same frame cannot award another round.
      await tester.tap(_choice(word));
      await tester.pumpAndSettle();
      final correct = ['ball', 'key', 'dog'].indexOf(word) + 1;
      expect(find.text('$correct of 3 correct'), findsOneWidget);
      if (word != 'dog') {
        await tester.tap(find.text('Next word'));
        await tester.pumpAndSettle();
      }
    }
    expect(find.text('Three words found!'), findsOneWidget);
    expect(_choice('dog'), findsNothing);
    await tester.tap(find.text('Play again'));
    await tester.pumpAndSettle();
    expect(find.text('0 of 3 correct'), findsOneWidget);
    expect(find.text('Find the ball.'), findsOneWidget);
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
