import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/di/providers.dart';
import '../core/services/recommendation_service.dart';
import '../models/medical_report.dart';
import '../models/product_recommendation.dart';
import 'reports_provider.dart';

final recommendationServiceProvider = Provider<RecommendationService>((ref) {
  return RecommendationService();
});

class RecommendationState {
  final bool isLoading;
  final bool hasQuestionnaire;
  final bool hasSkinAnalysis;
  final ProductRecommendationResponse? response;
  final String? errorMessage;
  final String selectedCategory; // 'All', 'Cleanser', 'Serum', 'Moisturizer', 'Sunscreen', 'Exfoliant', 'Eye Care'
  final String selectedPriceBand; // 'All', 'budget', 'mid_range', 'premium'

  const RecommendationState({
    this.isLoading = false,
    this.hasQuestionnaire = true,
    this.hasSkinAnalysis = true,
    this.response,
    this.errorMessage,
    this.selectedCategory = 'All',
    this.selectedPriceBand = 'All',
  });

  RecommendationState copyWith({
    bool? isLoading,
    bool? hasQuestionnaire,
    bool? hasSkinAnalysis,
    ProductRecommendationResponse? response,
    String? errorMessage,
    String? selectedCategory,
    String? selectedPriceBand,
  }) {
    return RecommendationState(
      isLoading: isLoading ?? this.isLoading,
      hasQuestionnaire: hasQuestionnaire ?? this.hasQuestionnaire,
      hasSkinAnalysis: hasSkinAnalysis ?? this.hasSkinAnalysis,
      response: response ?? this.response,
      errorMessage: errorMessage,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedPriceBand: selectedPriceBand ?? this.selectedPriceBand,
    );
  }

  List<RecommendedProductItem> get filteredProducts {
    if (response == null) return [];
    var list = response!.products;

    if (selectedCategory != 'All') {
      list = list.where((p) => p.category.toLowerCase() == selectedCategory.toLowerCase()).toList();
    }

    if (selectedPriceBand != 'All') {
      list = list.where((p) => p.priceBand.toLowerCase() == selectedPriceBand.toLowerCase()).toList();
    }

    return list;
  }
}

class RecommendationNotifier extends StateNotifier<RecommendationState> {
  final RecommendationService _service;
  final Ref _ref;

  RecommendationNotifier(this._service, this._ref) : super(const RecommendationState()) {
    _init();
  }

  void _init() {
    _ref.listen<List<MedicalReport>>(reportsProvider, (prev, next) {
      fetchRecommendations();
    });
    fetchRecommendations();
  }

  Future<void> fetchRecommendations({bool forceRefresh = false}) async {
    final reports = _ref.read(reportsProvider);
    final userId = _ref.read(activeUserIdProvider);

    // Find Questionnaire Report
    MedicalReport? questionnaireReport;
    for (final r in reports) {
      if (r.reportType == 'questionnaire' ||
          r.prediction == 'Skin Understanding' ||
          r.id.startsWith('SKIN-UND')) {
        questionnaireReport = r;
        break;
      }
    }

    // Find Latest Skin Scan Report
    MedicalReport? scanReport;
    for (final r in reports) {
      if (r.reportType == 'scan' &&
          r.prediction != 'Skin Understanding' &&
          !r.id.startsWith('SKIN-UND')) {
        scanReport = r;
        break;
      }
    }

    final hasQ = questionnaireReport != null;
    final hasS = scanReport != null;

    if (!hasQ || !hasS) {
      state = state.copyWith(
        isLoading: false,
        hasQuestionnaire: hasQ,
        hasSkinAnalysis: hasS,
        errorMessage: null,
      );
      return;
    }

    state = state.copyWith(
      isLoading: true,
      hasQuestionnaire: true,
      hasSkinAnalysis: true,
      errorMessage: null,
    );

    try {
      final response = await _service.fetchRecommendations(
        userId: userId,
        questionnaireReportId: questionnaireReport.id,
        questionnaireAnswers: questionnaireReport.questionnaireAnswers,
        latestSkinAnalysisReportId: scanReport.id,
        latestSkinAnalysis: scanReport.toJson(),
        forceRefresh: forceRefresh,
      );

      state = state.copyWith(
        isLoading: false,
        response: response,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void setCategoryFilter(String category) {
    state = state.copyWith(selectedCategory: category);
  }

  void setPriceBandFilter(String priceBand) {
    state = state.copyWith(selectedPriceBand: priceBand);
  }
}

final recommendationProvider =
    StateNotifierProvider<RecommendationNotifier, RecommendationState>((ref) {
  final service = ref.watch(recommendationServiceProvider);
  return RecommendationNotifier(service, ref);
});
