class ApiConstants {
  // Use 127.0.0.1 for both Web and Physical Android Devices.
  // CRITICAL: For physical Android devices, you MUST run this command in terminal first:
  // C:\Users\Hp\AppData\Local\Android\Sdk\platform-tools\adb.exe reverse tcp:8000 tcp:8000
  static String get baseUrl {
    return 'http://127.0.0.1:8000';
  }

  static const String predictEndpoint = '/predict';
  static const String chatbotEndpoint = '/chatbot/message';

  static const int connectTimeout = 15000; // 15 seconds
  static const int receiveTimeout = 15000; // 15 seconds
}
