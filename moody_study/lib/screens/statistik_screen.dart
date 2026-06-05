import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:dartz/dartz.dart' hide State;
import 'package:moody_study/core/failure.dart';
import 'package:moody_study/core/exception_handler.dart';
import '../services/api_config.dart';
import '../services/auth_service.dart';
import '../services/streak_service.dart';

class StatistikScreen extends StatefulWidget {
  const StatistikScreen({super.key});

  @override
  State<StatistikScreen> createState() => _StatistikScreenState();
}

class _StatistikScreenState extends State<StatistikScreen> {
  bool _loading = true;
  String? _error;

  // Data dari /api/stats
  int _totalSessions = 0;
  int _totalMinutes = 0;
  double _avgDuration = 0;
  double _focusRate = 0;
  Map<String, int> _sessionsPerDay = {};
  int _sessionsThisWeek = 0;
  int _sessionsLastWeek = 0;
  String _favoriteMood = '-';
  String _favoriteLocation = '-';

  // Data dari /api/streak
  int _totalXp = 0;
  int _currentStreak = 0;
  int _life = 3;
  String _levelName = 'Beginner';
  int _totalSessionsStreak = 0;
  int _sessionsToNext = 0;
  int _currentLevel = 1;

  // Data dari /api/award
  List<Map<String, dynamic>> _awards = [];

  // Data dari /api/quest/daily (total XP hari ini)
  int _todayXp = 0;
  int _maxXp = 0;

  static String get baseUrl => ApiConfig.baseUrl;

