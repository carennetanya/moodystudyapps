import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import 'theme_selector_screen.dart';
import 'mood_screen.dart';
import 'location_screen.dart';
import 'your_files_screen.dart';
import 'oddy_flashcard_screen.dart';
import 'statistik_screen.dart';
import 'daily_quest_screen.dart';
import 'kuis_screen.dart';
import 'profile_screen.dart';
import 'shop_screen.dart';
import 'collection_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:moody_study/services/streak_service.dart';
import 'package:moody_study/services/auth_service.dart';
import 'package:moody_study/services/profile_image_provider.dart';
import 'life_lost_popup.dart';
import 'package:moody_study/services/daily_quest_service.dart';
import 'package:moody_study/utils/app_localizations.dart';
import 'package:dartz/dartz.dart' hide State;
import 'package:moody_study/core/failure.dart';
import 'package:moody_study/core/exception_handler.dart';
import 'schedule_screen.dart';

// ── Time-slot theme ───────────────────────────────────────────────
enum IntroTimeSlot { pagi, siang, sore, malam }

class _SlotPalette {
  final Color bg;
  final Color accent;
  final Color textColor;
  final Color stripeColor;
  final List<Shadow> headlineShadows;

  const _SlotPalette({
    required this.bg,
    required this.accent,
    required this.textColor,
    required this.stripeColor,
    required this.headlineShadows,
  });
}

const _kDayShadows = <Shadow>[
  Shadow(color: Color(0xFFFFFFFF), offset: Offset(-3, -3), blurRadius: 0),
  Shadow(color: Color(0xFFFFFFFF), offset: Offset(3, -3), blurRadius: 0),
  Shadow(color: Color(0xFFFFFFFF), offset: Offset(-3, 3), blurRadius: 0),
  Shadow(color: Color(0xFFFFFFFF), offset: Offset(3, 3), blurRadius: 0),
];

const _kNightShadows = <Shadow>[];

extension _IntroTimeSlotX on IntroTimeSlot {
  _SlotPalette get palette {
    switch (this) {
      case IntroTimeSlot.pagi:
        return const _SlotPalette(
          bg: Color(0xFFFFE8B0),
          accent: Color(0xFFFF9E6B),
          textColor: Color(0xFF333333),
          stripeColor: Color(0x0D000000),
          headlineShadows: _kDayShadows,
        );
      case IntroTimeSlot.siang:
        return const _SlotPalette(
          bg: Color(0xFFFFF8E1),
          accent: Color(0xFFFFB300),
          textColor: Color(0xFF333333),
          stripeColor: Color(0x0D000000),
          headlineShadows: _kDayShadows,
        );
      case IntroTimeSlot.sore:
        return const _SlotPalette(
          bg: Color(0xFFFFB07A),
          accent: Color(0xFFD84315),
          textColor: Color(0xFF333333),
          stripeColor: Color(0x0D000000),
          headlineShadows: _kDayShadows,
        );
      case IntroTimeSlot.malam:
        return const _SlotPalette(
          bg: Color(0xFF1A237E),
          accent: Color(0xFF7986CB),
          textColor: Color(0xFFECEFF1),
          stripeColor: Color(0x14FFFFFF),
          headlineShadows: _kNightShadows,
        );
    }
  }
}

