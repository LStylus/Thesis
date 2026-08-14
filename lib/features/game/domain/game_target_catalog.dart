import 'package:flutter/services.dart';

import '../../../models/screening_word_model.dart';
import 'game_level_kind.dart';
import 'game_target.dart';

/// Loads the fallback game targets from `assets/data/game_targets.csv`.
///
/// The CSV records every target across the four levels with its paired
/// image/audio assets — this is the dev-bypass / fallback source used
/// when no learning module exists yet.  Level *structure* comes from
/// `GameLevelConfig`; the target *content* comes from here (or from the
/// learning module when available).
class GameTargetCatalog {
  static const String csvAsset = 'assets/data/game_targets.csv';
  static const int fallbackAge = 4;

  static Future<Map<String, List<GameTarget>>>? _cache;

  static Future<List<GameTarget>> targetsFor(GameLevelKind kind) async {
    final level = _levelColumnFor(kind);
    return (await _byLevel())[level] ?? const [];
  }

  static Future<Map<String, List<GameTarget>>> _byLevel() =>
      _cache ??= _readCsv();

  static String _levelColumnFor(GameLevelKind kind) => switch (kind) {
        GameLevelKind.bubbleBay => 'bubble_bay',
        GameLevelKind.coralCargo => 'coral_cargo',
        GameLevelKind.reefRoute => 'reef_route',
        GameLevelKind.captainsCall => 'captains_call',
      };

  static Future<Map<String, List<GameTarget>>> _readCsv() async {
    final raw = await rootBundle.loadString(csvAsset);
    final rows = _parseCsv(raw);
    final byLevel = <String, List<GameTarget>>{};

    for (final row in rows) {
      if (row.isEmpty || row.first == 'level') continue; // skip header
      final level = row[0];
      final id = row[1];
      final promptText = row[2];
      final apiWord = row[3];
      final sourceWord = row.length > 8 ? row[8] : apiWord;

      byLevel.putIfAbsent(level, () => []).add(GameTarget(
            id: id,
            promptText: promptText,
            focusText: apiWord,
            imageAssetPath: _nullable(row, 6),
            audioAssetPath: _nullable(row, 7),
            assessmentModel: ScreeningWordModel(
              id: id,
              audioId: sourceWord,
              displayWord: apiWord,
              age: fallbackAge,
            ),
          ));
    }
    return byLevel;
  }

  static String? _nullable(List<String> row, int index) {
    final value = index < row.length ? row[index].trim() : '';
    return value.isEmpty ? null : value;
  }

  /// Minimal CSV parser supporting double-quoted fields (the `phonemes`
  /// column contains commas: `"p,ɪ,ɡ"`).
  static List<List<String>> _parseCsv(String raw) {
    final rows = <List<String>>[];
    final row = <String>[];
    final cell = StringBuffer();
    var inQuotes = false;

    void flushCell() {
      row.add(cell.toString().trim());
      cell.clear();
    }

    for (var i = 0; i < raw.length; i++) {
      final ch = raw[i];
      if (inQuotes) {
        if (ch == '"') {
          if (i + 1 < raw.length && raw[i + 1] == '"') {
            cell.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          cell.write(ch);
        }
      } else if (ch == '"') {
        inQuotes = true;
      } else if (ch == ',') {
        flushCell();
      } else if (ch == '\n' || ch == '\r') {
        if (ch == '\r' && i + 1 < raw.length && raw[i + 1] == '\n') {
          i++;
        }
        flushCell();
        if (row.isNotEmpty && row.any((c) => c.isNotEmpty)) {
          rows.add(row.toList());
        }
        row.clear();
      } else {
        cell.write(ch);
      }
    }
    flushCell();
    if (row.isNotEmpty && row.any((c) => c.isNotEmpty)) {
      rows.add(row.toList());
    }
    return rows;
  }
}
