import 'dart:math';
import 'package:flutter/material.dart';
import 'theme_selector_screen.dart'; // for AppTheme

/// Callback types
typedef MoodSelectedCallback = void Function(String mood);

class CharacterIntroScreen extends StatefulWidget {
  final String userName;
  final AppTheme theme;
  final MoodSelectedCallback onMoodSelected;

  const CharacterIntroScreen({
    super.key,
    this.userName = 'Friend',
    this.theme = AppTheme.green,
    required this.onMoodSelected,
  });

  @override
  State<CharacterIntroScreen> createState() => _CharacterIntroScreenState();
}

class _CharacterIntroScreenState extends State<CharacterIntroScreen>
    with TickerProviderStateMixin {
  // ── Phase state ───────────────────────────────────────────────
  bool _characterShow = false;
  bool _eyesVisible = false;
  bool _isJumping = false;
  bool _showGreeting = false;
  String _greetingText = '';
  int _greetingPhase = 1; // 1=small, 2=medium, 3=big
  bool _showLandingPage = false;
  bool _showMoodScreen = false;

  // ── BG color ──────────────────────────────────────────────────
  Color _bgColor = Colors.black;

  // ── Mood hover ────────────────────────────────────────────────
  String _hoveredMood = '';

  // ── Eye look ──────────────────────────────────────────────────
  String _eyeLook = 'center'; // center | left | right

  // ── Animations ───────────────────────────────────────────────
  late AnimationController _characterDropController;
  late Animation<Offset> _characterDropAnim;

  late AnimationController _jumpController;
  late Animation<Offset> _jumpAnim;

  late AnimationController _greetingController;
  late Animation<double> _greetingScale;
  late Animation<double> _greetingOpacity;

  late AnimationController _bgExpandController;
  late Animation<Color?> _bgColorAnim;

  late AnimationController _landingFadeController;
  late Animation<double> _landingFadeAnim;

  late AnimationController _moodSlideController;
  late Animation<Offset> _moodSlideAnim;

  // ── Particle system ───────────────────────────────────────────
  final List<_Particle> _particles = [];
  late AnimationController _particleController;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startIntroSequence();
  }

  void _initAnimations() {
    // Character drop from top
    _characterDropController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _characterDropAnim = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _characterDropController,
      curve: Curves.bounceOut,
    ));

    // Jump animation
    _jumpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _jumpAnim = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -0.08),
    ).animate(CurvedAnimation(
      parent: _jumpController,
      curve: Curves.easeOut,
    ));

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

    // BG expand yellow
    _bgExpandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _bgColorAnim = ColorTween(
      begin: Colors.black,
      end: const Color(0xFFE5E81E),
    ).animate(CurvedAnimation(
        parent: _bgExpandController, curve: Curves.easeOut));
    _bgExpandController.addListener(() {
      if (mounted) {
        setState(() => _bgColor = _bgColorAnim.value ?? Colors.black);
      }
    });

    // Landing page fade in
    _landingFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _landingFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _landingFadeController, curve: Curves.easeIn),
    );

    // Mood screen slide
    _moodSlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _moodSlideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _moodSlideController, curve: Curves.easeOut));

    // Particle controller (runs continuously)
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _particleController.addListener(_updateParticles);
  }

  // ── Intro timeline ────────────────────────────────────────────
  void _startIntroSequence() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    setState(() => _characterShow = true);
    _characterDropController.forward();

    await Future.delayed(const Duration(milliseconds: 1700));
    if (!mounted) return;
    setState(() => _eyesVisible = true);

    // Eye wander
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() => _eyeLook = 'left');
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() => _eyeLook = 'right');
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() => _eyeLook = 'center');

    // Jump
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    setState(() => _isJumping = true);
    _jumpController.forward().then((_) => _jumpController.reverse());

    // Phase 1 greeting: eyes hide
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;
    setState(() {
      _eyesVisible = false;
      _greetingPhase = 1;
      _greetingText = 'Hi ${widget.userName}';
      _showGreeting = true;
    });
    _greetingController.forward(from: 0);

    // Phase 2
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    setState(() {
      _greetingPhase = 2;
      _greetingText = 'and';
    });
    _greetingController.forward(from: 0);

    // Phase 3
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() {
      _greetingPhase = 3;
      _greetingText = "I'm your Oddy!";
    });
    _greetingController.forward(from: 0);

    // BG expand to yellow
    await Future.delayed(const Duration(milliseconds: 730));
    if (!mounted) return;
    _bgExpandController.forward();

    // Show landing page
    await Future.delayed(const Duration(milliseconds: 1270));
    if (!mounted) return;
    setState(() {
      _showGreeting = false;
      _characterShow = false;
      _showLandingPage = true;
    });
    _landingFadeController.forward();
  }

  // ── Particles ─────────────────────────────────────────────────
  void _spawnParticles(String mood) {
    _particles.clear();
    final rand = Random();
    if (mood == 'happy') {
      for (int i = 0; i < 18; i++) {
        _particles.add(_Particle(
          x: rand.nextDouble(),
          y: rand.nextDouble() - 1,
          speedY: rand.nextDouble() * 0.003 + 0.002,
          speedX: (rand.nextDouble() - 0.5) * 0.0008,
          size: rand.nextDouble() * 10 + 6,
          type: rand.nextBool() ? 'flower' : 'sparkle',
          color: const Color(0xFFFF93AE),
          rotation: rand.nextDouble() * pi * 2,
          rotSpeed: (rand.nextDouble() - 0.5) * 0.06,
          swing: 0,
        ));
      }
    } else if (mood == 'okay') {
      final greens = [
        const Color(0xFFA5C882),
        const Color(0xFF7DB55A),
        const Color(0xFFB8D99C),
        const Color(0xFFC8E6A0),
      ];
      for (int i = 0; i < 12; i++) {
        _particles.add(_Particle(
          x: rand.nextDouble(),
          y: rand.nextDouble() - 1,
          speedY: rand.nextDouble() * 0.0025 + 0.0015,
          speedX: 0,
          size: rand.nextDouble() * 12 + 7,
          type: 'leaf',
          color: greens[rand.nextInt(greens.length)],
          rotation: rand.nextDouble() * pi * 2,
          rotSpeed: (rand.nextDouble() - 0.5) * 0.02,
          swing: rand.nextDouble() * pi * 2,
        ));
      }
    } else if (mood == 'tired') {
      for (int i = 0; i < 60; i++) {
        _particles.add(_Particle(
          x: rand.nextDouble(),
          y: rand.nextDouble(),
          speedY: rand.nextDouble() * 0.002 + 0.0015,
          speedX: -0.0004,
          size: rand.nextDouble() * 14 + 6,
          type: 'rain',
          color: const Color(0xFF90CAF9),
          rotation: 0,
          rotSpeed: 0,
          swing: 0,
        ));
      }
    }
  }

  void _clearParticles() => _particles.clear();

  void _updateParticles() {
    if (_particles.isEmpty) return;
    if (mounted) setState(() {});
    for (final p in _particles) {
      p.y += p.speedY;
      p.x += p.speedX;
      p.rotation += p.rotSpeed;
      if (p.type == 'leaf') p.swing += 0.02;
      if (p.type == 'leaf') p.x += sin(p.swing) * 0.0004;
      if (p.y > 1.05) {
        p.y = -0.05;
        p.x = Random().nextDouble();
      }
      if (p.x < -0.05) p.x = 1.05;
    }
  }

  // ── Mood selection ────────────────────────────────────────────
  void _onMoodSelected(String mood) {
    widget.onMoodSelected(mood);
  }

  void _switchToMoodScreen() {
    if (_showMoodScreen) return;
    setState(() => _showMoodScreen = true);
    _moodSlideController.forward(from: 0);
  }

  void _switchToHeroScreen() {
    if (!_showMoodScreen) return;
    _moodSlideController.reverse().then((_) {
      if (mounted) setState(() => _showMoodScreen = false);
    });
  }

  @override
  void dispose() {
    _characterDropController.dispose();
    _jumpController.dispose();
    _greetingController.dispose();
    _bgExpandController.dispose();
    _landingFadeController.dispose();
    _moodSlideController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  // ── Greeting font size by phase ───────────────────────────────
  double get _greetingFontSize {
    final w = MediaQuery.sizeOf(context).width;
    switch (_greetingPhase) {
      case 1:
        return (w * 0.05).clamp(18, 36);
      case 2:
        return (w * 0.08).clamp(30, 66);
      case 3:
        return (w * 0.12).clamp(46, 122);
      default:
        return 24;
    }
  }

  // ── Landing bg color ──────────────────────────────────────────
  Color get _landingBgColor {
    switch (_hoveredMood) {
      case 'happy':
        return const Color(0xFFFF93AE);
      case 'okay':
        return const Color(0xFFFDF6E3);
      case 'tired':
        return const Color(0xFF1A2A4A);
      default:
        return const Color(0xFFE5E81E);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _showLandingPage ? Colors.transparent : _bgColor,
      body: Stack(
        children: [
          // ── Landing Page ────────────────────────────────────
          if (_showLandingPage)
            FadeTransition(
              opacity: _landingFadeAnim,
              child: _LandingPage(
                bgColor: _landingBgColor,
                showMoodScreen: _showMoodScreen,
                hoveredMood: _hoveredMood,
                onSwipeUp: _switchToMoodScreen,
                onSwipeDown: _switchToHeroScreen,
                particles: _particles,
                heroContent: _HeroContent(userName: widget.userName),
                moodContent: _MoodContent(
                  moodSlideAnim: _moodSlideAnim,
                  onMoodHover: (mood) {
                    setState(() => _hoveredMood = mood);
                    if (mood.isNotEmpty) _spawnParticles(mood);
                    else _clearParticles();
                  },
                  onMoodSelected: _onMoodSelected,
                ),
              ),
            ),

          // ── Character Animation ──────────────────────────────
          if (!_showLandingPage) ...[
            if (_characterShow)
              SlideTransition(
                position: _isJumping ? _jumpAnim : _characterDropAnim,
                child: Center(
                  child: _CharacterWidget(
                    eyesVisible: _eyesVisible,
                    eyeLook: _eyeLook,
                  ),
                ),
              ),

            // Greeting text
            if (_showGreeting && _greetingText.isNotEmpty)
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
                    style: TextStyle(
                      fontFamily: 'BlackHanSans',
                      fontSize: _greetingFontSize,
                      color: const Color(0xFF642D05),
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// ── Landing Page ──────────────────────────────────────────────────
class _LandingPage extends StatefulWidget {
  final Color bgColor;
  final bool showMoodScreen;
  final String hoveredMood;
  final VoidCallback onSwipeUp;
  final VoidCallback onSwipeDown;
  final List<_Particle> particles;
  final Widget heroContent;
  final Widget moodContent;

  const _LandingPage({
    required this.bgColor,
    required this.showMoodScreen,
    required this.hoveredMood,
    required this.onSwipeUp,
    required this.onSwipeDown,
    required this.particles,
    required this.heroContent,
    required this.moodContent,
  });

  @override
  State<_LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<_LandingPage> {
  double _dragStartY = 0;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragStart: (details) {
        _dragStartY = details.globalPosition.dy;
        _isDragging = true;
      },
      onVerticalDragUpdate: (details) {
        if (!_isDragging) return;
        final dragDist = _dragStartY - details.globalPosition.dy;
        if (dragDist.abs() < 12) return;

        if (dragDist > 80) {
          _isDragging = false;
          widget.onSwipeUp();
        } else if (dragDist < -80) {
          _isDragging = false;
          widget.onSwipeDown();
        }
      },
      onVerticalDragEnd: (_) {
        _isDragging = false;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        color: widget.bgColor,
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            // Dot pattern bg
            CustomPaint(
              size: Size.infinite,
              painter: _DotPatternPainter(),
            ),

            // Particle overlay
            if (widget.particles.isNotEmpty)
              CustomPaint(
                size: Size.infinite,
                painter: _ParticlePainter(particles: widget.particles),
              ),

            // Top navbar: always visible icons + badge
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 6, bottom: 2),
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.topLeft,
                        child: _BookLanguageBadge(),
                      ),
                      if (!widget.showMoodScreen)
                        Align(
                          alignment: Alignment.topCenter,
                          child: _ScrollHint(onTap: widget.onSwipeUp),
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
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.05),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: widget.showMoodScreen
                    ? KeyedSubtree(key: const ValueKey('mood'), child: widget.moodContent)
                    : KeyedSubtree(key: const ValueKey('hero'), child: widget.heroContent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hero Content (horizontal: char left, text right) ────────────
class _HeroContent extends StatelessWidget {
  final String userName;
  const _HeroContent({required this.userName});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isSmall = size.width < 400;
    final imgH = (size.height * 0.28).clamp(120.0, 220.0);

    return SizedBox.expand(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 160, 24, 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Tagline above mascot
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

              // Mascot — centered, large, flipped horizontally
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
                      child: Text('🧑‍💻', style: TextStyle(fontSize: 80)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Headline
              _HeadlineText(isSmall: isSmall),

              const SizedBox(height: 14),

              // Body
              Text(
                "good mood or not,\nlet's keep studying with oddy!\nstart now \u266a",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w700,
                  fontSize: isSmall ? 12.0 : 14.0,
                  color: const Color(0xFF444444),
                  height: 1.8,
                ),
              ),
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
        // "moody" — large, italic, white outline
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
        // "study time ✦"
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
                  shadows: [],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
// ── Mood Content ──────────────────────────────────────────────────
class _MoodContent extends StatelessWidget {
  final Animation<Offset> moodSlideAnim;
  final void Function(String mood) onMoodHover;
  final void Function(String mood) onMoodSelected;

  const _MoodContent({
    required this.moodSlideAnim,
    required this.onMoodHover,
    required this.onMoodSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: moodSlideAnim,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Question
            Text(
              "How are you\nfeeling today?",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'BlackHanSans',
                fontSize: MediaQuery.sizeOf(context).width < 400 ? 26 : 32,
                color: const Color(0xFF642D05),
                letterSpacing: 1,
                shadows: const [
                  Shadow(color: Colors.white, offset: Offset(-2, -2), blurRadius: 0),
                  Shadow(color: Colors.white, offset: Offset(2, -2), blurRadius: 0),
                  Shadow(color: Colors.white, offset: Offset(-2, 2), blurRadius: 0),
                  Shadow(color: Colors.white, offset: Offset(2, 2), blurRadius: 0),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Mood buttons
            Column(
              children: [
                _MoodButton(
                  emoji: '😄',
                  label: 'Happy',
                  mood: 'happy',
                  bgColor: const Color(0xFFFF93AE),
                  onHover: onMoodHover,
                  onTap: onMoodSelected,
                ),
                const SizedBox(height: 12),
                _MoodButton(
                  emoji: '😐',
                  label: 'Just okay',
                  mood: 'okay',
                  bgColor: const Color(0xFFFDF6E3),
                  onHover: onMoodHover,
                  onTap: onMoodSelected,
                ),
                const SizedBox(height: 12),
                _MoodButton(
                  emoji: '😮‍💨',
                  label: 'Tired',
                  mood: 'tired',
                  bgColor: const Color(0xFF1A2A4A),
                  labelColor: Colors.white,
                  onHover: onMoodHover,
                  onTap: onMoodSelected,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MoodButton extends StatefulWidget {
  final String emoji;
  final String label;
  final String mood;
  final Color bgColor;
  final Color labelColor;
  final void Function(String) onHover;
  final void Function(String) onTap;

  const _MoodButton({
    required this.emoji,
    required this.label,
    required this.mood,
    required this.bgColor,
    required this.onHover,
    required this.onTap,
    this.labelColor = const Color(0xFF111111),
  });

  @override
  State<_MoodButton> createState() => _MoodButtonState();
}

class _MoodButtonState extends State<_MoodButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final btnWidth = (w * 0.75).clamp(200.0, 300.0);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap(widget.mood);
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        transform: Matrix4.translationValues(
          _pressed ? 3 : 0,
          _pressed ? 3 : 0,
          0,
        ),
        width: btnWidth,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: widget.bgColor,
          border: Border.all(color: const Color(0xFF111111), width: 3),
          borderRadius: BorderRadius.circular(20),
          boxShadow: _pressed
              ? const [BoxShadow(color: Color(0xFF111111), offset: Offset(2, 2), blurRadius: 0)]
              : const [BoxShadow(color: Color(0xFF111111), offset: Offset(6, 6), blurRadius: 0)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(widget.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'BlackHanSans',
                fontSize: 18,
                color: widget.labelColor,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Character Widget ──────────────────────────────────────────────
class _CharacterWidget extends StatelessWidget {
  final bool eyesVisible;
  final String eyeLook;

  const _CharacterWidget({
    required this.eyesVisible,
    required this.eyeLook,
  });

  @override
  Widget build(BuildContext context) {
    double eyeOffset = 0;
    if (eyeLook == 'left') eyeOffset = -3;
    if (eyeLook == 'right') eyeOffset = 3;

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E81E),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: const Color(0xFF111111), width: 3),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _Eye(visible: eyesVisible, pupilOffset: eyeOffset),
          const SizedBox(width: 6),
          _Eye(visible: eyesVisible, pupilOffset: eyeOffset),
        ],
      ),
    );
  }
}

class _Eye extends StatelessWidget {
  final bool visible;
  final double pupilOffset;

  const _Eye({required this.visible, required this.pupilOffset});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: visible ? const Color(0xFF915119) : Colors.transparent,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          transform: Matrix4.translationValues(visible ? pupilOffset : 0, 0, 0),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: visible ? const Color(0xFF111111) : Colors.transparent,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
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
          BoxShadow(color: Color(0xFF111111), offset: Offset(3, 3), blurRadius: 0),
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
          BoxShadow(color: Color(0xFF111111), offset: Offset(2, 2), blurRadius: 0),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
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
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
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
// ── Scroll Hint (black pill, yellow text, wobble) ───────────────
class _ScrollHint extends StatefulWidget {
  final VoidCallback onTap;
  const _ScrollHint({required this.onTap});

  @override
  State<_ScrollHint> createState() => _ScrollHintState();
}

class _ScrollHintState extends State<_ScrollHint>
    with SingleTickerProviderStateMixin {
  late AnimationController _wobble;
  late Animation<double> _rotate;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _wobble = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3000))
      ..repeat();
    _rotate = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: -0.017, end: 0.026), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.026, end: -0.017), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -0.017, end: 0.017), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.017, end: -0.009), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -0.009, end: -0.017), weight: 20),
    ]).animate(CurvedAnimation(parent: _wobble, curve: Curves.easeInOut));
    _scale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.04), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.04, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.03), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.03, end: 1.0), weight: 40),
    ]).animate(CurvedAnimation(parent: _wobble, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _wobble.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _wobble,
        builder: (_, child) => Transform.rotate(
          angle: _rotate.value,
          child: Transform.scale(scale: _scale.value, child: child),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            border: Border.all(color: const Color(0xFF111111), width: 3),
            borderRadius: BorderRadius.circular(999),
            boxShadow: const [
              BoxShadow(color: Colors.white, offset: Offset(4, 4), blurRadius: 0),
              BoxShadow(
                  color: Color(0xFF111111),
                  offset: Offset(4, 4),
                  blurRadius: 0,
                  spreadRadius: 2),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'SCROLL TO DISCOVER',
                style: TextStyle(
                  fontFamily: 'BlackHanSans',
                  fontSize: 12,
                  letterSpacing: 2,
                  color: Color(0xFFE5E81E),
                ),
              ),
              _BouncingArrow(),
            ],
          ),
        ),
      ),
    );
  }
}

