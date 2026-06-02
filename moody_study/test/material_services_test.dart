import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:moody_study/services/auth_service.dart';
import 'package:moody_study/services/material_service.dart';
import 'package:moody_study/models/material_response.dart';
import 'package:moody_study/models/generated_quiz_response.dart';
import 'package:moody_study/models/saved_file.dart';

/// Unit test ini memverifikasi logika parsing dan error handling
/// MaterialService tanpa menyentuh network (mock response manual).
///
/// Untuk mock HTTP penuh gunakan `mocktail` atau `http` mock client
/// dan inject via constructor injection.
void main() {
  setUp(() {
    AuthService.token = 'test-token';
  });

  tearDown(() {
    AuthService.token = null;
  });

  // ─────────────────────────────────────────────
  // summarizeMaterial
  // ─────────────────────────────────────────────
  group('MaterialService - summarizeMaterial()', () {
    test(
      'token null → throw Exception autentikasi diperlukan',
      () async {
        AuthService.token = null;
        expect(
          () => MaterialService.summarizeMaterial(
            fileName: 'test.pdf',
            originalText: 'isi teks',
          ),
          throwsException,
        );
      },
    );

    test('parsing MaterialResponse.fromJson dari body valid', () {
      final body = {
        'id': 1,
        'fileName': 'test.pdf',
        'summary': 'Ini ringkasan',
        'uploadedAt': '2025-01-01T10:00:00',
      };
      final result = MaterialResponse.fromJson(body);
      expect(result.summary, 'Ini ringkasan');
      expect(result.id, 1);
    });
  });

  // ─────────────────────────────────────────────
  // fetchSavedFiles
  // ─────────────────────────────────────────────
  group('MaterialService - fetchSavedFiles()', () {
    test('token null → throw Exception', () {
      AuthService.token = null;
      expect(
        () => MaterialService.fetchSavedFiles(),
        throwsException,
      );
    });

    test('parsing list SavedFile dari JSON array', () {
      final rawList = [
        {
          'id': 1,
          'fileName': 'file1.pdf',
          'fileType': 'pdf',
          'content': 'abc',
          'savedAt': '2025-01-01',
        },
        {
          'id': 2,
          'fileName': 'file2.pdf',
          'fileType': 'pdf',
          'content': 'def',
          'savedAt': '2025-01-02',
        },
      ];
      final files = rawList
          .map((item) => SavedFile.fromJson(item as Map<String, dynamic>))
          .toList();

      expect(files.length, 2);
      expect(files[0].fileName, 'file1.pdf');
      expect(files[1].id, 2);
    });
  });

  // ─────────────────────────────────────────────
  // generateQuiz
  // ─────────────────────────────────────────────
  group('MaterialService - generateQuiz()', () {
    test('token null → throw Exception', () {
      AuthService.token = null;
      expect(
        () => MaterialService.generateQuiz(
          materialId: 1,
          quizType: 'multiple_choice',
        ),
        throwsException,
      );
    });

    test('parsing GeneratedQuizResponse dari JSON valid', () {
      final json = {
        'id': 10,
        'materialId': 1,
        'fileName': 'quiz_bab1',
        'quizContent': '[]',
        'generatedAt': '2025-01-01',
        'saved': false,
      };
      final result = GeneratedQuizResponse.fromJson(json);
      expect(result.id, 10);
      expect(result.quizContent, '[]');
    });
  });

  // ─────────────────────────────────────────────
  // deleteSavedFile
  // ─────────────────────────────────────────────
  group('MaterialService - deleteSavedFile()', () {
    test('token null → throw Exception', () {
      AuthService.token = null;
      expect(
        () => MaterialService.deleteSavedFile(1),
        throwsException,
      );
    });
  });

  // ─────────────────────────────────────────────
  // renameSavedFile
  // ─────────────────────────────────────────────
  group('MaterialService - renameSavedFile()', () {
    test('token null → throw Exception', () {
      AuthService.token = null;
      expect(
        () => MaterialService.renameSavedFile(id: 1, newFileName: 'baru.pdf'),
        throwsException,
      );
    });
  });

  // ─────────────────────────────────────────────
  // getSavedQuizzes
  // ─────────────────────────────────────────────
  group('MaterialService - getSavedQuizzes()', () {
    test('token null → throw Exception', () {
      AuthService.token = null;
      expect(
        () => MaterialService.getSavedQuizzes(),
        throwsException,
      );
    });

    test('parsing list GeneratedQuizResponse dari JSON array', () {
      final rawList = [
        {
          'id': 1,
          'materialId': 1,
          'fileName': 'q1',
          'quizContent': '[]',
          'generatedAt': '2025-01-01',
          'saved': true,
        },
      ];
      final list = rawList
          .map(
            (e) => GeneratedQuizResponse.fromJson(e as Map<String, dynamic>),
          )
          .toList();
      expect(list.first.saved, isTrue);
    });
  });
}