IntroTimeSlot _slotFromNow() {
  final h = DateTime.now().hour;
  if (h >= 3 && h < 10) return IntroTimeSlot.pagi;
  if (h >= 10 && h < 15) return IntroTimeSlot.siang;
  if (h >= 15 && h < 18) return IntroTimeSlot.sore;
  return IntroTimeSlot.malam;
}

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

    // Cek bolos setelah landing page tampil
    _checkLoginStatus();
  }

  Future<Either<Failure, LoginCheckResult?>> _fetchLoginStatus() async {
    try {
      final token = AuthService.token;
      if (token == null) return const Right(null);
      final baseUrl = StreakService.baseUrl;
      final res = await http.post(
        Uri.parse('$baseUrl/api/streak/check-login'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (res.statusCode == 200) {
        return Right(LoginCheckResult.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>,
        ));
      }
      return const Right(null);
    } catch (e) {
      return Left(NetworkFailure(sanitizeException(e)));
    }
  }

  Future<void> _checkLoginStatus() async {
    final result = await _fetchLoginStatus();
    await result.fold(
      (f) async => debugPrint('checkLogin error: ${f.message}'),
      (loginResult) async {
        if (loginResult != null && mounted) {
          if (loginResult.livesLost > 0 || loginResult.leveledDown) {
            await Future.delayed(const Duration(milliseconds: 600));
            if (mounted) await showLifeLostPopup(context, loginResult);
          }
        }
      },
    );
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

  void _onScheduleTap() {
    if (!mounted) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const ScheduleScreen(),
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
                userName: widget.userName,
                theme: widget.theme,
                audioPlayer: widget.audioPlayer,
                onStartNow: _onStartNow,
                onScheduleTap: _onScheduleTap,
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
class _LandingPage extends StatefulWidget {
  final String userName;
  final AppTheme theme;
  final AudioPlayer? audioPlayer;
  final VoidCallback? onStartNow;
  final VoidCallback? onScheduleTap;

  const _LandingPage({
    required this.userName,
    required this.theme,
    this.audioPlayer,
    this.onStartNow,
    this.onScheduleTap,
  });

  @override
  State<_LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<_LandingPage> {
  int _selectedNav = 0;
  late IntroTimeSlot _slot;
  Timer? _slotTimer;

  AudioPlayer? _ownedPlayer;
  bool _isPlaying = false;

  AudioPlayer? get _player => widget.audioPlayer ?? _ownedPlayer;

  static const String _audioFile = 'audio/SZA - Good Days (Audio).mp3';

  @override
  void initState() {
    super.initState();
    _slot = _slotFromNow();
    _slotTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      final newSlot = _slotFromNow();
      if (newSlot != _slot) setState(() => _slot = newSlot);
    });
    _initMusic();
  }

  void _initMusic() async {
    if (widget.audioPlayer != null) {
      // Reuse player dari LoadingScreen yang sudah berjalan
      if (mounted) setState(() => _isPlaying = true);
    } else {
      // Buat player sendiri (flow register langsung)
      _ownedPlayer = AudioPlayer();
      try {
        await _ownedPlayer!.play(AssetSource(_audioFile));
        if (mounted) setState(() => _isPlaying = true);
      } catch (_) {}
    }
  }

  void _toggleMusic() async {
    final p = _player;
    if (p == null) return;
    if (_isPlaying) {
      await p.pause();
    } else {
      await p.resume();
    }
    if (mounted) setState(() => _isPlaying = !_isPlaying);
  }

  @override
  void dispose() {
    _slotTimer?.cancel();
    _ownedPlayer?.dispose();
    super.dispose();
  }

  void _onNavTap(BuildContext context, int index) {
    if (index == 0) {
      // Home: sudah di sini
      setState(() => _selectedNav = 0);
      return;
    }

    setState(() => _selectedNav = index);

    switch (index) {
      case 1: // Daily Quest
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const DailyQuestScreen(),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 300),
          ),
        ).then((_) => setState(() => _selectedNav = 0));
        break;
      case 2: // Your Files
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const YourFilesScreen(),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 300),
          ),
        ).then((_) => setState(() => _selectedNav = 0));
        break;
      case 3: // Quiz
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const KuisScreen(),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 300),
          ),
        ).then((_) => setState(() => _selectedNav = 0));
        break;
      case 4: // Statistik
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const StatistikScreen(),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 300),
          ),
        ).then((_) {
          DailyQuestService.completeReviewStats().catchError((_) {});
          setState(() => _selectedNav = 0);
        });
        break;
      case 5: // Profile
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const ProfileScreen(),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 300),
          ),
        ).then((_) => setState(() => _selectedNav = 0));
        break;
      case 6: // Shop
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const ShopScreen(),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 300),
          ),
        ).then((_) => setState(() => _selectedNav = 0));
        break;
      case 7: // Collection
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const CollectionScreen(),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 300),
          ),
        ).then((_) => setState(() => _selectedNav = 0));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = _slot.palette;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      color: palette.bg,
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: _DiagonalStripePainter(stripeColor: palette.stripeColor),
          ),

          // Main content
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  child: _HeroContent(
                    userName: widget.userName,
                    onStartNow: widget.onStartNow,
                    onScheduleTap: widget.onScheduleTap,
                    textColor: palette.textColor,
                    headlineShadows: palette.headlineShadows,
                  ),
                ),
              ],
            ),
          ),

          // Top bar (level badge + streak + lives)
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 6, bottom: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const _StatsBadge(),
                    const Spacer(),
                    _MusicToggleButton(
                      isPlaying: _isPlaying,
                      onTap: _toggleMusic,
                    ),
                    const SizedBox(width: 8),
                    const LanguageToggleButton(),
                    const SizedBox(width: 8),
                    const _LivesBox(),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Navigation Bar
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _BottomNavBar(
              selectedIndex: _selectedNav,
              onTap: (i) => _onNavTap(context, i),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bottom Navigation Bar ─────────────────────────────────────────
class _BottomNavBar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _BottomNavBar({required this.selectedIndex, required this.onTap});

  @override
  State<_BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<_BottomNavBar>
    with SingleTickerProviderStateMixin {
  bool _dropupOpen = false;
  OverlayEntry? _overlayEntry;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _removeOverlay();
    _animCtrl.dispose();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showOverlay(BuildContext context) {
    _removeOverlay();
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox?;
    final size = renderBox?.size ?? Size.zero;
    final offset = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;

    _overlayEntry = OverlayEntry(
      builder: (_) => Stack(
        children: [
          // tap outside to close
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeDropup,
              behavior: HitTestBehavior.translucent,
              child: Container(color: Colors.transparent),
            ),
          ),
          // dropup menu positioned above the "..." button
          Positioned(
            bottom: MediaQuery.of(context).size.height - offset.dy + 8,
            right: MediaQuery.of(context).size.width - (offset.dx + size.width),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF111111), width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xFF111111),
                          offset: Offset(3, 3),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _DropupItem(
                          icon: Icons.person_rounded,
                          label: 'Profile',
                          onTap: () => _onDropupItem(context, 5),
                          showDivider: true,
                        ),
                        _DropupItem(
                          icon: Icons.storefront_rounded,
                          label: 'Shop',
                          onTap: () => _onDropupItem(context, 6),
                          showDivider: true,
                        ),
                        _DropupItem(
                          icon: Icons.auto_awesome_rounded,
                          label: 'Collection',
                          onTap: () => _onDropupItem(context, 7),
                          showDivider: false,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    overlay.insert(_overlayEntry!);
    _animCtrl.forward(from: 0);
  }

  void _toggleDropup() {
    if (_dropupOpen) {
      _closeDropup();
    } else {
      setState(() => _dropupOpen = true);
      _showOverlay(context);
    }
  }

  void _closeDropup() {
    _animCtrl.reverse().then((_) {
      _removeOverlay();
      if (mounted) setState(() => _dropupOpen = false);
    });
  }

  void _onDropupItem(BuildContext context, int index) {
    _closeDropup();
    widget.onTap(index);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final items = [
      _NavItem(icon: Icons.home_rounded, label: l.navHome),
      _NavItem(icon: Icons.task_alt_rounded, label: l.navQuest),
      _NavItem(icon: Icons.folder_rounded, label: l.navFiles),
      _NavItem(icon: Icons.quiz_rounded, label: l.navQuiz),
      _NavItem(icon: Icons.bar_chart_rounded, label: l.navStats),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFF111111), width: 2.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 12,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ...List.generate(items.length, (i) {
                final item = items[i];
                final selected = widget.selectedIndex == i;
                return _NavButton(
                  icon: item.icon,
                  label: item.label,
                  selected: selected,
                  onTap: () => widget.onTap(i),
                  showQuestBadge: i == 1,
                );
              }),
              _MoreNavButton(
                isOpen: _dropupOpen,
                onTap: _toggleDropup,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Dropup item ───────────────────────────────────────────────────
class _DropupItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool showDivider;

  const _DropupItem({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: const Color(0xFF111111)),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111111),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
      ],
    );
  }
}

// ── "..." More button ─────────────────────────────────────────────
class _MoreNavButton extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onTap;

  const _MoreNavButton({required this.isOpen, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: isOpen
            ? BoxDecoration(
                color: const Color(0xFFF2EA05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF111111), width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xFF111111),
                    offset: Offset(2, 2),
                    blurRadius: 0,
                  ),
                ],
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.more_horiz_rounded,
              size: 24,
              color: isOpen ? const Color(0xFF111111) : const Color(0xFF888888),
            ),
            const SizedBox(height: 3),
            Text(
              'more',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isOpen ? const Color(0xFF111111) : const Color(0xFF888888),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Music Toggle Button ───────────────────────────────────────────
class _MusicToggleButton extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onTap;

  const _MusicToggleButton({required this.isPlaying, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF111111), width: 2),
          boxShadow: const [
            BoxShadow(color: Color(0xFF111111), offset: Offset(2, 2), blurRadius: 0),
          ],
        ),
        child: Icon(
          isPlaying ? Icons.music_note_rounded : Icons.music_off_rounded,
          size: 14,
          color: const Color(0xFF111111),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool showQuestBadge;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.showQuestBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: selected
            ? BoxDecoration(
                color: const Color(0xFFF2EA05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF111111), width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xFF111111),
                    offset: Offset(2, 2),
                    blurRadius: 0,
                  ),
                ],
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                // ── Icon ──
                Icon(
                  icon,
                  size: 24,
                  color: selected ? const Color(0xFF111111) : const Color(0xFF888888),
                ),
                // Quest badge: titik merah jika belum semua selesai
                if (showQuestBadge && !selected)
                  Positioned(
                    top: -2,
                    right: -4,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF3B5C),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Color(0x44000000), blurRadius: 2),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: selected ? const Color(0xFF111111) : const Color(0xFF888888),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hero Content ──────────────────────────────────────────────────
