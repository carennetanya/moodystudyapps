import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'theme_selector_screen.dart';
import 'upload_screen.dart';

class LocationScreen extends StatefulWidget {
  final String mood;
  final String userName;
  final AppTheme theme;
  final AudioPlayer? audioPlayer;

  const LocationScreen({
    super.key,
    required this.mood,
    this.userName = 'Friend',
    this.theme = AppTheme.green,
    this.audioPlayer,
  });

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // Banner notif
  late AnimationController _bannerController;
  late Animation<Offset> _bannerSlide;
  late Animation<double> _bannerFade;
  bool _showBanner = false;

  // Warna background berdasarkan mood
  Color get _bgColor {
    switch (widget.mood) {
      case 'happy':
        return const Color(0xFFFF8FAB); // pink
      case 'okay':
        return const Color(0xFFFFFFFF); // putih
      case 'sad':
        return const Color(0xFF90CAF9); // biru
      case 'tired':
        return const Color(0xFF90CAF9); // biru juga untuk tired
      default:
        return const Color(0xFFFF8FAB);
    }
  }

  Color get _stripeColor {
    switch (widget.mood) {
      case 'okay':
        return Colors.black.withOpacity(0.04);
      default:
        return Colors.black.withOpacity(0.06);
    }
  }

  @override
  void initState() {
    super.initState();

    // Screen fade-in
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

    // Banner slide-in dari atas
    _bannerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _bannerSlide = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _bannerController, curve: Curves.easeOutBack),
    );
    _bannerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bannerController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _bannerController.dispose();
    super.dispose();
  }

  String _selectedLocation = '';

  void _selectLocation(String location) {
    setState(() {
      _selectedLocation = location;
      _showBanner = true;
    });
    _bannerController.forward(from: 0);

    // Start fading out background music if available
    _fadeOutAudio();

    // Auto-hide banner setelah 3 detik
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _bannerController.reverse().then((_) {
          if (mounted) setState(() => _showBanner = false);
        });
      }
    });

    debugPrint('Location selected: $location, Mood: ${widget.mood}');

    // Delay navigasi supaya banner sempat keliatan
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => UploadScreen(
            mood: widget.mood,
            location: location,
            userName: widget.userName,
            theme: widget.theme,
            // audio is already faded/paused by this point
          ),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    });
  }

  Future<void> _fadeOutAudio({int durationMs = 700}) async {
    final player = widget.audioPlayer;
    if (player == null) return;
    try {
      const steps = 8;
      final stepDur = Duration(milliseconds: (durationMs / steps).round());
      for (var i = 0; i < steps; i++) {
        final vol = (1.0 - ((i + 1) / steps)).clamp(0.0, 1.0);
        await player.setVolume(vol);
        await Future.delayed(stepDur);
      }
      await player.pause();
      await player.setVolume(1.0);
    } catch (e) {
      debugPrint('Audio fade error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      color: _bgColor,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Diagonal stripe bg
            CustomPaint(
              size: Size.infinite,
              painter: _DiagonalStripePainter(stripeColor: _stripeColor),
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
                      const Align(
                        alignment: Alignment.topRight,
                        child: _LogoBadge(),
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
                          _QuestionText(),
                          const SizedBox(height: 36),
                          _LocationButton(
                            icon: Icons.home_outlined,
                            label: 'Home / Outside',
                            location: 'home',
                            onTap: _selectLocation,
                          ),
                          const SizedBox(height: 16),
                          _LocationButton(
                            icon: Icons.menu_book_outlined,
                            label: 'Library',
                            location: 'library',
                            onTap: _selectLocation,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Sound Alert Banner ──────────────────────────────────
            if (_showBanner)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 72),
                    child: SlideTransition(
                      position: _bannerSlide,
                      child: FadeTransition(
                        opacity: _bannerFade,
                        child: Center(
                          child: _SoundAlertBanner(location: _selectedLocation),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Sound Alert Banner ────────────────────────────────────────────
class _SoundAlertBanner extends StatelessWidget {
  final String location;
  const _SoundAlertBanner({required this.location});

  bool get _isLibrary => location == 'library';

  @override
  Widget build(BuildContext context) {
    // Home: kuning muda bg, border hitam, teks hitam, icon speaker aktif
    // Library: hitam bg, border hitam, teks hijau, icon speaker muted
    final bgColor = _isLibrary
        ? const Color(0xFF111111)
        : const Color(0xFFFFF9C4);
    final textColor = _isLibrary
        ? const Color(0xFF1EE86F)  // hijau
        : const Color(0xFF111111);
    final iconWidget = _isLibrary
        ? const Icon(Icons.volume_off_rounded, color: Color(0xFFFF6B8A), size: 20)
        : const Icon(Icons.volume_up_rounded, color: Color(0xFF111111), size: 20);
    final String label = _isLibrary
        ? 'Silent mode & visual alerts only'
        : 'Sound alerts & notifications active';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: const Color(0xFF111111), width: 2.5),
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF111111),
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          iconWidget,
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'BlackHanSans',
                fontSize: 14,
                color: textColor,
                letterSpacing: 0.3,
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

    return Text(
      'Where are you\nstudying now?',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: 'BlackHanSans',
        fontSize: fontSize,
        color: const Color(0xFF111111),
        letterSpacing: 0.5,
        height: 1.25,
        shadows: const [
          Shadow(color: Colors.white, offset: Offset(-2, -2), blurRadius: 0),
          Shadow(color: Colors.white, offset: Offset(2, -2), blurRadius: 0),
          Shadow(color: Colors.white, offset: Offset(-2, 2), blurRadius: 0),
          Shadow(color: Colors.white, offset: Offset(2, 2), blurRadius: 0),
        ],
      ),
    );
  }
}

// ── Location Button ───────────────────────────────────────────────
class _LocationButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final String location;
  final void Function(String) onTap;

  const _LocationButton({
    required this.icon,
    required this.label,
    required this.location,
    required this.onTap,
  });

  @override
  State<_LocationButton> createState() => _LocationButtonState();
}

class _LocationButtonState extends State<_LocationButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final btnWidth = (w * 0.82).clamp(240.0, 360.0);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap(widget.location);
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
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
        decoration: BoxDecoration(
          color: Colors.white,
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
            Icon(
              widget.icon,
              size: 32,
              color: const Color(0xFF111111),
            ),
            const SizedBox(height: 8),
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
  final Color stripeColor;
  const _DiagonalStripePainter({required this.stripeColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = stripeColor
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
  bool shouldRepaint(covariant _DiagonalStripePainter old) =>
      old.stripeColor != stripeColor;
}