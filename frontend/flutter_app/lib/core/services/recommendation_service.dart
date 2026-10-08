import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../../models/product_recommendation.dart';

class RecommendationService {
  late final Dio _dio;

  RecommendationService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(milliseconds: ApiConstants.connectTimeout),
        receiveTimeout: const Duration(milliseconds: ApiConstants.receiveTimeout),
      ),
    );
  }

  Future<ProductRecommendationResponse> fetchRecommendations({
    required String userId,
    String? questionnaireReportId,
    Map<String, dynamic>? questionnaireAnswers,
    String? latestSkinAnalysisReportId,
    Map<String, dynamic>? latestSkinAnalysis,
    bool forceRefresh = false,
  }) async {
    try {
      final payload = {
        'user_id': userId,
        'questionnaire_report_id': questionnaireReportId,
        'questionnaire_answers': questionnaireAnswers,
        'latest_skin_analysis_report_id': latestSkinAnalysisReportId,
        'latest_skin_analysis': latestSkinAnalysis,
        'force_refresh': forceRefresh,
      };

      final response = await _dio.post(
        ApiConstants.recommendationEndpoint,
        data: payload,
      );

      if (response.statusCode == 200 && response.data != null) {
        return ProductRecommendationResponse.fromJson(Map<String, dynamic>.from(response.data));
      } else {
        throw Exception('Server returned status code (${response.statusCode})');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Connection timed out while generating AI recommendations. Please try again.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Cannot connect to FastAPI server at ${ApiConstants.baseUrl}. Ensure backend is running.');
      } else if (e.response != null && e.response?.data != null) {
        final errDetail = e.response?.data['detail'] ?? 'Failed to reach AI recommendation service.';
        throw Exception(errDetail);
      }
      throw Exception('Network error: Ensure backend server is accessible.');
    } catch (e) {
      throw Exception('Unexpected error: ${e.toString().replaceAll("Exception: ", "")}');
    }
  }
}