class _HeroContent extends StatelessWidget {
  final String userName;
  final VoidCallback? onStartNow;
  final VoidCallback? onScheduleTap;
  final Color textColor;
  final List<Shadow> headlineShadows;

  const _HeroContent({
    required this.userName,
    this.onStartNow,
    this.onScheduleTap,
    required this.textColor,
    required this.headlineShadows,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isSmall = size.width < 400;
    final imgH = (size.height * 0.26).clamp(110.0, 200.0);

    return SizedBox.expand(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 155, 24, 100),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                AppLocalizations.of(context).homeTagline,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w700,
                  fontSize: isSmall ? 13.0 : 15.0,
                  color: textColor,
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
              _HeadlineText(
                isSmall: isSmall,
                textColor: textColor,
                shadows: headlineShadows,
              ),
              const SizedBox(height: 14),
              Text(
                AppLocalizations.of(context).homeSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w700,
                  fontSize: isSmall ? 12.0 : 14.0,
                  color: textColor,
                  height: 1.8,
                ),
              ),
              const SizedBox(height: 20),
              _StartNowButton(onTap: onStartNow),
              const SizedBox(height: 14),
              _ScheduleButton(onTap: onScheduleTap),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScheduleButton extends StatefulWidget {
  final VoidCallback? onTap;
  const _ScheduleButton({this.onTap});

  @override
  State<_ScheduleButton> createState() => _ScheduleButtonState();
}

class _ScheduleButtonState extends State<_ScheduleButton> {
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
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFF111111), width: 2),
          boxShadow: _pressed
              ? const [BoxShadow(color: Color(0x22000000), offset: Offset(2, 2), blurRadius: 0)]
              : const [BoxShadow(color: Color(0x22000000), offset: Offset(5, 5), blurRadius: 0)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(context).homeSchedule,
              style: const TextStyle(
                fontFamily: 'BlackHanSans',
                fontSize: 14,
                letterSpacing: 1.5,
                color: Color(0xFF111111),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.calendar_month, size: 18, color: Color(0xFF111111)),
          ],
        ),
      ),
    );
  }
}

