import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'auth_service.dart';

class StreakService {
  static String get baseUrl =>
      kIsWeb ? 'http://localhost:8081' : 'http://10.0.2.2:8081';

  /// Fetch current user's life count from backend `/api/streak`.
  /// Returns an int (default 3 if response missing).
  static Future<int> fetchLife() async {
    final uri = Uri.parse('$baseUrl/api/streak');
    final token = AuthService.token;

    if (token == null) {
      throw Exception('Autentikasi diperlukan. Silakan login ulang.');
    }

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        final life = body['life'];
        if (life is int) return life;
        if (life is num) return life.toInt();
      }
      return 3;
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Autentikasi gagal. Silakan login ulang.');
    }

    throw Exception('Gagal memuat data streak: ${response.statusCode}.');
  }

  static Future<StreakInfo> fetchStreak() async {
    final uri = Uri.parse('$baseUrl/api/streak');
    final token = AuthService.token;

    if (token == null) {
      throw Exception('Autentikasi diperlukan. Silakan login ulang.');
    }

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        final currentStreak = body['currentStreak'];
        final life = body['life'];
        final level = body['level'];

        return StreakInfo(
          currentStreak: currentStreak is int ? currentStreak : (currentStreak is num ? currentStreak.toInt() : 0),
          life: life is int ? life : (life is num ? life.toInt() : 3),
          level: StreakInfo.parseLevel(level),
          levelName: level is String ? level : null,
        );
      }
      return StreakInfo(currentStreak: 0, life: 3, level: 1);
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Autentikasi gagal. Silakan login ulang.');
    }

    throw Exception('Gagal memuat data streak: ${response.statusCode}.');
  }

  static Future<int> completeSession({
    required String mood,
    required String location,
    required int durationMinutes,
    required int focusSeconds,
    required int distractionSeconds,
  }) async {
    final uri = Uri.parse('$baseUrl/api/streak/complete');
    final token = AuthService.token;

    if (token == null) {
      throw Exception('Autentikasi diperlukan. Silakan login ulang.');
    }

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'mood': mood,
        'location': location,
        'durationMinutes': durationMinutes,
        'focusSeconds': focusSeconds,
        'distractionSeconds': distractionSeconds,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        final life = body['life'];
        if (life is int) return life;
        if (life is num) return life.toInt();
      }
      return 3;
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Autentikasi gagal. Silakan login ulang.');
    }

    throw Exception('Gagal menyimpan sesi: ${response.statusCode}.');
  }
}

class StreakInfo {
  final int currentStreak;
  final int life;
  final int level;
  final String? levelName;

  StreakInfo({
    required this.currentStreak,
    required this.life,
    required this.level,
    this.levelName,
  });

  static int parseLevel(Object? value) {
    if (value is int) return value.clamp(1, 5);
    if (value is String) {
      switch (value.toUpperCase()) {
        case 'BEGINNER':
          return 1;
        case 'LEARNER':
          return 2;
        case 'PRACTITIONER':
          return 3;
        case 'EXPERT':
          return 4;
        case 'MASTER':
          return 5;
        default:
          return int.tryParse(value) ?? 1;
      }
    }
    return 1;
  }
}
