import 'api_client.dart';
import 'api_config.dart';

class StreakService {
  /// Dipakai oleh screen lain (statistik, character_intro) untuk build URL sendiri.
  static String get baseUrl => ApiConfig.baseUrl;

  static Future<int> fetchLife() async {
    final res = await ApiClient.dio.get('/api/streak');
    final body = res.data;
    if (body is Map<String, dynamic>) {
      final life = body['life'];
      if (life is int) return life;
      if (life is num) return life.toInt();
    }
    return 3;
  }

  static Future<StreakInfo> fetchStreak() async {
    final res = await ApiClient.dio.get('/api/streak');
    final body = res.data;
    if (body is Map<String, dynamic>) {
      final currentStreak = body['currentStreak'];
      final life = body['life'];
      final level = body['level'];
      final levelName = body['levelName'] is String
          ? body['levelName']
          : (level is String ? level : null);
      return StreakInfo(
        currentStreak: currentStreak is int
            ? currentStreak
            : (currentStreak is num ? currentStreak.toInt() : 0),
        life: life is int ? life : (life is num ? life.toInt() : 3),
        level: StreakInfo.parseLevel(level),
        totalSessions: body['totalSessions'] is int
            ? body['totalSessions'] as int
            : (body['totalSessions'] is num
                ? (body['totalSessions'] as num).toInt()
                : 0),
        sessionsToNextLevel: body['sessionsToNextLevel'] is int
            ? body['sessionsToNextLevel'] as int
            : (body['sessionsToNextLevel'] is num
                ? (body['sessionsToNextLevel'] as num).toInt()
                : 0),
        levelName: levelName,
        nextLevelName:
            body['nextLevelName'] is String ? body['nextLevelName'] : null,
      );
    }
    return StreakInfo(
      currentStreak: 0,
      life: 3,
      level: 1,
      totalSessions: 0,
      sessionsToNextLevel: 6,
    );
  }

  static Future<SessionResult> completeSession({
    required String mood,
    required String location,
    required int durationMinutes,
    required int focusSeconds,
    required int distractionSeconds,
  }) async {
    final res = await ApiClient.dio.post(
      '/api/streak/complete',
      data: {
        'mood': mood,
        'location': location,
        'durationMinutes': durationMinutes,
        'focusSeconds': focusSeconds,
        'distractionSeconds': distractionSeconds,
      },
    );

    final body = res.data;
    if (body is Map<String, dynamic>) {
      final life = body['life'];
      final lifeInt =
          life is int ? life : (life is num ? life.toInt() : 3);

      final prevLevel = StreakInfo.parseLevel(body['previousLevel']);
      final newLevel = StreakInfo.parseLevel(body['level']);
      final leveledUp = body['leveledUp'] == true || newLevel > prevLevel;

      final totalXpInLevel = body['totalXpInLevel'] is int
          ? body['totalXpInLevel'] as int
          : (body['totalXpInLevel'] is num
              ? (body['totalXpInLevel'] as num).toInt()
              : 0);

      final cs = body['currentStreak'];
      final currentStreak = cs is int ? cs : (cs is num ? cs.toInt() : 0);

      return SessionResult(
        life: lifeInt,
        leveledUp: leveledUp,
        previousLevel: prevLevel,
        newLevel: newLevel,
        newLevelName:
            body['levelName'] is String ? body['levelName'] : null,
        xpEarnedInLevel: totalXpInLevel,
        currentStreak: currentStreak,
      );
    }
    return SessionResult(
      life: 3,
      leveledUp: false,
      previousLevel: 1,
      newLevel: 1,
      xpEarnedInLevel: 0,
      currentStreak: 0,
    );
  }
}

class SessionResult {
  final int life;
  final bool leveledUp;
  final int previousLevel;
  final int newLevel;
  final String? newLevelName;
  final int xpEarnedInLevel;
  final int currentStreak;

  SessionResult({
    required this.life,
    required this.leveledUp,
    required this.previousLevel,
    required this.newLevel,
    this.newLevelName,
    required this.xpEarnedInLevel,
    this.currentStreak = 0,
  });
}

class StreakInfo {
  final int currentStreak;
  final int life;
  final int level;
  final String? levelName;
  final int totalSessions;
  final int sessionsToNextLevel;
  final String? nextLevelName;

  StreakInfo({
    required this.currentStreak,
    required this.life,
    required this.level,
    required this.totalSessions,
    required this.sessionsToNextLevel,
    this.levelName,
    this.nextLevelName,
  });

  static int parseLevel(Object? value) {
    if (value is int) return value.clamp(1, 5);
    if (value is String) {
      switch (value.toUpperCase()) {
        case 'BEGINNER':
          return 1;
        case 'LEARNER':
          return 2;
        case 'PRACTITIONER':
          return 3;
        case 'EXPERT':
          return 4;
        case 'MASTER':
          return 5;
        default:
          return int.tryParse(value) ?? 1;
      }
    }
    return 1;
  }
}
