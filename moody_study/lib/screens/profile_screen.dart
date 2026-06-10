import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moody_study/services/api_client.dart';
import 'package:moody_study/services/user_provider.dart';
import 'package:moody_study/utils/app_localizations.dart';
import 'edit_profile_screen.dart';
import 'collection_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _kBlack  = Color(0xFF111111);
  static const _kYellow = Color(0xFFF2EA05);
  static const _kGreen  = Color(0xFF1EE86F);
  static const _kBg     = Color(0xFFF5F5F0);

  static const _skinAvatarMap = {
    's_fair':  'fair.png',
    's_warm':  'warm-beige.png',
    's_honey': 'honey.png',
    's_brown': 'brown-sugar.png',
    's_deep':  'deep.png',
  };

  String _activeSkinId = 's_fair';
  int _currentStreak = 0;
  int _totalCoins = 0;
  String _streakLevel = 'BEGINNER';
  bool _loading = true;

  String get _currentAvatarFile =>
      _skinAvatarMap[_activeSkinId] ?? 'fair.png';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadActiveSkin(),
      _loadStreakData(),
    ]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadActiveSkin() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('active_skin_id');
    if (saved != null && _skinAvatarMap.containsKey(saved)) {
      if (mounted) setState(() => _activeSkinId = saved);
    }
  }

  Future<void> _loadStreakData() async {
    try {
      final res = await ApiClient.dio.get('/api/streak');
      final body = res.data as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _currentStreak = (body['currentStreak'] as num?)?.toInt() ?? 0;
          _totalCoins    = (body['totalCoins'] as num?)?.toInt() ?? 0;
          _streakLevel   = (body['level'] as String?) ?? 'BEGINNER';
        });
      }
    } catch (_) {}
  }

  String _levelLabel(String level, AppLocalizations l) {
    switch (level.toUpperCase()) {
      case 'LEARNER':      return l.levelLearner;
      case 'PRACTITIONER': return l.levelPractitioner;
      case 'EXPERT':       return l.levelExpert;
      case 'MASTER':       return l.levelMaster;
      default:             return l.levelBeginner;
    }
  }

  int _levelNumber(String level) {
    switch (level.toUpperCase()) {
      case 'LEARNER':      return 2;
      case 'PRACTITIONER': return 3;
      case 'EXPERT':       return 4;
      case 'MASTER':       return 5;
      default:             return 1;
    }
  }

  Color _levelColor(String level) {
    switch (level.toUpperCase()) {
      case 'LEARNER':      return const Color(0xFF4CAF50);
      case 'PRACTITIONER': return const Color(0xFF2196F3);
      case 'EXPERT':       return const Color(0xFF9C27B0);
      case 'MASTER':       return const Color(0xFFFF6F00);
      default:             return const Color(0xFF9E9E9E);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final name  = userProvider.name  ?? '—';
    final email = userProvider.email ?? '—';

    return Scaffold(
      backgroundColor: _kBg,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: _kYellow, strokeWidth: 3),
            )
          : CustomScrollView(
              slivers: [
                // ── Header (avatar area + appbar) ──────────────────────────
                SliverAppBar(
                  expandedHeight: 280,
                  pinned: true,
                  backgroundColor: _kYellow,
                  elevation: 0,
                  leading: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: _kBlack, width: 2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.arrow_back, color: _kBlack, size: 20),
                    ),
                  ),
                  actions: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const EditProfileScreen(),
                        ),
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: _kBlack, width: 2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.settings_rounded, color: _kBlack, size: 20),
                      ),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      color: _kYellow,
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          // Decorative dots
                          Positioned(
                            top: 60, left: 20,
                            child: _Dot(size: 10, color: _kBlack.withOpacity(0.08)),
                          ),
                          Positioned(
                            top: 90, right: 40,
                            child: _Dot(size: 14, color: _kBlack.withOpacity(0.06)),
                          ),
                          Positioned(
                            top: 130, left: 60,
                            child: _Dot(size: 8, color: _kBlack.withOpacity(0.07)),
                          ),
                          // Avatar — tap to open CollectionScreen (Edit Avatar)
                          Positioned(
                            bottom: 0,
                            child: GestureDetector(
                              onTap: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const CollectionScreen(),
                                  ),
                                );
                                // Reload skin after returning from collection
                                _loadActiveSkin().then((_) {
                                  if (mounted) setState(() {});
                                });
                              },
                              child: Stack(
                                alignment: Alignment.bottomCenter,
                                children: [
                                  SizedBox(
                                    height: 200,
                                    child: Image.asset(
                                      'assets/images/avatars/$_currentAvatarFile',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  // Edit badge
                                  Positioned(
                                    bottom: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _kBlack,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.edit_rounded, color: _kYellow, size: 10),
                                          const SizedBox(width: 4),
                                          Text(
                                            AppLocalizations.of(context).profileEditAvatar,
                                            style: const TextStyle(
                                              fontFamily: 'Nunito',
                                              fontSize: 9,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── White card body ────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: _kBg,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Name + email block ──────────────────────────
                          _InfoBlock(
                            children: [
                              _InfoRow(label: AppLocalizations.of(context).profileFullName, value: name),
                              const _Divider(),
                              _InfoRow(label: AppLocalizations.of(context).profileEmailLabel, value: email),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // ── Ringkasan block ─────────────────────────────
                          _SectionLabel(label: AppLocalizations.of(context).profileSummary),
                          const SizedBox(height: 10),
                          _InfoBlock(
                            children: [
                              _StatRow(
                                emoji: '🔥',
                                value: '$_currentStreak ${AppLocalizations.of(context).profileStreakDays}',
                                label: AppLocalizations.of(context).profileStreakLabel,
                              ),
                              const _Divider(),
                              _StatRow(
                                emoji: '🪙',
                                value: '$_totalCoins',
                                label: AppLocalizations.of(context).profileCoinsOwned,
                              ),
                              const _Divider(),
                              _LevelRow(
                                level: _levelNumber(_streakLevel),
                                label: _levelLabel(_streakLevel, AppLocalizations.of(context)),
                                color: _levelColor(_streakLevel),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // ── Edit profile button ─────────────────────────
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const EditProfileScreen(),
                                ),
                              ),
                              icon: const Icon(Icons.edit_rounded, size: 16),
                              label: Text(
                                AppLocalizations.of(context).profileEditButton,
                                style: const TextStyle(
                                  fontFamily: 'BlackHanSans',
                                  fontSize: 14,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _kYellow,
                                foregroundColor: _kBlack,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(color: _kBlack, width: 2),
                                ),
                                elevation: 3,
                                shadowColor: _kBlack,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// ─── Reusable widgets ──────────────────────────────────────────────────────────

class _Dot extends StatelessWidget {
  final double size;
  final Color color;
  const _Dot({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final List<Widget> children;
  const _InfoBlock({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFF111111), width: 2),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Color(0xFF111111), offset: Offset(3, 3), blurRadius: 0),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: 'BlackHanSans',
        fontSize: 13,
        color: Color(0xFF111111),
        letterSpacing: 1.2,
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Divider(color: Color(0xFF111111), thickness: 1.5, height: 1),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'BlackHanSans',
              fontSize: 11,
              color: Color(0xFF111111),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              color: Color(0xFF333333),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  const _StatRow({required this.emoji, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'BlackHanSans',
                  fontSize: 16,
                  color: Color(0xFF111111),
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 11,
                  color: Color(0xFF888888),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LevelRow extends StatelessWidget {
  final int level;
  final String label;
  final Color color;
  const _LevelRow({required this.level, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Level badge (neobrutalist)
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: const Color(0xFF111111), width: 2),
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(color: Color(0xFF111111), offset: Offset(2, 2), blurRadius: 0),
              ],
            ),
            child: Center(
              child: Text(
                '$level',
                style: const TextStyle(
                  fontFamily: 'BlackHanSans',
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'BlackHanSans',
                  fontSize: 16,
                  color: Color(0xFF111111),
                ),
              ),
              Text(
                AppLocalizations.of(context).profileStreakLevel,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 11,
                  color: Color(0xFF888888),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}