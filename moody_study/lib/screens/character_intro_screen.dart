import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'theme_selector_screen.dart';
import 'mood_screen.dart';
import 'location_screen.dart';
import 'package:moody_study/services/streak_service.dart';

class CharacterIntroScreen extends StatefulWidget {
  final String userName;
  final AppTheme theme;
  final AudioPlayer? audioPlayer;

  const CharacterIntroScreen({
    super.key,
    this.userName = 'Friend',
    this.theme = AppTheme.green,
    this.audioPlayer,
  });

  @override
  State<CharacterIntroScreen> createState() => _CharacterIntroScreenState();
}

class _CharacterIntroScreenState extends State<CharacterIntroScreen>
    with TickerProviderStateMixin {

  bool _showLandingPage = false;
  String _greetingText = '';
  int _greetingPhase = 1;
  bool _showGreeting = false;

  // Greeting pop
  late AnimationController _greetingController;
  late Animation<double> _greetingScale;
  late Animation<double> _greetingOpacity;

  // Landing fade in
  late AnimationController _landingFadeController;
  late Animation<double> _landingFadeAnim;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startSequence();
  }

  void _initAnimations() {
    // Greeting pop-in
    _greetingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _greetingScale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
          parent: _greetingController,
          curve: const Cubic(0.34, 1.56, 0.64, 1)),
    );
    _greetingOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _greetingController, curve: Curves.easeIn),
    );

    // Landing fade in
    _landingFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _landingFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _landingFadeController, curve: Curves.easeIn),
    );
  }

  void _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() {
      _greetingPhase = 1;
      _greetingText = 'Hello ${widget.userName}';
      _showGreeting = true;
    });
    _greetingController.forward(from: 0);

    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() {
      _greetingPhase = 2;
      _greetingText = 'and';
    });
    _greetingController.forward(from: 0);

    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      _greetingPhase = 3;
      _greetingText = "I'm your Oddy!";
    });
    _greetingController.forward(from: 0);

    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() {
      _showGreeting = false;
      _showLandingPage = true;
    });
    _landingFadeController.forward();
  }

  @override
  void dispose() {
    _greetingController.dispose();
    _landingFadeController.dispose();
    super.dispose();
  }

  void _onStartNow() {
    if (!mounted) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => MoodScreen(
          userName: widget.userName,
          theme: widget.theme,
          onMoodSelected: (mood) {
            Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => LocationScreen(
                    mood: mood,
                    userName: widget.userName,
                    theme: widget.theme,
                    audioPlayer: widget.audioPlayer,
                  ),
                transitionsBuilder: (_, anim, __, child) =>
                    FadeTransition(opacity: anim, child: child),
                transitionDuration: const Duration(milliseconds: 400),
              ),
            );
          },
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  double get _greetingFontSize {
    final w = MediaQuery.sizeOf(context).width;
    switch (_greetingPhase) {
      case 1: return (w * 0.05).clamp(18, 36);
      case 2: return (w * 0.08).clamp(30, 66);
      case 3: return (w * 0.12).clamp(46, 122);
      default: return 24;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_showLandingPage)
            FadeTransition(
              opacity: _landingFadeAnim,
              child: _LandingPage(
                heroContent: _HeroContent(
                  userName: widget.userName,
                  onStartNow: _onStartNow,
                ),
              ),
            ),
          if (!_showLandingPage && _showGreeting && _greetingText.isNotEmpty)
            Center(
              child: AnimatedBuilder(
                animation: _greetingController,
                builder: (context, child) => Opacity(
                  opacity: _greetingOpacity.value,
                  child: Transform.scale(
                    scale: _greetingScale.value,
                    child: child,
                  ),
                ),
                child: Text(
                  _greetingText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'BlackHanSans',
                    fontSize: _greetingFontSize,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Landing Page ──────────────────────────────────────────────────
class _LandingPage extends StatelessWidget {
  final Widget heroContent;
  const _LandingPage({required this.heroContent});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE5E81E),
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        children: [
          CustomPaint(
              size: Size.infinite, painter: _DiagonalStripePainter()),
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 16, right: 16, top: 6, bottom: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const _StatsBadge(),
                    const Spacer(),
                    const _LivesBox(),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(child: heroContent),
        ],
      ),
    );
  }
}

// ── Hero Content ──────────────────────────────────────────────────
class _HeroContent extends StatelessWidget {
  final String userName;
  final VoidCallback? onStartNow;
  const _HeroContent({required this.userName, this.onStartNow});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isSmall = size.width < 400;
    final imgH = (size.height * 0.28).clamp(120.0, 220.0);

