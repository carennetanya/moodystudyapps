import 'dart:math';
import 'package:flutter/material.dart';

/// Data yang diterima dari /api/streak/check-login
class LoginCheckResult {
  final int currentLife;
  final int livesLost;
  final int daysSkipped;
  final bool leveledDown;
  final String previousLevel;
  final String currentLevel;
  final int sessionsToRecoverLife;
  final int sessionsCompletedToday;

  const LoginCheckResult({
    required this.currentLife,
    required this.livesLost,
    required this.daysSkipped,
    required this.leveledDown,
    required this.previousLevel,
    required this.currentLevel,
    required this.sessionsToRecoverLife,
    required this.sessionsCompletedToday,
  });

  factory LoginCheckResult.fromJson(Map<String, dynamic> json) {
    return LoginCheckResult(
      currentLife: (json['currentLife'] as num?)?.toInt() ?? 3,
      livesLost: (json['livesLost'] as num?)?.toInt() ?? 0,
      daysSkipped: (json['daysSkipped'] as num?)?.toInt() ?? 0,
      leveledDown: json['leveledDown'] as bool? ?? false,
      previousLevel: json['previousLevel'] as String? ?? '',
      currentLevel: json['currentLevel'] as String? ?? '',
      sessionsToRecoverLife: (json['sessionsToRecoverLife'] as num?)?.toInt() ?? 2,
      sessionsCompletedToday: (json['sessionsCompletedToday'] as num?)?.toInt() ?? 0,
    );
  }
}

String _levelDisplayName(String level) {
  switch (level.toUpperCase()) {
    case 'BEGINNER':
      return 'Beginner';
    case 'LEARNER':
      return 'Learner';
    case 'PRACTITIONER':
      return 'Practitioner';
    case 'EXPERT':
      return 'Expert';
    case 'MASTER':
      return 'Master';
    default:
      return level;
  }
}

/// Tampilkan popup kalau ada nyawa yang hilang.
/// Panggil ini dari character_intro_screen setelah check-login.
Future<void> showLifeLostPopup(BuildContext context, LoginCheckResult result) async {
  if (result.livesLost <= 0 && !result.leveledDown) return;

  if (result.livesLost > 0) {
    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.6),
      pageBuilder: (_, __, ___) => _LifeLostPopup(result: result),
    );
  }

  if (result.leveledDown) {
    await showLevelDownPopup(context, result);
  }
}

Future<void> showLifeRecoveredPopup(BuildContext context, int totalLife) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.favorite, size: 52, color: Color(0xFFEF5350)),
          const SizedBox(height: 18),
          const Text(
            'Life Restored!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            totalLife >= 3
                ? 'Your lives are now full at 3.'
                : 'Your total lives are now $totalLife.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, color: Color(0xFF444444), height: 1.5),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF2EA05),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF111111), width: 2.5),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Text('Great, keep going!', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ],
    ),
  );
}

Future<void> showLevelDownPopup(BuildContext context, LoginCheckResult result) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.arrow_downward, size: 52, color: Color(0xFFFFA726)),
          const SizedBox(height: 18),
          const Text(
            'Level Down!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your level dropped from ${_levelDisplayName(result.previousLevel)} to ${_levelDisplayName(result.currentLevel)}.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, color: Color(0xFF444444), height: 1.5),
          ),
          const SizedBox(height: 12),
          const Text(
            'Recover your focus and rebuild your streak to climb back up.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF777777), height: 1.5),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF2EA05),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF111111), width: 2.5),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Text('Okay, I understand', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ],
    ),
  );
}

class _LifeLostPopup extends StatefulWidget {
  final LoginCheckResult result;
  const _LifeLostPopup({required this.result});

  @override
  State<_LifeLostPopup> createState() => _LifeLostPopupState();
}

