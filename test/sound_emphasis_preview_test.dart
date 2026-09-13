import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thesis/features/game/presentation/sound_emphasis_preview_page.dart';

void main() {
  Widget preview({
    bool reduced = false,
    Widget page = const SoundEmphasisPreviewPage(),
  }) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduced),
      child: Scaffold(
        appBar: AppBar(title: const Text('Sound Emphasis')),
        body: page,
      ),
    ),
  );

  testWidgets('tap pulses the sound, shows caption, replays and disposes', (
    tester,
  ) async {
    await tester.pumpWidget(preview());
    await tester.tap(find.text('Picture placeholder'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('SUN — notice /s/ at the beginning.'), findsOneWidget);
    final target = find.byKey(const ValueKey('target-sound-reaction'));
    expect(
      tester.widget<Transform>(target).transform.entry(0, 0),
      closeTo(1.1, 0.001),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<Transform>(target).transform.entry(0, 0),
      closeTo(1, 0.001),
    );
    await tester.tap(find.byTooltip('Replay emphasis'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(
      tester.widget<Transform>(target).transform.entry(0, 0),
      greaterThan(1.09),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('configured end sound and reduced motion keep correct caption', (
    tester,
  ) async {
    await tester.pumpWidget(
      preview(
        reduced: true,
        page: const SoundEmphasisPreviewPage(
          beforeTarget: 'BU',
          targetText: 'S',
          afterTarget: '',
          position: SoundEmphasisPosition.end,
        ),
      ),
    );
    await tester.tap(find.byTooltip('Play emphasis'));
    await tester.pumpAndSettle();
    expect(find.text('BUS — notice /s/ at the end.'), findsOneWidget);
    expect(
      tester
          .widget<Transform>(
            find.byKey(const ValueKey('target-sound-reaction')),
          )
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
    testWidgets('picture, emphasis and caption fit at $size', (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(preview());
      await tester.tap(find.byTooltip('Play emphasis'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      final screen = Offset.zero & size;
      for (final key in [
        'sound-picture-reaction',
        'target-sound-reaction',
        'sound-caption',
      ]) {
        final rect = tester.getRect(find.byKey(ValueKey(key)));
        expect(screen.contains(rect.topLeft), isTrue);
        expect(screen.contains(rect.bottomRight), isTrue);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
    });
  }
}
