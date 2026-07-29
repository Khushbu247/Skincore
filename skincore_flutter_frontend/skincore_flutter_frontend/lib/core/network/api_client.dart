import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Base URL for the FastAPI backend.
/// Swap via --dart-define=API_BASE_URL=https://api.skincore.app for release builds.
const _apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000/api/v1', // Android emulator -> host localhost
);

class ApiClient {
  final Dio dio;

  ApiClient() : dio = Dio(BaseOptions(baseUrl: _apiBaseUrl, connectTimeout: const Duration(seconds: 15))) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            final token = await user.getIdToken();
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          // Centralized error normalization — surfaces backend `detail` message.
          final detail = error.response?.data is Map ? error.response?.data['detail'] : null;
          handler.next(
            error.copyWith(error: detail ?? error.message),
          );
        },
      ),
    );
  }
}

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
