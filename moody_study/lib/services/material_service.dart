import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'auth_service.dart';

class MaterialService {
  static String get baseUrl =>
      kIsWeb ? 'http://localhost:8081' : 'http://10.0.2.2:8081';

  static Future<String> summarizeMaterial({
    required String fileName,
    required String originalText,
  }) async {
    final uri = Uri.parse('$baseUrl/api/material/upload');
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
        'fileName': fileName,
        'originalText': originalText,
      }),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic> && body['summary'] is String) {
        return body['summary'] as String;
      }
      throw Exception('Respons server tidak valid.');
    }

    String message = 'Ringkasan gagal: ${response.statusCode}.';
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        if (body['error'] is String) {
          message = body['error'] as String;
        } else if (body['message'] is String) {
          message = body['message'] as String;
        }
      }
    } catch (_) {
      if (response.body.isNotEmpty) {
        message = 'Ringkasan gagal: ${response.statusCode}. ${response.body}';
      }
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      message = 'Autentikasi gagal. Silakan login ulang.';
    }

    throw Exception(message);
  }
}
