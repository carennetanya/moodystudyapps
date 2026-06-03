import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    const envUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }

    // When not overridden by --dart-define, use the SSH backend server directly.
    return 'http://202.46.28.170:8081';
  }
}
