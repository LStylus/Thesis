import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_fonts.dart';
import 'game_asset_catalog.dart';

class GameAssetGalleryScreen extends StatelessWidget {
  const GameAssetGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: gameAssetGroups.length,
      child: Scaffold(
        backgroundColor: const Color(0xFF073F5C),
        appBar: AppBar(
          backgroundColor: const Color(0xFF075274),
          foregroundColor: Colors.white,
          title: const Text(
            'Game Assets',
            style: TextStyle(
              fontFamily: AppFonts.fredoka,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: const Color(0xFFFFE477),
            unselectedLabelColor: Colors.white70,
            indicatorColor: const Color(0xFFFFE477),
            tabs: [for (final group in gameAssetGroups) Tab(text: group.label)],
          ),
        ),
        body: TabBarView(
          children: [
            for (final group in gameAssetGroups)
              _AssetGrid(assets: group.assets),
          ],
        ),
      ),
    );
  }
}

class _AssetGrid extends StatelessWidget {
  final List<String> assets;

  const _AssetGrid({required this.assets});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 210,
        mainAxisExtent: 190,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: assets.length,
      itemBuilder: (context, index) => _AssetTile(path: assets[index]),
    );
  }
}

class _AssetTile extends StatelessWidget {
  final String path;

  const _AssetTile({required this.path});

  @override
  Widget build(BuildContext context) {
    final name = path.split('/').last.replaceAll(RegExp(r'\.(svg|png)$'), '');
    final isSvg = path.endsWith('.svg');
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Expanded(
              child: isSvg
                  ? SvgPicture.asset(path, fit: BoxFit.contain)
                  : Image.asset(path, fit: BoxFit.cover),
            ),
            const SizedBox(height: 8),
            Text(
              name.replaceAll('_', ' '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF31566B),
                fontFamily: AppFonts.fredoka,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
