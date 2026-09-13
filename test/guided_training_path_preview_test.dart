import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thesis/features/game/presentation/guided_training_path_preview_page.dart';
import 'package:thesis/features/game/presentation/gameplay_gallery_page.dart';

Widget _app({bool reduced = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduced),
    child: Scaffold(
      appBar: AppBar(title: const Text('Guided Training Path')),
      body: const GuidedTrainingPathPreviewPage(),
    ),
  ),
);

Future<void> _begin(WidgetTester tester) async {
  await tester.tap(find.text('Your turn'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Preview crossing animation'));
  await tester.pump();
}

void main() {
  testWidgets(
    'word and speaking captions cannot automatically advance the path',
    (tester) async {
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();
      final actor = find.byKey(const ValueKey('path-character'));
      final start = tester.getTopLeft(actor);
      await tester.pump(const Duration(seconds: 10));
      expect(tester.getTopLeft(actor), start);
      expect(find.text('This is a ball.'), findsOneWidget);
      expect(find.text('Preview crossing animation'), findsNothing);
      await tester.tap(find.text('Your turn'));
      await tester.pumpAndSettle();
      expect(find.text('Your turn: say ball.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 10));
      expect(tester.getTopLeft(actor), start);
      expect(find.text('Next scene'), findsNothing);
      await tester.tap(find.text('Show word caption'));
      await tester.pumpAndSettle();
      expect(find.text('This is a ball.'), findsOneWidget);
    },
  );

  testWidgets(
    'crossing moves, pauses, resumes and ignores duplicate preview taps',
    (tester) async {
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();
      final actor = find.byKey(const ValueKey('path-character'));
      final start = tester.getTopLeft(actor);
      await tester.tap(find.text('Your turn'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Preview crossing animation'));
      await tester.tap(find.text('Preview crossing animation'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(tester.getTopLeft(actor).dx, greaterThan(start.dx));
      await tester.tap(find.text('Pause preview'));
      await tester.pump();
      final paused = tester.getTopLeft(actor);
      await tester.pump(const Duration(seconds: 8));
      expect(tester.getTopLeft(actor), paused);
      expect(find.text('Next scene'), findsNothing);
      await tester.tap(find.text('Resume preview'));
      await tester.pumpAndSettle();
      expect(find.text('Scene 1 of 3 · Animation preview'), findsOneWidget);
      expect(find.text('Next scene'), findsOneWidget);
      expect(tester.getTopLeft(actor).dx, greaterThan(paused.dx));
    },
  );

  testWidgets('three simulated scenes replay without speech scores', (
    tester,
  ) async {
    await tester.pumpWidget(_app(reduced: true));
    await tester.pumpAndSettle();
    for (final word in ['ball', 'key', 'dog']) {
      expect(find.text('This is a $word.'), findsOneWidget);
      await _begin(tester);
      await tester.pumpAndSettle();
      if (word != 'dog') {
        await tester.tap(find.text('Next scene'));
        await tester.pumpAndSettle();
      }
    }
    expect(find.text('Path animation preview finished!'), findsOneWidget);
    expect(
      find.text(
        'Template only · No recording, speech checking or saved progress.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('correct'), findsNothing);
    await tester.tap(find.text('Replay path preview'));
    await tester.pumpAndSettle();
    expect(find.text('Scene 1 of 3 · Animation preview'), findsOneWidget);
    expect(find.text('This is a ball.'), findsOneWidget);
  });

  testWidgets('backgrounding pauses motion; restart and disposal are safe', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await _begin(tester);
    await tester.pump(const Duration(milliseconds: 600));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    final actor = find.byKey(const ValueKey('path-character'));
    final position = tester.getTopLeft(actor);
    await tester.pump(const Duration(seconds: 5));
    expect(tester.getTopLeft(actor), position);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.text('Resume preview'), findsOneWidget);
    await tester.tap(find.byTooltip('Restart path preview'));
    await tester.pumpAndSettle();
    expect(find.text('This is a ball.'), findsOneWidget);
    await _begin(tester);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 5));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'gallery opens the path and returns without enabling the next game',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: GameplayGalleryPage()));
      await tester.scrollUntilVisible(find.text('Guided Training Path'), 200);
      await tester.tap(find.text('Guided Training Path'));
      await tester.pumpAndSettle();
      expect(find.text('Rock hop'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Gameplay Templates'), findsOneWidget);
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
    testWidgets('path and moving character fit at $size', (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Your turn'));
      await _begin(tester);
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 200));
        final field = tester.getRect(find.byKey(const ValueKey('path-field')));
        final actor = tester.getRect(
          find.byKey(const ValueKey('path-character')),
        );
        expect(field.contains(actor.topLeft), isTrue);
        expect(field.contains(actor.bottomRight), isTrue);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
