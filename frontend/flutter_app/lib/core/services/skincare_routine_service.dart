import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/skincare_routine.dart';

class SkincareRoutineService {
  static String _storageKey(String userId) => 'skincare_routines_$userId';

  Future<List<SkincareRoutineItem>> getRoutines(SharedPreferences prefs, String userId) async {
    final rawData = prefs.getString(_storageKey(userId));
    if (rawData == null || rawData.isEmpty) {
      return [];
    }
    try {
      final List<dynamic> jsonList = jsonDecode(rawData);
      return jsonList
          .map((item) => SkincareRoutineItem.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveRoutines(
    SharedPreferences prefs,
    String userId,
    List<SkincareRoutineItem> routines,
  ) async {
    final jsonList = routines.map((r) => r.toMap()).toList();
    await prefs.setString(_storageKey(userId), jsonEncode(jsonList));
  }
}
