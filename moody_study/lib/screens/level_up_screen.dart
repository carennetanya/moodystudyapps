import 'dart:math';
import 'package:flutter/material.dart';

/// Shown when a user levels up after completing a session.
/// [newLevel] 1–5, [newLevelName] e.g. "Learner",
/// [xpEarnedInLevel] total XP accumulated during the completed level.
class LevelUpScreen extends StatefulWidget {
  final int newLevel;
  final String newLevelName;
  final int xpEarnedInLevel;
  final String userName;
  final VoidCallback onContinue;

  const LevelUpScreen({
    super.key,
    required this.newLevel,
    required this.newLevelName,
    required this.xpEarnedInLevel,
    required this.userName,
    required this.onContinue,
  });

  @override
  State<LevelUpScreen> createState() => _LevelUpScreenState();
}

class _LevelUpScreenState extends State<LevelUpScreen>
    with TickerProviderStateMixin {
  late AnimationController _scaleCtrl;
  late AnimationController _fadeCtrl;
  late AnimationController _confettiCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _confettiAnim;

  final List<_ConfettiParticle> _particles = [];

  @override
  void initState() {
    super.initState();

    // Generate confetti particles
    final rng = Random();
    for (int i = 0; i < 28; i++) {
      _particles.add(_ConfettiParticle(
        x: rng.nextDouble(),
        delay: rng.nextDouble() * 0.6,
        size: 6 + rng.nextDouble() * 8,
        color: _confettiColors[rng.nextInt(_confettiColors.length)],
        rotation: rng.nextDouble() * 2 * pi,
        speed: 0.6 + rng.nextDouble() * 0.4,
      ));
    }

    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _scaleAnim = CurvedAnimation(parent: _scaleCtrl, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _confettiAnim = _confettiCtrl;

    Future.delayed(const Duration(milliseconds: 100), () {
      _scaleCtrl.forward();
      _fadeCtrl.forward();
      _confettiCtrl.repeat();
    });
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    _fadeCtrl.dispose();
    _confettiCtrl.dispose();
    super.dispose();
  }

  static const _confettiColors = [
    Color(0xFFF2EA05),
    Color(0xFF1EE86F),
    Color(0xFFFF6B6B),
    Color(0xFF74B9FF),
    Color(0xFFA29BFE),
    Color(0xFFFD79A8),
    Color(0xFF00CEC9),
  ];

  /// Medal color per level
  Color get _medalColor {
    switch (widget.newLevel) {
      case 1: return const Color(0xFFCD7F32); // Bronze
      case 2: return const Color(0xFFC0C0C0); // Silver
      case 3: return const Color(0xFFFFD700); // Gold
      case 4: return const Color(0xFF00CEC9); // Teal/Sapphire
      case 5: return const Color(0xFFA29BFE); // Purple/Diamond
      default: return const Color(0xFFCD7F32);
    }
  }

  Color get _medalDark {
    switch (widget.newLevel) {
      case 1: return const Color(0xFF8B5A2B);
      case 2: return const Color(0xFF888888);
      case 3: return const Color(0xFFB8860B);
      case 4: return const Color(0xFF007A78);
      case 5: return const Color(0xFF6C5CE7);
      default: return const Color(0xFF8B5A2B);
    }
  }

  Color get _bgColor {
    switch (widget.newLevel) {
      case 1: return const Color(0xFFFFF8F0);
      case 2: return const Color(0xFFF5F5F5);
      case 3: return const Color(0xFFFFFBE6);
      case 4: return const Color(0xFFE6FFFC);
      case 5: return const Color(0xFFF0EEFF);
      default: return const Color(0xFFFFF8F0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        children: [
          // Confetti layer
          AnimatedBuilder(
            animation: _confettiAnim,
            builder: (_, __) => CustomPaint(
              size: Size.infinite,
              painter: _ConfettiPainter(
                particles: _particles,
                progress: _confettiAnim.value,
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                children: [
                  const SizedBox(height: 48),

                  // Medal
                  ScaleTransition(
                    scale: _scaleAnim,
                    child: _MedalWidget(
                      level: widget.newLevel,
                      color: _medalColor,
                      darkColor: _medalDark,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Congrats text
                  const Text(
                    'Congrats!',
                    style: TextStyle(
                      fontFamily: 'BlackHanSans',
                      fontSize: 36,
                      color: Color(0xFF111111),
                      letterSpacing: 0.5,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    'You earned ${widget.xpEarnedInLevel} points and\nunlocked Level ${widget.newLevel} (${widget.newLevelName})',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 15,
                      color: Color(0xFF555555),
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // XP detail card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color(0xFF111111), width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0xFF111111),
                            offset: Offset(4, 4),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '⚡',
                            style: TextStyle(fontSize: 22),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${widget.xpEarnedInLevel} points',
                                style: TextStyle(
                                  fontFamily: 'BlackHanSans',
                                  fontSize: 20,
                                  color: _medalColor == const Color(0xFFFFD700)
                                      ? const Color(0xFFB8860B)
                                      : _medalColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                'earned in Level ${widget.newLevel - 1}',
                                style: const TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 12,
                                  color: Color(0xFF888888),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Continue button
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 32),
                    child: GestureDetector(
                      onTap: widget.onContinue,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: _medalColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color(0xFF111111), width: 2.5),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0xFF111111),
                              offset: Offset(4, 4),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: const Text(
                          '🚀  Keep Going!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'BlackHanSans',
                            fontSize: 18,
                            color: Color(0xFF111111),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Medal Widget ──────────────────────────────────────────────────────────────

class _MedalWidget extends StatelessWidget {
  final int level;
  final Color color;
  final Color darkColor;

  const _MedalWidget({
    required this.level,
    required this.color,
    required this.darkColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 180,
      child: CustomPaint(
        painter: _MedalPainter(color: color, darkColor: darkColor, level: level),
      ),
    );
  }
}

class _MedalPainter extends CustomPainter {
  final Color color;
  final Color darkColor;
  final int level;

  _MedalPainter({required this.color, required this.darkColor, required this.level});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 - 10;
    final r = size.width * 0.38;

    // Ribbon left
    final ribbonPaint = Paint()..color = darkColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 30, cy + r - 10, 22, 50),
        const Radius.circular(4),
      ),
      ribbonPaint,
    );
    // Ribbon right
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx + 8, cy + r - 10, 22, 50),
        const Radius.circular(4),
      ),
      ribbonPaint,
    );

    // Medal circle shadow
    final shadowPaint = Paint()..color = Colors.black.withOpacity(0.18);
    canvas.drawCircle(Offset(cx + 4, cy + 4), r, shadowPaint);

    // Medal circle
    final circlePaint = Paint()..color = color;
    canvas.drawCircle(Offset(cx, cy), r, circlePaint);

    // Inner ring highlight
    final ringPaint = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    canvas.drawCircle(Offset(cx, cy), r - 8, ringPaint);

    // Level number
    final textPainter = TextPainter(
      text: TextSpan(
        text: '$level',
        style: TextStyle(
          fontFamily: 'BlackHanSans',
          fontSize: r * 0.85,
          color: Colors.white,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.2),
              offset: const Offset(2, 2),
              blurRadius: 4,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(cx - textPainter.width / 2, cy - textPainter.height / 2),
    );

    // Star at bottom of medal
    _drawStar(canvas, Offset(cx, cy + r + 2), 14, color, darkColor);
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Color fill, Color border) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final outerAngle = (i * 4 * pi / 5) - pi / 2;
      final innerAngle = outerAngle + 2 * pi / 5;
      final outerX = center.dx + radius * cos(outerAngle);
      final outerY = center.dy + radius * sin(outerAngle);
      final innerX = center.dx + (radius * 0.4) * cos(innerAngle);
      final innerY = center.dy + (radius * 0.4) * sin(innerAngle);
      if (i == 0) {
        path.moveTo(outerX, outerY);
      } else {
        path.lineTo(outerX, outerY);
      }
      path.lineTo(innerX, innerY);
    }
    path.close();

    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _MedalPainter old) =>
      old.color != color || old.level != level;
}

// ── Confetti ──────────────────────────────────────────────────────────────────

class _ConfettiParticle {
  final double x;
  final double delay;
  final double size;
  final Color color;
  final double rotation;
  final double speed;

  const _ConfettiParticle({
    required this.x,
    required this.delay,
    required this.size,
    required this.color,
    required this.rotation,
    required this.speed,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      // Each particle has its own phase based on delay, looping independently
      final raw = (progress + p.delay) % 1.0;
      final t = raw / p.speed > 1.0 ? (raw / p.speed) % 1.0 : raw / p.speed;
      final tClamped = t.clamp(0.0, 1.0);

      final y = -p.size + (size.height + p.size * 2) * tClamped;
      final x = p.x * size.width + sin(tClamped * pi * 4 + p.rotation) * 24;
      final opacity = tClamped > 0.85 ? (1.0 - tClamped) / 0.15 : 1.0;

      final paint = Paint()..color = p.color.withOpacity(opacity.clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotation + tClamped * pi * 3);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.5),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.progress != progress;
}