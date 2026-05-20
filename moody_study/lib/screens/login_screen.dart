import 'package:flutter/material.dart';
import 'package:moody_study/services/auth_service.dart';
import 'loading_screen.dart';
import 'character_intro_screen.dart';
import 'theme_selector_screen.dart';
import 'register_screen.dart';
import '../widgets/music_visualizer_widget.dart';
import 'package:audioplayers/audioplayers.dart';

class LoginScreen extends StatefulWidget {
  final AppTheme theme;
  final AudioPlayer? audioPlayer;

  const LoginScreen({super.key, this.theme = AppTheme.green, this.audioPlayer});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isPlaying = true;

  static const String _songName = 'Good Days - SZA';
  static const String _audioFile = 'audio/SZA - Good Days (Audio).mp3';

  late AnimationController _fadeController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideIn;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    _slideIn = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    return email.isNotEmpty && email.contains('@') && password.length >= 6;
  }

  void _onLogin() async {
    if (!_isFormValid) {
      setState(() {
        if (_emailController.text.trim().isEmpty) {
          _errorMessage = 'Email is required!';
        } else if (!_emailController.text.contains('@')) {
          _errorMessage = 'Invalid email!';
        } else if (_passwordController.text.length < 6) {
          _errorMessage = 'Password must be at least 6 characters!';
        }
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userData = await AuthService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      final userName = (userData['name'] as String?) ?? 'Friend';

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => CharacterIntroScreen(
            userName: userName,
            theme: widget.theme,
            audioPlayer: widget.audioPlayer,
          ),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _navigateToSignUp() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => RegisterScreen(theme: widget.theme, audioPlayer: widget.audioPlayer),
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
    final cardBg = Colors.white;
    final textColor = const Color(0xFF111111);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          SafeArea(
            child: FadeTransition(
              opacity: _fadeIn,
              child: SlideTransition(
                position: _slideIn,
                child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                children: [
                  // Header
                  _buildHeader(isDark),
                  const SizedBox(height: 32),

                  // Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 36),
                    decoration: BoxDecoration(
                      color: cardBg,
                      border:
                          Border.all(color: const Color(0xFF111111), width: 4),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xFF111111),
                          offset: Offset(10, 10),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Subtitle
                        Text(
                          'Welcome back',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: textColor.withOpacity(0.5),
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Email field
                        _buildLabel('Email'),
                        const SizedBox(height: 6),
                        _LoginInput(
                          controller: _emailController,
                          focusNode: _emailFocus,
                          hintText: 'email@example.com',
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          onSubmitted: (_) => FocusScope.of(context)
                              .requestFocus(_passwordFocus),
                          onChanged: (_) =>
                              setState(() => _errorMessage = null),
                        ),
                        const SizedBox(height: 18),

                        // Password field
                        _buildLabel('Password'),
                        const SizedBox(height: 6),
                        _LoginInput(
                          controller: _passwordController,
                          focusNode: _passwordFocus,
                          hintText: 'min. 6 characters',
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _onLogin(),
                          onChanged: (_) =>
                              setState(() => _errorMessage = null),
                          suffixIcon: GestureDetector(
                            onTap: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                            child: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: const Color(0xFF111111).withOpacity(0.4),
                              size: 22,
                            ),
                          ),
                        ),

                        // Error message
                        AnimatedSize(
                          duration: const Duration(milliseconds: 250),
                          child: _errorMessage != null
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 14),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF0015)
                                          .withOpacity(0.08),
                                      border: Border.all(
                                          color: const Color(0xFFFF0015),
                                          width: 2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(
                                        fontFamily: 'Nunito',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFFFF0015),
                                      ),
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),

                        const SizedBox(height: 28),

                        // Login button
                        SizedBox(
                          width: double.infinity,
                          child: _LoginButton(
                            enabled: _isFormValid && !_isLoading,
                            isLoading: _isLoading,
                            onTap: _onLogin,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Don't have account
                  GestureDetector(
                    onTap: _navigateToSignUp,
                    child: Text(
                      'Don\'t have an account? Sign up',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? const Color(0xFFE2E8F0)
                            : const Color(0xFF111111),
                        decoration: TextDecoration.underline,
                        decorationThickness: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
              ),
            ),
          ),
          if (widget.audioPlayer != null)
            MusicVisualizerWidget(
              show: true,
              isPlaying: _isPlaying,
              isDark: isDark,
              onToggle: _onMusicToggle,
            ),
        ],
      ),
    );
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

  Widget _buildHeader(bool isDark) {
    final textColor =
        isDark ? const Color(0xFFE2E8F0) : const Color(0xFF111111);
    final strokeColor =
        isDark ? const Color(0xFF1a1a2e) : const Color(0xFF111111);

    return Column(
      children: [
        Stack(
          children: [
            Text(
              'Login',
              style: TextStyle(
                fontFamily: 'BlackHanSans',
                fontSize: 52,
                letterSpacing: 2,
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 8
                  ..strokeJoin = StrokeJoin.round
                  ..color = strokeColor,
              ),
            ),
            Text(
              'Login',
              style: TextStyle(
                fontFamily: 'BlackHanSans',
                fontSize: 52,
                color: Colors.white,
                letterSpacing: 2,
                shadows: [
                  Shadow(
                    color: strokeColor,
                    offset: const Offset(5, 5),
                    blurRadius: 0,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'to Moody Study',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textColor.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'BlackHanSans',
        fontSize: 15,
        color: Color(0xFF111111),
        letterSpacing: 1,
      ),
    );
  }
}

class _LoginInput extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final ValueChanged<String> onSubmitted;
  final ValueChanged<String> onChanged;
  final Widget? suffixIcon;

  const _LoginInput({
    required this.controller,
    required this.focusNode,
    required this.hintText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    required this.onSubmitted,
    required this.onChanged,
    this.suffixIcon,
  });

  @override
  State<_LoginInput> createState() => _LoginInputState();
}

class _LoginInputState extends State<_LoginInput> {
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(() {
      if (mounted) setState(() => _isFocused = widget.focusNode.hasFocus);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: _isFocused ? Colors.white : const Color(0xFFF5F5F5),
        border: Border.all(
          color: const Color(0xFF111111),
          width: 3,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: const Color(0xFF111111).withOpacity(0.08),
                  blurRadius: 0,
                  spreadRadius: 3,
                ),
              ]
            : [],
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        obscureText: widget.obscureText,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        onSubmitted: widget.onSubmitted,
        onChanged: widget.onChanged,
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 16,
          color: Color(0xFF111111),
        ),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 16,
            color: Color(0xFF999999),
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          suffixIcon: widget.suffixIcon != null
              ? Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: widget.suffixIcon,
                )
              : null,
          suffixIconConstraints:
              const BoxConstraints(minWidth: 0, minHeight: 0),
        ),
      ),
    );
  }
}

class _LoginButton extends StatefulWidget {
  final bool enabled;
  final bool isLoading;
  final VoidCallback onTap;

  const _LoginButton({
    required this.enabled,
    required this.isLoading,
    required this.onTap,
  });

  @override
  State<_LoginButton> createState() => _LoginButtonState();
}

class _LoginButtonState extends State<_LoginButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.enabled && !widget.isLoading;

    return GestureDetector(
      onTapDown: isActive ? (_) => setState(() => _pressed = true) : null,
      onTapUp: isActive
          ? (_) {
              setState(() => _pressed = false);
              widget.onTap();
            }
          : null,
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        transform: Matrix4.translationValues(
          _pressed ? 3 : 0,
          _pressed ? 3 : 0,
          0,
        ),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF111111)
              : const Color(0xFF111111).withOpacity(0.4),
          border: Border.all(
            color: isActive
                ? const Color(0xFF111111)
                : const Color(0xFF111111).withOpacity(0.4),
            width: 3,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isActive && !_pressed
              ? const [
                  BoxShadow(
                    color: Color(0xFF111111),
                    offset: Offset(6, 6),
                    blurRadius: 0,
                  ),
                ]
              : isActive
                  ? const [
                      BoxShadow(
                        color: Color(0xFF111111),
                        offset: Offset(2, 2),
                        blurRadius: 0,
                      ),
                    ]
                  : [],
        ),
        child: Center(
          child: widget.isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
              : Text(
                  'SIGN IN NOW',
                  style: TextStyle(
                    fontFamily: 'BlackHanSans',
                    fontSize: 20,
                    letterSpacing: 2,
                    color:
                        isActive ? Colors.white : Colors.white.withOpacity(0.5),
                  ),
                ),
        ),
      ),
    );
  }
}