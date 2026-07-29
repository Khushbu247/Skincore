import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/api_constants.dart';
import '../../models/prediction_result.dart';

class ApiService {
  late final Dio _dio;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(
          milliseconds: ApiConstants.connectTimeout,
        ),
        receiveTimeout: const Duration(
          milliseconds: ApiConstants.receiveTimeout,
        ),
      ),
    );
  }

  Future<PredictionResult> predictSkinCondition(XFile pickedFile) async {
    try {
      final bytes = await pickedFile.readAsBytes();
      final String fileName = pickedFile.name.isNotEmpty ? pickedFile.name : 'skin_image.jpg';

      final FormData formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: fileName,
        ),
      });

      final response = await _dio.post(
        ApiConstants.predictEndpoint,
        data: formData,
      );

      if (response.statusCode == 200) {
        return PredictionResult.fromJson(response.data);
      } else {
        throw Exception(
          'Server returned an error (${response.statusCode}). Please try again later.',
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw Exception(
          'Connection timed out. Please check server availability and try again.',
        );
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception(
          'Cannot connect to FastAPI server at ${ApiConstants.baseUrl}. Ensure server is running.',
        );
      } else if (e.response != null) {
        if (e.response?.statusCode == 422) {
          throw Exception('Invalid image format. Please upload a JPG, JPEG, or PNG photo.');
        } else if (e.response?.statusCode == 500) {
          throw Exception(
            'Internal server error during model prediction.',
          );
        }
        throw Exception(
          'Server error: ${e.response?.statusMessage ?? "Unknown"}',
        );
      }
      throw Exception(
        'Network error: Ensure backend server is accessible.',
      );
    } catch (e) {
      throw Exception(
        'An unexpected error occurred: ${e.toString().replaceAll("Exception: ", "")}',
      );
    }
  }
}