    return SizedBox.expand(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 160, 24, 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'study anytime anywhere',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w700,
                  fontSize: isSmall ? 13.0 : 15.0,
                  color: const Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 8),
              Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()..scale(-1.0, 1.0),
                child: Image.asset(
                  'assets/images/logo.png',
                  height: imgH,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => SizedBox(
                    height: imgH,
                    child: const Center(
                        child: Text('🧑‍💻',
                            style: TextStyle(fontSize: 80))),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _HeadlineText(isSmall: isSmall),
              const SizedBox(height: 14),
              Text(
                "good mood or not,\nlet's keep studying with oddy!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w700,
                  fontSize: isSmall ? 12.0 : 14.0,
                  color: const Color(0xFF444444),
                  height: 1.8,
                ),
              ),
              const SizedBox(height: 20),
              _StartNowButton(onTap: onStartNow),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeadlineText extends StatelessWidget {
  final bool isSmall;
  const _HeadlineText({required this.isSmall});

  static const _whiteShadows = [
    Shadow(color: Colors.white, offset: Offset(-3, -3), blurRadius: 0),
    Shadow(color: Colors.white, offset: Offset(3, -3), blurRadius: 0),
    Shadow(color: Colors.white, offset: Offset(-3, 3), blurRadius: 0),
    Shadow(color: Colors.white, offset: Offset(3, 3), blurRadius: 0),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'moody',
          style: TextStyle(
            fontFamily: 'BlackHanSans',
            fontSize: isSmall ? 28.0 : 34.0,
            fontStyle: FontStyle.italic,
            color: const Color(0xFF111111),
            letterSpacing: -1,
            height: 1,
            shadows: _whiteShadows,
          ),
        ),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontFamily: 'BlackHanSans',
              fontSize: isSmall ? 18.0 : 22.0,
              color: const Color(0xFF111111),
              letterSpacing: 0.2,
              height: 1.25,
              shadows: _whiteShadows,
            ),
            children: const [
              TextSpan(text: 'study time '),
              TextSpan(
                text: '✦',
                style: TextStyle(
                    fontFamily: null,
                    fontSize: 16,
                    color: Color(0xFF111111),
                    shadows: []),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Start Now Button ──────────────────────────────────────────────
class _StartNowButton extends StatefulWidget {
  final VoidCallback? onTap;
  const _StartNowButton({this.onTap});

  @override
  State<_StartNowButton> createState() => _StartNowButtonState();
}

class _StartNowButtonState extends State<_StartNowButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: Matrix4.translationValues(
            _pressed ? 4 : 0, _pressed ? 4 : 0, 0),
        padding:
            const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(999),
          boxShadow: _pressed
              ? const [
                  BoxShadow(
                      color: Color(0xFF111111),
                      offset: Offset(2, 2),
                      blurRadius: 0)
                ]
              : const [
                  BoxShadow(
                      color: Colors.white,
                      offset: Offset(5, 5),
                      blurRadius: 0),
                  BoxShadow(
                      color: Color(0xFF111111),
                      offset: Offset(5, 5),
                      blurRadius: 0,
                      spreadRadius: 2),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'start now',
              style: TextStyle(
                fontFamily: 'BlackHanSans',
                fontSize: 16,
                letterSpacing: 2,
                color: Color(0xFFE5E81E),
              ),
            ),
            SizedBox(width: 6),
            Text('♪',
                style: TextStyle(
                    fontSize: 16, color: Color(0xFFE5E81E))),
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
              color: Color(0xFF111111),
              offset: Offset(3, 3),
              blurRadius: 0),
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

// ── Stats Badge (Level badge + Streak pill) ───────────────────────
class _StatsBadge extends StatefulWidget {
  const _StatsBadge();

  @override
  State<_StatsBadge> createState() => _StatsBadgeState();
}

class _StatsBadgeState extends State<_StatsBadge> {
  late final Future<StreakInfo> _streakFuture;

  @override
  void initState() {
    super.initState();
    _streakFuture = StreakService.fetchStreak();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<StreakInfo>(
      future: _streakFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: const [
              _LevelBadge(level: 1),
              SizedBox(width: 8),
              _StatPill(icon: '🔥', label: 'Streak', value: '0'),
            ],
          );
        }

        if (snapshot.hasError) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: const [
              _LevelBadge(level: 1),
              SizedBox(width: 8),
              _StatPill(icon: '🔥', label: 'Streak', value: '0'),
            ],
          );
        }

        final info = snapshot.data;
        final level = info?.level ?? 1;
        final streakValue = info?.currentStreak ?? 0;

        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _LevelBadge(level: level),
            const SizedBox(width: 8),
            _StatPill(icon: '🔥', label: 'Streak', value: streakValue.toString()),
          ],
        );
      },
    );
  }
}

