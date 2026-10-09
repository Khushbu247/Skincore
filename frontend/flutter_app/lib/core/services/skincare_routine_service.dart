import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/skincare_routine.dart';

class SkincareRoutineService {
  static String _routinesStorageKey(String userId) => 'skincare_routines_$userId';
  static String _logsStorageKey(String userId) => 'skincare_routine_logs_$userId';

  /// Get routine definitions (local cache + Firestore sync)
  Future<List<SkincareRoutineItem>> getRoutines(SharedPreferences prefs, String userId) async {
    final userKey = userId.isNotEmpty ? userId : 'guest';
    final localList = _getLocalRoutines(prefs, userKey);

    // Sync from Firestore if user is authenticated
    if (userId.isNotEmpty) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('routines')
            .get()
            .timeout(const Duration(seconds: 4));

        if (snapshot.docs.isNotEmpty) {
          final remoteRoutines = snapshot.docs
              .map((doc) {
                try {
                  return SkincareRoutineItem.fromMap(doc.data());
                } catch (e) {
                  debugPrint('Error parsing routine doc ${doc.id}: $e');
                  return null;
                }
              })
              .whereType<SkincareRoutineItem>()
              .toList();

          await _saveLocalRoutines(prefs, userKey, remoteRoutines);
          return remoteRoutines;
        } else if (localList.isNotEmpty) {
          // Push local offline routines to Firestore if Firestore is empty
          await saveRoutines(prefs, userId, localList);
          return localList;
        }
      } catch (e) {
        debugPrint('Firestore getRoutines error for $userId: $e');
      }
    }

    return localList;
  }

  /// Save routine definitions (local cache + Firestore)
  Future<void> saveRoutines(
    SharedPreferences prefs,
    String userId,
    List<SkincareRoutineItem> routines,
  ) async {
    final userKey = userId.isNotEmpty ? userId : 'guest';
    await _saveLocalRoutines(prefs, userKey, routines);

    if (userId.isNotEmpty) {
      try {
        final batch = FirebaseFirestore.instance.batch();
        final collectionRef = FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('routines');

        // Overwrite or set definitions
        for (final item in routines) {
          batch.set(collectionRef.doc(item.id), item.toMap(), SetOptions(merge: true));
        }
        await batch.commit();
      } catch (e) {
        debugPrint('Firestore saveRoutines error: $e');
      }
    }
  }

  /// Delete a single routine definition from Firestore & local cache
  Future<void> deleteRoutine(SharedPreferences prefs, String userId, String routineId) async {
    final userKey = userId.isNotEmpty ? userId : 'guest';
    final current = _getLocalRoutines(prefs, userKey);
    final updated = current.where((r) => r.id != routineId).toList();
    await _saveLocalRoutines(prefs, userKey, updated);

    if (userId.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('routines')
            .doc(routineId)
            .delete();
      } catch (e) {
        debugPrint('Firestore deleteRoutine error: $e');
      }
    }
  }

  /// Fetch completion logs
  Future<List<RoutineCompletionLog>> getCompletionLogs(SharedPreferences prefs, String userId) async {
    final userKey = userId.isNotEmpty ? userId : 'guest';
    final localLogs = _getLocalLogs(prefs, userKey);

    if (userId.isNotEmpty) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('routine_history')
            .get()
            .timeout(const Duration(seconds: 4));

        if (snapshot.docs.isNotEmpty) {
          final remoteLogs = snapshot.docs
              .map((doc) {
                try {
                  return RoutineCompletionLog.fromMap(doc.data());
                } catch (_) {
                  return null;
                }
              })
              .whereType<RoutineCompletionLog>()
              .toList();

          await _saveLocalLogs(prefs, userKey, remoteLogs);
          return remoteLogs;
        }
      } catch (e) {
        debugPrint('Firestore getCompletionLogs error: $e');
      }
    }

    return localLogs;
  }

  /// Toggle routine completion for a given date ('YYYY-MM-DD')
  Future<List<RoutineCompletionLog>> toggleCompletionLog({
    required SharedPreferences prefs,
    required String userId,
    required String routineId,
    required String dateString,
  }) async {
    final userKey = userId.isNotEmpty ? userId : 'guest';
    final currentLogs = _getLocalLogs(prefs, userKey);
    final logId = '${dateString}_$routineId';

    final exists = currentLogs.any((l) => l.id == logId);
    List<RoutineCompletionLog> updatedLogs;

    if (exists) {
      updatedLogs = currentLogs.where((l) => l.id != logId).toList();
      if (userId.isNotEmpty) {
        FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('routine_history')
            .doc(logId)
            .delete()
            .catchError((e) => debugPrint('Firestore delete log error: $e'));
      }
    } else {
      final newLog = RoutineCompletionLog(
        id: logId,
        routineId: routineId,
        userId: userKey,
        dateString: dateString,
        completedAt: DateTime.now(),
      );
      updatedLogs = [...currentLogs, newLog];
      if (userId.isNotEmpty) {
        FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('routine_history')
            .doc(logId)
            .set(newLog.toMap())
            .catchError((e) => debugPrint('Firestore save log error: $e'));
      }
    }

    await _saveLocalLogs(prefs, userKey, updatedLogs);
    return updatedLogs;
  }

  /// Retention cleanup: Purge completion logs older than daysRetention (30 days)
  /// STRICT SAFETY GUARANTEE: Never deletes routine definitions, reports, questionnaire or profiles.
  Future<int> cleanupOldHistory(SharedPreferences prefs, String userId, {int daysRetention = 30}) async {
    final userKey = userId.isNotEmpty ? userId : 'guest';
    final cutoffDate = DateTime.now().subtract(Duration(days: daysRetention));
    final currentLogs = _getLocalLogs(prefs, userKey);

    final eligibleLogs = currentLogs.where((l) => l.completedAt.isAfter(cutoffDate)).toList();
    final deletedCount = currentLogs.length - eligibleLogs.length;

    await _saveLocalLogs(prefs, userKey, eligibleLogs);

    if (userId.isNotEmpty && deletedCount > 0) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('routine_history')
            .where('completedAt', isLessThan: cutoffDate.toIso8601String())
            .get();

        if (snapshot.docs.isNotEmpty) {
          final batch = FirebaseFirestore.instance.batch();
          for (final doc in snapshot.docs) {
            batch.delete(doc.reference);
          }
          await batch.commit();
        }
      } catch (e) {
        debugPrint('Firestore cleanupOldHistory error: $e');
      }
    }

    return deletedCount;
  }

  // --- Local Helper Storage Methods ---

  List<SkincareRoutineItem> _getLocalRoutines(SharedPreferences prefs, String userKey) {
    final raw = prefs.getString(_routinesStorageKey(userKey));
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(raw);
      return list.map((i) => SkincareRoutineItem.fromMap(i as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveLocalRoutines(
    SharedPreferences prefs,
    String userKey,
    List<SkincareRoutineItem> routines,
  ) async {
    final jsonList = routines.map((r) => r.toMap()).toList();
    await prefs.setString(_routinesStorageKey(userKey), jsonEncode(jsonList));
  }

  List<RoutineCompletionLog> _getLocalLogs(SharedPreferences prefs, String userKey) {
    final raw = prefs.getString(_logsStorageKey(userKey));
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(raw);
      return list.map((i) => RoutineCompletionLog.fromMap(i as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveLocalLogs(
    SharedPreferences prefs,
    String userKey,
    List<RoutineCompletionLog> logs,
  ) async {
    final jsonList = logs.map((l) => l.toMap()).toList();
    await prefs.setString(_logsStorageKey(userKey), jsonEncode(jsonList));
  }
}
