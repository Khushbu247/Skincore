import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/di/providers.dart';
import '../core/services/report_storage_service.dart';
import '../models/medical_report.dart';
import '../models/prediction_result.dart';

final reportStorageServiceProvider = Provider<ReportStorageService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ReportStorageService(prefs);
});

final isReturningUserProvider = StateNotifierProvider<IsReturningUserNotifier, bool>((ref) {
  final storage = ref.watch(reportStorageServiceProvider);
  return IsReturningUserNotifier(storage);
});

class IsReturningUserNotifier extends StateNotifier<bool> {
  final ReportStorageService _storage;

  IsReturningUserNotifier(this._storage) : super(_storage.isReturningUser());

  Future<void> markExisting() async {
    await _storage.markUserAsExisting();
    state = true;
  }
}

class ReportsNotifier extends StateNotifier<List<MedicalReport>> {
  final ReportStorageService _storage;
  final Ref _ref;

  ReportsNotifier(this._storage, this._ref) : super([]) {
    _init();
  }

  void _init() {
    _ref.listen(activeUserIdProvider, (prev, next) {
      loadReportsForUser(next);
    });

    final currentUid = _ref.read(activeUserIdProvider);
    loadReportsForUser(currentUid);
  }

  Future<void> loadReportsForUser(String uid) async {
    final loaded = await _storage.getSavedReports(uid);
    if (loaded.isEmpty) {
      // Seed initial sample report for immediate user demo
      final sampleReport = MedicalReport.fromPredictionResult(
        id: 'REP-20260820-0941',
        dateTime: DateTime.now().subtract(const Duration(days: 3, hours: 2)),
        imagePath: 'assets/images/sample_skin.jpg',
        result: PredictionResult(
          prediction: 'acne',
          confidence: 94.8,
          probabilities: {
            'acne': 94.8,
            'eczema_rash': 3.2,
            'pigmentation': 1.5,
            'serious_condition': 0.5,
          },
          modelVersion: 'MobileNetV2-v1.0',
          imageSize: '224x224',
          processingTimeMs: 245.0,
        ),
      );
      state = [sampleReport];
      await _storage.saveReport(uid: uid, report: sampleReport);
    } else {
      state = loaded;
    }
  }

  Future<void> addReportFromPrediction({
    required String imagePath,
    required PredictionResult result,
  }) async {
    final now = DateTime.now();
    final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final randStr = (now.millisecondsSinceEpoch % 10000).toString().padLeft(4, '0');
    final id = 'REP-$dateStr-$randStr';

    final report = MedicalReport.fromPredictionResult(
      id: id,
      dateTime: now,
      imagePath: imagePath,
      result: result,
    );

    final uid = _ref.read(activeUserIdProvider);
    await _storage.saveReport(uid: uid, report: report);
    state = [report, ...state.where((r) => r.id != report.id)];
  }

  Future<void> replaceQuestionnaireReport(MedicalReport newReport) async {
    final uid = _ref.read(activeUserIdProvider);
    final existingQuestionnaireReports = state.where((r) =>
        r.reportType == 'questionnaire' ||
        r.prediction == 'Skin Understanding' ||
        r.id.startsWith('SKIN-UND')).toList();

    for (final oldReport in existingQuestionnaireReports) {
      await _storage.deleteReport(uid: uid, reportId: oldReport.id);
    }

    await _storage.saveReport(uid: uid, report: newReport);

    final nonQuestionnaireReports = state.where((r) =>
        r.reportType != 'questionnaire' &&
        r.prediction != 'Skin Understanding' &&
        !r.id.startsWith('SKIN-UND')).toList();

    state = [newReport, ...nonQuestionnaireReports];
  }

  Future<void> saveCustomReport(MedicalReport report) async {
    if (report.reportType == 'questionnaire' ||
        report.prediction == 'Skin Understanding' ||
        report.id.startsWith('SKIN-UND')) {
      await replaceQuestionnaireReport(report);
      return;
    }
    final uid = _ref.read(activeUserIdProvider);
    await _storage.saveReport(uid: uid, report: report);
    state = [report, ...state.where((r) => r.id != report.id && r.prediction != report.prediction)];
  }

  Future<void> deleteReport(String id) async {
    final uid = _ref.read(activeUserIdProvider);
    await _storage.deleteReport(uid: uid, reportId: id);
    state = state.where((r) => r.id != id).toList();
  }
}

final reportsProvider = StateNotifierProvider<ReportsNotifier, List<MedicalReport>>((ref) {
  final storage = ref.watch(reportStorageServiceProvider);
  return ReportsNotifier(storage, ref);
});
