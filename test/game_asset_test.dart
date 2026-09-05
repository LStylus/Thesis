import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thesis/core/constants/app_assets.dart';
import 'package:thesis/features/game/domain/game_target_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'retained content assets exist on disk and in the current bundle',
    () async {
      final targets = await GameTargetCatalog.targets();
      expect(targets, isNotEmpty);
      expect(targets.first.targetSound, 'p');
      expect(() => targets.clear(), throwsUnsupportedError);
      final paths = <String>{
        ..._svgAssets,
        AppAssets.microphoneButton,
        for (final target in targets) ...[
          if (target.imageAssetPath != null) target.imageAssetPath!,
          if (target.audioAssetPath != null) target.audioAssetPath!,
        ],
      };
      for (final path in paths) {
        // Disk check prevents an old test bundle from hiding deleted source assets.
        expect(File(path).existsSync(), isTrue, reason: path);
        expect(
          (await rootBundle.load(path)).lengthInBytes,
          greaterThan(0),
          reason: path,
        );
      }
    },
  );

  testWidgets('retained SVG artwork loads through Flutter', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SingleChildScrollView(
          child: Wrap(
            children: [
              for (final asset in _svgAssets)
                SizedBox.square(dimension: 72, child: SvgPicture.asset(asset)),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

const _svgAssets = [
  AppAssets.childExplorer,
  AppAssets.homeMapBackground,
  AppAssets.passingCloud,
  AppAssets.homeMapFlag,
  'assets/game/words/pig.svg',
  'assets/game/words/ball.svg',
  'assets/game/words/goat.svg',
  'assets/game/words/key.svg',
  'assets/game/words/dog.svg',
  'assets/game/words/10.svg',
];