// ── Level Badge (crown style, interactive) ────────────────────────
class _LevelBadge extends StatefulWidget {
  final int level;
  const _LevelBadge({required this.level});

  @override
  State<_LevelBadge> createState() => _LevelBadgeState();
}

class _LevelBadgeState extends State<_LevelBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  // Level configs: [bgColor, shimmerColor, accentColor, starColor, wingColor]
  static const _levelConfigs = [
    {'bg': Color(0xFFB8A8E8), 'shimmer': Color(0xFFD4C8F5), 'accent': Color(0xFF7B6DB5), 'ribbon': Color(0xFF8A7DC8), 'label': '1'},
    {'bg': Color(0xFFCC88EE), 'shimmer': Color(0xFFE4AAFF), 'accent': Color(0xFF9944BB), 'ribbon': Color(0xFFAA55CC), 'label': '2'},
    {'bg': Color(0xFF66CCEE), 'shimmer': Color(0xFF99DDFF), 'accent': Color(0xFF2299BB), 'ribbon': Color(0xFF44AACC), 'label': '3'},
    {'bg': Color(0xFFFF9900), 'shimmer': Color(0xFFFFBB44), 'accent': Color(0xFFBB5500), 'ribbon': Color(0xFFDD7700), 'label': '4'},
    {'bg': Color(0xFFFF7766), 'shimmer': Color(0xFFFFAA99), 'accent': Color(0xFFCC3322), 'ribbon': Color(0xFFEE5544), 'label': '5'},
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap() async {
    await _controller.forward();
    await _controller.reverse();
    if (!mounted) return;
    _showLevelDialog();
  }

  void _showLevelDialog() {
    final cfg = _levelConfigs[(widget.level - 1).clamp(0, 4)];
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF111111), width: 2),
            boxShadow: const [
              BoxShadow(color: Color(0xFF111111), offset: Offset(4, 4), blurRadius: 0),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LevelBadgePainter(level: widget.level, size: 100),
              const SizedBox(height: 16),
              Text(
                'Level ${widget.level}',
                style: const TextStyle(
                  fontFamily: 'BlackHanSans',
                  fontSize: 22,
                  color: Color(0xFF111111),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _levelName(widget.level),
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: cfg['bg'] as Color,
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: 0.65,
                  minHeight: 12,
                  backgroundColor: const Color(0xFFEEEEEE),
                  valueColor: AlwaysStoppedAnimation<Color>(cfg['bg'] as Color),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '650 / 1000 XP',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF888888),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _levelName(int level) {
    switch (level) {
      case 1: return 'Rookie Scholar';
      case 2: return 'Rising Mind';
      case 3: return 'Bright Thinker';
      case 4: return 'Gold Studier';
      case 5: return 'Oddy Master';
      default: return 'Scholar';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: _LevelBadgePainter(level: widget.level, size: 52),
      ),
    );
  }
}

// ── Level Badge Painter ───────────────────────────────────────────
class _LevelBadgePainter extends StatelessWidget {
  final int level;
  final double size;
  const _LevelBadgePainter({required this.level, required this.size});

  static const _levelConfigs = [
    {'bg': Color(0xFFB8A8E8), 'shimmer': Color(0xFFD4C8F5), 'dark': Color(0xFF7B6DB5), 'ribbon': Color(0xFF8A7DC8)},
    {'bg': Color(0xFFCC88EE), 'shimmer': Color(0xFFE4AAFF), 'dark': Color(0xFF9944BB), 'ribbon': Color(0xFFAA55CC)},
    {'bg': Color(0xFF66CCEE), 'shimmer': Color(0xFF99DDFF), 'dark': Color(0xFF2299BB), 'ribbon': Color(0xFF44AACC)},
    {'bg': Color(0xFFFF9900), 'shimmer': Color(0xFFFFBB44), 'dark': Color(0xFFBB5500), 'ribbon': Color(0xFFDD7700)},
    {'bg': Color(0xFFFF7766), 'shimmer': Color(0xFFFFAA99), 'dark': Color(0xFFCC3322), 'ribbon': Color(0xFFEE5544)},
  ];

