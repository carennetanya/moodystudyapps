import 'package:flutter/material.dart';
import 'package:dartz/dartz.dart' hide State;
import 'package:moody_study/core/error/exception_mapper.dart';
import 'package:moody_study/core/error/failures.dart';
import '../models/daily_quest_model.dart';
import '../services/daily_quest_service.dart';
import '../utils/app_localizations.dart';

/// Layar Daily Quest — menampilkan 3 quest harian dan progress Coin hari ini.
/// Tambahkan navigasi ke screen ini dari home/character_intro dengan:
///   Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyQuestScreen()));
class DailyQuestScreen extends StatefulWidget {
  const DailyQuestScreen({super.key});

  @override
  State<DailyQuestScreen> createState() => _DailyQuestScreenState();
}

class _DailyQuestScreenState extends State<DailyQuestScreen> {
  DailyQuestModel? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadQuests();
  }

  Future<Either<AppFailure, DailyQuestModel>> _fetchQuests() async {
    try {
      return Right(await DailyQuestService.getDailyQuests());
    } catch (e) {
      return Left(ExceptionMapper.map(e));
    }
  }

  Future<void> _loadQuests() async {
    setState(() { _loading = true; _error = null; });
    final result = await _fetchQuests();
    if (!mounted) return;
    result.fold(
      (failure) => setState(() { _error = failure.localizedMessage(context); _loading = false; }),
      (data) => setState(() { _data = data; _loading = false; }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF1EE86F)))
                  : _error != null
                      ? _buildError(context)
                      : _buildBody(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        color: Color(0xFFF2EA05),
        border: Border(
          bottom: BorderSide(color: Color(0xFF111111), width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(Icons.arrow_back, size: 24, color: Color(0xFF111111)),
              ),
              const SizedBox(width: 12),
              const Text(
                'Daily Quest',
                style: TextStyle(
                  fontFamily: 'BlackHanSans',
                  fontSize: 22,
                  color: Color(0xFF111111),
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              // Coin Badge
              if (_data != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('⚡', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 4),
                      Text(
                        '${_data!.todayCoins} / ${_data!.maxCoins} Coins',
                        style: const TextStyle(
                          fontFamily: 'BlackHanSans',
                          fontSize: 14,
                          color: Color(0xFFF2EA05),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _data != null
                ? '${l.questSubtitle} • ${_data!.questDate}'
                : l.questSubtitle,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              color: Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Color(0xFFDD2C00)),
            const SizedBox(height: 12),
            Text(
              _error ?? l.questError,
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Nunito', fontSize: 14, color: Color(0xFF555555)),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _loadQuests,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2EA05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF111111), width: 2),
                  boxShadow: const [
                    BoxShadow(color: Color(0xFF111111), offset: Offset(3, 3), blurRadius: 0),
                  ],
                ),
                child: Text(
                  l.questRetry,
                  style: const TextStyle(
                    fontFamily: 'BlackHanSans',
                    fontSize: 14,
                    color: Color(0xFF111111),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final l = AppLocalizations.of(context);
    final quests = _data?.quests ?? [];
    final completedCount = quests.where((q) => q.completed).length;
    final allDone = completedCount == quests.length && quests.isNotEmpty;

    return RefreshIndicator(
      color: const Color(0xFF1EE86F),
      onRefresh: _loadQuests,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Progress bar
          _buildProgressBar(completedCount, quests.length),
          const SizedBox(height: 8),
          Text(
            allDone
                ? l.questAllDone
                : l.questProgress(completedCount, quests.length),
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: allDone ? const Color(0xFF1EE86F) : const Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 20),
          // Quest cards
          ...quests.map((q) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _QuestCard(quest: q),
          )),
          const SizedBox(height: 12),
          // Info text
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFDDDDDD), width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 18, color: Color(0xFF888888)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l.questInfo,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      color: Color(0xFF666666),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(int done, int total) {
    final ratio = total == 0 ? 0.0 : done / total;
    return Container(
      height: 10,
      decoration: BoxDecoration(
        color: const Color(0xFFDDDDDD),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF111111), width: 1.5),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: ratio,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1EE86F),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}

// ─── Quest Card Widget ────────────────────────────────────────────────────────

class _QuestCard extends StatelessWidget {
  final QuestItem quest;

  const _QuestCard({required this.quest});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final done = quest.completed;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: done ? const Color(0xFFE8FFF1) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: done ? const Color(0xFF1EE86F) : const Color(0xFF111111),
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: done ? const Color(0xFF1EE86F) : const Color(0xFF111111),
            offset: const Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: done ? const Color(0xFF1EE86F) : const Color(0xFFF5F5F0),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF111111), width: 2),
            ),
            child: Icon(
              done ? Icons.check_rounded : _getQuestIcon(quest.questKey),
              color: const Color(0xFF111111),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        quest.title,
                        style: TextStyle(
                          fontFamily: 'BlackHanSans',
                          fontSize: 15,
                          color: const Color(0xFF111111),
                          decoration: done ? TextDecoration.lineThrough : null,
                          decorationColor: const Color(0xFF111111),
                        ),
                      ),
                    ),
                    // Coin chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: done ? const Color(0xFF1EE86F) : const Color(0xFFF2EA05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF111111), width: 1.5),
                      ),
                      child: Text(
                        '+${quest.coinReward} Coins',
                        style: const TextStyle(
                          fontFamily: 'BlackHanSans',
                          fontSize: 11,
                          color: Color(0xFF111111),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  quest.description,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    color: done ? const Color(0xFF444444) : const Color(0xFF666666),
                    height: 1.4,
                  ),
                ),
                if (done) ...[
                  const SizedBox(height: 6),
                  Text(
                    '✓ ${l.questCompleted}',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A9A50),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getQuestIcon(String key) {
    switch (key) {
      case 'FIRST_SESSION':
        return Icons.play_circle_outline;
      case 'ZERO_DISTRACTION':
        return Icons.center_focus_strong;
      case 'MARATHON':
        return Icons.directions_run;
      case 'LONG_FOCUS':
        return Icons.timer;
      case 'TOLERANCE_LIMIT':
        return Icons.tune;
      case 'MORNING_WARRIOR':
        return Icons.wb_sunny_outlined;
      case 'NIGHT_FIGHTER':
        return Icons.nightlight_round;
      case 'DOUBLE_SESSION':
        return Icons.library_books_outlined;
      case 'CONSISTENCY_HOUR':
        return Icons.access_time;
      case 'REVIEW_STATS':
        return Icons.bar_chart;
      default:
        return Icons.task_alt;
    }
  }
}