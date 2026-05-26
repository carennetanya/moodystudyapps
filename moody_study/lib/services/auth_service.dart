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
  static String? token;

  static String get baseUrl {
  if (kIsWeb) return 'http://localhost:8081';
  // Ganti dengan IP LAN kamu, misal:
  return 'http://192.168.1.9:8081';
}

  static Future<Map<String, dynamic>> register({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/api/auth/register');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'username': username,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final receivedToken = body['token'] as String?;
      if (receivedToken != null) {
        token = receivedToken;
      }
      return body;
    }

    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic> && body['message'] is String) {
        throw AuthException(body['message'] as String);
      }
    } catch (e) {
      if (e is AuthException) rethrow;
    }

    throw AuthException(
      'Register failed. Kode: ${response.statusCode}.',
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

    if (response.statusCode == 200 || response.statusCode == 201) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final receivedToken = body['token'] as String?;
      if (receivedToken != null) {
        token = receivedToken;
      }
      return body;
    }

    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic> && body['message'] is String) {
        throw AuthException(body['message'] as String);
      }
    } catch (e) {
      if (e is AuthException) rethrow;
    }

    throw AuthException(
      'Login failed. Kode: ${response.statusCode}.',
    );
  }
}