  @override
  Widget build(BuildContext context) {
    final cfg = _levelConfigs[(level - 1).clamp(0, 4)];
    final bg = cfg['bg'] as Color;
    final shimmer = cfg['shimmer'] as Color;
    final dark = cfg['dark'] as Color;
    final ribbon = cfg['ribbon'] as Color;
    final starCount = level.clamp(1, 5);
    final hasWings = level >= 3;
    final hasCrown = level == 5;

    return SizedBox(
      width: size,
      height: size * 1.15,
      child: CustomPaint(
        painter: _BadgePainter(
          bg: bg,
          shimmer: shimmer,
          dark: dark,
          ribbon: ribbon,
          level: level,
          starCount: starCount,
          hasWings: hasWings,
          hasCrown: hasCrown,
        ),
      ),
    );
  }
}


// u2500u2500 Badge Outline Painter u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500
class _BadgeOutlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final outlinePaint = Paint()
      ..color = Colors.black.withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(Offset(cx, h * 0.34), w * 0.36, outlinePaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - w * 0.42, h * 0.54, w * 0.84, h * 0.22),
        const Radius.circular(6),
      ),
      outlinePaint,
    );
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BadgePainter extends CustomPainter {
  final Color bg, shimmer, dark, ribbon;
  final int level, starCount;
  final bool hasWings, hasCrown;

  const _BadgePainter({
    required this.bg, required this.shimmer, required this.dark,
    required this.ribbon, required this.level, required this.starCount,
    required this.hasWings, required this.hasCrown,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    final bodyPaint = Paint()..color = bg..style = PaintingStyle.fill;
    final darkPaint = Paint()..color = dark..style = PaintingStyle.fill;
    final shimmerPaint = Paint()..color = shimmer..style = PaintingStyle.fill;
    final ribbonPaint = Paint()..color = ribbon..style = PaintingStyle.fill;
    final whitePaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    final shadowPaint = Paint()..color = Colors.black.withOpacity(0.15)..style = PaintingStyle.fill;

    // Wings (level 3+)
    if (hasWings) {
      final wingColor = level == 3 ? const Color(0xFF88DDFF) : const Color(0xFFFFEE88);
      final wingPaint = Paint()..color = wingColor..style = PaintingStyle.fill;
      // left wing
      final leftWing = Path()
        ..moveTo(cx - w * 0.28, h * 0.38)
        ..cubicTo(cx - w * 0.55, h * 0.20, cx - w * 0.62, h * 0.38, cx - w * 0.50, h * 0.52)
        ..cubicTo(cx - w * 0.42, h * 0.46, cx - w * 0.33, h * 0.44, cx - w * 0.28, h * 0.46)
        ..close();
      canvas.drawPath(leftWing, wingPaint);
      // right wing
      final rightWing = Path()
        ..moveTo(cx + w * 0.28, h * 0.38)
        ..cubicTo(cx + w * 0.55, h * 0.20, cx + w * 0.62, h * 0.38, cx + w * 0.50, h * 0.52)
        ..cubicTo(cx + w * 0.42, h * 0.46, cx + w * 0.33, h * 0.44, cx + w * 0.28, h * 0.46)
        ..close();
      canvas.drawPath(rightWing, wingPaint);
      // wing outline
      final wingOutline = Paint()..color = wingColor.withOpacity(0.6)..style = PaintingStyle.stroke..strokeWidth = 1;
      canvas.drawPath(leftWing, wingOutline);
      canvas.drawPath(rightWing, wingOutline);
    }

    // Crown spikes (level 5)
    if (hasCrown) {
      final crownPaint = Paint()..color = dark..style = PaintingStyle.fill;
      for (int i = 0; i < 5; i++) {
        final angle = -90 + (i - 2) * 30.0;
        final rad = angle * 3.14159 / 180;
        final tipR = w * 0.38;
        final baseR = w * 0.28;
        final tx = cx + tipR * cos(rad);
        final ty = h * 0.18 + tipR * sin(rad);
        final b1x = cx + baseR * cos((angle - 10) * 3.14159 / 180);
        final b1y = h * 0.18 + baseR * sin((angle - 10) * 3.14159 / 180);
        final b2x = cx + baseR * cos((angle + 10) * 3.14159 / 180);
        final b2y = h * 0.18 + baseR * sin((angle + 10) * 3.14159 / 180);
        final spike = Path()..moveTo(b1x, b1y)..lineTo(tx, ty)..lineTo(b2x, b2y)..close();
        canvas.drawPath(spike, crownPaint);
      }
    }

    // Main dome shadow
    canvas.drawCircle(Offset(cx, h * 0.36), w * 0.36, shadowPaint);

    // Main dome
    canvas.drawCircle(Offset(cx, h * 0.34), w * 0.36, bodyPaint);

    // Shimmer highlight on dome
    final shimmerPath = Path()
      ..addOval(Rect.fromCenter(
        center: Offset(cx - w * 0.06, h * 0.18),
        width: w * 0.28,
        height: w * 0.22,
      ));
    canvas.drawPath(shimmerPath, shimmerPaint..color = shimmer.withOpacity(0.7));

    // Small white glint
    canvas.drawCircle(Offset(cx - w * 0.10, h * 0.14), w * 0.05, whitePaint..color = Colors.white.withOpacity(0.9));

    // Ribbon/banner
    final ribbonRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx - w * 0.42, h * 0.54, w * 0.84, h * 0.22),
      const Radius.circular(6),
    );
    canvas.drawRRect(ribbonRect, ribbonPaint);

    // Ribbon dark accent top
    final ribbonTop = Paint()..color = dark.withOpacity(0.3)..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(cx - w * 0.42, h * 0.54, w * 0.84, h * 0.04), const Radius.circular(6)),
      ribbonTop,
    );

    // Stars on ribbon
    final starY = h * 0.655;
    final starSize = w * 0.095;
    final starSpacing = w * 0.22;
    final totalStarW = starCount * starSize * 2 + (starCount - 1) * (starSpacing - starSize * 2);
    final starStartX = cx - totalStarW / 2 + starSize;
    for (int i = 0; i < starCount; i++) {
      final sx = starStartX + i * starSpacing;
      _drawStar(canvas, Offset(sx, starY), starSize, const Color(0xFFFFDD44), const Color(0xFFFFAA00));
    }

    // Level number
    final textPainter = TextPainter(
      text: TextSpan(
        text: '$level',
        style: TextStyle(
          fontSize: w * 0.32,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          shadows: [
            Shadow(color: dark, offset: const Offset(0, 2), blurRadius: 3),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(cx - textPainter.width / 2, h * 0.14));
  }

  void _drawStar(Canvas canvas, Offset center, double r, Color fill, Color stroke) {
    final path = Path();
    for (int i = 0; i < 10; i++) {
      final angle = (i * 36 - 90) * 3.14159 / 180;
      final radius = i.isEven ? r : r * 0.45;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = fill..style = PaintingStyle.fill);
    canvas.drawPath(path, Paint()..color = stroke..style = PaintingStyle.stroke..strokeWidth = 0.8);
  }

  double cos(double rad) => _cos(rad);
  double sin(double rad) => _sin(rad);

  static double _cos(double x) {
    double result = 1, term = 1;
    for (int i = 1; i <= 8; i++) {
      term *= -x * x / ((2 * i - 1) * (2 * i));
      result += term;
    }
    return result;
  }

  static double _sin(double x) {
    double result = x, term = x;
    for (int i = 1; i <= 8; i++) {
      term *= -x * x / ((2 * i) * (2 * i + 1));
      result += term;
    }
    return result;
  }

  @override
  bool shouldRepaint(covariant _BadgePainter old) =>
      old.level != level || old.bg != bg;
}

// ── Streak Pill ───────────────────────────────────────────────────
class _StatPill extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  const _StatPill({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.local_fire_department,
          size: 20,
          color: Colors.white,
          shadows: const [
            Shadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 4),
          ],
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1.0,
            shadows: [
              Shadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 4),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Lives Box (fetches life count and renders hearts) ───────────
class _LivesBox extends StatelessWidget {
  const _LivesBox();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: StreakService.fetchLife(),
      builder: (context, snapshot) {
        final int life = snapshot.data ?? 3;

        List<Widget> hearts = List.generate(3, (i) {
          if (i < life) {
            return const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(Icons.favorite, color: Color(0xFFFF3B5C), size: 22),
            );
          }
          return const Padding(
            padding: EdgeInsets.only(right: 4),
            child: Icon(Icons.favorite_border, color: Color(0xFFBBBBBB), size: 22),
          );
        });

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFF111111), width: 2.0),
            borderRadius: BorderRadius.circular(6),
            boxShadow: const [
              BoxShadow(
                  color: Color(0xFF111111),
                  offset: Offset(3, 3),
                  blurRadius: 0),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: hearts,
          ),
        );
      },
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