class _HeadlineText extends StatelessWidget {
  final bool isSmall;
  final Color textColor;
  final List<Shadow> shadows;

  const _HeadlineText({
    required this.isSmall,
    required this.textColor,
    required this.shadows,
  });

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
            color: textColor,
            letterSpacing: -1,
            height: 1,
            shadows: shadows,
          ),
        ),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontFamily: 'BlackHanSans',
              fontSize: isSmall ? 18.0 : 22.0,
              color: textColor,
              letterSpacing: 0.2,
              height: 1.25,
              shadows: shadows,
            ),
            children: [
              const TextSpan(text: 'study time '),
              TextSpan(
                text: '✦',
                style: TextStyle(
                    fontFamily: null,
                    fontSize: 16,
                    color: textColor,
                    shadows: const []),
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
          children: [
            Text(
              AppLocalizations.of(context).homeStartNow,
              style: const TextStyle(
                fontFamily: 'BlackHanSans',
                fontSize: 16,
                letterSpacing: 2,
                color: Color(0xFFE5E81E),
              ),
            ),
            const SizedBox(width: 6),
            const Text('♪',
                style: TextStyle(
                    fontSize: 16, color: Color(0xFFE5E81E))),
          ],
        ),
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
        if (snapshot.connectionState == ConnectionState.waiting ||
            snapshot.hasError) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _LevelBadge(level: 1, totalSessions: 0, sessionsToNextLevel: 6, nextLevelName: 'LEARNER'),
              const SizedBox(width: 8),
              const _StatPill(icon: '🔥', label: 'Streak', value: '0'),
            ],
          );
        }

        final info = snapshot.data;
        final level = info?.level ?? 1;
        final streakValue = info?.currentStreak ?? 0;
        final totalSessions = info?.totalSessions ?? 0;

        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _LevelBadge(level: level, totalSessions: totalSessions, sessionsToNextLevel: info?.sessionsToNextLevel ?? 0, nextLevelName: info?.nextLevelName),
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
  final int totalSessions;
  final int sessionsToNextLevel;
  final String? nextLevelName;

  const _LevelBadge({
    required this.level,
    required this.totalSessions,
    required this.sessionsToNextLevel,
    this.nextLevelName,
  });

  @override
  State<_LevelBadge> createState() => _LevelBadgeState();
}

