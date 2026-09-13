import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thesis/features/game/presentation/picture_listen_preview_page.dart';

void main() {
  Widget preview({bool reducedMotion = false}) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reducedMotion),
      child: Scaffold(
        appBar: AppBar(title: const Text('Picture Listen')),
        body: const PictureListenPreviewPage(),
      ),
    ),
  );

  testWidgets('taps animate, switch captions, replay and dispose safely', (
    tester,
  ) async {
    await tester.pumpWidget(preview());
    expect(find.text('Choose any picture.'), findsOneWidget);
    await tester.tap(find.text('Image 1'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 325));
    expect(find.text('Sun'), findsOneWidget);
    final reaction = tester.widget<Transform>(
      find.byKey(const ValueKey('picture-reaction-0')),
    );
    expect(reaction.transform.entry(0, 0), greaterThan(1.05));
    await tester.tap(find.text('Image 2'));
    await tester.pump();
    await tester.tap(find.text('Image 3'));
    await tester.pumpAndSettle();
    expect(find.text('Ball'), findsOneWidget);
    expect(find.text('Cat'), findsNothing);
    await tester.tap(find.text('Image 3'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 325));
    expect(
      tester
          .widget<Transform>(find.byKey(const ValueKey('picture-reaction-2')))
          .transform
          .entry(0, 0),
      greaterThan(1.05),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion retains captions without bounce', (tester) async {
    await tester.pumpWidget(preview(reducedMotion: true));
    await tester.tap(find.text('Image 2'));
    await tester.pumpAndSettle();
    expect(find.text('Cat'), findsOneWidget);
    expect(
      tester
          .widget<Transform>(find.byKey(const ValueKey('picture-reaction-1')))
          .transform
          .entry(0, 0),
      1,
    );
    expect(tester.takeException(), isNull);
  });

  for (final size in [
    const Size(1280, 720),
    const Size(844, 390),
    const Size(568, 320),
  ]) {
    testWidgets('animated frames and caption fit at $size', (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(preview());
      await tester.tap(find.text('Image 2'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 325));
      final screen = Offset.zero & size;
      final frames = <Rect>[];
      for (var i = 0; i < 3; i++) {
        final frame = find.descendant(
          of: find.byKey(ValueKey('picture-reaction-$i')),
          matching: find.byType(AnimatedContainer),
        );
        final rect = tester.getRect(frame);
        expect(screen.contains(rect.topLeft), isTrue);
        expect(screen.contains(rect.bottomRight), isTrue);
        for (final previous in frames) {
          expect(rect.overlaps(previous), isFalse);
        }
        expect(
          (tester.widget<AnimatedContainer>(frame).decoration as BoxDecoration)
              .color,
          Colors.black,
        );
        frames.add(rect);
      }
      expect(
        screen.contains(tester.getRect(find.text('Cat')).bottomRight),
        isTrue,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
    });
  }
}
