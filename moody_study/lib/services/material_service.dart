import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/generated_quiz_response.dart';
import '../models/material_response.dart';
import '../models/saved_file.dart';
import 'api_config.dart';
import 'auth_service.dart';

class MaterialService {
  static String get baseUrl => ApiConfig.baseUrl;
  static Future<MaterialResponse> summarizeMaterial({
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
      body: jsonEncode({'fileName': fileName, 'originalText': originalText}),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        return MaterialResponse.fromJson(body);
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

  static Future<List<SavedFile>> fetchSavedFiles() async {
    final uri = Uri.parse('$baseUrl/api/files');
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
      if (body is List) {
        return body
            .map((item) => SavedFile.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Respons server tidak valid.');
    }

    String message = 'Gagal memuat file: ${response.statusCode}.';
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
        message = 'Gagal memuat file: ${response.statusCode}. ${response.body}';
      }
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      message = 'Autentikasi gagal. Silakan login ulang.';
    }

    throw Exception(message);
  }

  static Future<void> saveFileAsPdf({
    required String fileName,
    required String fileType,
    required String base64Content,
  }) async {
    final uri = Uri.parse('$baseUrl/api/files/save');
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
        'fileType': fileType,
        'content': base64Content,
      }),
    );

    if (response.statusCode == 200) {
      return;
    }

    String message = 'Simpan file gagal: ${response.statusCode}.';
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
        message = 'Simpan file gagal: ${response.statusCode}. ${response.body}';
      }
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      message = 'Autentikasi gagal. Silakan login ulang.';
    }

    throw Exception(message);
  }

  static Future<GeneratedQuizResponse> generateQuiz({
    required int materialId,
    required String quizType,
    int questionCount = 5,
    String difficulty = 'medium',
  }) async {
    final uri = Uri.parse('$baseUrl/api/quiz/generate');
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
        'materialId': materialId,
        'quizType': quizType,
        'difficulty': difficulty,
        'questionCount': questionCount,
      }),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        return GeneratedQuizResponse.fromJson(body);
      }
      throw Exception('Respons server tidak valid.');
    }

    String message = 'Gagal membuat quiz: ${response.statusCode}.';
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
        message =
            'Gagal membuat quiz: ${response.statusCode}. ${response.body}';
      }
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      message = 'Autentikasi gagal. Silakan login ulang.';
    }

    throw Exception(message);
  }

  static Future<void> deleteSavedFile(int id) async {
    final uri = Uri.parse('$baseUrl/api/files/$id');
    final token = AuthService.token;

    if (token == null) {
      throw Exception('Autentikasi diperlukan. Silakan login ulang.');
    }

    final response = await http.delete(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 204 || response.statusCode == 200) {
      return;
    }

    String message = 'Hapus file gagal: ${response.statusCode}.';
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
        message = 'Hapus file gagal: ${response.statusCode}. ${response.body}';
      }
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      message = 'Autentikasi gagal. Silakan login ulang.';
    }

    throw Exception(message);
  }

  static Future<void> renameSavedFile({
    required int id,
    required String newFileName,
  }) async {
    final uri = Uri.parse('$baseUrl/api/files/$id/rename');
    final token = AuthService.token;

    if (token == null) {
      throw Exception('Autentikasi diperlukan. Silakan login ulang.');
    }

    final response = await http.patch(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'newFileName': newFileName}),
    );

    if (response.statusCode == 200) {
      return;
    }

    String message = 'Ganti nama gagal: ${response.statusCode}.';
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
        message = 'Ganti nama gagal: ${response.statusCode}. ${response.body}';
      }
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      message = 'Autentikasi gagal. Silakan login ulang.';
    }

    throw Exception(message);
  }
  static Future<GeneratedQuizResponse> toggleSaveQuiz(int quizId) async {
    final token = AuthService.token;
    if (token == null) throw Exception('Autentikasi diperlukan.');
    final uri = Uri.parse('$baseUrl/api/quiz/$quizId/save');
    final response = await http.post(uri, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });
    if (response.statusCode == 200) {
      return GeneratedQuizResponse.fromJson(jsonDecode(response.body));
    }
    throw Exception('Gagal menyimpan flashcard: \${response.statusCode}');
  }

  static Future<List<GeneratedQuizResponse>> getSavedQuizzes() async {
    final token = AuthService.token;
    if (token == null) throw Exception('Autentikasi diperlukan.');
    final uri = Uri.parse('$baseUrl/api/quiz/saved');
    final response = await http.get(uri, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.map((e) => GeneratedQuizResponse.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Gagal memuat saved quiz: \${response.statusCode}');
  }

}