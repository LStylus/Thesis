import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thesis/features/game/presentation/falling_sound_bubbles_preview_page.dart';

Widget _app({bool reduced = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduced),
    child: Scaffold(
      appBar: AppBar(title: const Text('Falling Sound Bubbles')),
      body: const FallingSoundBubblesPreviewPage(randomSeed: 42),
    ),
  ),
);
void main() {
  testWidgets('independent falls reroll positions without viewed progress', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    final bubbles = [
      for (var i = 1; i <= 3; i++) find.byKey(ValueKey('sound-bubble-$i')),
    ];
    final starts = bubbles.map(tester.getTopLeft).toList();
    expect(starts.map((p) => p.dy).toSet().length, 3);
    await tester.pump(const Duration(milliseconds: 500));
    final distances = [
      for (var i = 0; i < 3; i++)
        tester.getTopLeft(bubbles[i]).dy - starts[i].dy,
    ];
    expect(distances.every((d) => d > 0), isTrue);
    expect(distances.toSet().length, 3);
    final horizontalPositions = [
      for (final start in starts) <double>{start.dx},
    ];
    final field = tester.getRect(find.byKey(const ValueKey('bubble-field')));
    for (var tick = 0; tick < 150; tick++) {
      await tester.pump(const Duration(milliseconds: 200));
      for (var i = 0; i < 3; i++) {
        final rect = tester.getRect(bubbles[i]);
        horizontalPositions[i].add(rect.left);
        expect(rect.left, greaterThanOrEqualTo(field.left));
        expect(rect.right, lessThanOrEqualTo(field.right));
      }
    }
    expect(
      horizontalPositions.every((positions) => positions.length >= 3),
      isTrue,
    );
    expect(find.text('0 of 3 viewed'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('manual pause freezes flights and resume does not catch up', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    final bubble = find.byKey(const ValueKey('sound-bubble-1'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byTooltip('Pause bubbles'));
    await tester.pump();
    final paused = tester.getTopLeft(bubble);
    await tester.pump(const Duration(seconds: 20));
    expect(tester.getTopLeft(bubble), paused);
    await tester.tap(find.byTooltip('Resume bubbles'));
    await tester.pump();
    expect(tester.getTopLeft(bubble), paused);
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.getTopLeft(bubble).dy, greaterThan(paused.dy));
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('caption pauses others for three seconds then removes bubble', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.byKey(const ValueKey('sound-bubble-1')));
    await tester.pump();
    expect(find.text('This is a ball.'), findsOneWidget);
    expect(find.byKey(const ValueKey('spotlight-backdrop')), findsOneWidget);
    final other = find.byKey(const ValueKey('sound-bubble-2'));
    final position = tester.getTopLeft(other);
    await tester.pump(const Duration(seconds: 2));
    expect(tester.getTopLeft(other), position);
    expect(find.text('0 of 3 viewed'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const ValueKey('spotlight-backdrop')), findsNothing);
    expect(find.text('1 of 3 viewed'), findsOneWidget);
    await tester.pump(const Duration(seconds: 12));
    expect(find.byKey(const ValueKey('sound-bubble-1')), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    'three unique captions complete the preview and replay resets it',
    (tester) async {
      await tester.pumpWidget(_app(reduced: true));
      for (var i = 1; i <= 3; i++) {
        await tester.tap(find.byKey(ValueKey('sound-bubble-$i')));
        await tester.pump();
        await tester.pump(const Duration(seconds: 3));
      }
      expect(find.text('3 of 3 viewed'), findsOneWidget);
      expect(find.text('All pictures viewed!'), findsOneWidget);
      await tester.tap(find.text('Play again'));
      await tester.pump();
      expect(find.text('0 of 3 viewed'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'backgrounding cancels caption timer; restart and disposal are safe',
    (tester) async {
      await tester.pumpWidget(_app(reduced: true));
      await tester.tap(find.byKey(const ValueKey('sound-bubble-1')));
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(seconds: 5));
      expect(find.text('0 of 3 viewed'), findsOneWidget);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.tap(find.text('Show caption'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('1 of 3 viewed'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('sound-bubble-2')));
      await tester.pump();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 5));
      expect(tester.takeException(), isNull);
    },
  );
  for (final size in [
    const Size(1280, 720),
    const Size(844, 390),
    const Size(568, 320),
    const Size(390, 844),
  ]) {
    testWidgets('caption spotlight fits at $size', (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_app(reduced: true));
      await tester.tap(find.byKey(const ValueKey('sound-bubble-1')));
      await tester.pump();
      expect(
        (Offset.zero & size).contains(
          tester
              .getRect(find.text('Temporary caption · Voice-over coming later'))
              .bottomRight,
        ),
        isTrue,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
