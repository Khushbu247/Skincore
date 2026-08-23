import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/medical_report.dart';

class ReportStorageService {
  static const String _reportsKeyPrefix = 'skincore_medical_reports_v2_';
  static const String _firstLoginKey = 'skincore_has_logged_in_before';

  final SharedPreferences _prefs;

  ReportStorageService(this._prefs);

  /// Check if user has logged in previously
  bool isReturningUser() {
    return _prefs.getBool(_firstLoginKey) ?? false;
  }

  /// Mark user as having logged in before
  Future<void> markUserAsExisting() async {
    await _prefs.setBool(_firstLoginKey, true);
  }

  /// Fetch medical reports permanently from Firebase Firestore & local SharedPreferences cache
  Future<List<MedicalReport>> getSavedReports(String? uid) async {
    final userKey = uid ?? 'guest';
    final localReports = _getLocalReports(userKey);

    // 1. If local cache exists, return immediately for 100% fast UI load, and sync Firestore in background
    if (localReports.isNotEmpty && uid != null && uid.isNotEmpty) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('reports')
          .get()
          .timeout(const Duration(seconds: 4))
          .then((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          final reports = snapshot.docs
              .map((doc) {
                try {
                  return MedicalReport.fromJson(doc.data());
                } catch (_) {
                  return null;
                }
              })
              .whereType<MedicalReport>()
              .toList();

          reports.sort((a, b) => b.dateTime.compareTo(a.dateTime));
          _saveLocalReports(uid, reports);
        }
      }).catchError((e) {
        debugPrint('Background Firestore getSavedReports error for $uid: $e');
      });

      return localReports;
    }

    // 2. Otherwise query Firebase Firestore directly
    if (uid != null && uid.isNotEmpty) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('reports')
            .get()
            .timeout(const Duration(seconds: 4));

        if (snapshot.docs.isNotEmpty) {
          final reports = snapshot.docs
              .map((doc) {
                try {
                  return MedicalReport.fromJson(doc.data());
                } catch (e) {
                  debugPrint('Error parsing report doc ${doc.id}: $e');
                  return null;
                }
              })
              .whereType<MedicalReport>()
              .toList();

          reports.sort((a, b) => b.dateTime.compareTo(a.dateTime));
          await _saveLocalReports(uid, reports);
          return reports;
        }
      } catch (e) {
        debugPrint('Firestore getSavedReports error for $uid: $e');
      }
    }

    return localReports;
  }

  /// Save a new medical report permanently to Firebase Firestore & local storage
  Future<void> saveReport({required String? uid, required MedicalReport report}) async {
    final userKey = uid ?? 'guest';

    // 1. Update local cache for instant UI responsiveness
    final current = _getLocalReports(userKey);
    current.removeWhere((r) => r.id == report.id);
    current.insert(0, report);
    await _saveLocalReports(userKey, current);

    // 2. Save permanently in Firebase Firestore under user account
    if (uid != null && uid.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('reports')
            .doc(report.id)
            .set(report.toJson(), SetOptions(merge: true))
            .timeout(const Duration(seconds: 4));
        debugPrint('Successfully saved report ${report.id} to Firestore for user $uid');
      } catch (e) {
        debugPrint('Firestore saveReport error for $uid: $e');
      }
    }
  }

  /// Delete a report by ID from Firebase Firestore & local storage
  Future<void> deleteReport({required String? uid, required String reportId}) async {
    final userKey = uid ?? 'guest';
    final current = _getLocalReports(userKey);
    current.removeWhere((r) => r.id == reportId);
    await _saveLocalReports(userKey, current);

    if (uid != null && uid.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('reports')
            .doc(reportId)
            .delete()
            .timeout(const Duration(seconds: 4));
      } catch (e) {
        debugPrint('Firestore deleteReport error: $e');
      }
    }
  }

  List<MedicalReport> _getLocalReports(String userKey) {
    try {
      final raw = _prefs.getString('$_reportsKeyPrefix$userKey');
      if (raw == null || raw.isEmpty) return [];
      final List<dynamic> list = jsonDecode(raw);
      return list.map((item) => MedicalReport.fromJson(item)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveLocalReports(String userKey, List<MedicalReport> reports) async {
    try {
      final raw = jsonEncode(reports.map((r) => r.toJson()).toList());
      await _prefs.setString('$_reportsKeyPrefix$userKey', raw);
    } catch (_) {}
  }
}
