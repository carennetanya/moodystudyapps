import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'loading_screen.dart';
import 'register_screen.dart';
import 'login_screen.dart';
import '../widgets/music_visualizer_widget.dart';
import '../widgets/now_playing_widget.dart';

class ThemeSelectorScreen extends StatefulWidget {
  const ThemeSelectorScreen({super.key});

  @override
  State<ThemeSelectorScreen> createState() => _ThemeSelectorScreenState();
}

class _ThemeSelectorScreenState extends State<ThemeSelectorScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _slideIn = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _selectTheme(AppTheme theme) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => LoadingScreen(theme: theme),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1EE86F),
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fadeIn,
            child: SlideTransition(
              position: _slideIn,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Stack(
                      children: [
                        Text(
                          'Choose your\nTheme',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'BlackHanSans',
                            fontSize: 38,
                            letterSpacing: 1,
                            foreground: Paint()
                              ..style = PaintingStyle.stroke
                              ..strokeWidth = 8
                              ..strokeJoin = StrokeJoin.round
                              ..color = const Color(0xFF111111),
                          ),
                        ),
                        const Text(
                          'Choose your\nTheme',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'BlackHanSans',
                            fontSize: 38,
                            color: Colors.white,
                            letterSpacing: 1,
                            shadows: [
                              Shadow(
                                color: Color(0xFF111111),
                                offset: Offset(4, 4),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 48),

                    // Green Theme Button
                    _ThemeButton(
                      label: 'Light Mode',
                      dotColor: const Color(0xFF1EE86F),
                      bgColor: Colors.white,
                      textColor: const Color(0xFF111111),
                      borderColor: const Color(0xFF111111),
                      shadowColor: const Color(0xFF111111),
                      onTap: () => _selectTheme(AppTheme.green),
                    ),

                    const SizedBox(height: 20),

                    // Dark Theme Button
                    _ThemeButton(
                      label: 'Dark Mode',
                      dotColor: const Color(0xFF1a1a2e),
                      bgColor: const Color(0xFF1a1a2e),
                      textColor: const Color(0xFFE2E8F0),
                      borderColor: const Color(0xFFE2E8F0),
                      shadowColor: const Color(0xFF000000),
                      onTap: () => _selectTheme(AppTheme.dark),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeButton extends StatefulWidget {
  final String label;
  final Color dotColor;
  final Color bgColor;
  final Color textColor;
  final Color borderColor;
  final Color shadowColor;
  final VoidCallback onTap;

  const _ThemeButton({
    required this.label,
    required this.dotColor,
    required this.bgColor,
    required this.textColor,
    required this.borderColor,
    required this.shadowColor,
    required this.onTap,
  });

  @override
  State<_ThemeButton> createState() => _ThemeButtonState();
}

class _ThemeButtonState extends State<_ThemeButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: Matrix4.translationValues(
          _pressed ? 4 : 0,
          _pressed ? 4 : 0,
          0,
        ),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        decoration: BoxDecoration(
          color: widget.bgColor,
          border: Border.all(color: widget.borderColor, width: 4),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: widget.shadowColor,
              offset: _pressed ? const Offset(2, 2) : const Offset(6, 6),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: widget.dotColor,
                shape: BoxShape.circle,
                border: Border.all(color: widget.borderColor, width: 3),
              ),
            ),
            const SizedBox(width: 14),
            Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'BlackHanSans',
                fontSize: 22,
                letterSpacing: 2,
                color: widget.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthChoiceScreen extends StatefulWidget {
  final AppTheme theme;
  // Passed from LoadingScreen so music keeps playing across navigation
  final AudioPlayer? audioPlayer;

  const AuthChoiceScreen({super.key, required this.theme, this.audioPlayer});

  @override
  State<AuthChoiceScreen> createState() => _AuthChoiceScreenState();
}

class _AuthChoiceScreenState extends State<AuthChoiceScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideIn;

  bool _isPlaying = true;

  static const String _songName = 'Good Days - SZA';
  static const String _audioFile = 'audio/SZA - Good Days (Audio).mp3';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _slideIn = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    // Do NOT pause music here — let it keep playing into login/register screens
    super.dispose();
  }

  void _onMusicToggle() async {
    final newState = !_isPlaying;
    setState(() => _isPlaying = newState);
    try {
      if (newState) {
        await widget.audioPlayer?.play(AssetSource(_audioFile));
      } else {
        await widget.audioPlayer?.pause();
      }
    } catch (e) {
      debugPrint('Audio toggle error: $e');
    }
  }

  void _goToSignUp() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => RegisterScreen(theme: widget.theme, audioPlayer: widget.audioPlayer),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => LoginScreen(theme: widget.theme, audioPlayer: widget.audioPlayer),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.theme == AppTheme.dark;
    final bgColor = isDark ? const Color(0xFF1a1a2e) : const Color(0xFF1EE86F);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: FadeTransition(
                opacity: _fadeIn,
                child: SlideTransition(
                  position: _slideIn,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Stack(
                      children: [
                        Text(
                          'Welcome to\nMoody Study',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'BlackHanSans',
                            fontSize: 38,
                            letterSpacing: 1,
                            foreground: Paint()
                              ..style = PaintingStyle.stroke
                              ..strokeWidth = 8
                              ..strokeJoin = StrokeJoin.round
                              ..color = isDark
                                  ? const Color(0xFF1a1a2e)
                                  : const Color(0xFF111111),
                          ),
                        ),
                        Text(
                          'Welcome to\nMoody Study',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'BlackHanSans',
                            fontSize: 38,
                            color: Colors.white,
                            letterSpacing: 1,
                            shadows: [
                              Shadow(
                                color: isDark
                                    ? const Color(0xFF1a1a2e)
                                    : const Color(0xFF111111),
                                offset: const Offset(4, 4),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 48),

                    // Sign Up Button
                    _AuthButton(
                      label: 'Sign Up',
                      bgColor: Colors.white,
                      textColor: const Color(0xFF111111),
                      borderColor: const Color(0xFF111111),
                      shadowColor: const Color(0xFF111111),
                      onTap: _goToSignUp,
                    ),

                    const SizedBox(height: 20),

                    // Login Button
                    _AuthButton(
                      label: 'Login',
                      bgColor: isDark ? const Color(0xFF2a2a4e) : Colors.white,
                      textColor: isDark
                          ? const Color(0xFFE2E8F0)
                          : const Color(0xFF111111),
                      borderColor: isDark
                          ? const Color(0xFFE2E8F0)
                          : const Color(0xFF111111),
                      shadowColor: isDark
                          ? const Color(0xFF000000)
                          : const Color(0xFF111111),
                      onTap: _goToLogin,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
            if (widget.audioPlayer != null) ...[
              NowPlayingWidget(
                show: true,
                songName: _songName,
                isPlaying: _isPlaying,
              ),
              MusicVisualizerWidget(
                show: true,
                isPlaying: _isPlaying,
                isDark: isDark,
                onToggle: _onMusicToggle,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AuthButton extends StatefulWidget {
  final String label;
  final Color bgColor;
  final Color textColor;
  final Color borderColor;
  final Color shadowColor;
  final VoidCallback onTap;

  const _AuthButton({
    required this.label,
    required this.bgColor,
    required this.textColor,
    required this.borderColor,
    required this.shadowColor,
    required this.onTap,
  });

  @override
  State<_AuthButton> createState() => _AuthButtonState();
}

class _AuthButtonState extends State<_AuthButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: Matrix4.translationValues(
          _pressed ? 4 : 0,
          _pressed ? 4 : 0,
          0,
        ),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        decoration: BoxDecoration(
          color: widget.bgColor,
          border: Border.all(color: widget.borderColor, width: 4),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: widget.shadowColor,
              offset: _pressed ? const Offset(2, 2) : const Offset(6, 6),
              blurRadius: 0,
            ),
          ],
        ),
        child: Center(
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'BlackHanSans',
              fontSize: 22,
              letterSpacing: 2,
              color: widget.textColor,
            ),
          ),
        ),
      ),
    );
  }
}

enum AppTheme { green, dark }