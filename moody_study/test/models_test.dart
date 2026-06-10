import 'package:flutter_test/flutter_test.dart';
import 'package:moody_study/models/material_response.dart';
import 'package:moody_study/models/saved_file.dart';
import 'package:moody_study/models/generated_quiz_response.dart';
import 'package:moody_study/models/daily_quest_model.dart';

void main() {
  // ─────────────────────────────────────────────
  // MaterialResponse
  // ─────────────────────────────────────────────
  group('MaterialResponse.fromJson()', () {
    test('parsing JSON lengkap → semua field terisi', () {
      final json = {
        'id': 1,
        'fileName': 'bab1.pdf',
        'summary': 'Ringkasan bab 1',
        'uploadedAt': '2025-01-01T10:00:00',
      };
      final result = MaterialResponse.fromJson(json);

      expect(result.id, 1);
      expect(result.fileName, 'bab1.pdf');
      expect(result.summary, 'Ringkasan bab 1');
      expect(result.uploadedAt, '2025-01-01T10:00:00');
    });

    test('id berupa double di JSON (dari beberapa backend) → di-convert ke int', () {
      final json = {
        'id': 2.0,
        'fileName': 'slide.pptx',
        'summary': 'Slide kuliah',
        'uploadedAt': '2025-02-01T08:00:00',
      };
      final result = MaterialResponse.fromJson(json);
      expect(result.id, 2);
      expect(result.id, isA<int>());
    });
  });

  // ─────────────────────────────────────────────
  // SavedFile
  // ─────────────────────────────────────────────
  group('SavedFile.fromJson()', () {
    test('parsing JSON lengkap → semua field terisi', () {
      final json = {
        'id': 10,
        'fileName': 'catatan.pdf',
        'fileType': 'pdf',
        'content': 'base64content==',
        'savedAt': '2025-03-01T09:00:00',
      };
      final result = SavedFile.fromJson(json);

      expect(result.id, 10);
      expect(result.fileName, 'catatan.pdf');
      expect(result.fileType, 'pdf');
      expect(result.content, 'base64content==');
      expect(result.savedAt, '2025-03-01T09:00:00');
    });

    test('field content bisa berisi string kosong', () {
      final json = {
        'id': 11,
        'fileName': 'empty.pdf',
        'fileType': 'pdf',
        'content': '',
        'savedAt': '2025-03-01T09:00:00',
      };
      final result = SavedFile.fromJson(json);
      expect(result.content, isEmpty);
    });
  });

  // ─────────────────────────────────────────────
  // GeneratedQuizResponse
  // ─────────────────────────────────────────────
  group('GeneratedQuizResponse.fromJson()', () {
    test('parsing JSON lengkap dengan saved = true', () {
      final json = {
        'id': 5,
        'materialId': 1,
        'fileName': 'quiz_bab1',
        'quizContent': '[{"q":"Apa itu AI?","a":"Kecerdasan Buatan"}]',
        'generatedAt': '2025-04-01T11:00:00',
        'saved': true,
      };
      final result = GeneratedQuizResponse.fromJson(json);

      expect(result.id, 5);
      expect(result.materialId, 1);
      expect(result.saved, isTrue);
    });

    test('field saved null di JSON → default false', () {
      final json = {
        'id': 6,
        'materialId': 2,
        'fileName': 'quiz_bab2',
        'quizContent': '[]',
        'generatedAt': '2025-04-02T11:00:00',
        // 'saved' tidak ada
      };
      final result = GeneratedQuizResponse.fromJson(json);
      expect(result.saved, isFalse);
    });

    test('id berupa num (double) → di-convert ke int', () {
      final json = {
        'id': 3.0,
        'materialId': 1.0,
        'fileName': 'q',
        'quizContent': '[]',
        'generatedAt': '2025-04-01T00:00:00',
        'saved': false,
      };
      final result = GeneratedQuizResponse.fromJson(json);
      expect(result.id, 3);
      expect(result.materialId, 1);
    });
  });

  // ─────────────────────────────────────────────
  // DailyQuestModel
  // ─────────────────────────────────────────────
  group('DailyQuestModel.fromJson()', () {
    test('parsing JSON dengan 3 quests', () {
      final json = {
        'questDate': '2025-05-01',
        'todayXp': 30,
        'maxXp': 90,
        'quests': [
          {
            'id': 1,
            'questKey': 'UPLOAD_MATERIAL',
            'title': 'Upload materi',
            'description': 'Upload 1 materi belajar',
            'xpReward': 30,
            'completed': true,
          },
          {
            'id': 2,
            'questKey': 'STUDY_SESSION',
            'title': 'Sesi belajar',
            'description': 'Selesaikan 1 sesi belajar',
            'xpReward': 30,
            'completed': false,
          },
          {
            'id': 3,
            'questKey': 'REVIEW_STATS',
            'title': 'Review statistik',
            'description': 'Buka halaman statistik',
            'xpReward': 30,
            'completed': false,
          },
        ],
      };
      final result = DailyQuestModel.fromJson(json);

      expect(result.questDate, '2025-05-01');
      expect(result.todayCoins, 30);
      expect(result.maxCoins, 90);
      expect(result.quests.length, 3);
      expect(result.quests.first.questKey, 'UPLOAD_MATERIAL');
      expect(result.quests.first.completed, isTrue);
      expect(result.quests.last.completed, isFalse);
    });

    test('quests kosong → list tetap valid', () {
      final json = {
        'questDate': '2025-05-02',
        'todayXp': 0,
        'maxXp': 0,
        'quests': [],
      };
      final result = DailyQuestModel.fromJson(json);
      expect(result.quests, isEmpty);
    });

    test('field null di JSON → pakai nilai default', () {
      final json = <String, dynamic>{};
      final result = DailyQuestModel.fromJson(json);
      expect(result.questDate, '');
      expect(result.todayCoins, 0);
      expect(result.maxCoins, 0);
      expect(result.quests, isEmpty);
    });
  });

  // ─────────────────────────────────────────────
  // QuestItem
  // ─────────────────────────────────────────────
  group('QuestItem.fromJson()', () {
    test('xpReward terbaca dengan benar', () {
      final json = {
        'id': 1,
        'questKey': 'UPLOAD_MATERIAL',
        'title': 'Upload materi',
        'description': 'Upload 1 materi',
        'coinReward': 50,
        'completed': false,
      };
      final item = QuestItem.fromJson(json);
      expect(item.coinReward, 50);
      expect(item.completed, isFalse);
    });
  });
}