class _BouncingArrow extends StatefulWidget {
  @override
  State<_BouncingArrow> createState() => _BouncingArrowState();
}

class _BouncingArrowState extends State<_BouncingArrow>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _y;
  late Animation<double> _op;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
    _y = Tween(begin: 0.0, end: 5.0)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
    _op = Tween(begin: 1.0, end: 0.6)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _y.value),
        child: Opacity(
          opacity: _op.value,
          child: const Text('↓',
              style: TextStyle(
                  fontSize: 22, color: Color(0xFFE5E81E), height: 1.1)),
        ),
      ),
    );
  }
}
// ── Diagonal Stripe Painter (matches Vue -45deg lines) ───────────
class _DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.05)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const gap = 24.0;
    final total = size.width + size.height;
    for (double i = -size.height; i < total; i += gap) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Particle Painter ──────────────────────────────────────────────
class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  const _ParticlePainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()..color = p.color.withOpacity(0.75);
      final cx = p.x * size.width;
      final cy = p.y * size.height;

      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(p.rotation);

      if (p.type == 'flower') {
        _drawFlower(canvas, p.size, paint);
      } else if (p.type == 'sparkle') {
        _drawSparkle(canvas, p.size, paint);
      } else if (p.type == 'leaf') {
        paint.color = p.color;
        _drawLeaf(canvas, p.size, paint);
      } else if (p.type == 'rain') {
        paint
          ..color = p.color.withOpacity(0.7)
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke;
        canvas.drawLine(Offset.zero, Offset(-1.2, p.size), paint);
      }

      canvas.restore();
    }
  }

  void _drawFlower(Canvas canvas, double size, Paint paint) {
    paint.color = Colors.white.withOpacity(0.85);
    for (int i = 0; i < 5; i++) {
      canvas.save();
      canvas.rotate(i * 2 * pi / 5);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(0, -size / 2), width: size / 2, height: size / 1.25),
        paint,
      );
      canvas.restore();
    }
    paint.color = const Color(0xFFFFF176);
    canvas.drawCircle(Offset.zero, size / 4, paint);
  }

  void _drawSparkle(Canvas canvas, double size, Paint paint) {
    paint
      ..color = const Color(0xFFFFEB3B)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < 4; i++) {
      canvas.save();
      canvas.rotate(i * pi / 4);
      canvas.drawLine(Offset(0, -size * 0.6), Offset(0, size * 0.6), paint);
      canvas.restore();
    }
  }

  void _drawLeaf(Canvas canvas, double size, Paint paint) {
    final path = Path()
      ..moveTo(0, -size / 2)
      ..cubicTo(size / 2, -size / 4, size / 2, size / 4, 0, size / 2)
      ..cubicTo(-size / 2, size / 4, -size / 2, -size / 4, 0, -size / 2);
    paint.style = PaintingStyle.fill;
    canvas.drawPath(path, paint);
    paint
      ..color = const Color(0xFF507832).withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, -size / 2), Offset(0, size / 2), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ── Particle model ────────────────────────────────────────────────
class _Particle {
  double x, y;
  double speedY, speedX;
  double size;
  String type;
  Color color;
  double rotation, rotSpeed;
  double swing;

  _Particle({
    required this.x,
    required this.y,
    required this.speedY,
    required this.speedX,
    required this.size,
    required this.type,
    required this.color,
    required this.rotation,
    required this.rotSpeed,
    required this.swing,
  });
}