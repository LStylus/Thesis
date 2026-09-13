import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thesis/features/game/presentation/sound_bucket_preview_page.dart';
import 'package:thesis/features/game/presentation/build_and_say_preview_page.dart';
import 'package:thesis/features/game/presentation/gameplay_gallery_page.dart';

Widget _app(Widget child, {bool reduced = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduced),
    child: Scaffold(
      appBar: AppBar(title: const Text('Preview')),
      body: child,
    ),
  ),
);
Finder _bucket(String word) => find.byKey(ValueKey('bucket-$word'));
Finder _piece(int id) => find.byKey(ValueKey('build-piece-$id'));
String _target(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => t.data ?? '')
    .firstWhere((text) => text.startsWith('Put '))
    .split(' ')[1];

void main() {
  testWidgets(
    'bucket wrong drag returns, three distinct matches lock and replay',
    (tester) async {
      await tester.pumpWidget(
        _app(const SoundBucketPreviewPage(randomSeed: 42)),
      );
      await tester.pumpAndSettle();
      final first = _target(tester);
      final wrong = [
        'ball',
        'key',
        'dog',
        'pig',
      ].firstWhere((word) => word != first);
      final bubble = find.byKey(const ValueKey('bucket-bubble'));
      await tester.drag(
        bubble,
        tester.getCenter(_bucket(wrong)) - tester.getCenter(bubble),
      );
      await tester.pumpAndSettle();
      expect(find.text('0 of 3 matched'), findsOneWidget);
      expect(
        find.text('Try another bucket. Your bubble is still here.'),
        findsOneWidget,
      );
      final matched = <String>{};
      for (var i = 0; i < 3; i++) {
        final target = _target(tester);
        expect(matched.add(target), isTrue);
        if (i == 0) {
          await tester.drag(
            bubble,
            tester.getCenter(_bucket(target)) - tester.getCenter(bubble),
          );
        } else {
          await tester.tap(_bucket(target));
        }
        await tester.pumpAndSettle();
        expect(find.text('${i + 1} of 3 matched'), findsOneWidget);
        expect(tester.widget<InkWell>(_bucket(target)).onTap, isNull);
        if (i < 2) {
          await tester.tap(find.text('Next bubble'));
          await tester.pumpAndSettle();
          await tester.tap(_bucket(target));
          await tester.pumpAndSettle();
          expect(find.text('${i + 1} of 3 matched'), findsOneWidget);
        }
      }
      expect(find.text('Three buckets filled!'), findsOneWidget);
      await tester.tap(find.text('Play again'));
      await tester.pumpAndSettle();
      expect(find.text('0 of 3 matched'), findsOneWidget);
    },
  );

  testWidgets('build pieces retry and speech preview never awards completion', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const BuildAndSayPreviewPage(randomSeed: 42)));
    await tester.pumpAndSettle();
    expect(find.text('Preview speaking animation'), findsNothing);
    await tester.tap(_piece(1));
    await tester.pumpAndSettle();
    expect(find.text('Try a different piece. Keep building!'), findsOneWidget);
    await tester.drag(
      _piece(0),
      tester.getCenter(find.byKey(const ValueKey('build-slot-0'))) -
          tester.getCenter(_piece(0)),
    );
    await tester.pumpAndSettle();
    expect(_piece(0), findsNothing);
    for (final id in [1, 3, 2]) {
      await tester.tap(_piece(id));
      await tester.pumpAndSettle();
    }
    expect(find.text('Show word caption'), findsOneWidget);
    expect(find.text('Preview speaking animation'), findsNothing);
    await tester.tap(find.text('Show word caption'));
    await tester.pumpAndSettle();
    expect(find.text('This is a ball.'), findsOneWidget);
    await tester.tap(find.text('Your turn'));
    await tester.pumpAndSettle();
    expect(find.text('Your turn: say ball.'), findsOneWidget);
    await tester.tap(find.text('Preview speaking animation'));
    await tester.pump();
    expect(find.text('Animating…'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(find.text('Animating…'), findsNothing);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.tap(find.text('Preview speaking animation'));
    await tester.pumpAndSettle();
    expect(
      find.text('Animation only · No recording or pronunciation checking.'),
      findsOneWidget,
    );
    expect(find.textContaining('correct'), findsNothing);
    await tester.tap(find.text('Build again'));
    await tester.pumpAndSettle();
    expect(_piece(0), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });

  testWidgets('gallery opens both templates and Back returns', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: GameplayGalleryPage()));
    for (final title in ['Sound Bucket', 'Build & Say']) {
      await tester.scrollUntilVisible(find.text(title), 200);
      await tester.tap(find.text(title));
      await tester.pumpAndSettle();
      expect(find.text(title), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Gameplay Templates'), findsOneWidget);
    }
  });

  for (final size in [
    const Size(1280, 720),
    const Size(844, 390),
    const Size(568, 320),
    const Size(390, 844),
  ]) {
    testWidgets('both templates fit and have usable targets at $size', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _app(const SoundBucketPreviewPage(), reduced: true),
      );
      await tester.pumpAndSettle();
      for (final word in ['ball', 'key', 'dog', 'pig']) {
        final rect = tester.getRect(_bucket(word));
        expect(rect.height, greaterThanOrEqualTo(64));
        expect((Offset.zero & size).contains(rect.bottomRight), isTrue);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(
        _app(const BuildAndSayPreviewPage(), reduced: true),
      );
      await tester.pumpAndSettle();
      for (var i = 0; i < 4; i++) {
        expect(
          (Offset.zero & size).contains(tester.getRect(_piece(i)).bottomRight),
          isTrue,
        );
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