  Map<String, String> get _headers {
    final token = AuthService.token;
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<Either<Failure, void>> _fetchAll() async {
    try {
      await Future.wait([
        _loadStats(),
        _loadStreak(),
        _loadAwards(),
        _loadQuest(),
      ]);
      return const Right(null);
    } catch (e) {
      return Left(ServiceFailure(sanitizeException(e)));
    }
  }

  Future<void> _loadAll() async {
    setState(() { _loading = true; _error = null; });
    final result = await _fetchAll();
    if (!mounted) return;
    result.fold(
      (failure) => setState(() { _error = failure.message; _loading = false; }),
      (_) => setState(() => _loading = false),
    );
  }

  Future<void> _loadStats() async {
    final res = await http.get(Uri.parse('$baseUrl/api/stats'), headers: _headers);
    if (res.statusCode == 200) {
      final d = jsonDecode(res.body) as Map<String, dynamic>;
      setState(() {
        _totalSessions = (d['totalSessions'] as num?)?.toInt() ?? 0;
        _totalMinutes = (d['totalStudyMinutes'] as num?)?.toInt() ?? 0;
        _avgDuration = (d['avgDurationMinutes'] as num?)?.toDouble() ?? 0;
        _focusRate = (d['focusRatePercent'] as num?)?.toDouble() ?? 0;
        _sessionsThisWeek = (d['sessionsThisWeek'] as num?)?.toInt() ?? 0;
        _sessionsLastWeek = (d['sessionsLastWeek'] as num?)?.toInt() ?? 0;
        _favoriteMood = d['favoriteMood'] as String? ?? '-';
        _favoriteLocation = d['favoriteLocation'] as String? ?? '-';
        final spd = d['sessionsPerDay'] as Map<String, dynamic>? ?? {};
        _sessionsPerDay = spd.map((k, v) => MapEntry(k, (v as num).toInt()));
      });
    }
  }

  Future<void> _loadStreak() async {
    final token = AuthService.token;
    final baseUrl = StreakService.baseUrl;
    final res = await http.get(
      Uri.parse('$baseUrl/api/streak'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      final d = jsonDecode(res.body) as Map<String, dynamic>;
      setState(() {
        _currentStreak = (d['currentStreak'] as num?)?.toInt() ?? 0;
        _life = (d['life'] as num?)?.toInt() ?? 3;
        _levelName = (d['level'] as String?) ?? 'BEGINNER';
        _totalSessionsStreak = (d['totalSessions'] as num?)?.toInt() ?? 0;
        _sessionsToNext = (d['sessionsToNextLevel'] as num?)?.toInt() ?? 0;
        _currentLevel = _levelNameToInt(_levelName);
      });
    }
    // Ambil total XP dari /api/user/xp atau hitung dari award
    final xpRes = await http.get(
      Uri.parse('$baseUrl/api/user/xp'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    );
    if (xpRes.statusCode == 200) {
      final xd = jsonDecode(xpRes.body) as Map<String, dynamic>;
      setState(() => _totalXp = (xd['totalXp'] as num?)?.toInt() ?? 0);
    }
  }

  int _levelNameToInt(String name) {
    switch (name.toUpperCase()) {
      case 'LEARNER': return 2;
      case 'PRACTITIONER': return 3;
      case 'EXPERT': return 4;
      case 'MASTER': return 5;
      default: return 1;
    }
  }

  Future<void> _loadAwards() async {
    final res = await http.get(Uri.parse('$baseUrl/api/award'), headers: _headers);
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List<dynamic>;
      setState(() {
        _awards = list.map((e) => e as Map<String, dynamic>).toList();
      });
    }
  }

  Future<void> _loadQuest() async {
    final res = await http.get(Uri.parse('$baseUrl/api/quest/daily'), headers: _headers);
    if (res.statusCode == 200) {
      final d = jsonDecode(res.body) as Map<String, dynamic>;
      setState(() {
        _todayXp = (d['todayXp'] as num?)?.toInt() ?? 0;
        _maxXp = (d['maxXp'] as num?)?.toInt() ?? 0;
      });
    }
  }

  // ── Level thresholds ─────────────────────────────
  static const _levelThresholds = [0, 6, 13, 22, 33];
  static const _levelNames = ['Beginner', 'Learner', 'Practitioner', 'Expert', 'Master'];
  static const _levelColors = [
    Color(0xFFCD7F32), // Bronze
    Color(0xFFC0C0C0), // Silver
    Color(0xFFFFD700), // Gold
    Color(0xFF00CEC9), // Teal
    Color(0xFFA29BFE), // Purple
  ];
  static const _levelXpRewards = [0, 50, 100, 200, 400];

  // Hitung XP yang dikumpul di tiap level dari awards
  int _xpAtLevel(int level) {
    // level 1 = index 0, dst
    final award = _awards.firstWhere(
      (a) => (a['level'] as num?)?.toInt() == level,
      orElse: () => {},
    );
    if (award.isEmpty) return 0;
    return (award['xpPoints'] as num?)?.toInt() ?? 0;
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}j' : '${h}j ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF1EE86F)))
                  : _error != null
                      ? _buildError()
                      : _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        color: Color(0xFFF2EA05),
        border: Border(bottom: BorderSide(color: Color(0xFF111111), width: 3)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(Icons.arrow_back, size: 24, color: Color(0xFF111111)),
          ),
          const SizedBox(width: 12),
          const Text(
            'Statistik',
            style: TextStyle(
              fontFamily: 'BlackHanSans',
              fontSize: 22,
              color: Color(0xFF111111),
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          // XP hari ini badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('⚡', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 4),
                Text(
                  '$_todayXp / $_maxXp XP',
                  style: const TextStyle(
                    fontFamily: 'BlackHanSans',
                    fontSize: 13,
                    color: Color(0xFFF2EA05),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Color(0xFFDD2C00)),
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Nunito', fontSize: 14, color: Color(0xFF555555))),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _loadAll,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF2EA05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF111111), width: 2),
                boxShadow: const [BoxShadow(color: Color(0xFF111111), offset: Offset(3, 3))],
              ),
              child: const Text('Coba Lagi',
                  style: TextStyle(fontFamily: 'BlackHanSans', fontSize: 14, color: Color(0xFF111111))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      color: const Color(0xFF1EE86F),
      onRefresh: _loadAll,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Level Progress ──────────────────────────
          _buildSectionTitle('🏆 Level & Progress'),
          const SizedBox(height: 12),
          _buildLevelCard(),
          const SizedBox(height: 8),
          _buildXpPerLevelList(),

          const SizedBox(height: 24),

          // ── Ringkasan ────────────────────────────────
          _buildSectionTitle('📊 Ringkasan Belajar'),
          const SizedBox(height: 12),
          _buildSummaryGrid(),

          const SizedBox(height: 24),

          // ── Grafik 7 hari ────────────────────────────
          _buildSectionTitle('📅 Sesi 7 Hari Terakhir'),
          const SizedBox(height: 12),
          _buildBarChart(),

          const SizedBox(height: 24),

          // ── Streak & Life ────────────────────────────
          _buildSectionTitle('🔥 Streak & Lives'),
          const SizedBox(height: 12),
          _buildStreakCard(),

          const SizedBox(height: 24),

          // ── Kebiasaan ────────────────────────────────
          _buildSectionTitle('💡 Kebiasaan Belajar'),
          const SizedBox(height: 12),
          _buildHabitsRow(),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'BlackHanSans',
        fontSize: 16,
        color: Color(0xFF111111),
        letterSpacing: 0.3,
      ),
    );
  }

  // ── Level Card ──────────────────────────────────────────
  Widget _buildLevelCard() {
    final levelIndex = (_currentLevel - 1).clamp(0, 4);
    final color = _levelColors[levelIndex];
    final nextThreshold = _currentLevel < 5 ? _levelThresholds[_currentLevel] : _totalSessionsStreak;
    final prevThreshold = _levelThresholds[levelIndex];
    final progressInLevel = _totalSessionsStreak - prevThreshold;
    final totalInLevel = nextThreshold - prevThreshold;
    final ratio = totalInLevel <= 0 ? 1.0 : (progressInLevel / totalInLevel).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF111111), width: 2.5),
        boxShadow: const [BoxShadow(color: Color(0xFF111111), offset: Offset(4, 4), blurRadius: 0)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF111111), width: 2),
                ),
                child: Center(
                  child: Text(
                    '$_currentLevel',
                    style: const TextStyle(
                      fontFamily: 'BlackHanSans',
                      fontSize: 22,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _levelName,
                      style: const TextStyle(
                        fontFamily: 'BlackHanSans',
                        fontSize: 18,
                        color: Color(0xFF111111),
                      ),
                    ),
                    Text(
                      _currentLevel < 5
                          ? '$_totalSessionsStreak / $nextThreshold sesi'
                          : 'Level Maksimal 🎉',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 13,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ),
              if (_currentLevel < 5)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2EA05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF111111), width: 1.5),
                  ),
                  child: Text(
                    '$_sessionsToNext sesi lagi',
                    style: const TextStyle(
                      fontFamily: 'BlackHanSans',
                      fontSize: 11,
                      color: Color(0xFF111111),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 10,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E5E5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF111111), width: 1.5),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: ratio,
                child: Container(color: color),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── XP per level list ───────────────────────────────────
  Widget _buildXpPerLevelList() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF111111), width: 2),
        boxShadow: const [BoxShadow(color: Color(0xFF111111), offset: Offset(4, 4), blurRadius: 0)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'XP Bonus per Level',
            style: TextStyle(fontFamily: 'BlackHanSans', fontSize: 14, color: Color(0xFF111111)),
          ),
          const SizedBox(height: 12),
          ...List.generate(5, (i) {
            final levelNum = i + 1;
            final color = _levelColors[i];
            final isUnlocked = levelNum <= _currentLevel;
            final isEarned = levelNum > 1 && levelNum <= _currentLevel;
            final xpReward = levelNum > 1 ? _levelXpRewards[i] : 0;
            final awardXp = _xpAtLevel(levelNum);
            final isTappable = isUnlocked && levelNum < _currentLevel;

            return GestureDetector(
              onTap: isTappable ? () => _showLevelHistory(context, levelNum) : null,
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: isTappable ? const EdgeInsets.all(6) : EdgeInsets.zero,
                decoration: isTappable
                    ? BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF1EE86F), width: 1.5),
                      )
                    : null,
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isUnlocked ? color : const Color(0xFFE5E5E5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isUnlocked ? const Color(0xFF111111) : const Color(0xFFCCCCCC),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$levelNum',
                          style: TextStyle(
                            fontFamily: 'BlackHanSans',
                            fontSize: 14,
                            color: isUnlocked ? Colors.white : const Color(0xFFAAAAAA),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _levelNames[i],
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isUnlocked ? const Color(0xFF111111) : const Color(0xFFAAAAAA),
                            ),
                          ),
                          Text(
                            levelNum == 1
                                ? 'Level awal'
                                : isEarned
                                    ? 'Bonus +$awardXp XP diterima ✓'
                                    : 'Bonus +$xpReward XP saat naik level',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 11,
                              color: isEarned
                                  ? const Color(0xFF1A9A50)
                                  : const Color(0xFF888888),
                            ),
                          ),
                          if (isTappable)
                            const Text(
                              'Tap untuk lihat riwayat →',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 10,
                                color: Color(0xFF1A9A50),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (levelNum == _currentLevel)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2EA05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF111111), width: 1.5),
                        ),
                        child: const Text(
                          'Sekarang',
                          style: TextStyle(fontFamily: 'BlackHanSans', fontSize: 10, color: Color(0xFF111111)),
                        ),
                      )
                    else if (isEarned)
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF1EE86F), size: 22)
                    else
                      const Icon(Icons.lock_outline_rounded, color: Color(0xFFCCCCCC), size: 22),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

    // ── Summary grid ────────────────────────────────────────
  Widget _buildSummaryGrid() {
    final items = [
      {'icon': '📚', 'label': 'Total Sesi', 'value': '$_totalSessions'},
      {'icon': '⏱️', 'label': 'Total Belajar', 'value': _formatMinutes(_totalMinutes)},
      {'icon': '⌀', 'label': 'Rata-rata Sesi', 'value': '${_avgDuration.toStringAsFixed(0)}m'},
      {'icon': '🎯', 'label': 'Focus Rate', 'value': '${_focusRate.toStringAsFixed(0)}%'},
      {'icon': '📈', 'label': 'Minggu Ini', 'value': '$_sessionsThisWeek sesi'},
      {'icon': '📉', 'label': 'Minggu Lalu', 'value': '$_sessionsLastWeek sesi'},
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          mainAxisExtent: 110,
        ),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (_, i) => _buildStatCard(
          icon: items[i]['icon']!,
          label: items[i]['label']!,
          value: items[i]['value']!,
        ),
      ),
    );
  }

  Widget _buildStatCard({required String icon, required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF111111), width: 2),
        boxShadow: const [BoxShadow(color: Color(0xFF111111), offset: Offset(3, 3), blurRadius: 0)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'BlackHanSans',
              fontSize: 18,
              color: Color(0xFF111111),
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 11,
              color: Color(0xFF888888),
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  // ── Bar chart 7 hari ────────────────────────────────────
  Widget _buildBarChart() {
    if (_sessionsPerDay.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxVal = _sessionsPerDay.values.fold(0, (a, b) => a > b ? a : b);
    final days = _sessionsPerDay.keys.toList();
    final dayLabels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF111111), width: 2),
        boxShadow: const [BoxShadow(color: Color(0xFF111111), offset: Offset(4, 4), blurRadius: 0)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: days.asMap().entries.map((entry) {
              final val = _sessionsPerDay[entry.value] ?? 0;
              final ratio = maxVal == 0 ? 0.0 : val / maxVal;
              final isToday = entry.key == days.length - 1;

              // Get day label (Mon-Sun)
              final date = DateTime.tryParse(entry.value);
              final label = date != null ? dayLabels[date.weekday - 1] : '?';

              return Expanded(
                child: Column(
                  children: [
                    Text(
                      val > 0 ? '$val' : '',
                      style: const TextStyle(
                        fontFamily: 'BlackHanSans',
                        fontSize: 11,
                        color: Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 80,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: ratio == 0 ? 0.04 : ratio,
                        child: Container(
                          decoration: BoxDecoration(
                            color: isToday ? const Color(0xFF1EE86F) : const Color(0xFFF2EA05),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF111111), width: 1.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 11,
                        fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                        color: isToday ? const Color(0xFF1A9A50) : const Color(0xFF888888),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Streak card ─────────────────────────────────────────
  Widget _buildStreakCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF111111), width: 2.5),
        boxShadow: const [BoxShadow(color: Color(0xFF111111), offset: Offset(4, 4), blurRadius: 0)],
      ),
      child: Row(
        children: [
          // Streak
          Expanded(
            child: Column(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 32)),
                const SizedBox(height: 4),
                Text(
                  '$_currentStreak',
                  style: const TextStyle(
                    fontFamily: 'BlackHanSans',
                    fontSize: 32,
                    color: Color(0xFF111111),
                  ),
                ),
                const Text(
                  'hari berturut',
                  style: TextStyle(fontFamily: 'Nunito', fontSize: 12, color: Color(0xFF888888)),
                ),
              ],
            ),
          ),
          Container(width: 1.5, height: 70, color: const Color(0xFFDDDDDD)),
          // Lives
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Text(
                      i < _life ? '❤️' : '🖤',
                      style: const TextStyle(fontSize: 20),
                    ),
                  )),
                ),
                const SizedBox(height: 6),
                Text(
                  '$_life / 3 lives',
                  style: const TextStyle(
                    fontFamily: 'BlackHanSans',
                    fontSize: 16,
                    color: Color(0xFF111111),
                  ),
                ),
                const Text(
                  'sisa nyawa',
                  style: TextStyle(fontFamily: 'Nunito', fontSize: 12, color: Color(0xFF888888)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Habits row ──────────────────────────────────────────
  Widget _buildHabitsRow() {
    final moodEmoji = _moodEmoji(_favoriteMood);
    final locationEmoji = _locationEmoji(_favoriteLocation);

    return Row(
      children: [
        Expanded(
          child: _buildHabitCard(
            emoji: moodEmoji,
            label: 'Mood Favorit',
            value: _favoriteMood == 'none' || _favoriteMood == '-' ? 'Belum ada' : _favoriteMood,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildHabitCard(
            emoji: locationEmoji,
            label: 'Lokasi Favorit',
            value: _favoriteLocation == 'none' || _favoriteLocation == '-' ? 'Belum ada' : _favoriteLocation,
          ),
        ),
      ],
    );
  }

  Widget _buildHabitCard({required String emoji, required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF111111), width: 2),
        boxShadow: const [BoxShadow(color: Color(0xFF111111), offset: Offset(3, 3), blurRadius: 0)],
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'BlackHanSans',
              fontSize: 13,
              color: Color(0xFF111111),
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontFamily: 'Nunito', fontSize: 11, color: Color(0xFF888888)),
          ),
        ],
      ),
    );
  }

  String _moodEmoji(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy': case 'senang': return '😊';
      case 'sad': case 'sedih': return '😢';
      case 'stressed': case 'stres': return '😤';
      case 'calm': case 'tenang': return '😌';
      case 'excited': case 'semangat': return '🤩';
      case 'tired': case 'lelah': return '😴';
      default: return '😐';
    }
  }

  String _locationEmoji(String loc) {
    switch (loc.toLowerCase()) {
      case 'home': case 'rumah': return '🏠';
      case 'library': case 'perpustakaan': return '📚';
      case 'cafe': case 'kafe': return '☕';
      case 'school': case 'sekolah': case 'campus': case 'kampus': return '🏫';
      default: return '📍';
    }
  }

  // ── Level History Bottom Sheet ─────────────────────────────────────────
  Future<void> _showLevelHistory(BuildContext context, int level) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LevelHistorySheet(level: level),
    );
  }

}