class _LifeLostPopupState extends State<_LifeLostPopup>
    with TickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final AnimationController _crackCtrl;
  late final AnimationController _shakeCtrl;
  late final Animation<double> _entryScale;
  late final Animation<double> _crackProgress;
  late final Animation<double> _shake;

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _crackCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));

    _entryScale = CurvedAnimation(parent: _entryCtrl, curve: const Cubic(0.34, 1.56, 0.64, 1));
    _crackProgress = CurvedAnimation(parent: _crackCtrl, curve: Curves.easeOutCubic);
    _shake = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticOut),
    );

    _playSequence();
  }

  Future<void> _playSequence() async {
    await Future.delayed(const Duration(milliseconds: 150));
    _entryCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _shakeCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 100));
    _crackCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _crackCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  String _levelDisplayName(String level) {
    switch (level.toUpperCase()) {
      case 'BEGINNER': return 'Beginner';
      case 'LEARNER': return 'Learner';
      case 'PRACTITIONER': return 'Practitioner';
      case 'EXPERT': return 'Expert';
      case 'MASTER': return 'Master';
      default: return level;
    }
  }

  @override
  Widget build(BuildContext context) {
    final livesLost = widget.result.livesLost;
    final currentLife = widget.result.currentLife;
    final leveledDown = widget.result.leveledDown;
    final daysSkipped = widget.result.daysSkipped;
    final sessionsNeeded = widget.result.sessionsToRecoverLife * livesLost
        - widget.result.sessionsCompletedToday;

    return Center(
      child: ScaleTransition(
        scale: _entryScale,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFDE7),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFF111111), width: 3),
            boxShadow: const [
              BoxShadow(color: Color(0xFF111111), offset: Offset(6, 6), blurRadius: 0),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Judul
              Text(
                daysSkipped == 1 ? 'Kamu Bolos Kemarin! 😤' : 'Kamu Bolos $daysSkipped Hari! 😤',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'BlackHanSans',
                  fontSize: 20,
                  color: Color(0xFF111111),
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 20),

              // Animasi hati retak
              AnimatedBuilder(
                animation: Listenable.merge([_crackProgress, _shake]),
                builder: (_, __) {
                  final shakeOffset = sin(_shakeCtrl.value * pi * 6) * 6 * (1 - _shakeCtrl.value);
                  return Transform.translate(
                    offset: Offset(shakeOffset, 0),
                    child: _HeartsRow(
                      totalLives: 3,
                      currentLife: currentLife,
                      livesLost: livesLost,
                      crackProgress: _crackProgress.value,
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // Life lost info
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFEF5350), width: 1.5),
                ),
                child: Text(
                  livesLost == 1
                      ? '−1 life lost'
                      : '−$livesLost lives lost',
                  style: const TextStyle(
                    fontFamily: 'BlackHanSans',
                    fontSize: 16,
                    color: Color(0xFFEF5350),
                    letterSpacing: 0.3,
                  ),
                ),
              ),

              // Level down info
              if (leveledDown) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFFA726), width: 1.5),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        '⚠️ Level Turun!',
                        style: TextStyle(
                          fontFamily: 'BlackHanSans',
                          fontSize: 14,
                          color: Color(0xFFE65100),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_levelDisplayName(widget.result.previousLevel)} → ${_levelDisplayName(widget.result.currentLevel)}',
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 13,
                          color: Color(0xFF555555),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Info cara pulihkan nyawa
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8FFF1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF1EE86F), width: 1.5),
                ),
                child: Column(
                  children: [
                    const Text(
                      '💪 Life Recovery Guide',
                      style: TextStyle(
                        fontFamily: 'BlackHanSans',
                        fontSize: 13,
                        color: Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Complete ${widget.result.sessionsToRecoverLife} study sessions\nto restore 1 life',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        color: Color(0xFF444444),
                        height: 1.5,
                      ),
                    ),
                    if (livesLost > 1) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Need $sessionsNeeded study sessions to restore all lives',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 11,
                          color: Color(0xFF888888),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Tombol
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(color: Color(0xFF444444), offset: Offset(0, 4), blurRadius: 8),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      '💪 Okay, let’s go!',
                      style: TextStyle(
                        fontFamily: 'BlackHanSans',
                        fontSize: 15,
                        color: Color(0xFFF2EA05),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Hearts Row dengan animasi retak ─────────────────────────────────────────
class _HeartsRow extends StatelessWidget {
  final int totalLives;
  final int currentLife;
  final int livesLost;
  final double crackProgress;

  const _HeartsRow({
    required this.totalLives,
    required this.currentLife,
    required this.livesLost,
    required this.crackProgress,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalLives, (i) {
        // index dari kanan: nyawa yang hilang duluan dari kanan
        final lostIndex = totalLives - 1 - i;
        final isLost = lostIndex < livesLost;
        final isCracking = lostIndex == livesLost - 1; // yang paling baru hilang

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: SizedBox(
            width: 52,
            height: 52,
            child: isLost
                ? isCracking
                    ? CustomPaint(
                        painter: _CrackedHeartPainter(crackProgress: crackProgress),
                      )
                    : CustomPaint(
                        painter: _CrackedHeartPainter(crackProgress: 1.0),
                      )
                : CustomPaint(
                    painter: _FullHeartPainter(),
                  ),
          ),
        );
      }),
    );
  }
}

// ── Full heart painter ───────────────────────────────────────────────────────
class _FullHeartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFEF5350);
    final border = Paint()
      ..color = const Color(0xFF111111)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final path = _heartPath(size);
    canvas.drawPath(path, paint);
    canvas.drawPath(path, border);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Cracked heart painter ────────────────────────────────────────────────────
