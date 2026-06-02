import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    const envUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }

    if (kIsWeb) {
      return 'https://your-deployed-backend.com';
    }

    if (kReleaseMode) {
      return 'https://your-deployed-backend.com';
    }

    // Local development default, can be overridden with --dart-define
    return 'http://192.168.1.5:8081';
  }
}
