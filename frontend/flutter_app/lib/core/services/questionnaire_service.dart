import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

class QuestionItem {
  final int id;
  final String section;
  final String question;
  final String answerType;
  final List<String> options;
  final String jsonField;

  QuestionItem({
    required this.id,
    required this.section,
    required this.question,
    required String answerType,
    required this.options,
    required this.jsonField,
  }) : answerType = (jsonField == 'main_concern' || id == 2 || question.toLowerCase().contains('main skin concern'))
            ? 'Multiple choice'
            : answerType;

  bool get isMultipleChoice =>
      answerType.toLowerCase().contains('multiple') ||
      jsonField == 'main_concern' ||
      id == 2 ||
      question.toLowerCase().contains('main skin concern');

  bool get isSingleChoice => answerType.toLowerCase().contains('single') && !isMultipleChoice;

  bool get isOpenText => answerType.toLowerCase().contains('open') || answerType.toLowerCase().contains('text');
}

class QuestionnaireService {
  static const String _localQuestionnairePrefix = 'skincore_questionnaire_v1_';
  final SharedPreferences _prefs;

  QuestionnaireService(this._prefs);

  static List<QuestionItem>? _cachedQuestions;

  /// Load and parse 12 questions from SkinCore_Questionnaire.csv
  static Future<List<QuestionItem>> loadQuestions() async {
    if (_cachedQuestions != null && _cachedQuestions!.isNotEmpty) {
      return _cachedQuestions!;
    }

    try {
      final rawData = await rootBundle.loadString('assets/data/SkinCore_Questionnaire.csv');
      final rows = _parseCsv(rawData);

      final items = <QuestionItem>[];
      // Skip title row (row 0) and header row (row 1)
      for (var i = 2; i < rows.length; i++) {
        final row = rows[i];
        if (row.length >= 6) {
          final qNo = int.tryParse(row[0]) ?? (i - 1);
          final section = row[1];
          final question = row[2];
          final rawAnswerType = row[3];
          final rawOptions = row[4];
          final jsonField = row[5];

          final answerType = (jsonField == 'main_concern' || qNo == 2) ? 'Multiple choice' : rawAnswerType;
          final delimiter = rawOptions.contains(';') ? ';' : '/';
          final optionsList = rawOptions
              .split(delimiter)
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty && !s.startsWith('Free text'))
              .toList();

          if (question.isNotEmpty) {
            items.add(QuestionItem(
              id: qNo,
              section: section,
              question: question,
              answerType: answerType,
              options: optionsList,
              jsonField: jsonField,
            ));
          }
        }
      }

      _cachedQuestions = items;
      return items;
    } catch (_) {
      return _fallbackQuestions();
    }
  }

  /// Save completed questionnaire response permanently to Firebase Firestore & local storage
  Future<void> saveQuestionnaireResponse({
    required String uid,
    required Map<String, dynamic> answers,
  }) async {
    final localData = {
      'uid': uid,
      'completedAt': DateTime.now().toIso8601String(),
      'answers': answers,
    };

    // 1. Save locally in SharedPreferences immediately for 100% instant local persistence
    await _prefs.setString('$_localQuestionnairePrefix$uid', jsonEncode(localData));

    // 2. Save permanently in Firebase Firestore
    if (uid.isNotEmpty) {
      try {
        final firestoreData = {
          'uid': uid,
          'completedAt': DateTime.now().toIso8601String(),
          'timestamp': FieldValue.serverTimestamp(),
          'answers': answers,
        };

        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('questionnaire')
            .doc('profile')
            .set(firestoreData, SetOptions(merge: true))
            .timeout(const Duration(seconds: 4));

        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'hasCompletedQuestionnaire': true,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)).timeout(const Duration(seconds: 4));

        debugPrint('Successfully saved questionnaire profile to Firestore for user $uid');
      } catch (e) {
        debugPrint('Firestore saveQuestionnaireResponse error for $uid: $e');
      }
    }
  }

  Map<String, dynamic> _sanitizeForJson(Map<String, dynamic> data) {
    final result = <String, dynamic>{};
    data.forEach((key, value) {
      if (value is Timestamp) {
        result[key] = value.toDate().toIso8601String();
      } else if (value is Map) {
        result[key] = _sanitizeForJson(Map<String, dynamic>.from(value));
      } else if (value is List) {
        result[key] = value.map((item) {
          if (item is Timestamp) return item.toDate().toIso8601String();
          if (item is Map) return _sanitizeForJson(Map<String, dynamic>.from(item));
          return item;
        }).toList();
      } else {
        result[key] = value;
      }
    });
    return result;
  }

  /// Check if user has already completed questionnaire
  Future<Map<String, dynamic>?> getQuestionnaireResponse(String uid) async {
    if (uid.isEmpty) return null;

    // 1. Try local SharedPreferences cache FIRST for instant UI response
    final raw = _prefs.getString('$_localQuestionnairePrefix$uid');
    if (raw != null && raw.isNotEmpty) {
      try {
        final localData = jsonDecode(raw) as Map<String, dynamic>;
        
        // Sync Firestore in background
        FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('questionnaire')
            .doc('profile')
            .get()
            .timeout(const Duration(seconds: 4))
            .then((doc) {
          if (doc.exists && doc.data() != null) {
            final sanitized = _sanitizeForJson(doc.data()!);
            _prefs.setString('$_localQuestionnairePrefix$uid', jsonEncode(sanitized));
          }
        }).catchError((_) {});

        return localData;
      } catch (_) {}
    }

    // 2. If not cached locally, fetch from Firebase Firestore
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('questionnaire')
          .doc('profile')
          .get()
          .timeout(const Duration(seconds: 4));

      if (doc.exists && doc.data() != null) {
        final sanitized = _sanitizeForJson(doc.data()!);
        await _prefs.setString('$_localQuestionnairePrefix$uid', jsonEncode(sanitized));
        return sanitized;
      }
    } catch (e) {
      debugPrint('Firestore getQuestionnaireResponse error for $uid: $e');
    }

    return null;
  }

  /// Custom RFC-4180 CSV parser
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
          i++;
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

  static List<QuestionItem> _fallbackQuestions() {
    return [
      QuestionItem(
        id: 1,
        section: "Basic Skin Profile",
        question: "How would you describe your skin type?",
        answerType: "Single choice",
        options: ["Normal", "Dry", "Oily", "Combination", "Sensitive", "Not sure"],
        jsonField: "skin_type",
      ),
      QuestionItem(
        id: 2,
        section: "Basic Skin Profile",
        question: "What is your main skin concern?",
        answerType: "Multiple choice",
        options: [
          "Acne / pimples",
          "Dark spots / pigmentation",
          "Redness / rash",
          "Dryness / flaking",
          "Excess oil",
          "Uneven skin tone",
          "Itching / irritation",
          "Other"
        ],
        jsonField: "main_concern",
      ),
    ];
  }
}
