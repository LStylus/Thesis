import 'dart:math';

class ProfileAssets {
  static const List<String> all = [
    'assets/profiles/1.png',
    'assets/profiles/2.png',
    'assets/profiles/3.png',
    'assets/profiles/4.png',
    'assets/profiles/5.png',
    'assets/profiles/6.png',
    'assets/profiles/7.png',
    'assets/profiles/8.png',
  ];

  static String pickUnique(Set<String> usedAssets, {Random? random}) {
    final available = all
        .where((asset) => !usedAssets.contains(asset))
        .toList();
    final pool = available.isNotEmpty ? available : all;
    final picker = random ?? Random();
    return pool[picker.nextInt(pool.length)];
  }

  static String fallbackForId(String seed) {
    if (all.isEmpty) return '';
    final index = seed.hashCode.abs() % all.length;
    return all[index];
  }
}
