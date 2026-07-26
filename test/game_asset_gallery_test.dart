import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thesis/features/game/presentation/game_asset_catalog.dart';

void main() {
  testWidgets('every generated game asset loads through Flutter', (
    tester,
  ) async {
    final assets = gameAssetGroups.expand((group) => group.assets).toList();
    await tester.pumpWidget(
      MaterialApp(
        home: SingleChildScrollView(
          child: Wrap(
            children: [
              for (final asset in assets)
                SizedBox.square(
                  dimension: 48,
                  child: asset.endsWith('.svg')
                      ? SvgPicture.asset(asset)
                      : Image.asset(asset),
                ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
  });
}
