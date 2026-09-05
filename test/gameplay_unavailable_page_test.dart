import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thesis/features/game/presentation/gameplay_unavailable_page.dart';
import 'package:thesis/widgets/voyage_loading_screen.dart';

void main() {
  testWidgets('old game entry can open and return without a session result', (
    tester,
  ) async {
    Object? result = 'not returned';
    await tester.binding.setSurfaceSize(const Size(800, 360));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await Navigator.of(context).push<Object?>(
                    MaterialPageRoute(
                      builder: (_) => const GameplayUnavailablePage(),
                    ),
                  );
                },
                child: const Text('Map entry'),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('Map entry'));
    await tester.pumpAndSettle();
    expect(find.text('New gameplay system coming next.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Back to map'));
    await tester.pumpAndSettle();
    expect(result, isNull);
    expect(find.text('Map entry'), findsOneWidget);
  });

  testWidgets(
    'loading screen uses retained artwork and disposes its animation',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 360));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(const MaterialApp(home: VoyageLoadingScreen()));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
}
