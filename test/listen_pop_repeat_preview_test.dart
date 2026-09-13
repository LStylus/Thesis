import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thesis/features/game/presentation/listen_pop_repeat_preview_page.dart';
import 'package:thesis/features/game/presentation/gameplay_gallery_page.dart';

Widget _app({bool reduced = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduced),
    child: Scaffold(
      appBar: AppBar(title: const Text('Listen, Pop & Repeat')),
      body: const ListenPopRepeatPreviewPage(),
    ),
  ),
);

Future<void> _pop(WidgetTester tester, int id) async {
  await tester.tap(find.byKey(ValueKey('repeat-bubble-$id')));
  await tester.pumpAndSettle();
}

Future<void> _speak(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Your turn'));
  await tester.tap(find.text('Your turn'));
  await tester.pump();
  await tester.ensureVisible(find.text('Preview speaking animation'));
  await tester.tap(find.text('Preview speaking animation'));
  await tester.pump();
}

void main() {
  testWidgets('pop latches picture; captions and time alone cannot finish', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.byKey(const ValueKey('repeat-bubble-0')));
    // The other bubble may still be in the old frame; state guard rejects it.
    await tester.tap(find.byKey(const ValueKey('repeat-bubble-1')));
    await tester.pumpAndSettle();
    expect(find.text('This is a ball.'), findsOneWidget);
    expect(find.byKey(const ValueKey('repeat-dim')), findsOneWidget);
    final other = tester.getTopLeft(
      find.byKey(const ValueKey('repeat-bubble-1')),
    );
    await tester.pump(const Duration(seconds: 10));
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('repeat-bubble-1'))),
      other,
    );
    expect(find.text('0 of 3 preview turns finished'), findsOneWidget);
    expect(find.text('Next bubble'), findsNothing);
    await tester.tap(find.text('Your turn'));
    await tester.pump();
    expect(find.text('Your turn: say ball.'), findsOneWidget);
    await tester.tap(find.text('Show word caption'));
    await tester.pump();
    expect(find.text('This is a ball.'), findsOneWidget);
  });

  testWidgets(
    'three reduced-motion previews remove only explicitly finished bubbles and replay',
    (tester) async {
      await tester.pumpWidget(_app(reduced: true));
      await tester.pumpAndSettle();
      for (final id in [2, 0, 1]) {
        await _pop(tester, id);
        await _speak(tester);
        await tester.pumpAndSettle();
        expect(
          find.text('Speaking animation finished. No speech was checked.'),
          findsOneWidget,
        );
        final last = id == 1;
        await tester.tap(find.text(last ? 'Finish preview' : 'Next bubble'));
        await tester.pumpAndSettle();
        expect(find.byKey(ValueKey('repeat-bubble-$id')), findsNothing);
      }
      expect(find.text('3 of 3 preview turns finished'), findsOneWidget);
      expect(find.text('All three bubble previews finished!'), findsOneWidget);
      await tester.tap(find.text('Replay bubble preview'));
      await tester.pumpAndSettle();
      for (var i = 0; i < 3; i++) {
        expect(find.byKey(ValueKey('repeat-bubble-$i')), findsOneWidget);
      }
      expect(find.text('0 of 3 preview turns finished'), findsOneWidget);
    },
  );

  testWidgets(
    'background pauses animation until explicit resume; disposal is safe',
    (tester) async {
      await tester.pumpWidget(_app());
      await _pop(tester, 0);
      await _speak(tester);
      await tester.pump(const Duration(milliseconds: 400));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(seconds: 5));
      expect(find.text('Next bubble'), findsNothing);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(find.text('Resume preview'), findsOneWidget);
      await tester.tap(find.text('Resume preview'));
      await tester.pumpAndSettle();
      expect(find.text('Next bubble'), findsOneWidget);
      await tester.tap(find.text('Repeat this word'));
      await tester.pump();
      await tester.tap(find.text('Preview speaking animation'));
      await tester.pump();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 5));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('pause blocks popping; restart clears an active turn', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.byTooltip('Pause preview'));
    await tester.pump();
    final bubble = find.byKey(const ValueKey('repeat-bubble-0'));
    final start = tester.getTopLeft(bubble);
    await tester.pump(const Duration(seconds: 5));
    expect(tester.getTopLeft(bubble), start);
    await tester.tap(bubble, warnIfMissed: false);
    await tester.pump();
    expect(find.byKey(const ValueKey('repeat-focus')), findsNothing);
    await tester.tap(find.text('Resume preview'));
    await tester.pump();
    await _pop(tester, 0);
    await tester.tap(find.byTooltip('Restart bubble preview'));
    await tester.pump();
    expect(find.byKey(const ValueKey('repeat-focus')), findsNothing);
    expect(find.text('0 of 3 preview turns finished'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'gallery opens repeat template and returns; later games remain disabled',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: GameplayGalleryPage()));
      await tester.scrollUntilVisible(find.text('Listen, Pop & Repeat'), 200);
      await tester.tap(find.text('Listen, Pop & Repeat'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Choose any bubble'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Forest Discovery'), 100);
      final tile = tester.widget<ListTile>(
        find.ancestor(
          of: find.text('Forest Discovery'),
          matching: find.byType(ListTile),
        ),
      );
      expect(tile.enabled, isFalse);
    },
  );

  for (final size in [
    const Size(1280, 720),
    const Size(844, 390),
    const Size(568, 320),
    const Size(390, 844),
  ]) {
    testWidgets('bubble bounds and focused picture fit at $size', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_app());
      for (var frame = 0; frame < 6; frame++) {
        await tester.pump(const Duration(milliseconds: 700));
        final field = tester.getRect(
          find.byKey(const ValueKey('repeat-field')),
        );
        for (var i = 0; i < 3; i++) {
          final rect = tester.getRect(find.byKey(ValueKey('repeat-bubble-$i')));
          expect(field.contains(rect.topLeft), isTrue);
          expect(field.contains(rect.bottomRight), isTrue);
        }
      }
      await _pop(tester, 0);
      await _speak(tester);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('repeat-focus')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
