import 'dart:async';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:dartz/dartz.dart' hide State;
import 'package:moody_study/core/exception_handler.dart';
import 'package:moody_study/core/failure.dart' show AudioFailure, Failure;
import 'package:moody_study/core/error/failures.dart';
import 'package:moody_study/services/auth_service.dart';
import 'package:moody_study/services/validation_service.dart';
import 'package:moody_study/utils/input_formatters.dart';
import 'character_intro_screen.dart';
import 'theme_selector_screen.dart';
import 'login_screen.dart';
import '../widgets/music_visualizer_widget.dart';
import '../utils/app_localizations.dart';
import '../widgets/patrol_pin_dialog.dart';

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

  // Per-field inline error text (null = no error shown)
  String? _nameError;
  String? _usernameError;
  String? _emailError;
  String? _passwordError;

  // Async check state
  bool _isUsernameChecking = false;
  bool _isEmailChecking = false;
  bool _isOffline = false;

  // Debounce timers
  Timer? _usernameDebounce;
  Timer? _emailDebounce;

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _isPlaying = true;

  static const String _audioFile = 'audio/SZA - Good Days (Audio).mp3';

  late AnimationController _fadeController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideIn;

  // Regex matching the backend @Pattern constraint
  static final _usernameRegex = RegExp(r'^[a-z0-9._-]+$');
  static final _emailRegex =
      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

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
    _usernameDebounce?.cancel();
    _emailDebounce?.cancel();
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

  // ─── Form validity ──────────────────────────────────────────────────────────

  bool get _isFormValid {
    final name = _nameController.text.trim();
    final username = _usernameController.text;
    final email = _emailController.text;
    final password = _passwordController.text;
    final confirm = _confirmController.text;
    return name.isNotEmpty &&
        name.length <= 30 &&
        username.isNotEmpty &&
        _usernameError == null &&
        _emailError == null &&
        _nameError == null &&
        _passwordError == null &&
        email.isNotEmpty &&
        password.length >= 6 &&
        password == confirm &&
        !_isUsernameChecking &&
        !_isEmailChecking &&
        !_isOffline;
  }

  // ─── Validation helpers ─────────────────────────────────────────────────────

  void _onNameChanged(String v) {
    final l = AppLocalizations.of(context, listen: false);
    final trimmed = v.trim();
    String? err;
    if (trimmed.length > 30) err = l.validationNameTooLong;
    setState(() => _nameError = err);
  }

  void _onUsernameChanged(String v) {
    _usernameDebounce?.cancel();
    final l = AppLocalizations.of(context, listen: false);

    if (v.isEmpty) {
      setState(() {
        _usernameError = null;
        _isUsernameChecking = false;
      });
      return;
    }

    // Immediate format checks
    String? err;
    if (v.length < 3) {
      err = l.validationUsernameTooShort;
    } else if (v.length > 16) {
      err = l.validationUsernameTooLong;
    } else if (!_usernameRegex.hasMatch(v)) {
      err = l.validationUsernameFormat;
    }

    if (err != null) {
      setState(() {
        _usernameError = err;
        _isUsernameChecking = false;
      });
      return;
    }

    // Format OK → debounced async check
    setState(() {
      _usernameError = null;
      _isUsernameChecking = true;
    });
    _usernameDebounce = Timer(
      const Duration(milliseconds: 500),
      () => _checkUsername(v),
    );
  }

  void _onEmailChanged(String v) {
    _emailDebounce?.cancel();
    final l = AppLocalizations.of(context, listen: false);

    if (v.isEmpty) {
      setState(() {
        _emailError = null;
        _isEmailChecking = false;
      });
      return;
    }

    // Immediate format checks
    if (v.contains(' ')) {
      setState(() {
        _emailError = l.validationEmailContainsSpace;
        _isEmailChecking = false;
      });
      return;
    }
    if (!_emailRegex.hasMatch(v)) {
      setState(() {
        _emailError = l.validationEmailFormat;
        _isEmailChecking = false;
      });
      return;
    }

    // Format OK → debounced async check
    setState(() {
      _emailError = null;
      _isEmailChecking = true;
    });
    _emailDebounce = Timer(
      const Duration(milliseconds: 500),
      () => _checkEmail(v),
    );
  }

  void _onPasswordChanged(String v) {
    final l = AppLocalizations.of(context, listen: false);
    setState(() {
      _passwordError = v.isNotEmpty && v.length < 6
          ? l.validationPasswordTooShort
          : null;
    });
  }

  // ─── Async uniqueness checks ────────────────────────────────────────────────

  Future<void> _checkUsername(String username) async {
    if (!mounted) return;
    final l = AppLocalizations.of(context, listen: false);
    final result = await ValidationService.checkUsername(username);
    if (!mounted) return;
    result.fold(
      (failure) {
        final offline =
            failure is NetworkOfflineFailure || failure is NetworkTimeoutFailure;
        setState(() {
          _isUsernameChecking = false;
          if (offline) _isOffline = true;
        });
      },
      (check) {
        setState(() {
          _isUsernameChecking = false;
          _isOffline = false;
          if (!check.available) _usernameError = l.validationUsernameAlreadyTaken;
        });
      },
    );
  }

  Future<void> _checkEmail(String email) async {
    if (!mounted) return;
    final l = AppLocalizations.of(context, listen: false);
    final result = await ValidationService.checkEmail(email);
    if (!mounted) return;
    result.fold(
      (failure) {
        final offline =
            failure is NetworkOfflineFailure || failure is NetworkTimeoutFailure;
        setState(() {
          _isEmailChecking = false;
          if (offline) _isOffline = true;
        });
      },
      (check) {
        setState(() {
          _isEmailChecking = false;
          _isOffline = false;
          if (!check.available) _emailError = l.validationEmailAlreadyRegistered;
        });
      },
    );
  }

  // ─── Navigation ─────────────────────────────────────────────────────────────

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            LoginScreen(theme: widget.theme, audioPlayer: widget.audioPlayer),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  // ─── Submit ──────────────────────────────────────────────────────────────────

  void _onRegister() async {
    final l = AppLocalizations.of(context, listen: false);

    // Trigger name validation on submit (catches empty field)
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = l.validationNameEmpty);
      return;
    }

    final password = _passwordController.text;
    final confirm = _confirmController.text;
    if (password != confirm) {
      setState(() => _passwordError = l.registerPasswordMismatch);
      return;
    }

    if (!_isFormValid) return;

    setState(() => _isLoading = true);

    final result = await AuthService.register(
      name: name,
      username: _usernameController.text,
      email: _emailController.text,
      password: password,
    );

    if (!mounted) return;

    result.fold(
      (failure) {
        // Map server-side taken errors back to inline field errors
        final msg = failure.localizedMessage(context);
        setState(() {
          _isLoading = false;
          if (failure is EmailAlreadyRegisteredFailure ||
              failure.messageKey == 'errors.validation.email.taken') {
            _emailError = msg;
          } else if (failure is UsernameAlreadyTakenFailure ||
              failure.messageKey == 'errors.validation.username.taken') {
            _usernameError = msg;
          } else {
            _nameError = msg;
          }
        });
      },
      (_) async {
        if (mounted) {
          await showPatrolPinDialog(context, PatrolPinDialogMode.setup);
        }
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => CharacterIntroScreen(
              userName: _nameController.text.trim(),
              theme: widget.theme,
            ),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      },
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isDark = widget.theme == AppTheme.dark;
    final bgColor = isDark ? const Color(0xFF1a1a2e) : const Color(0xFF1EE86F);

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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Column(
                    children: [
                      _buildHeader(isDark),
                      const SizedBox(height: 32),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 36),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                              color: const Color(0xFF111111), width: 4),
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
                            Align(
                              alignment: Alignment.center,
                              child: Text(
                                'Create new account',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF111111).withOpacity(0.5),
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // ── Offline banner ─────────────────────────────
                            if (_isOffline)
                              _OfflineBanner(message: l.bannerOffline),

                            // ── Name ───────────────────────────────────────
                            _buildLabel(l.registerFullName),
                            const SizedBox(height: 6),
                            _RegisterInput(
                              controller: _nameController,
                              focusNode: _nameFocus,
                              hintText: l.registerNameHint,
                              textInputAction: TextInputAction.next,
                              enabled: !_isOffline,
                              errorText: _nameError,
                              onSubmitted: (_) => FocusScope.of(context)
                                  .requestFocus(_usernameFocus),
                              onChanged: _onNameChanged,
                            ),
                            const SizedBox(height: 18),

                            // ── Username ───────────────────────────────────
                            _buildLabel(l.registerUsername),
                            const SizedBox(height: 6),
                            _RegisterInput(
                              controller: _usernameController,
                              focusNode: _usernameFocus,
                              hintText: 'username',
                              textInputAction: TextInputAction.next,
                              enabled: !_isOffline,
                              errorText: _usernameError,
                              isChecking: _isUsernameChecking,
                              inputFormatters: [
                                LowercaseTextInputFormatter(),
                                NoSpaceTextInputFormatter(),
                              ],
                              onSubmitted: (_) => FocusScope.of(context)
                                  .requestFocus(_emailFocus),
                              onChanged: _onUsernameChanged,
                            ),
                            const SizedBox(height: 18),

                            // ── Email ──────────────────────────────────────
                            _buildLabel(l.loginEmail),
                            const SizedBox(height: 6),
                            _RegisterInput(
                              controller: _emailController,
                              focusNode: _emailFocus,
                              hintText: 'email@example.com',
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              enabled: !_isOffline,
                              errorText: _emailError,
                              isChecking: _isEmailChecking,
                              inputFormatters: [LowercaseEmailFormatter()],
                              onSubmitted: (_) => FocusScope.of(context)
                                  .requestFocus(_passwordFocus),
                              onChanged: _onEmailChanged,
                            ),
                            const SizedBox(height: 18),

                            // ── Password ───────────────────────────────────
                            _buildLabel(l.loginPassword),
                            const SizedBox(height: 6),
                            _RegisterInput(
                              controller: _passwordController,
                              focusNode: _passwordFocus,
                              hintText: l.registerPasswordHint,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.next,
                              enabled: !_isOffline,
                              errorText: _passwordError,
                              onSubmitted: (_) => FocusScope.of(context)
                                  .requestFocus(_confirmFocus),
                              onChanged: _onPasswordChanged,
                              suffixIcon: GestureDetector(
                                onTap: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                                child: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color:
                                      const Color(0xFF111111).withOpacity(0.4),
                                  size: 22,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),

                            // ── Confirm password ───────────────────────────
                            _buildLabel(l.registerConfirmPassword),
                            const SizedBox(height: 6),
                            _RegisterInput(
                              controller: _confirmController,
                              focusNode: _confirmFocus,
                              hintText: l.registerConfirmHint,
                              obscureText: _obscureConfirm,
                              textInputAction: TextInputAction.done,
                              enabled: !_isOffline,
                              onSubmitted: (_) => _onRegister(),
                              onChanged: (_) {
                                // Clear password mismatch error once user edits confirm
                                if (_passwordError != null) {
                                  setState(() => _passwordError = null);
                                }
                              },
                              suffixIcon: GestureDetector(
                                onTap: () => setState(
                                    () => _obscureConfirm = !_obscureConfirm),
                                child: Icon(
                                  _obscureConfirm
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color:
                                      const Color(0xFF111111).withOpacity(0.4),
                                  size: 22,
                                ),
                              ),
                            ),

                            const SizedBox(height: 28),

                            SizedBox(
                              width: double.infinity,
                              child: _RegisterButton(
                                enabled: _isFormValid && !_isLoading,
                                isLoading: _isLoading,
                                onTap: _onRegister,
                                label: l.registerSignUp,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      GestureDetector(
                        onTap: _navigateToLogin,
                        child: Text(
                          l.registerHaveAccount,
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

  Future<Either<Failure, void>> _toggleAudioPlayback(bool play) async {
    try {
      if (play) {
        await widget.audioPlayer?.play(AssetSource(_audioFile));
      } else {
        await widget.audioPlayer?.pause();
      }
      return const Right(null);
    } catch (e) {
      return Left(AudioFailure(sanitizeException(e)));
    }
  }

  void _onMusicToggle() async {
    final newState = !_isPlaying;
    setState(() => _isPlaying = newState);
    (await _toggleAudioPlayback(newState)).fold(
      (f) => debugPrint('Audio toggle error: ${f.message}'),
      (_) {},
    );
  }

  Widget _buildHeader(bool isDark) {
    final l = AppLocalizations.of(context);
    final textColor =
        isDark ? const Color(0xFFE2E8F0) : const Color(0xFF111111);
    final strokeColor =
        isDark ? const Color(0xFF1a1a2e) : const Color(0xFF111111);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Align(
          alignment: Alignment.center,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                l.registerTitle,
                textAlign: TextAlign.center,
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
                l.registerTitle,
                textAlign: TextAlign.center,
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
        ),
        const SizedBox(height: 6),
        Text(
          l.registerSubtitle,
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

// ─── Offline banner ───────────────────────────────────────────────────────────

class _OfflineBanner extends StatelessWidget {
  final String message;
  const _OfflineBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFF0015).withOpacity(0.08),
        border: Border.all(color: const Color(0xFFFF0015), width: 2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded,
              size: 16, color: Color(0xFFFF0015)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFFFF0015),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Input widget ─────────────────────────────────────────────────────────────

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
  final List<dynamic>? inputFormatters;
  final String? errorText;
  final bool isChecking;
  final bool enabled;

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
    this.inputFormatters,
    this.errorText,
    this.isChecking = false,
    this.enabled = true,
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
    final hasError = widget.errorText != null;
    final borderColor = hasError
        ? const Color(0xFFFF0015)
        : const Color(0xFF111111);

    // suffix: spinner while checking, otherwise the provided suffixIcon
    Widget? suffix;
    if (widget.isChecking) {
      suffix = const Padding(
        padding: EdgeInsets.only(right: 12),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFF111111),
          ),
        ),
      );
    } else if (widget.suffixIcon != null) {
      suffix = Padding(
        padding: const EdgeInsets.only(right: 12),
        child: widget.suffixIcon,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: !widget.enabled
                ? const Color(0xFFEEEEEE)
                : _isFocused
                    ? Colors.white
                    : const Color(0xFFF5F5F5),
            border: Border.all(color: borderColor, width: 3),
            borderRadius: BorderRadius.circular(14),
            boxShadow: _isFocused && widget.enabled
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
            readOnly: !widget.enabled,
            inputFormatters: widget.inputFormatters != null
                ? List.castFrom(widget.inputFormatters!)
                : null,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 16,
              color: widget.enabled
                  ? const Color(0xFF111111)
                  : const Color(0xFF999999),
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
              suffixIcon: suffix,
              suffixIconConstraints:
                  const BoxConstraints(minWidth: 0, minHeight: 0),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 5, left: 4),
            child: Text(
              widget.errorText!,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFFFF0015),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Register button ──────────────────────────────────────────────────────────

class _RegisterButton extends StatefulWidget {
  final bool enabled;
  final bool isLoading;
  final VoidCallback onTap;
  final String label;

  const _RegisterButton({
    required this.enabled,
    required this.isLoading,
    required this.onTap,
    required this.label,
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
                  widget.label,
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