class _CrackedHeartPainter extends CustomPainter {
  final double crackProgress;
  _CrackedHeartPainter({required this.crackProgress});

  @override
  void paint(Canvas canvas, Size size) {
    // Base heart — warna lebih gelap/abu untuk yang hilang
    final basePaint = Paint()..color = const Color(0xFFBDBDBD);
    final borderPaint = Paint()
      ..color = const Color(0xFF111111)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final path = _heartPath(size);
    canvas.drawPath(path, basePaint);
    canvas.drawPath(path, borderPaint);

    if (crackProgress <= 0) return;

    // Garis retak utama — dari tengah atas ke bawah
    final crackPaint = Paint()
      ..color = const Color(0xFF111111)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final cx = size.width * 0.5;
    final cy = size.height * 0.3;
    final endY = size.height * 0.85 * crackProgress;

    // Retak utama berliku
    final crackPath = Path();
    crackPath.moveTo(cx, cy);
    crackPath.lineTo(cx - 4, cy + (endY - cy) * 0.3);
    crackPath.lineTo(cx + 5, cy + (endY - cy) * 0.6);
    crackPath.lineTo(cx - 2, endY);

    canvas.drawPath(crackPath, crackPaint);

    if (crackProgress > 0.5) {
      // Cabang retak kiri
      final branchPaint = Paint()
        ..color = const Color(0xFF111111).withOpacity((crackProgress - 0.5) * 2)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
        Offset(cx - 2, cy + (endY - cy) * 0.4),
        Offset(cx - 12, cy + (endY - cy) * 0.55),
        branchPaint,
      );
      canvas.drawLine(
        Offset(cx + 3, cy + (endY - cy) * 0.65),
        Offset(cx + 12, cy + (endY - cy) * 0.75),
        branchPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_CrackedHeartPainter old) => old.crackProgress != crackProgress;
}

Path _heartPath(Size size) {
  final w = size.width;
  final h = size.height;
  final path = Path();
  path.moveTo(w * 0.5, h * 0.85);
  path.cubicTo(w * 0.1, h * 0.6, 0, h * 0.4, w * 0.25, h * 0.25);
  path.cubicTo(w * 0.35, h * 0.15, w * 0.5, h * 0.25, w * 0.5, h * 0.35);
  path.cubicTo(w * 0.5, h * 0.25, w * 0.65, h * 0.15, w * 0.75, h * 0.25);
  path.cubicTo(w, h * 0.4, w, h * 0.6, w * 0.5, h * 0.85);
  path.close();
  return path;
}