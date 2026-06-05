import 'package:dio/dio.dart';
import 'api_client.dart';
import '../models/generated_quiz_response.dart';
import '../models/material_response.dart';
import '../models/saved_file.dart';

class MaterialService {
  static Future<MaterialResponse> summarizeMaterial({
    required String fileName,
    required String originalText,
  }) async {
    final res = await ApiClient.dio.post(
      '/api/material/upload',
      data: {'fileName': fileName, 'originalText': originalText},
    );

    return MaterialResponse.fromJson(res.data as Map<String, dynamic>);


    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        return MaterialResponse.fromJson(body);
      }
      throw Exception('Respons server tidak valid.');
    }

    String message = 'Gagal membuat ringkasan. Silakan coba lagi.';
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        if (body['error'] is String) {
          message = body['error'] as String;
        } else if (body['message'] is String) {
          message = body['message'] as String;
        }
      }
    } catch (_) {}

    if (response.statusCode == 401 || response.statusCode == 403) {
      message = 'Sesi login habis. Silakan login ulang.';
    }

    throw Exception(message);
  }

  static Future<List<SavedFile>> fetchSavedFiles() async {
    final res = await ApiClient.dio.get('/api/files');
    final body = res.data;
    if (body is List) {
      return body.map((item) => SavedFile.fromJson(item as Map<String, dynamic>)).toList();
    }
    throw Exception('Respons server tidak valid.');


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

    String message = 'Gagal memuat file. Silakan coba lagi.';
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        if (body['error'] is String) {
          message = body['error'] as String;
        } else if (body['message'] is String) {
          message = body['message'] as String;
        }
      }
    } catch (_) {}

    if (response.statusCode == 401 || response.statusCode == 403) {
      message = 'Sesi login habis. Silakan login ulang.';
    }

    throw Exception(message);
>>>>>>> 47e58ec (Trials Try Catch)
  }

  static Future<void> saveFileAsPdf({
    required String fileName,
    required String fileType,
    required String base64Content,
  }) async {
    await ApiClient.dio.post(
      '/api/files/save',
      data: {'fileName': fileName, 'fileType': fileType, 'content': base64Content},
    );

    if (response.statusCode == 200) {
      return;
    }

    String message = 'Gagal menyimpan file. Silakan coba lagi.';
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        if (body['error'] is String) {
          message = body['error'] as String;
        } else if (body['message'] is String) {
          message = body['message'] as String;
        }
      }
    } catch (_) {}

    if (response.statusCode == 401 || response.statusCode == 403) {
      message = 'Sesi login habis. Silakan login ulang.';
    }

    throw Exception(message);
  }

  static Future<GeneratedQuizResponse> generateQuiz({
    required int materialId,
    required String quizType,
    int questionCount = 5,
    String difficulty = 'medium',
  }) async {
    final res = await ApiClient.dio.post(
      '/api/quiz/generate',
      data: {
        'materialId': materialId,
        'quizType': quizType,
        'difficulty': difficulty,
        'questionCount': questionCount,
      },
    );

    return GeneratedQuizResponse.fromJson(res.data as Map<String, dynamic>);
  }

  static Future<void> deleteSavedFile(int id) async {
    await ApiClient.dio.delete('/api/files/$id');

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        return GeneratedQuizResponse.fromJson(body);
      }
      throw Exception('Respons server tidak valid.');
    }

    String message = 'Gagal membuat kuis. Silakan coba lagi.';
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        if (body['error'] is String) {
          message = body['error'] as String;
        } else if (body['message'] is String) {
          message = body['message'] as String;
        }
      }
    } catch (_) {}

    if (response.statusCode == 401 || response.statusCode == 403) {
      message = 'Sesi login habis. Silakan login ulang.';
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

    String message = 'Gagal menghapus file. Silakan coba lagi.';
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        if (body['error'] is String) {
          message = body['error'] as String;
        } else if (body['message'] is String) {
          message = body['message'] as String;
        }
      }
    } catch (_) {}

    if (response.statusCode == 401 || response.statusCode == 403) {
      message = 'Sesi login habis. Silakan login ulang.';
    }

    throw Exception(message);
>>>>>>> 47e58ec (Trials Try Catch)
  }

  static Future<void> renameSavedFile({
    required int id,
    required String newFileName,
  }) async {
    await ApiClient.dio.patch('/api/files/$id/rename', data: {'newFileName': newFileName});

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

    String message = 'Gagal mengganti nama file. Silakan coba lagi.';
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        if (body['error'] is String) {
          message = body['error'] as String;
        } else if (body['message'] is String) {
          message = body['message'] as String;
        }
      }
    } catch (_) {}

    if (response.statusCode == 401 || response.statusCode == 403) {
      message = 'Sesi login habis. Silakan login ulang.';
    }

    throw Exception(message);
  }

  static Future<GeneratedQuizResponse> toggleSaveQuiz(int quizId) async {

    final res = await ApiClient.dio.post('/api/quiz/$quizId/save');
    return GeneratedQuizResponse.fromJson(res.data as Map<String, dynamic>);
  }

  static Future<List<GeneratedQuizResponse>> getSavedQuizzes() async {
    final res = await ApiClient.dio.get('/api/quiz/saved');
    final list = res.data as List<dynamic>;
    return list.map((e) => GeneratedQuizResponse.fromJson(e as Map<String, dynamic>)).toList();

    final token = AuthService.token;
    if (token == null) throw Exception('Sesi login habis. Silakan login ulang.');
    final uri = Uri.parse('$baseUrl/api/quiz/$quizId/save');
    final response = await http.post(uri, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });
    if (response.statusCode == 200) {
      return GeneratedQuizResponse.fromJson(jsonDecode(response.body));
    }
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Sesi login habis. Silakan login ulang.');
    }
    throw Exception('Gagal menyimpan flashcard. Silakan coba lagi.');
  }

  static Future<List<GeneratedQuizResponse>> getSavedQuizzes() async {
    final token = AuthService.token;
    if (token == null) throw Exception('Sesi login habis. Silakan login ulang.');
    final uri = Uri.parse('$baseUrl/api/quiz/saved');
    final response = await http.get(uri, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.map((e) => GeneratedQuizResponse.fromJson(e as Map<String, dynamic>)).toList();
    }
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Sesi login habis. Silakan login ulang.');
    }
    throw Exception('Gagal memuat kuis tersimpan. Silakan coba lagi.');
  }
}