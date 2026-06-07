import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    const envUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (envUrl.isNotEmpty) return envUrl;

    // Web (Chrome dev) → localhost. Mobile → remote server.
    if (kIsWeb) return 'http://localhost:8081';
    return 'http://202.46.28.170:8081';
  }
}
