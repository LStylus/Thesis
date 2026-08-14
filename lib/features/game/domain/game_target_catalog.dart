import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../models/screening_word_model.dart';
import 'game_target.dart';

/// Loads the fallback game targets from `assets/data/game_targets.csv`.
///
/// The CSV records every target across the four module levels (syllable,
/// word, phrase, sentence — in order) with its paired image/audio assets.
/// This is the fallback source used when no learning module exists.
class GameTargetCatalog {
  static const String csvAsset = 'assets/data/game_targets.csv';
  static const int fallbackAge = 4;

  static Future<List<GameTarget>>? _cache;

  static Future<List<GameTarget>> targets() => _cache ??= _readCsv();

  static Future<List<GameTarget>> _readCsv() async {
    try {
      final raw = await rootBundle.loadString(csvAsset);
      final rows = _parseCsv(raw);
      final targets = <GameTarget>[];

      for (final row in rows) {
        if (row.isEmpty || row.first == 'level') continue; // skip header
        final id = row[1];
        final promptText = row[2];
        final apiWord = row[3];
        final sourceWord = row.length > 8 ? row[8] : apiWord;

        targets.add(GameTarget(
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
      return targets;
    } catch (error) {
      debugPrint('[game-catalog] load_failed error=$error');
      return const [];
    }
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
