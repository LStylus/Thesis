import 'package:flutter/material.dart';

import 'features/game/presentation/game_asset_gallery_screen.dart';

void main() {
  runApp(const GameAssetGalleryApp());
}

class GameAssetGalleryApp extends StatelessWidget {
  const GameAssetGalleryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GameAssetGalleryScreen(),
    );
  }
}