class _LevelBadgeState extends State<_LevelBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

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
    final ctx = context;
    await _controller.forward();
    await _controller.reverse();
    if (!mounted) return;
    _showLevelDialog(ctx);
  }

  int _levelMinSessions(int level) {
    return switch (level) {
      1 => 0, 2 => 6, 3 => 13, 4 => 22, 5 => 33, _ => 0,
    };
  }

  int _nextLevelThreshold(int level) {
    return switch (level) {
      1 => 6, 2 => 13, 3 => 22, 4 => 33, _ => 33,
    };
  }

  String _levelName(int level) {
    switch (level) {
      case 1: return 'Beginner';
      case 2: return 'Learner';
      case 3: return 'Practitioner';
      case 4: return 'Expert';
      case 5: return 'Master';
      default: return 'Beginner';
    }
  }

  void _showLevelDialog(BuildContext ctx) {
    final cfg = _levelConfigs[(widget.level - 1).clamp(0, 4)];
    final nextLevel = (widget.level < 5 ? widget.level + 1 : 5);
    final nextLevelName = _levelName(nextLevel);
    final bool isMax = widget.level >= 5;
    final int currentMin = _levelMinSessions(widget.level);
    final int threshold = _nextLevelThreshold(widget.level);
    final int sessionsNeeded = isMax ? 0 : math.max(0, threshold - widget.totalSessions);
    final int levelProgressTotal = isMax ? 1 : (threshold - currentMin);
    final int levelProgressCurrent = isMax
        ? levelProgressTotal
        : math.max(0, widget.totalSessions - currentMin);
    final double progress = isMax || levelProgressTotal == 0
        ? 1.0
        : (levelProgressCurrent / levelProgressTotal).clamp(0.0, 1.0);
    final String currentLevelName = _levelName(widget.level);

    showDialog(
      context: ctx,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: _LevelBadgePainter(level: widget.level, size: 100)),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Level ${widget.level} · $currentLevelName',
                  style: const TextStyle(
                    fontFamily: 'BlackHanSans',
                    fontSize: 22,
                    color: Color(0xFF111111),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  isMax ? 'Highest rank' : 'Next: Level $nextLevel ($nextLevelName)',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: cfg['bg'] as Color,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Total sessions: ${widget.totalSessions}',
                style: const TextStyle(
                  fontFamily: 'Nunito', fontSize: 14, fontWeight: FontWeight.w600,
                  color: Color(0xFF111111),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                isMax
                    ? 'You have reached the highest level. Keep it up!'
                    : 'Need $sessionsNeeded more session${sessionsNeeded == 1 ? '' : 's'} to reach Level $nextLevel ($nextLevelName).',
                style: const TextStyle(
                  fontFamily: 'Nunito', fontSize: 13, color: Color(0xFF555555),
                ),
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 12,
                  backgroundColor: const Color(0xFFEEEEEE),
                  valueColor: AlwaysStoppedAnimation<Color>(cfg['bg'] as Color),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isMax
                    ? 'Max level achieved'
                    : '$levelProgressCurrent / $levelProgressTotal sessions in this level',
                style: const TextStyle(
                  fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w700,
                  color: Color(0xFF888888),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(6),
            child: ScaleTransition(
              scale: _scaleAnim,
              child: _LevelBadgePainter(level: widget.level, size: 52),
            ),
          ),
          Positioned.fill(
            child: GestureDetector(
              onTap: _onTap,
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),
        ],
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
          bg: bg, shimmer: shimmer, dark: dark, ribbon: ribbon,
          level: level, starCount: starCount, hasWings: hasWings, hasCrown: hasCrown,
        ),
      ),
    );
  }
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

    if (hasWings) {
      final wingColor = level == 3 ? const Color(0xFF88DDFF) : const Color(0xFFFFEE88);
      final wingPaint = Paint()..color = wingColor..style = PaintingStyle.fill;
      final leftWing = Path()
        ..moveTo(cx - w * 0.28, h * 0.38)
        ..cubicTo(cx - w * 0.55, h * 0.20, cx - w * 0.62, h * 0.38, cx - w * 0.50, h * 0.52)
        ..cubicTo(cx - w * 0.42, h * 0.46, cx - w * 0.33, h * 0.44, cx - w * 0.28, h * 0.46)
        ..close();
      canvas.drawPath(leftWing, wingPaint);
      final rightWing = Path()
        ..moveTo(cx + w * 0.28, h * 0.38)
        ..cubicTo(cx + w * 0.55, h * 0.20, cx + w * 0.62, h * 0.38, cx + w * 0.50, h * 0.52)
        ..cubicTo(cx + w * 0.42, h * 0.46, cx + w * 0.33, h * 0.44, cx + w * 0.28, h * 0.46)
        ..close();
      canvas.drawPath(rightWing, wingPaint);
    }

    if (hasCrown) {
      final crownPaint = Paint()..color = dark..style = PaintingStyle.fill;
      for (int i = 0; i < 5; i++) {
        final angle = -90 + (i - 2) * 30.0;
        final rad = angle * 3.14159 / 180;
        final tipR = w * 0.38;
        final baseR = w * 0.28;
        final tx = cx + tipR * _cos(rad);
        final ty = h * 0.18 + tipR * _sin(rad);
        final b1x = cx + baseR * _cos((angle - 10) * 3.14159 / 180);
        final b1y = h * 0.18 + baseR * _sin((angle - 10) * 3.14159 / 180);
        final b2x = cx + baseR * _cos((angle + 10) * 3.14159 / 180);
        final b2y = h * 0.18 + baseR * _sin((angle + 10) * 3.14159 / 180);
        final spike = Path()..moveTo(b1x, b1y)..lineTo(tx, ty)..lineTo(b2x, b2y)..close();
        canvas.drawPath(spike, crownPaint);
      }
    }

    canvas.drawCircle(Offset(cx, h * 0.36), w * 0.36, shadowPaint);
    canvas.drawCircle(Offset(cx, h * 0.34), w * 0.36, bodyPaint);

    final shimmerPath = Path()
      ..addOval(Rect.fromCenter(
        center: Offset(cx - w * 0.06, h * 0.18),
        width: w * 0.28, height: w * 0.22,
      ));
    canvas.drawPath(shimmerPath, shimmerPaint..color = shimmer.withOpacity(0.7));
    canvas.drawCircle(Offset(cx - w * 0.10, h * 0.14), w * 0.05, whitePaint..color = Colors.white.withOpacity(0.9));

    final ribbonRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx - w * 0.42, h * 0.54, w * 0.84, h * 0.22),
      const Radius.circular(6),
    );
    canvas.drawRRect(ribbonRect, ribbonPaint);

    final ribbonTop = Paint()..color = dark.withOpacity(0.3)..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(cx - w * 0.42, h * 0.54, w * 0.84, h * 0.04), const Radius.circular(6)),
      ribbonTop,
    );

    final starY = h * 0.655;
    final starSize = w * 0.095;
    final starSpacing = w * 0.22;
    final totalStarW = starCount * starSize * 2 + (starCount - 1) * (starSpacing - starSize * 2);
    final starStartX = cx - totalStarW / 2 + starSize;
    for (int i = 0; i < starCount; i++) {
      final sx = starStartX + i * starSpacing;
      _drawStar(canvas, Offset(sx, starY), starSize, const Color(0xFFFFDD44), const Color(0xFFFFAA00));
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: '$level',
        style: TextStyle(
          fontSize: w * 0.32,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          shadows: [Shadow(color: dark, offset: const Offset(0, 2), blurRadius: 3)],
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
      final x = center.dx + radius * _cos(angle);
      final y = center.dy + radius * _sin(angle);
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = fill..style = PaintingStyle.fill);
    canvas.drawPath(path, Paint()..color = stroke..style = PaintingStyle.stroke..strokeWidth = 0.8);
  }

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
        const Icon(
          Icons.local_fire_department,
          size: 20,
          color: Colors.white,
          shadows: [Shadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 4)],
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
            shadows: [Shadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 4)],
          ),
        ),
      ],
    );
  }
}

