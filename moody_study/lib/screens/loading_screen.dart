import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:dartz/dartz.dart' hide State;
import 'package:moody_study/core/failure.dart';
import 'package:moody_study/core/exception_handler.dart';
import '../widgets/moody_title.dart';
import '../widgets/sub_tagline.dart';
import '../widgets/sound_warning.dart';
import '../widgets/now_playing_widget.dart';
import '../widgets/music_visualizer_widget.dart';
import '../widgets/name_form_overlay.dart';
import 'character_intro_screen.dart';
import 'theme_selector_screen.dart';
import 'login_screen.dart';

class LoadingScreen extends StatefulWidget {
  final AppTheme theme;
  final bool fromRegister;
  final String? userName;

  const LoadingScreen({
    super.key,
    this.theme = AppTheme.green,
    this.fromRegister = false,
    this.userName,
  });

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with TickerProviderStateMixin {
  bool _showSub = false;
  bool _showBtn = false;
  bool _showWarning = false;
  bool _started = false;
  bool _titleDone = false;

  bool _showMusicUI = false;
  bool _isPlaying = true;
  bool _showNameForm = false;
  bool _audioPlayerTransferred = false;

  static const String _songName = 'Good Days - SZA';
  static const String _audioFile = 'audio/SZA - Good Days (Audio).mp3';

  final AudioPlayer _audioPlayer = AudioPlayer();

  late AnimationController _btnController;
  late Animation<double> _btnScale;
  late Animation<double> _btnOpacity;

  late AnimationController _startedController;
  late Animation<double> _startedOpacity;

  @override
  void initState() {
    super.initState();

    _btnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _btnScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _btnController, curve: Curves.elasticOut),
    );
    _btnOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _btnController, curve: Curves.easeIn),
    );

    _startedController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _startedOpacity = Tween<double>(begin: 1.0, end: 0.5).animate(
      CurvedAnimation(parent: _startedController, curve: Curves.easeOut),
    );

    _audioPlayer.setReleaseMode(ReleaseMode.loop);

    // If coming from register, auto-trigger start after title animation completes
    if (widget.fromRegister) {
      Future.delayed(const Duration(milliseconds: 100), () {
        // Will be triggered via _onTitleDone -> _onStart flow
      });
    }
  }

  @override
  void dispose() {
    _btnController.dispose();
    _startedController.dispose();
    if (!_audioPlayerTransferred) {
      _audioPlayer.dispose();
    }
    super.dispose();
  }

  void _onTitleDone() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _showSub = true);
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    setState(() {
      _showBtn = true;
      _showWarning = true;
      _titleDone = true;
    });
    _btnController.forward();

    // If coming from register, auto-start after a brief delay
    if (widget.fromRegister) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      _onStartFromRegister();
      return;
    }

    await Future.delayed(const Duration(milliseconds: 7400));
    if (!mounted) return;
    setState(() => _showWarning = false);
  }

  Future<Either<Failure, void>> _playAudio() async {
    try {
      await _audioPlayer.play(AssetSource(_audioFile));
      return const Right(null);
    } catch (e) {
      return Left(AudioFailure(sanitizeException(e)));
    }
  }

  Future<Either<Failure, void>> _toggleAudioPlayback(bool play) async {
    try {
      if (play) {
        await _audioPlayer.play(AssetSource(_audioFile));
      } else {
        await _audioPlayer.pause();
      }
      return const Right(null);
    } catch (e) {
      return Left(AudioFailure(sanitizeException(e)));
    }
  }

  void _onStartFromRegister() async {
    setState(() {
      _started = true;
      _showMusicUI = true;
      _isPlaying = true;
      _showWarning = false;
    });
    _startedController.forward();

    (await _playAudio()).fold(
      (f) => debugPrint('Audio play error: ${f.message}'),
      (_) {},
    );

    if (!mounted) return;
    _navigateToIntro(widget.userName ?? '');
  }

  void _onStart() async {
    if (_started) return;

    setState(() {
      _started = true;
      _showMusicUI = true;
      _isPlaying = true;
      _showWarning = false;
    });
    _startedController.forward();

    (await _playAudio()).fold(
      (f) => debugPrint('Audio play error: ${f.message}'),
      (_) {},
    );

    if (!mounted) return;

    if (!widget.fromRegister) {
      // Pass audioPlayer so music keeps playing across screen transition
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => AuthChoiceScreen(
            theme: widget.theme,
            audioPlayer: _audioPlayer,
          ),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } else {
      _navigateToIntro(widget.userName ?? '');
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

  void _navigateToIntro(String name) {
    _audioPlayerTransferred = true;
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => CharacterIntroScreen(
          userName: name,
          theme: widget.theme,
          audioPlayer: _audioPlayer,
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _onNameSubmit(String name) {
    setState(() => _showNameForm = false);
    _navigateToIntro(name);
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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MoodyTitle(onDone: _onTitleDone),
                    const SizedBox(height: 4),
                    SubTagline(show: _showSub),
                    const SizedBox(height: 28),
                    if (_showBtn)
                      ScaleTransition(
                        scale: _btnScale,
                        child: FadeTransition(
                          opacity: _btnOpacity,
                          child: AnimatedBuilder(
                            animation: _startedOpacity,
                            builder: (context, child) => Opacity(
                              opacity: _started ? _startedOpacity.value : 1.0,
                              child: child,
                            ),
                            child: _StartButton(
                              started: _started,
                              onTap: _onStart,
                              isDark: isDark,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      child: _showWarning
                          ? const SoundWarning(key: ValueKey('warning'))
                          : const SizedBox.shrink(key: ValueKey('empty')),
                    ),
                  ],
                ),
              ),
            ),
            NowPlayingWidget(
              show: _showMusicUI,
              songName: _songName,
              isPlaying: _isPlaying,
            ),
            MusicVisualizerWidget(
              show: _showMusicUI,
              isPlaying: _isPlaying,
              isDark: isDark,
              onToggle: _onMusicToggle,
            ),
            NameFormOverlay(
              show: _showNameForm,
              isDark: isDark,
              onSubmit: _onNameSubmit,
            ),
          ],
        ),
      ),
    );
  }
}

