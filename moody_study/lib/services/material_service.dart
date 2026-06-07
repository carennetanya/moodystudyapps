import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

import 'api_client.dart';
import '../core/error/exception_mapper.dart';
import '../core/error/failures.dart';
import '../models/generated_quiz_response.dart';
import '../models/material_response.dart';
import '../models/saved_file.dart';

class MaterialService {
  /// Ekstrak teks dari PDF via backend (Apache PDFBox).
  /// Throws [AppFailure] subclass untuk error spesifik:
  ///   [PdfTooLargeFailure], [PdfCorruptedFailure],
  ///   [PdfPasswordProtectedFailure], [PdfScannedNotSupportedFailure]
  static Future<String> extractTextFromFile(PlatformFile file) async {
    final bytes = file.bytes ??
        (file.path != null ? await File(file.path!).readAsBytes() : null);
    if (bytes == null || bytes.isEmpty) return '';

    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: file.name),
    });

    try {
      final res = await ApiClient.dio.post(
        '/api/schedule/extract-text',
        data: formData,
      );
      final text = (res.data as Map<String, dynamic>)['text'] as String? ?? '';
      if (text.trim().length < 10) throw const PdfScannedNotSupportedFailure();
      return text;
    } on AppFailure {
      rethrow;
    } on DioException catch (e) {
      throw ExceptionMapper.mapPdf(e);
    }
  }

  static Future<MaterialResponse> summarizeMaterial({
    required String fileName,
    required String originalText,
  }) async {
    final res = await ApiClient.dio.post(
      '/api/material/upload',
      data: {'fileName': fileName, 'originalText': originalText},
    );
    return MaterialResponse.fromJson(res.data as Map<String, dynamic>);
  }

  static Future<List<SavedFile>> fetchSavedFiles() async {
    final res = await ApiClient.dio.get('/api/files');
    final body = res.data;
    if (body is List) {
      return body.map((item) => SavedFile.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
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
  }

  static Future<void> renameSavedFile({
    required int id,
    required String newFileName,
  }) async {
    await ApiClient.dio.patch('/api/files/$id/rename', data: {'newFileName': newFileName});
  }

  static Future<GeneratedQuizResponse> toggleSaveQuiz(int quizId) async {
    final res = await ApiClient.dio.post('/api/quiz/$quizId/save');
    return GeneratedQuizResponse.fromJson(res.data as Map<String, dynamic>);
  }

  static Future<List<GeneratedQuizResponse>> getSavedQuizzes() async {
    final res = await ApiClient.dio.get('/api/quiz/saved');
    final list = res.data as List<dynamic>;
    return list.map((e) => GeneratedQuizResponse.fromJson(e as Map<String, dynamic>)).toList();
  }
}