// ── Lives Box ─────────────────────────────────────────────────────
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
              BoxShadow(color: Color(0xFF111111), offset: Offset(3, 3), blurRadius: 0),
            ],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: hearts),
        );
      },
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
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DiagonalStripePainter old) =>
      old.stripeColor != stripeColor;
}

class _StatPlaceholderScreen extends StatelessWidget {
  const _StatPlaceholderScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2EA05),
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const Icon(Icons.arrow_back, color: Color(0xFF111111)),
        ),
        title: const Text(
          'Statistik',
          style: TextStyle(fontFamily: 'BlackHanSans', color: Color(0xFF111111)),
        ),
      ),
      body: const Center(
        child: Text(
          '📊 Halaman statistik\nakan segera hadir!',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Nunito', fontSize: 16, color: Color(0xFF555555)),
        ),
      ),
    );
  }
}

class _QuizPlaceholderScreen extends StatelessWidget {
  const _QuizPlaceholderScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2EA05),
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const Icon(Icons.arrow_back, color: Color(0xFF111111)),
        ),
        title: const Text(
          'Quiz',
          style: TextStyle(fontFamily: 'BlackHanSans', color: Color(0xFF111111)),
        ),
      ),
      body: const Center(
        child: Text(
          '🧠 Pilih materi dulu\nuntuk mulai quiz!',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Nunito', fontSize: 16, color: Color(0xFF555555)),
        ),
      ),
    );
  }
}