class _StartButton extends StatefulWidget {
  final bool started;
  final VoidCallback onTap;
  final bool isDark;

  const _StartButton(
      {required this.started, required this.onTap, this.isDark = false});

  @override
  State<_StartButton> createState() => _StartButtonState();
}

class _StartButtonState extends State<_StartButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final btnBg = isDark ? const Color(0xFF16213e) : Colors.white;
    final btnBorder =
        isDark ? const Color(0xFFE2E8F0) : const Color(0xFF111111);
    final btnText = isDark ? const Color(0xFFE2E8F0) : const Color(0xFF111111);
    final btnShadow =
        isDark ? const Color(0xFF000000) : const Color(0xFF111111);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        transform: Matrix4.translationValues(
          _pressed ? 3 : 0,
          _pressed ? 3 : 0,
          0,
        ),
        decoration: BoxDecoration(
          color: widget.started ? btnBg.withValues(alpha: 0.5) : btnBg,
          border: Border.all(color: btnBorder, width: 4),
          borderRadius: BorderRadius.circular(16),
          boxShadow: _pressed
              ? [
                  BoxShadow(
                      color: btnShadow,
                      offset: const Offset(2, 2),
                      blurRadius: 0)
                ]
              : [
                  BoxShadow(
                      color: btnShadow,
                      offset: const Offset(6, 6),
                      blurRadius: 0)
                ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 52, vertical: 18),
        child: Text(
          'START',
          style: TextStyle(
            fontFamily: 'BlackHanSans',
            fontSize: 26,
            letterSpacing: 3,
            color: widget.started ? btnText.withValues(alpha: 0.5) : btnText,
          ),
        ),
      ),
    );
  }
}