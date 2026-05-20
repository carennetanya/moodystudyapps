import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:moody_study/services/auth_service.dart';
import 'loading_screen.dart';
import 'theme_selector_screen.dart';
import 'login_screen.dart';
import '../widgets/music_visualizer_widget.dart';

class RegisterScreen extends StatefulWidget {
  final AppTheme theme;
  final AudioPlayer? audioPlayer;

  const RegisterScreen({super.key, this.theme = AppTheme.green, this.audioPlayer});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _usernameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmFocus = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
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
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _nameFocus.dispose();
    _usernameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;
    return name.isNotEmpty &&
        username.isNotEmpty &&
        username.length >= 3 &&
        !username.contains(' ') &&
        email.isNotEmpty &&
        email.contains('@') &&
        password.length >= 6 &&
        password == confirm;
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => LoginScreen(theme: widget.theme, audioPlayer: widget.audioPlayer),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _onRegister() async {
    if (!_isFormValid) {
      setState(() {
        if (_nameController.text.trim().isEmpty) {
          _errorMessage = 'Name is required!';
        } else if (_usernameController.text.trim().isEmpty) {
          _errorMessage = 'Username is required!';
        } else if (_usernameController.text.trim().length < 3 ||
            _usernameController.text.contains(' ')) {
          _errorMessage = 'Username must be at least 3 characters without spaces!';
        } else if (!_emailController.text.contains('@')) {
          _errorMessage = 'Invalid email!';
        } else if (_passwordController.text.length < 6) {
          _errorMessage = 'Password must be at least 6 characters!';
        } else if (_passwordController.text != _confirmController.text) {
          _errorMessage = 'Passwords do not match!';
        }
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthService.register(
        name: _nameController.text.trim(),
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) =>
              LoadingScreen(theme: widget.theme, fromRegister: true),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
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
                          'Create new account',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: textColor.withOpacity(0.5),
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Name field
                        _buildLabel('Full Name'),
                        const SizedBox(height: 6),
                        _RegisterInput(
                          controller: _nameController,
                          focusNode: _nameFocus,
                          hintText: 'Your name',
                          textInputAction: TextInputAction.next,
                          onSubmitted: (_) => FocusScope.of(context)
                              .requestFocus(_usernameFocus),
                          onChanged: (_) =>
                              setState(() => _errorMessage = null),
                        ),
                        const SizedBox(height: 18),

                        // Username field
                        _buildLabel('Username'),
                        const SizedBox(height: 6),
                        _RegisterInput(
                          controller: _usernameController,
                          focusNode: _usernameFocus,
                          hintText: 'username',
                          textInputAction: TextInputAction.next,
                          onSubmitted: (_) => FocusScope.of(context)
                              .requestFocus(_emailFocus),
                          onChanged: (_) =>
                              setState(() => _errorMessage = null),
                        ),
                        const SizedBox(height: 18),

                        // Email field
                        _buildLabel('Email'),
                        const SizedBox(height: 6),
                        _RegisterInput(
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
                        _RegisterInput(
                          controller: _passwordController,
                          focusNode: _passwordFocus,
                          hintText: 'min. 6 characters',
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.next,
                          onSubmitted: (_) => FocusScope.of(context)
                              .requestFocus(_confirmFocus),
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
                        const SizedBox(height: 18),

                        // Confirm password
                        _buildLabel('Confirm Password'),
                        const SizedBox(height: 6),
                        _RegisterInput(
                          controller: _confirmController,
                          focusNode: _confirmFocus,
                          hintText: 'repeat password',
                          obscureText: _obscureConfirm,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _onRegister(),
                          onChanged: (_) =>
                              setState(() => _errorMessage = null),
                          suffixIcon: GestureDetector(
                            onTap: () => setState(
                                () => _obscureConfirm = !_obscureConfirm),
                            child: Icon(
                              _obscureConfirm
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

                        // Register button
                        SizedBox(
                          width: double.infinity,
                          child: _RegisterButton(
                            enabled: _isFormValid && !_isLoading,
                            isLoading: _isLoading,
                            onTap: _onRegister,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Already have account
                  GestureDetector(
                    onTap: _navigateToLogin,
                    child: Text(
                      'Already have an account? Login',
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
              'Sign Up',
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
              'Sign Up',
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

class _RegisterInput extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final ValueChanged<String> onSubmitted;
  final ValueChanged<String> onChanged;
  final Widget? suffixIcon;

  const _RegisterInput({
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
  State<_RegisterInput> createState() => _RegisterInputState();
}

class _RegisterInputState extends State<_RegisterInput> {
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

class _RegisterButton extends StatefulWidget {
  final bool enabled;
  final bool isLoading;
  final VoidCallback onTap;

  const _RegisterButton({
    required this.enabled,
    required this.isLoading,
    required this.onTap,
  });

  @override
  State<_RegisterButton> createState() => _RegisterButtonState();
}

class _RegisterButtonState extends State<_RegisterButton> {
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
                  'SIGN UP NOW',
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