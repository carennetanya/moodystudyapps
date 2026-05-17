import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AuthException implements Exception {
  final String message;

  AuthException(this.message);

  @override
  String toString() => message;
}

class AuthService {
  // Gunakan URL yang benar berdasarkan platform.
  // Android emulator menggunakan 10.0.2.2 untuk host machine,
  // web dan desktop menggunakan localhost.
  static String get baseUrl => kIsWeb ? 'http://localhost:8081' : 'http://10.0.2.2:8081';

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/api/auth/register');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic> && body['message'] is String) {
        throw AuthException(body['message'] as String);
      }
    } catch (_) {
      // fallback to plain text response
    }

    throw AuthException(
      'Register failed. Kode: ${response.statusCode}. Cek backend atau jaringan.',
    );
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/api/auth/login');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic> && body['message'] is String) {
        throw AuthException(body['message'] as String);
      }
    } catch (_) {
      // fallback to plain text response
    }

    throw AuthException(
      'Login failed. Kode: ${response.statusCode}. Cek backend atau jaringan.',
    );
  }
}
