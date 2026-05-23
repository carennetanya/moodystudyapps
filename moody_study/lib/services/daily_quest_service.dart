import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'auth_service.dart';
import '../models/daily_quest_model.dart';

class DailyQuestService {
  static String get baseUrl =>
      kIsWeb ? 'http://localhost:8081' : 'http://10.0.2.2:8081';

  static Map<String, String> get _authHeaders {
    final token = AuthService.token;
    if (token == null) throw Exception('Autentikasi diperlukan. Silakan login ulang.');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Ambil 3 daily quest hari ini beserta total XP user.
  /// Backend auto-generate jika belum ada untuk hari ini.
  static Future<DailyQuestModel> getDailyQuests() async {
    final uri = Uri.parse('$baseUrl/api/quest/daily');
    final response = await http.get(uri, headers: _authHeaders);

    if (response.statusCode == 200) {
      return DailyQuestModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Autentikasi gagal. Silakan login ulang.');
    }

    throw Exception('Gagal memuat daily quest: ${response.statusCode}.');
  }

  /// Tandai quest REVIEW_STATS selesai.
  /// Panggil ini saat user membuka halaman statistik.
  static Future<DailyQuestModel> completeReviewStats() async {
    final uri = Uri.parse('$baseUrl/api/quest/complete-review');
    final response = await http.post(uri, headers: _authHeaders);

    if (response.statusCode == 200) {
      return DailyQuestModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Autentikasi gagal. Silakan login ulang.');
    }

    throw Exception('Gagal menyelesaikan quest review: ${response.statusCode}.');
  }
}