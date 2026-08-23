import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SkinMyth {
  final int id;
  final String myth;
  final String truth;
  final String explanation;
  final String category;
  final String difficulty;

  SkinMyth({
    required this.id,
    required this.myth,
    required this.truth,
    required this.explanation,
    required this.category,
    required this.difficulty,
  });
}

class MythService {
  static List<SkinMyth>? _cachedMyths;

  /// Load and parse skincore_myths_dataset.csv from assets
  static Future<List<SkinMyth>> loadMyths() async {
    if (_cachedMyths != null && _cachedMyths!.isNotEmpty) {
      return _cachedMyths!;
    }

    try {
      final rawData = await rootBundle.loadString('assets/data/skincore_myths_dataset.csv');
      final rows = _parseCsv(rawData);

      final myths = <SkinMyth>[];
      // Skip header row (row 0)
      for (var i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.length >= 4) {
          final id = int.tryParse(row[0]) ?? i;
          final myth = row[1];
          final truth = row[2];
          final explanation = row[3];
          final category = row.length > 4 ? row[4] : 'General Skincare';
          final difficulty = row.length > 5 ? row[5] : 'Easy';

          if (myth.isNotEmpty && truth.isNotEmpty) {
            myths.add(SkinMyth(
              id: id,
              myth: myth,
              truth: truth,
              explanation: explanation,
              category: category,
              difficulty: difficulty,
            ));
          }
        }
      }

      _cachedMyths = myths;
      return myths;
    } catch (e) {
      // Fallback fallback myth if asset loading fails
      return [
        SkinMyth(
          id: 1,
          myth: "Oily skin should skip moisturizer to avoid more breakouts.",
          truth: "Oily and acne-prone skin still benefits from the right moisturizer.",
          explanation: "Skipping moisturizer can make skin overcompensate by producing more oil; a lightweight, non-comedogenic formula helps balance this.",
          category: "Acne & Pimples",
          difficulty: "Easy",
        ),
      ];
    }
  }

  /// Select daily myth based on current calendar date
  static SkinMyth getMythOfTheDay(List<SkinMyth> myths) {
    if (myths.isEmpty) {
      return SkinMyth(
        id: 1,
        myth: "Oily skin should skip moisturizer to avoid more breakouts.",
        truth: "Oily and acne-prone skin still benefits from the right moisturizer.",
        explanation: "Skipping moisturizer can make skin overcompensate by producing more oil; a lightweight, non-comedogenic formula helps balance this.",
        category: "Acne & Pimples",
        difficulty: "Easy",
      );
    }

    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    final dayOfYear = now.difference(startOfYear).inDays;

    final index = dayOfYear % myths.length;
    return myths[index];
  }

  /// Custom RFC-4180 compliant CSV parser
  static List<List<String>> _parseCsv(String input) {
    final rows = <List<String>>[];
    var currentCell = StringBuffer();
    var inQuotes = false;
    var currentRow = <String>[];

    for (var i = 0; i < input.length; i++) {
      final char = input[i];
      final nextChar = i + 1 < input.length ? input[i + 1] : null;

      if (char == '"') {
        if (inQuotes && nextChar == '"') {
          currentCell.write('"');
          i++; // skip escaped quote
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        currentRow.add(currentCell.toString().trim());
        currentCell.clear();
      } else if ((char == '\n' || char == '\r') && !inQuotes) {
        if (char == '\r' && nextChar == '\n') {
          i++;
        }
        currentRow.add(currentCell.toString().trim());
        currentCell.clear();
        if (currentRow.any((c) => c.isNotEmpty)) {
          rows.add(currentRow);
        }
        currentRow = <String>[];
      } else {
        currentCell.write(char);
      }
    }

    if (currentCell.isNotEmpty || currentRow.isNotEmpty) {
      currentRow.add(currentCell.toString().trim());
      if (currentRow.any((c) => c.isNotEmpty)) {
        rows.add(currentRow);
      }
    }

    return rows;
  }
}

/// Riverpod FutureProvider for Myth of the Day
final mythOfTheDayProvider = FutureProvider<SkinMyth>((ref) async {
  final myths = await MythService.loadMyths();
  return MythService.getMythOfTheDay(myths);
});