// ── _LevelHistorySheet ───────────────────────────────────────────────────────

class _LevelHistorySheet extends StatefulWidget {
  final int level;
  const _LevelHistorySheet({required this.level});

  @override
  State<_LevelHistorySheet> createState() => _LevelHistorySheetState();
}

class _LevelHistorySheetState extends State<_LevelHistorySheet> {
  bool _loading = true;
  Map<String, dynamic>? _data;
  String? _error;

  static const _levelNames = ['Beginner', 'Learner', 'Practitioner', 'Expert', 'Master'];
  static const _levelColors = [
    Color(0xFFCD7F32),
    Color(0xFFC0C0C0),
    Color(0xFFFFD700),
    Color(0xFF00CEC9),
    Color(0xFFA29BFE),
  ];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<Either<Failure, Map<String, dynamic>?>> _fetchHistory() async {
    try {
      final token = AuthService.token;
      final baseUrl = StreakService.baseUrl;
      final res = await http.get(
        Uri.parse('$baseUrl/api/streak/level-history/${widget.level}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (res.statusCode == 200) {
        return Right(jsonDecode(res.body) as Map<String, dynamic>);
      }
      return Left(NetworkFailure('Gagal memuat data'));
    } catch (e) {
      return Left(NetworkFailure(sanitizeException(e)));
    }
  }

  Future<void> _loadHistory() async {
    final result = await _fetchHistory();
    if (!mounted) return;
    result.fold(
      (failure) => setState(() { _error = failure.message; _loading = false; }),
      (data) => setState(() { _data = data; _loading = false; }),
    );
  }

  String _formatMinutes(int m) {
    if (m < 60) return '${m}m';
    return '${m ~/ 60}j ${m % 60}m';
  }

  String _moodEmoji(String? mood) {
    switch ((mood ?? '').toLowerCase()) {
      case 'happy': case 'senang': return '😊';
      case 'sad': case 'sedih': return '😢';
      case 'stressed': case 'stres': return '😤';
      case 'calm': case 'tenang': return '😌';
      case 'excited': case 'semangat': return '🤩';
      case 'tired': case 'lelah': return '😴';
      default: return '😐';
    }
  }

  @override
  Widget build(BuildContext context) {
    final idx = widget.level - 1;
    final color = _levelColors[idx.clamp(0, 4)];
    final name = _levelNames[idx.clamp(0, 4)];

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF5F5F0),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(color: Color(0xFF111111), width: 3),
            left: BorderSide(color: Color(0xFF111111), width: 3),
            right: BorderSide(color: Color(0xFF111111), width: 3),
          ),
        ),
        child: Column(
          children: [
            // Handle
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCCCCCC),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF111111), width: 2),
                    ),
                    child: Center(
                      child: Text('${widget.level}',
                        style: const TextStyle(
                          fontFamily: 'BlackHanSans', fontSize: 18, color: Colors.white,
                        )),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Level ${widget.level} — $name',
                        style: const TextStyle(
                          fontFamily: 'BlackHanSans', fontSize: 16, color: Color(0xFF111111),
                        )),
                      if (_data != null)
                        Text(
                          _data!['startedAt'] != null
                              ? 'Mulai ${_data!['startedAt']}${_data!['completedAt'] != null ? ' · Selesai ${_data!['completedAt']}' : ''}'
                              : '',
                          style: const TextStyle(fontFamily: 'Nunito', fontSize: 11, color: Color(0xFF888888)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Content
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF1EE86F)))
                  : _error != null
                      ? Center(child: Text(_error!, style: const TextStyle(fontFamily: 'Nunito', color: Color(0xFF888888))))
                      : _buildContent(controller),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ScrollController controller) {
    final sessions = (_data!['sessions'] as List<dynamic>? ?? [])
        .map((e) => e as Map<String, dynamic>)
        .toList();

    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      children: [
        // Ringkasan
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF111111), width: 2),
            boxShadow: const [BoxShadow(color: Color(0xFF111111), offset: Offset(3, 3), blurRadius: 0)],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _summaryItem('📚', '${_data!['totalSessions']}', 'Total Sesi'),
              Container(width: 1, height: 40, color: const Color(0xFFDDDDDD)),
              _summaryItem('⏱️', _formatMinutes((_data!['totalMinutes'] as num).toInt()), 'Total Belajar'),
              Container(width: 1, height: 40, color: const Color(0xFFDDDDDD)),
              _summaryItem('⚡', '+${_data!['xpBonus']} XP', 'Bonus'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text('Sesi Belajar',
          style: TextStyle(fontFamily: 'BlackHanSans', fontSize: 14, color: Color(0xFF111111))),
        const SizedBox(height: 12),
        if (sessions.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Belum ada sesi di level ini',
                style: TextStyle(fontFamily: 'Nunito', fontSize: 13, color: Color(0xFF888888))),
            ),
          )
        else
          ...sessions.asMap().entries.map((entry) {
            final i = entry.key;
            final s = entry.value;
            final distraction = ((s['distractionSeconds'] as num?)?.toInt() ?? 0);
            final distractionCount = distraction == 0 ? 0 : (distraction / 30).ceil();

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFDDDDDD), width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2EA05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF111111), width: 1.5),
                    ),
                    child: Center(
                      child: Text('${i + 1}',
                        style: const TextStyle(fontFamily: 'BlackHanSans', fontSize: 13, color: Color(0xFF111111))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s['startTime'] ?? '',
                          style: const TextStyle(fontFamily: 'Nunito', fontSize: 12, color: Color(0xFF888888))),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text('⏱ ${_formatMinutes((s['durationMinutes'] as num).toInt())}',
                              style: const TextStyle(fontFamily: 'BlackHanSans', fontSize: 13, color: Color(0xFF111111))),
                            const SizedBox(width: 10),
                            Text(_moodEmoji(s['mood'] as String?),
                              style: const TextStyle(fontSize: 14)),
                            if (distractionCount > 0) ...[
                              const SizedBox(width: 6),
                              Text('⚠️ $distractionCount×',
                                style: const TextStyle(fontFamily: 'Nunito', fontSize: 11, color: Color(0xFFEF5350))),
                            ],
                          ],
                        ),
                        if ((s['files'] as List<dynamic>? ?? []).isNotEmpty) ...[
                          const SizedBox(height: 6),
                          ...(s['files'] as List<dynamic>).map((f) {
                            final file = f as Map<String, dynamic>;
                            return Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Row(children: [
                                const Icon(Icons.insert_drive_file_outlined, size: 13, color: Color(0xFF888888)),
                                const SizedBox(width: 4),
                                Expanded(child: Text(
                                  file['fileName'] as String? ?? '',
                                  style: const TextStyle(fontFamily: 'Nunito', fontSize: 11, color: Color(0xFF666666)),
                                  overflow: TextOverflow.ellipsis,
                                )),
                              ]),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _summaryItem(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontFamily: 'BlackHanSans', fontSize: 14, color: Color(0xFF111111))),
        Text(label, style: const TextStyle(fontFamily: 'Nunito', fontSize: 10, color: Color(0xFF888888))),
      ],
    );
  }
}