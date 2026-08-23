import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/di/providers.dart';
import '../core/services/questionnaire_service.dart';
import '../models/medical_report.dart';
import 'reports_provider.dart';

final questionnaireServiceProvider = Provider<QuestionnaireService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return QuestionnaireService(prefs);
});

class QuestionnaireState {
  final bool isLoading;
  final bool isCompleted;
  final Map<String, dynamic>? answers;

  QuestionnaireState({
    this.isLoading = true,
    this.isCompleted = false,
    this.answers,
  });

  String get skinType => answers?['skin_type'] ?? 'Combination';

  String get mainConcern {
    final raw = answers?['main_concern'];
    if (raw is List) {
      return raw.isEmpty ? 'Acne & Oiliness' : raw.join(', ');
    } else if (raw is String && raw.isNotEmpty) {
      return raw;
    }
    return 'Acne & Oiliness';
  }

  QuestionnaireState copyWith({
    bool? isLoading,
    bool? isCompleted,
    Map<String, dynamic>? answers,
  }) {
    return QuestionnaireState(
      isLoading: isLoading ?? this.isLoading,
      isCompleted: isCompleted ?? this.isCompleted,
      answers: answers ?? this.answers,
    );
  }
}

class QuestionnaireNotifier extends StateNotifier<QuestionnaireState> {
  final QuestionnaireService _service;
  final Ref _ref;

  QuestionnaireNotifier(this._service, this._ref) : super(QuestionnaireState()) {
    _init();
  }

  void _init() {
    _ref.listen(activeUserIdProvider, (prev, next) {
      checkUserQuestionnaire(next);
    });

    final currentUid = _ref.read(activeUserIdProvider);
    checkUserQuestionnaire(currentUid);
  }

  Future<void> checkUserQuestionnaire(String uid) async {
    state = state.copyWith(isLoading: true);
    final response = await _service.getQuestionnaireResponse(uid);

    if (response != null && response['answers'] != null) {
      final answers = Map<String, dynamic>.from(response['answers']);

      // Ensure "Skin Understanding" report is present in reportsProvider
      final currentReports = _ref.read(reportsProvider);
      if (!currentReports.any((r) => r.prediction == 'Skin Understanding')) {
        final customReport = MedicalReport.fromQuestionnaire(
          id: 'SKIN-UND-PROFILE',
          dateTime: DateTime.tryParse(response['completedAt'] ?? '') ?? DateTime.now(),
          answers: answers,
        );
        _ref.read(reportsProvider.notifier).saveCustomReport(customReport);
      }

      state = QuestionnaireState(
        isLoading: false,
        isCompleted: true,
        answers: answers,
      );
    } else {
      state = QuestionnaireState(
        isLoading: false,
        isCompleted: false,
      );
    }
  }

  Future<void> submitQuestionnaire({
    required String uid,
    required Map<String, dynamic> answers,
  }) async {
    state = state.copyWith(isLoading: true);
    final activeUid = _ref.read(activeUserIdProvider);

    await _service.saveQuestionnaireResponse(uid: activeUid, answers: answers);

    // Save/Replace single "Skin Understanding" report in reportsProvider & Firebase Firestore
    final now = DateTime.now();
    final customReport = MedicalReport.fromQuestionnaire(
      id: 'SKIN-UND-PROFILE',
      dateTime: now,
      answers: answers,
    );

    await _ref.read(reportsProvider.notifier).replaceQuestionnaireReport(customReport);

    state = QuestionnaireState(
      isLoading: false,
      isCompleted: true,
      answers: answers,
    );
  }
}

final questionnaireProvider = StateNotifierProvider<QuestionnaireNotifier, QuestionnaireState>((ref) {
  final service = ref.watch(questionnaireServiceProvider);
  return QuestionnaireNotifier(service, ref);
});
