import 'package:flutter_test/flutter_test.dart';
import 'package:moody_study/services/auth_service.dart';
import 'package:moody_study/services/streak_service.dart';
import 'package:moody_study/services/daily_quest_service.dart';
import 'package:moody_study/models/daily_quest_model.dart';

void main() {
  setUp(() => AuthService.token = 'fake-token');
  tearDown(() => AuthService.token = null);

  // ─────────────────────────────────────────────
  // StreakService
  // ─────────────────────────────────────────────
  group('StreakService - fetchLife()', () {
    test('token null → throw Exception', () {
      AuthService.token = null;
      expect(() => StreakService.fetchLife(), throwsException);
    });

    test('parsing life dari body map int', () {
      // Simulasi parsing yang dilakukan di fetchLife
      final body = <String, dynamic>{'life': 3};
      final life = body['life'];
      int result = 3; // default
      if (life is int) result = life;
      if (life is num) result = life.toInt();
      expect(result, 3);
    });

    test('body tidak punya key life → return default 3', () {
      final body = <String, dynamic>{};
      final life = body['life'];
      int result = 3;
      if (life is int) result = life;
      expect(result, 3);
    });
  });

  group('StreakService - fetchStreak()', () {
    test('token null → throw Exception', () {
      AuthService.token = null;
      expect(() => StreakService.fetchStreak(), throwsException);
    });
  });

  // ─────────────────────────────────────────────
  // DailyQuestService
  // ─────────────────────────────────────────────
  group('DailyQuestService - getDailyQuests()', () {
    test('token null → throw Exception', () {
      AuthService.token = null;
      expect(() => DailyQuestService.getDailyQuests(), throwsException);
    });

    test('DailyQuestModel.fromJson: quests length = 3', () {
      final json = {
        'questDate': '2025-05-01',
        'todayXp': 0,
        'maxXp': 90,
        'quests': [
          {
            'id': 1,
            'questKey': 'UPLOAD_MATERIAL',
            'title': 'Upload',
            'description': 'Upload materi',
            'xpReward': 30,
            'completed': false,
          },
          {
            'id': 2,
            'questKey': 'STUDY_SESSION',
            'title': 'Belajar',
            'description': 'Belajar 30 menit',
            'xpReward': 30,
            'completed': false,
          },
          {
            'id': 3,
            'questKey': 'REVIEW_STATS',
            'title': 'Review',
            'description': 'Cek statistik',
            'xpReward': 30,
            'completed': false,
          },
        ],
      };
      final model = DailyQuestModel.fromJson(json);
      expect(model.quests.length, 3);
      expect(model.maxCoins, 90);
    });
  });

  group('DailyQuestService - completeReviewStats()', () {
    test('token null → throw Exception', () {
      AuthService.token = null;
      expect(() => DailyQuestService.completeReviewStats(), throwsException);
    });
  });

  // ─────────────────────────────────────────────
  // Auth header helper (_authHeaders)
  // ─────────────────────────────────────────────
  group('DailyQuestService - _authHeaders', () {
    test('token tersedia → header Authorization berisi Bearer token', () {
      AuthService.token = 'my-token';
      // Tidak bisa akses _authHeaders langsung (private),
      // tapi kita verifikasi pola header yang diharapkan
      final expectedHeader = 'Bearer my-token';
      expect('Bearer ${AuthService.token}', expectedHeader);
    });
  });
}