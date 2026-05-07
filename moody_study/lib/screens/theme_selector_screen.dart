import 'package:flutter/material.dart';
import 'loading_screen.dart';

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
                      label: 'Green Mode',
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

enum AppTheme { green, dark }
