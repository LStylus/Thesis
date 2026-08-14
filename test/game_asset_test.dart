import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the production game SVG set loads through Flutter', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SingleChildScrollView(
          child: Wrap(
            children: [
              for (final asset in _assets)
                SizedBox.square(dimension: 72, child: SvgPicture.asset(asset)),
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

const _assets = [
  'assets/game/adventure/game_sky_background.svg',
  'assets/game/adventure/floating_school_island.svg',
  'assets/game/adventure/passing_cloud.svg',
  'assets/game/adventure/schoolhouse.svg',
  'assets/game/adventure/child_explorer_idle.svg',
  'assets/game/adventure/child_explorer_happy.svg',
  'assets/game/adventure/sound_tile.svg',
  'assets/game/adventure/sorting_bin_blue.svg',
  'assets/game/adventure/sorting_bin_green.svg',
  'assets/game/adventure/pop_target.svg',
  'assets/game/adventure/pair_card.svg',
  'assets/game/adventure/echo_crystal.svg',
  'assets/game/adventure/stepping_stone.svg',
  'assets/game/adventure/bridge_segment.svg',
  'assets/game/adventure/sound_orb.svg',
  'assets/game/adventure/meter_frame.svg',
  'assets/game/adventure/reward_star.svg',
  'assets/game/words/pig.svg',
  'assets/game/words/ball.svg',
  'assets/game/words/goat.svg',
  'assets/game/words/key.svg',
  'assets/game/words/dog.svg',
  'assets/game/words/10.svg',
];
