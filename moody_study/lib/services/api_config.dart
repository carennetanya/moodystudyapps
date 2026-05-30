import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:8081';
    // Perbaiki dengan IP LAN komputer kamu, sesuai ipconfig.
    return 'http://192.168.1.5:8081';
  }
}
