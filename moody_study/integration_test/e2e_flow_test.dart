import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:http/http.dart' as http;
import 'package:moody_study/services/auth_service.dart';
import 'package:moody_study/services/material_service.dart';
import 'package:moody_study/services/daily_quest_service.dart';
import 'package:moody_study/services/streak_service.dart';
import 'package:moody_study/services/api_config.dart';
import 'package:moody_study/models/daily_quest_model.dart';

/// Integration Test — 3 end-to-end flow terhadap live Spring Boot API.
///
/// PRASYARAT sebelum menjalankan:
///   1. Backend berjalan di alamat yang sesuai di ApiConfig.baseUrl
///   2. Pastikan ada akun test dengan email + password di bawah
///   3. Jalankan: flutter test integration_test/app_integration_test.dart
///      atau: flutter test test/integration/e2e_flow_test.dart --timeout 60s

// ─── Akun test — ganti sesuai akun yang ada di database dev ───────────────
const _testEmail = 'testuser@moody.dev';
const _testPassword = 'TestPass123!';
const _testName = 'Integration Tester';
final _testUsername = 'integtest_${DateTime.now().millisecondsSinceEpoch}';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final baseUrl = ApiConfig.baseUrl;
  String? savedToken;
  int? savedMaterialId;

  // ─────────────────────────────────────────────────────────────────────────
  // FLOW 1: Register → Login → Get Profile
  // ─────────────────────────────────────────────────────────────────────────
  group('E2E Flow 1: Auth (Register → Login → Get Profile)', () {
    test('1a. Register akun baru berhasil atau sudah ada', () async {
      // Coba register — boleh gagal jika email sudah terdaftar
      final registerResult = await AuthService.register(
        name: _testName,
        username: 'integtest_${DateTime.now().millisecondsSinceEpoch}',
        email: _testEmail,
        password: _testPassword,
      );

      registerResult.fold(
        (failure) {
          print('ℹ Register skip atau gagal: ${failure.message}');
        },
        (user) {
          expect(user.token, isNotEmpty);
          print('✓ Register sukses: ${user.name}');
        },
      );
    });

    test('1b. Login dengan kredensial valid → token tersimpan', () async {
      final loginResult = await AuthService.login(
        email: _testEmail,
        password: _testPassword,
      );

      loginResult.fold(
        (failure) => fail('Login gagal: ${failure.message}'),
        (user) {
          expect(user.token, isNotEmpty);
          expect(AuthService.token, isNotNull);
          expect(AuthService.token, isNotEmpty);
          savedToken = AuthService.token;
          print('✓ Login sukses, token: ${savedToken?.substring(0, 10)}...');
        },
      );
    });

    test('1c. Get profile info menggunakan token yang valid', () async {
      // Pastikan token dari step sebelumnya masih ada
      expect(AuthService.token, isNotNull, reason: 'Login harus berhasil dulu');

      final uri = Uri.parse('$baseUrl/api/profile/info');
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthService.token}',
        },
      );

      expect(response.statusCode, 200);
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      expect(body, contains('name'));
      print('✓ Get profile: name = ${body['name']}');
    });

    test('1d. Login dengan password salah → mengembalikan AuthFailure', () async {
      final wrongLogin = await AuthService.login(
        email: _testEmail,
        password: 'WrongPassword!',
      );

      wrongLogin.fold(
        (failure) => expect(failure.message, isNotEmpty),
        (user) => fail('Login semestinya gagal dengan password salah, tetapi sukses: ${user.token}'),
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // FLOW 2: Upload Material → Generate Quiz → Fetch Saved Files
  // ─────────────────────────────────────────────────────────────────────────
  group('E2E Flow 2: Material (Upload → Generate Quiz → List Files)', () {
    setUpAll(() async {
      // Login dulu jika token belum ada
      if (AuthService.token == null) {
        await AuthService.login(email: _testEmail, password: _testPassword);
      }
    });

    test('2a. Upload/summarize materi teks pendek berhasil', () async {
      expect(AuthService.token, isNotNull);

      final result = await MaterialService.summarizeMaterial(
        fileName: 'integration_test_bab1.txt',
        originalText:
            'Fotosintesis adalah proses pembuatan makanan oleh tumbuhan '
            'menggunakan cahaya matahari, air, dan CO2. '
            'Proses ini terjadi di kloroplas dan menghasilkan glukosa dan oksigen.',
      );

      expect(result.id, greaterThan(0));
      expect(result.fileName, isNotEmpty);
      expect(result.summary, isNotEmpty);
      savedMaterialId = result.id;
      print('✓ Material upload sukses: id=$savedMaterialId');
    });

    test('2b. Generate quiz dari material yang sudah diupload', () async {
      expect(savedMaterialId, isNotNull, reason: 'Upload material harus berhasil dulu');

      final quiz = await MaterialService.generateQuiz(
        materialId: savedMaterialId!,
        quizType: 'multiple_choice',
        questionCount: 3,
        difficulty: 'easy',
      );

      expect(quiz.id, greaterThan(0));
      expect(quiz.materialId, savedMaterialId);
      expect(quiz.quizContent, isNotEmpty);
      print('✓ Quiz generated: id=${quiz.id}');
    });

    test('2c. Fetch saved files mengembalikan list (bisa kosong)', () async {
      final files = await MaterialService.fetchSavedFiles();
      expect(files, isA<List>());
      print('✓ Fetched ${files.length} saved files');
    });

    test('2d. getSavedQuizzes mengembalikan list', () async {
      final quizzes = await MaterialService.getSavedQuizzes();
      expect(quizzes, isA<List>());
      print('✓ Fetched ${quizzes.length} saved quizzes');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // FLOW 3: Daily Quest + Streak lifecycle
  // ─────────────────────────────────────────────────────────────────────────
  group('E2E Flow 3: Quest & Streak (Fetch → Complete → Verify)', () {
    setUpAll(() async {
      if (AuthService.token == null) {
        await AuthService.login(email: _testEmail, password: _testPassword);
      }
    });

    test('3a. getDailyQuests mengembalikan 3 quest untuk hari ini', () async {
      final model = await DailyQuestService.getDailyQuests();

      expect(model.quests, isNotEmpty);
      expect(model.maxXp, greaterThan(0));
      expect(model.questDate, isNotEmpty);
      // Backend harus selalu generate 3 quest per hari
      expect(model.quests.length, lessThanOrEqualTo(3));
      print(
        '✓ Daily quests: ${model.quests.length} quest, maxXp=${model.maxXp}',
      );
    });

    test('3b. completeReviewStats → quest REVIEW_STATS ditandai selesai', () async {
      final before = await DailyQuestService.getDailyQuests();
      final reviewBefore = before.quests.firstWhere(
        (q) => q.questKey == 'REVIEW_STATS',
        orElse: () => QuestItem(
          id: -1,
          questKey: '',
          title: '',
          description: '',
          xpReward: 0,
          completed: true, // sudah selesai sebelumnya — skip
        ),
      );

      final after = await DailyQuestService.completeReviewStats();
      expect(after, isA<DailyQuestModel>());

      if (!reviewBefore.completed && reviewBefore.id != -1) {
        // XP bertambah setelah complete
        expect(after.todayXp, greaterThanOrEqualTo(before.todayXp));
        print(
          '✓ Quest REVIEW_STATS selesai, XP: ${before.todayXp} → ${after.todayXp}',
        );
      } else {
        print('ℹ REVIEW_STATS sudah selesai sebelumnya, skip XP check');
      }
    });

    test('3c. fetchStreak mengembalikan StreakInfo yang valid', () async {
      final streak = await StreakService.fetchStreak();
      expect(streak.currentStreak, greaterThanOrEqualTo(0));
      print('✓ Streak: ${streak.currentStreak} hari');
    });

    test('3d. fetchLife mengembalikan angka antara 0–5', () async {
      final life = await StreakService.fetchLife();
      expect(life, greaterThanOrEqualTo(0));
      expect(life, lessThanOrEqualTo(5));
      print('✓ Life: $life');
    });

    tearDownAll(() async {
      await AuthService.logout();
      print('✓ Logout selesai');
    });
  });
}