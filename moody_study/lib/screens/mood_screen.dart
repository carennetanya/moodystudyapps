import 'package:flutter/material.dart';
import 'theme_selector_screen.dart'; // for AppTheme

typedef MoodSelectedCallback = void Function(String mood);

class MoodScreen extends StatefulWidget {
  final String userName;
  final AppTheme theme;
  final MoodSelectedCallback onMoodSelected;

  const MoodScreen({
    super.key,
    this.userName = 'Friend',
    this.theme = AppTheme.green,
    required this.onMoodSelected,
  });

  @override
  State<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends State<MoodScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5E81E),
      body: Stack(
        children: [
          // Diagonal stripe bg
          CustomPaint(
            size: Size.infinite,
            painter: _DiagonalStripePainter(),
          ),

          // Navbar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 16, right: 16, top: 6, bottom: 2),
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: _BookLanguageBadge(),
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: const _LogoBadge(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Question
                        _QuestionText(),
                        const SizedBox(height: 36),

                        // Mood buttons
                        _MoodButton(
                          emoji: '😄',
                          label: 'Happy',
                          mood: 'happy',
                          bgColor: const Color(0xFFFFF9C4),
                          onTap: widget.onMoodSelected,
                        ),
                        const SizedBox(height: 14),
                        _MoodButton(
                          emoji: '😐',
                          label: 'Just okay',
                          mood: 'okay',
                          bgColor: Colors.white,
                          onTap: widget.onMoodSelected,
                        ),
                        const SizedBox(height: 14),
                        _MoodButton(
                          emoji: '😮‍💨',
                          label: 'Tired',
                          mood: 'tired',
                          bgColor: const Color(0xFFE8E8E8),
                          onTap: widget.onMoodSelected,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Question Text ─────────────────────────────────────────────────
class _QuestionText extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final fontSize = (w * 0.075).clamp(24.0, 38.0);

    return Column(
      children: [
        Text(
          'So...',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'BlackHanSans',
            fontSize: fontSize * 0.75,
            fontStyle: FontStyle.italic,
            color: const Color(0xFF111111),
            letterSpacing: 0.5,
            shadows: const [
              Shadow(color: Colors.white, offset: Offset(-2, -2), blurRadius: 0),
              Shadow(color: Colors.white, offset: Offset(2, -2), blurRadius: 0),
              Shadow(color: Colors.white, offset: Offset(-2, 2), blurRadius: 0),
              Shadow(color: Colors.white, offset: Offset(2, 2), blurRadius: 0),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "How's your mood today?",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'BlackHanSans',
            fontSize: fontSize,
            color: const Color(0xFF111111),
            letterSpacing: 0.5,
            height: 1.2,
            shadows: const [
              Shadow(color: Colors.white, offset: Offset(-2, -2), blurRadius: 0),
              Shadow(color: Colors.white, offset: Offset(2, -2), blurRadius: 0),
              Shadow(color: Colors.white, offset: Offset(-2, 2), blurRadius: 0),
              Shadow(color: Colors.white, offset: Offset(2, 2), blurRadius: 0),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Mood Button ───────────────────────────────────────────────────
class _MoodButton extends StatefulWidget {
  final String emoji;
  final String label;
  final String mood;
  final Color bgColor;
  final void Function(String) onTap;

  const _MoodButton({
    required this.emoji,
    required this.label,
    required this.mood,
    required this.bgColor,
    required this.onTap,
  });

  @override
  State<_MoodButton> createState() => _MoodButtonState();
}

class _MoodButtonState extends State<_MoodButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final btnWidth = (w * 0.78).clamp(220.0, 340.0);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap(widget.mood);
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: Matrix4.translationValues(
          _pressed ? 4 : 0,
          _pressed ? 4 : 0,
          0,
        ),
        width: btnWidth,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
        decoration: BoxDecoration(
          color: widget.bgColor,
          border: Border.all(color: const Color(0xFF111111), width: 3),
          borderRadius: BorderRadius.circular(20),
          boxShadow: _pressed
              ? const [
                  BoxShadow(
                      color: Color(0xFF111111),
                      offset: Offset(2, 2),
                      blurRadius: 0)
                ]
              : const [
                  BoxShadow(
                      color: Color(0xFF111111),
                      offset: Offset(6, 6),
                      blurRadius: 0)
                ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 6),
            Text(
              widget.label,
              style: const TextStyle(
                fontFamily: 'BlackHanSans',
                fontSize: 16,
                color: Color(0xFF111111),
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Logo Badge ────────────────────────────────────────────────────
class _LogoBadge extends StatelessWidget {
  const _LogoBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFF111111), width: 2.0),
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [
          BoxShadow(
              color: Color(0xFF111111), offset: Offset(3, 3), blurRadius: 0),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()..scale(-1.0, 1.0),
            child: Image.asset(
              'assets/images/logo.png',
              width: 28,
              height: 28,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const Text('🎓', style: TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 4),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('moody',
                  style: TextStyle(
                      fontFamily: 'BlackHanSans',
                      fontSize: 14,
                      color: Color(0xFF111111),
                      height: 1.1)),
              Text('study',
                  style: TextStyle(
                      fontFamily: 'BlackHanSans',
                      fontSize: 10,
                      color: Color(0xFF555555),
                      letterSpacing: 1.5,
                      height: 1.1)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Book + Language Badge ─────────────────────────────────────────
class _BookLanguageBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        border: Border.all(color: const Color(0xFF111111), width: 2),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
              color: Color(0xFF111111), offset: Offset(2, 2), blurRadius: 0),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: Color(0xFF111111),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.book, size: 18, color: Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: Color(0xFF111111),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.translate, size: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Diagonal Stripe Painter ───────────────────────────────────────
class _DiagonalStripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.05)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const gap = 24.0;
    final total = size.width + size.height;
    for (double i = -size.height; i < total; i += gap) {
      canvas.drawLine(
          Offset(i, 0), Offset(i + size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}