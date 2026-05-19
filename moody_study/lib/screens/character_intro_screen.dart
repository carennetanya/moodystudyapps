import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'theme_selector_screen.dart';
import 'mood_screen.dart';
import 'location_screen.dart';

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
                child: Stack(
                  children: [
                    Align(
                        alignment: Alignment.topLeft,
                        child: _BookLanguageBadge()),
                    const Align(
                        alignment: Alignment.topRight,
                        child: _LogoBadge()),
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
              color: Color(0xFF111111),
              offset: Offset(2, 2),
              blurRadius: 0),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
                color: Color(0xFF111111), shape: BoxShape.circle),
            child: const Center(
                child: Icon(Icons.book, size: 18, color: Colors.white)),
          ),
          const SizedBox(height: 8),
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
                color: Color(0xFF111111), shape: BoxShape.circle),
            child: const Center(
                child: Icon(Icons.translate,
                    size: 18, color: Colors.white)),
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