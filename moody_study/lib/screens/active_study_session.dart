import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
 
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';
import 'package:moody_study/screens/oddy_flashcard_screen.dart';
import 'package:moody_study/screens/your_files_screen.dart';
import 'package:moody_study/screens/headphone_screen.dart';
import 'package:moody_study/services/material_service.dart';
import 'package:moody_study/models/material_response.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:moody_study/services/spotify_service.dart';
import 'package:spotify_sdk/spotify_sdk.dart';
 
import 'package:moody_study/services/streak_service.dart';
import 'package:moody_study/services/auth_service.dart';
import 'package:moody_study/screens/life_lost_popup.dart';
import 'package:dartz/dartz.dart' hide State;
import 'package:moody_study/core/failure.dart';
import 'package:moody_study/core/exception_handler.dart';
import 'package:http/http.dart' as http;
import 'character_intro_screen.dart';
import 'level_up_screen.dart';
import 'streak_counter_screen.dart';
import 'theme_selector_screen.dart';
import '../services/patrol_pin_service.dart';
import '../widgets/patrol_pin_dialog.dart';
import '../services/lock_task_service.dart';
 
class ActiveStudySession extends StatefulWidget {
  final String mood;
  final String location;
  final String userName;
  final AppTheme theme;
  final List<PlatformFile> files;
  final int initialMinutes;
 
  const ActiveStudySession({
    super.key,
    required this.mood,
    this.location = 'home',
    this.userName = 'Friend',
    this.theme = AppTheme.green,
    this.files = const [],
    this.initialMinutes = 40,
  });
 
  @override
  State<ActiveStudySession> createState() => _ActiveStudySessionState();
}
 
class _ActiveStudySessionState extends State<ActiveStudySession>
    with WidgetsBindingObserver {
  late Duration _remaining;
  late final ValueNotifier<Duration> _remainingNotifier;
  Timer? _timer;
  bool _running = false;
  bool _savingPdf = false;
  bool _musicWasPausedByAlarm = false; 
  String _summary = '';
  bool _loadingSummary = true;
  String? _summaryError;
  int? _materialId;
  int? _initialStreak;
  int? _initialLife;
 
  Timer? _awayTimer;
  Timer? _flashTimer;
  Timer? _vibrationTimer;
  DateTime? _awayStartTime;
  bool _awayAlarmTriggered = false;
  int _totalDistractionSeconds = 0;
  bool _showRedFlash = false;
  int _distractionCount = 0;
  bool get _isPatrolMode => _distractionCount >= 3;
  int _patrolTapCount = 0;
  static const int _patrolTapsRequired = 5;
  AudioPlayer? _awayAlarmPlayer;
  StreamSubscription<void>? _alarmLoopSubscription;
  bool _alarmShouldLoop = false;
  late final AudioPlayer _musicPlayer;
  StreamSubscription<PlayerState>? _musicStateSubscription;
  bool _musicPlaying = false;

  // Notification plugin for background alarm
  final FlutterLocalNotificationsPlugin _notifPlugin =
      FlutterLocalNotificationsPlugin();
  bool _pendingAlarmDialog = false;
  Duration _pendingAlarmDuration = Duration.zero;
 
  int get _totalSeconds => widget.initialMinutes * 60;
 
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _remaining = Duration(minutes: widget.initialMinutes);
    _remainingNotifier = ValueNotifier<Duration>(_remaining);
    _musicPlayer = AudioPlayer();
    _musicPlayer.setReleaseMode(ReleaseMode.loop);
    _musicStateSubscription = _musicPlayer.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() => _musicPlaying = state == PlayerState.playing);
    });
    _loadInitialStreak();
    _loadSummary();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _notifPlugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
    if (!kIsWeb && Platform.isAndroid) {
      final android = _notifPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
    }
  }

  Future<void> _showDistractedNotification() async {
    // Channel ID pakai _v3 supaya Android tidak pakai cache channel lama yang masih alarm.wav
    final channelId = _isLibraryLocation
        ? 'distraction_library_v3'
        : 'distraction_alarm_v3';
    final channelName = _isLibraryLocation
        ? 'Library Distraction Alert'
        : 'Distraction Alarm';

    final Int64List? vibrationPattern = kIsWeb
        ? null
        : (_isLibraryLocation
            ? Int64List.fromList([0, 400, 200, 400, 200, 400, 200, 400])
            : Int64List.fromList([0, 500, 500]));

    final androidChannel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: 'Notifies when you leave the study session',
      importance: Importance.max,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('alarm'), // file: res/raw/alarm.mp3
      enableVibration: true,
      vibrationPattern: vibrationPattern,
    );
    final androidImpl = _notifPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(androidChannel);

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: 'Notifies when you leave the study session',
      importance: Importance.max,
      priority: Priority.max,
      sound: const RawResourceAndroidNotificationSound('alarm'), // file: res/raw/alarm.mp3
      enableVibration: true,
      vibrationPattern: vibrationPattern,
      playSound: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
    );

    const iosDetails = DarwinNotificationDetails(
      sound: 'alarm.mp3',
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    final title = _isLibraryLocation
        ? '📚 Fokus! Kamu di perpustakaan!'
        : '👀 Hey, come back!';
    final body = _isLibraryLocation
        ? 'Kamu meninggalkan sesi belajar. Tetap tenang dan kembali fokus. 🤫'
        : 'You left your study session. Tap to return.';

    await _notifPlugin.show(42, title, body, details);
  }

  Future<void> _cancelDistractedNotification() async {
    await _notifPlugin.cancel(42);
  }

  Future<Either<Failure, StreakInfo>> _fetchInitialStreak() async {
    try {
      return Right(await StreakService.fetchStreak());
    } catch (e) {
      return Left(ServiceFailure(sanitizeException(e)));
    }
  }

  Future<void> _loadInitialStreak() async {
    (await _fetchInitialStreak()).fold(
      (_) {},
      (streakInfo) {
        if (!mounted) return;
        setState(() {
          _initialStreak = streakInfo.currentStreak;
          _initialLife = streakInfo.life;
        });
      },
    );
  }

  Future<Either<Failure, LoginCheckResult?>> _fetchLoginCheck() async {
    try {
      final token = AuthService.token;
      if (token == null) return const Right(null);
      final res = await http.post(
        Uri.parse('${StreakService.baseUrl}/api/streak/check-login'),
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

  Future<void> _checkAndShowLifeLost() async {
    final result = await _fetchLoginCheck();
    await result.fold(
      (f) async => debugPrint('_checkAndShowLifeLost error: ${f.message}'),
      (loginResult) async {
        if (loginResult != null && mounted) {
          if (loginResult.livesLost > 0 || loginResult.leveledDown) {
            if (mounted) await showLifeLostPopup(context, loginResult);
          }
        }
      },
    );
  }

  Future<void> _loadSummary() async {
    if (!mounted) return;
    setState(() {
      _loadingSummary = true;
      _summaryError = null;
    });
 
    if (widget.files.isEmpty) {
      if (!mounted) return;
      setState(() {
        _loadingSummary = false;
        _summary = 'No material available to summarize.';
      });
      return;
    }
 
    final file = widget.files.first;
    final originalText = await _extractTextFromFile(file);
    if (originalText.trim().isEmpty) {
      if (!mounted) return;
      setState(() {
        _loadingSummary = false;
        _summary = 'Unable to read material from file ${file.name}.';
      });
      return;
    }
 
    final summaryResult = await _fetchSummary(file.name, originalText);
    if (!mounted) return;
    summaryResult.fold(
      (f) {
        final sanitized = _sanitizeError(f.message);
        setState(() {
          _loadingSummary = false;
          _summaryError = sanitized;
          _summary = 'Summary failed to load.';
        });
        debugPrint('Gemini summary error: ${f.message}');
      },
      (response) {
        setState(() {
          _loadingSummary = false;
          _summary = response.summary;
          _materialId = response.id;
          _summaryError = null;
        });
        _startTimer();
      },
    );
  }

  Future<Either<Failure, MaterialResponse>> _fetchSummary(String fileName, String originalText) async {
    try {
      return Right(await MaterialService.summarizeMaterial(
        fileName: fileName,
        originalText: originalText,
      ));
    } catch (e) {
      return Left(ServiceFailure(sanitizeException(e)));
    }
  }

  Future<Either<Failure, SessionResult>> _doCompleteSession({
    required String mood,
    required String location,
    required int durationMinutes,
    required int focusSeconds,
    required int distractionSeconds,
  }) async {
    try {
      return Right(await StreakService.completeSession(
        mood: mood,
        location: location,
        durationMinutes: durationMinutes,
        focusSeconds: focusSeconds,
        distractionSeconds: distractionSeconds,
      ));
    } catch (e) {
      return Left(ServiceFailure(sanitizeException(e)));
    }
  }
 
  String _sanitizeError(String raw) {
    var s = raw.replaceAll('<EOL>', '\n');
    final msgMatch = RegExp('"message"\s*:\s*"([^"]+)"').firstMatch(s);
    if (msgMatch != null) return msgMatch.group(1)!;
    s = s.replaceAll(RegExp(r'[\{\}\[\]]'), '');
    if (s.length > 200) return s.substring(0, 200) + '...';
    return s;
  }
 
  void _openHeadphoneScreen() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => HeadphoneScreen(audioPlayer: _musicPlayer),
    ));
  }
 
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (!mounted) return;
      final s = _remaining.inSeconds - 1;
      if (s <= 0) {
        _remaining = Duration.zero;
        _remainingNotifier.value = Duration.zero;
        _running = false;
        t.cancel();
        if (mounted) await _showSessionComplete();
      } else {
        _remaining = Duration(seconds: s);
        _remainingNotifier.value = _remaining;
      }
    });
    setState(() {
      _running = true;
    });
  }
 
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_shouldTrackAway) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _startAwayTimer();
    } else if (state == AppLifecycleState.resumed) {
      _cancelDistractedNotification();
      if (_pendingAlarmDialog) {
        _pendingAlarmDialog = false;
        // Langsung play alarm begitu user balik — tidak tunggu dialog
        unawaited(_playAwayAlarm());
        // Tunda sedikit supaya context sudah siap
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) _handleReturnFromBackground(_pendingAlarmDuration);
        });
      } else {
        _cancelAwayTimer();
      }
    }
  }
 
  bool get _isHomeLocation => widget.location == 'home';
  bool get _isLibraryLocation => widget.location == 'library';
  bool get _shouldTrackAway => _isHomeLocation || _isLibraryLocation;
 
  void _startAwayTimer() {
    if (_awayTimer != null || _awayAlarmTriggered) return;
    _awayStartTime = DateTime.now();
    _awayTimer = Timer(const Duration(seconds: 30), _triggerAwayAlarm);
  }
 
  Future<void> _cancelAwayTimer() async {
    _awayTimer?.cancel();
    _awayTimer = null;
    if (!_awayAlarmTriggered) {
      _awayStartTime = null;
    }
  }
 
  Future<void> _triggerAwayAlarm() async {
    _awayTimer = null;
    _awayAlarmTriggered = true;
    if (mounted) setState(() {});

    final awayDuration = _awayStartTime != null
        ? DateTime.now().difference(_awayStartTime!)
        : const Duration(seconds: 30);

    // Cek apakah app sedang di foreground atau background
    // Kalau background: kirim notifikasi + vibrate, tandai pending dialog
    // Kalau foreground: jalankan alarm + dialog seperti biasa
    final isBackground = WidgetsBinding.instance.lifecycleState !=
        AppLifecycleState.resumed;

    if (isBackground) {
      // Simpan info untuk ditampilkan saat user kembali
      _pendingAlarmDialog = true;
      _pendingAlarmDuration = awayDuration;

      // Kirim notifikasi dengan suara alarm (sudah location-aware: home vs library)
      await _showDistractedNotification();

      if (_isLibraryLocation) {
        // Library: vibrate intens saja (tidak play alarm keras supaya tidak ganggu orang lain)
        // Suara sudah lewat notifikasi (alarm.wav via channel)
        unawaited(_startAwayVibration());
      } else {
        // Home / luar: play alarm.wav via AudioPlayer + vibrate
        await _playAwayAlarm();
      }
      return;
    }

    // App masih foreground — play alarm langsung lalu tampilkan dialog
    unawaited(_playAwayAlarm());
    await _handleReturnFromBackground(awayDuration);
  }

  Future<Either<Failure, void>> _tryPauseMusicPlayer() async {
    try {
      if (_musicPlayer.state == PlayerState.playing) {
        await _musicPlayer.pause();
      }
      return const Right(null);
    } catch (e) {
      return Left(AudioFailure(sanitizeException(e)));
    }
  }

  Future<Either<Failure, bool>> _tryPauseSpotify() async {
    try {
      final spState = await SpotifySdk.getPlayerState()
          .timeout(const Duration(seconds: 2));
      if (spState != null && !spState.isPaused) {
        await SpotifyService.pause();
        return const Right(true);
      }
      return const Right(false);
    } catch (e) {
      return Left(ServiceFailure(sanitizeException(e)));
    }
  }

  Future<Either<Failure, void>> _tryResumeMusicPlayer() async {
    try {
      await _musicPlayer.resume();
      return const Right(null);
    } catch (e) {
      return Left(AudioFailure(sanitizeException(e)));
    }
  }

  Future<Either<Failure, void>> _tryResumeSpotify() async {
    try {
      await SpotifyService.resume();
      return const Right(null);
    } catch (e) {
      return Left(ServiceFailure(sanitizeException(e)));
    }
  }

  Future<void> _handleReturnFromBackground(Duration awayDuration) async {
    // Pause musik
    _musicWasPausedByAlarm = false;
    (await _tryPauseMusicPlayer()).fold(
      (_) {},
      (_) {
        if (_musicPlayer.state == PlayerState.playing) _musicWasPausedByAlarm = true;
      },
    );
    (await _tryPauseSpotify()).fold(
      (_) {},
      (paused) { if (paused) _musicWasPausedByAlarm = true; },
    );

    if (_isLibraryLocation) {
      _startFlashEffect();
      await _showReturnPopup(awayDuration);
      await _stopAwayAlarm();
      _stopFlashEffect();
    } else if (_isHomeLocation) {
      await _showReturnPopup(awayDuration);
      await _stopAwayAlarm();
    }

    _awayTimer?.cancel();
    _awayTimer = null;
    _awayStartTime = null;
    if (mounted) {
      setState(() {
        _awayAlarmTriggered = false;
        _showRedFlash = false;
      });
    }

    // Resume musik
    if (_musicWasPausedByAlarm) {
      (await _tryResumeMusicPlayer()).fold((_) {}, (_) {});
      (await _tryResumeSpotify()).fold((_) {}, (_) {});
      _musicWasPausedByAlarm = false;
    }
  }

  Future<Either<Failure, void>> _tryCancelVibration() async {
    try {
      if (await Vibration.hasVibrator() == true) {
        await Vibration.cancel();
      }
      return const Right(null);
    } catch (e) {
      return Left(ServiceFailure(sanitizeException(e)));
    }
  }

  Future<Either<Failure, void>> _tryStopAlarmPlayer() async {
    try {
      await _awayAlarmPlayer?.stop();
      await _awayAlarmPlayer?.dispose();
      _awayAlarmPlayer = null;
      return const Right(null);
    } catch (e) {
      return Left(AudioFailure(sanitizeException(e)));
    }
  }

  Future<void> _stopAwayAlarm() async {
    // Hentikan loop alarm
    _alarmShouldLoop = false;
    await _alarmLoopSubscription?.cancel();
    _alarmLoopSubscription = null;

    _vibrationTimer?.cancel();
    _vibrationTimer = null;
    (await _tryCancelVibration()).fold((_) {}, (_) {});
    (await _tryStopAlarmPlayer()).fold((_) {}, (_) {});
  }

  void _startFlashEffect() {
    _stopFlashEffect();
    _showRedFlash = true;
    _flashTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted) return;
      setState(() => _showRedFlash = !_showRedFlash);
    });
  }
 
  void _stopFlashEffect() {
    _flashTimer?.cancel();
    _flashTimer = null;
    _showRedFlash = false;
  }
 
  Future<void> _showReturnPopup(Duration awayDuration) async {
    if (!mounted) return;
    final seconds = awayDuration.inSeconds;
    _totalDistractionSeconds += seconds;
    setState(() { _distractionCount++; });
    if (_isPatrolMode) unawaited(_enterPatrolUiLock());
    final minutes = awayDuration.inMinutes;
    final formatted = minutes > 0
        ? '$minutes min ${seconds % 60} sec'
        : '$seconds sec';
 
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.remove_red_eye,
              size: 48,
              color: _isLibraryLocation
                  ? (_showRedFlash ? Colors.red : const Color(0xFF222222))
                  : const Color(0xFF222222),
            ),
            const SizedBox(height: 16),
            Text(
              _distractionCount + 1 >= 3 ? '🚨 Last Warning!' : 'Hey, come back!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _distractionCount + 1 >= 3 ? Colors.red : const Color(0xFF111111),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _isLibraryLocation
                  ? 'You were distracted for $formatted. In the library, stay calm and focus. 📚'
                  : 'You were distracted for $formatted. Your study session is waiting.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
            if (_distractionCount + 1 >= 3) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEEEE),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red, width: 1.5),
                ),
                child: const Text(
                  '🔒 Patrol mode will activate. You won\'t be able to exit!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.red, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF2EA05),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFF111111), width: 2.5),
                ),
                shadowColor: const Color(0xFF111111),
                elevation: 4,
              ),
              onPressed: () {
                if (_isLibraryLocation) _stopFlashEffect();
                Navigator.of(context).pop();
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Text('I\'m back!', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
 
  Future<void> _playAwayAlarm() async {
    unawaited(_startAwayVibration());
    _alarmShouldLoop = true;
    _loopAlarm();
  }

  Future<Either<Failure, void>> _doLoopAlarm() async {
    try {
      await _awayAlarmPlayer?.stop();
      await _awayAlarmPlayer?.dispose();
      _awayAlarmPlayer = null;

      if (!_alarmShouldLoop) return const Right(null);

      _awayAlarmPlayer = AudioPlayer();
      _alarmLoopSubscription = _awayAlarmPlayer!.onPlayerComplete.listen((_) {
        if (_alarmShouldLoop) _loopAlarm();
      });

      await _awayAlarmPlayer!.setVolume(1.0);
      await _awayAlarmPlayer!.play(AssetSource('audio/alarm.mp3'));
      return const Right(null);
    } catch (e) {
      return Left(AudioFailure(sanitizeException(e)));
    }
  }

  Future<void> _loopAlarm() async {
    if (!_alarmShouldLoop) return;
    (await _doLoopAlarm()).fold(
      (f) => debugPrint('=== ALARM audio failed: ${f.message} ==='),
      (_) {},
    );
  }

  Future<Either<Failure, void>> _tryVibrate() async {
    try {
      if (await Vibration.hasVibrator() == true) {
        await Vibration.vibrate(duration: 500);
      }
      return const Right(null);
    } catch (e) {
      return Left(ServiceFailure(sanitizeException(e)));
    }
  }

  Future<Either<Failure, void>> _tryHaptic() async {
    try {
      HapticFeedback.vibrate();
      return const Right(null);
    } catch (e) {
      return Left(ServiceFailure(sanitizeException(e)));
    }
  }

  Future<void> _startAwayVibration() async {
    _vibrationTimer?.cancel();
    _vibrationTimer = null;

    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      await Vibration.vibrate(duration: 500);
      _vibrationTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) async {
          (await _tryVibrate()).fold((_) {}, (_) {});
        },
      );
    } else {
      HapticFeedback.vibrate();
      _vibrationTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) async {
          (await _tryHaptic()).fold((_) {}, (_) {});
        },
      );
    }
  }

  void _toggleRunning() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
      return;
    }
    _startTimer();
  }
 
  Future<Either<Failure, String>> _doSaveCurrentFileAsPdf(PlatformFile file) async {
    try {
      final pdfBytes = await _createPdfBytes(file);
      final pdfFileName = _normalizePdfFileName(file.name);
      final base64Content = base64Encode(pdfBytes);
      await MaterialService.saveFileAsPdf(
        fileName: pdfFileName,
        fileType: 'pdf',
        base64Content: base64Content,
      );
      return Right(pdfFileName);
    } catch (e) {
      return Left(ServiceFailure(sanitizeException(e)));
    }
  }

  Future<void> _saveCurrentFileAsPdf() async {
    if (widget.files.isEmpty) return;
    final file = widget.files.first;
    if (!mounted) return;
    setState(() => _savingPdf = true);
    final result = await _doSaveCurrentFileAsPdf(file);
    if (!mounted) return;
    result.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(f.message.isNotEmpty ? f.message : 'Gagal menyimpan PDF. Silakan coba lagi.')),
      ),
      (fileName) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File "$fileName" berhasil disimpan ke Your Files.')),
      ),
    );
    if (mounted) setState(() => _savingPdf = false);
  }
 
  Future<List<int>> _createPdfBytes(PlatformFile file) async {
    if (file.extension?.toLowerCase() == 'pdf') {
      final raw = file.bytes ??
          (file.path != null ? await File(file.path!).readAsBytes() : null);
      if (raw == null || raw.isEmpty) throw Exception('Unable to read source PDF.');
      return raw;
    }
    final originalText = await _extractTextFromFile(file);
    if (originalText.trim().isEmpty) {
      throw Exception('No text could be converted from file ${file.name}.');
    }
    final pdf = pw.Document();
    final chunks = _splitTextIntoChunks(originalText, 800);
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => chunks
            .map((chunk) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Paragraph(
                    text: chunk,
                    style: const pw.TextStyle(fontSize: 12, lineSpacing: 1.4),
                  ),
                ))
            .toList(),
      ),
    );
    return pdf.save();
  }
 
  List<String> _splitTextIntoChunks(String text, int maxChunkSize) {
    final trimmed = text.trim();
    if (trimmed.length <= maxChunkSize) return [trimmed];
    final paragraphs = trimmed
        .split(RegExp(r'\n{2,}'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    final chunks = <String>[];
    for (final paragraph in paragraphs) {
      int start = 0;
      while (start < paragraph.length) {
        int end = start + maxChunkSize;
        if (end >= paragraph.length) {
          chunks.add(paragraph.substring(start).trim());
          break;
        }
        int splitAt = paragraph.lastIndexOf(RegExp(r'[\s\n]'), end);
        if (splitAt <= start) splitAt = end;
        chunks.add(paragraph.substring(start, splitAt).trim());
        start = splitAt + 1;
      }
    }
    return chunks;
  }
 
  String _normalizePdfFileName(String fileName) {
    if (fileName.toLowerCase().endsWith('.pdf')) return fileName;
    return fileName.replaceAll(RegExp(r'\.[^.]+$'), '') + '.pdf';
  }
 
  Future<void> _showSessionComplete() async {
    if (!mounted) return;
    final studyDuration = Duration(seconds: _totalSeconds - _remaining.inSeconds);
    final mins = studyDuration.inMinutes;
    final secs = studyDuration.inSeconds.remainder(60);
    final durationText = mins > 0 ? '$mins min ${secs}s' : '${secs}s';
    final action = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _DoneEarlyDialog(
        userName: widget.userName,
        durationText: durationText,
        isPatrolMode: _isPatrolMode,
      ),
    );
    if (action == null || action == 'continue') return;
    SessionResult? sessionResult;
    final sessionResult2 = await _doCompleteSession(
      mood: widget.mood,
      location: widget.location,
      durationMinutes: studyDuration.inMinutes,
      focusSeconds: studyDuration.inSeconds,
      distractionSeconds: _totalDistractionSeconds,
    );
    sessionResult2.fold(
      (f) => debugPrint('Failed to save session to database: ${f.message}'),
      (result) => sessionResult = result,
    );
    if (!mounted) return;
    final sr = sessionResult; // non-nullable local for null promotion
    final shouldShowStreak = sr != null &&
        sr.currentStreak > 0 &&
        (_initialStreak == null || sr.currentStreak > _initialStreak!);
    final previousLife = _initialLife;
    if (shouldShowStreak) {
      await Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => StreakCounterScreen(
            previousStreak: (sr.currentStreak - 1).clamp(0, sr.currentStreak),
            newStreak: sr.currentStreak,
            userName: widget.userName,
            onContinue: () => Navigator.of(context).pop(),
          ),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
      if (!mounted) return;
    }
    if (sr != null) {
      _initialStreak = sr.currentStreak;
      _initialLife = sr.life;
    }
    if (sr != null && sr.leveledUp) {
      await Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => LevelUpScreen(
            newLevel: sr.newLevel,
            newLevelName: sr.newLevelName ?? _levelName(sr.newLevel),
            coinsEarned: sr.coinsEarned,
            userName: widget.userName,
            onContinue: () => Navigator.of(context).pop(),
          ),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
      if (!mounted) return;
    }
    if (sr != null && previousLife != null && sr.life > previousLife) {
      await showLifeRecoveredPopup(context, sr.life);
    }
    if (sr != null && previousLife != null && sr.life < previousLife) {
      if (mounted) await _checkAndShowLifeLost();
    }
    if (action == 'save') {
      if (_materialId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your summary is still preparing. Please wait a moment before saving.')),
        );
        return;
      }
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const YourFilesScreen()));
      return;
    }
    if (action == 'exit') {
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => CharacterIntroScreen(userName: widget.userName, theme: widget.theme),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
        (route) => false,
      );
    }
  }
 
  String _levelName(int level) {
    switch (level) {
      case 1: return 'Beginner';
      case 2: return 'Learner';
      case 3: return 'Practitioner';
      case 4: return 'Expert';
      case 5: return 'Master';
      default: return 'Level $level';
    }
  }

  String _formatDuration(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '${d.inHours.toString().padLeft(2, '0')}:$mm:$ss';
    }
    return '$mm:$ss';
  }
 
  Future<String> _extractTextFromFile(PlatformFile file) async {
    final extension = file.extension?.toLowerCase() ?? '';
    if (extension == 'txt' || extension == 'md' || extension == 'csv') {
      final raw = file.bytes ?? (file.path != null ? await File(file.path!).readAsBytes() : null);
      if (raw != null) return _decodeUtf8(raw).getOrElse(() => '');
      return '';
    }
    if (extension == 'docx') {
      final result = await _extractDocxText(file);
      return result.fold((_) => '', (text) => text?.trim() ?? '');
    }
    if (extension == 'pdf') {
      try {
        return await MaterialService.extractTextFromFile(file);
      } catch (_) {
        return '';
      }
    }
    return '';
  }

  Either<Failure, String> _decodeUtf8(List<int> bytes) {
    try {
      return Right(utf8.decode(bytes, allowMalformed: true));
    } catch (e) {
      return Left(ParseFailure(sanitizeException(e)));
    }
  }
 
  Future<Either<Failure, String?>> _extractDocxText(PlatformFile file) async {
    try {
      final bytes = file.bytes ?? (file.path != null ? await File(file.path!).readAsBytes() : null);
      if (bytes == null) return const Right(null);
      final archive = ZipDecoder().decodeBytes(bytes);
      ArchiveFile? documentEntry;
      for (final entry in archive.files) {
        if (entry.name == 'word/document.xml') { documentEntry = entry; break; }
      }
      if (documentEntry == null || documentEntry.content == null) return const Right(null);
      final xml = utf8.decode(documentEntry.content as List<int>, allowMalformed: true);
      final text = _stripXmlText(xml).trim();
      return Right(text.isEmpty ? null : text);
    } catch (e) {
      return Left(StorageFailure(sanitizeException(e)));
    }
  }
 
  String _stripXmlText(String xml) {
    var text = xml.replaceAll(RegExp(r'\r\n|\r'), '\n');
    text = text.replaceAll(RegExp(r'</w:p>', caseSensitive: false), '\n');
    text = text.replaceAll(RegExp(r'<w:t[^>]*>'), '\x02');
    text = text.replaceAll(RegExp(r'</w:t>', caseSensitive: false), '\x03');
    text = text.replaceAll(RegExp(r'<[^>]*>', dotAll: true), '');
    final buffer = StringBuffer();
    bool inRun = false;
    for (var i = 0; i < text.length; i++) {
      final c = text[i];
      if (c == '\x02') { inRun = true; }
      else if (c == '\x03') { inRun = false; buffer.write(' '); }
      else if (inRun) { buffer.write(c); }
      else if (c == '\n') { buffer.write('\n'); }
    }
    var result = buffer.toString();
    result = result.replaceAll(RegExp(r' {2,}'), ' ');
    result = result.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    result = result.replaceAll(RegExp(r'^ +', multiLine: true), '');
    return result.trim();
  }
 
  Color get _bgColor {
    switch (widget.mood) {
      case 'happy': return const Color(0xFFFF8FAB);
      case 'okay': return const Color(0xFFFFFFFF);
      case 'sad':
      case 'tired': return const Color(0xFF90CAF9);
      default: return const Color(0xFFFFFFFF);
    }
  }
 
  Color get _stripeColor {
    switch (widget.mood) {
      case 'okay': return Colors.black.withOpacity(0.04);
      default: return Colors.black.withOpacity(0.06);
    }
  }
 
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _awayTimer?.cancel();
    _alarmShouldLoop = false;
    _alarmLoopSubscription?.cancel();
    _stopAwayAlarm();
    _awayAlarmPlayer?.dispose();
    _musicStateSubscription?.cancel();
    _musicPlayer.dispose();
    _remainingNotifier.dispose();
    unawaited(_exitPatrolUiLock());
    super.dispose();
  }
 
  Future<void> _enterPatrolUiLock() async {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await LockTaskService.startLock();
  }

  Future<void> _exitPatrolUiLock() async {
    await LockTaskService.stopLock();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  Future<void> _showPatrolLockedDialog() async {
    if (!mounted) return;
    final hasPin = await PatrolPinService.hasPin();
    if (!mounted) return;

    if (!hasPin) {
      // Belum set PIN — locked total, kasih info cara set PIN
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: Colors.red, shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF111111), width: 3),
                  boxShadow: const [BoxShadow(color: Color(0xFF111111), offset: Offset(3, 3))],
                ),
                child: const Icon(Icons.lock, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 16),
              const Text('🚨 Patrol Mode Aktif!', textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text(
                'Kamu udah distraksi 3 kali. Selesaikan sesimu dulu!\n\nTip: Set Emergency PIN di Profile Screen biar bisa keluar darurat. 👊',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF2EA05), foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: Color(0xFF111111), width: 2.5),
                  ),
                  elevation: 4,
                ),
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Text('Oke, fokus lagi! 💪', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      );
      return;
    }

    // Punya PIN — tampilkan numpad verify
    final verified = await showPatrolPinDialog(context, PatrolPinDialogMode.verify);
    if (verified && mounted) {
      await _exitPatrolUiLock();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isPatrolMode,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop && _isPatrolMode) {
          setState(() => _patrolTapCount++);
          if (_patrolTapCount >= _patrolTapsRequired) {
            setState(() => _patrolTapCount = 0);
            await _showPatrolLockedDialog();
          } else {
            final remaining = _patrolTapsRequired - _patrolTapCount;
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Text('🔒', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(
                      remaining == 1
                        ? 'Tap sekali lagi untuk emergency exit'
                        : 'Tap $remaining kali lagi untuk emergency exit',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                backgroundColor: Colors.red.shade700,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      },
      child: AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      color: _bgColor,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            CustomPaint(
              size: Size.infinite,
              painter: _DiagonalStripePainter(stripeColor: _stripeColor),
            ),
            if (_isLibraryLocation && _awayAlarmTriggered)
              IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _showRedFlash ? 0.45 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(color: Colors.red),
                ),
              ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            if (_isPatrolMode) {
                              setState(() => _patrolTapCount++);
                              if (_patrolTapCount >= _patrolTapsRequired) {
                                setState(() => _patrolTapCount = 0);
                                await _showPatrolLockedDialog();
                              } else {
                                final remaining = _patrolTapsRequired - _patrolTapCount;
                                ScaffoldMessenger.of(context).clearSnackBars();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Text('🔒', style: TextStyle(fontSize: 16)),
                                        const SizedBox(width: 8),
                                        Text(
                                          remaining == 1
                                            ? 'Tap sekali lagi untuk emergency exit'
                                            : 'Tap $remaining kali lagi untuk emergency exit',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: Colors.red.shade700,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                              return;
                            }
                            Navigator.of(context).pop();
                          },
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: _isPatrolMode
                              ? Container(
                                  key: const ValueKey('locked'),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFF111111), width: 2),
                                    boxShadow: const [BoxShadow(color: Color(0xFF111111), offset: Offset(2, 2))],
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.lock, color: Colors.white, size: 16),
                                      SizedBox(width: 4),
                                      Text('LOCKED', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                    ],
                                  ),
                                )
                              : const Icon(Icons.arrow_back, color: Color(0xFF111111), size: 24, key: ValueKey('back')),
                          ),
                        ),
                        const Spacer(),
                        if (kDebugMode)
                          IconButton(
                            tooltip: 'Trigger alarm (debug)',
                            onPressed: () async => await _playAwayAlarm(),
                            icon: const Icon(Icons.alarm, color: Colors.red),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Keep going, ${widget.userName}! 💪',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'BlackHanSans',
                        fontSize: 24,
                        color: Color(0xFF111111),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: _openHeadphoneScreen,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFF111111), width: 2),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [BoxShadow(color: Color(0xFF111111), offset: Offset(3, 3), blurRadius: 0)],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.headphones, color: Color(0xFF111111), size: 30),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Headphone Player',
                                    style: TextStyle(fontFamily: 'BlackHanSans', fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111111)),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _musicPlaying ? 'Tap to control music' : 'Tap to open music player',
                                    style: const TextStyle(fontFamily: 'Nunito', fontSize: 12, color: Color(0xFF666666)),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Color(0xFF111111), size: 24),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    RepaintBoundary(
                      child: ValueListenableBuilder<Duration>(
                        valueListenable: _remainingNotifier,
                        builder: (context, remaining, _) {
                          final progress = _loadingSummary
                              ? 1.0
                              : (remaining.inSeconds / _totalSeconds).clamp(0.0, 1.0);
                          return SizedBox(
                            width: 200,
                            height: 200,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CustomPaint(
                                  size: const Size(200, 200),
                                  painter: _ArcTimerPainter(progress: progress),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 28),
                                        child: Text(
                                          _formatDuration(remaining),
                                          style: TextStyle(
                                            fontFamily: 'BlackHanSans',
                                            fontSize: 44,
                                            color: widget.mood == 'okay' ? Colors.black : Colors.black87,
                                            height: 1,
                                          ),
                                          softWrap: false,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'REMAINING',
                                      style: TextStyle(
                                        fontFamily: 'Nunito',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: widget.mood == 'okay' ? Colors.black54 : Colors.black54,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: _toggleRunning,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: const Color(0xFF111111), width: 2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_running ? Icons.pause : Icons.play_arrow, color: const Color(0xFF111111), size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  _running ? 'Pause' : 'Resume',
                                  style: const TextStyle(fontFamily: 'BlackHanSans', fontSize: 14, color: Color(0xFF111111), letterSpacing: 0.5),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: _showSessionComplete,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5E81E),
                              border: Border.all(color: const Color(0xFF111111), width: 2),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [BoxShadow(color: Color(0xFF111111), offset: Offset(2, 2), blurRadius: 0)],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.check, color: Color(0xFF111111), size: 18),
                                SizedBox(width: 6),
                                Text('Done Early', style: TextStyle(fontFamily: 'BlackHanSans', fontSize: 14, color: Color(0xFF111111), letterSpacing: 0.5)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    if (_awayAlarmTriggered)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE5E5),
                          border: Border.all(color: const Color(0xFFDD2C00), width: 2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.notifications_active, color: Color(0xFFDD2C00)),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Alarm is active because you left the app for more than 30 seconds.',
                                style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF111111)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFF111111), width: 3),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [BoxShadow(color: Color(0xFF111111), offset: Offset(6, 6), blurRadius: 0)],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.description, size: 20, color: Color(0xFF111111)),
                                  SizedBox(width: 8),
                                  Text('Material Summary', style: TextStyle(fontFamily: 'BlackHanSans', fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111111))),
                                ],
                              ),
                              if (_loadingSummary)
                                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Color(0xFF1EE86F))))
                              else
                                Text(_summaryError == null ? 'Ready' : 'Error', style: const TextStyle(fontFamily: 'Nunito', fontSize: 12, color: Color(0xFFAAAAAA))),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_loadingSummary)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Column(
                                children: [
                                  Container(height: 12, width: double.infinity, decoration: BoxDecoration(color: const Color(0xFFEEEEEE), borderRadius: BorderRadius.circular(6))),
                                  const SizedBox(height: 8),
                                  Container(height: 12, width: 80, decoration: BoxDecoration(color: const Color(0xFFEEEEEE), borderRadius: BorderRadius.circular(6))),
                                ],
                              ),
                            )
                          else
                            SizedBox(
                              height: 200,
                              child: SingleChildScrollView(
                                child: Text(_summary, style: const TextStyle(fontFamily: 'Nunito', fontSize: 13, height: 1.6, color: Color(0xFF444444))),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Column(
                      children: [
                        GestureDetector(
                          onTap: (_savingPdf || _loadingSummary || _summaryError != null) ? null : _saveCurrentFileAsPdf,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0E81E),
                              border: Border.all(color: const Color(0xFF111111), width: 2),
                              borderRadius: BorderRadius.circular(40),
                              boxShadow: const [BoxShadow(color: Color(0xFF111111), offset: Offset(4, 4), blurRadius: 0)],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_savingPdf)
                                  const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Color(0xFF111111))))
                                else if (_loadingSummary || _summaryError != null)
                                  const Icon(Icons.block, color: Color(0xFF777777), size: 20)
                                else
                                  const Icon(Icons.download, color: Color(0xFF111111), size: 20),
                                const SizedBox(width: 10),
                                Text(_savingPdf ? 'Saving PDF...' : 'Save as PDF', style: const TextStyle(fontFamily: 'BlackHanSans', fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111111))),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        GestureDetector(
                          onTap: () => Navigator.of(context).push(PageRouteBuilder(
                            pageBuilder: (_, __, ___) => const YourFilesScreen(),
                            transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
                            transitionDuration: const Duration(milliseconds: 300),
                          )),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3AA9E8),
                              border: Border.all(color: const Color(0xFF111111), width: 2),
                              borderRadius: BorderRadius.circular(40),
                              boxShadow: const [BoxShadow(color: Color(0xFF111111), offset: Offset(4, 4), blurRadius: 0)],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.folder, color: Color(0xFFFFFFFF), size: 20),
                                SizedBox(width: 10),
                                Text('Your Files', style: TextStyle(fontFamily: 'BlackHanSans', fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFFFFFFF))),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        GestureDetector(
                          onTap: () {
                            if (_materialId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Material is not ready yet. Please wait for the summary to finish.')),
                              );
                              return;
                            }
                            Navigator.of(context).push(PageRouteBuilder(
                              pageBuilder: (_, __, ___) => OddyFlashcardScreen(materialId: _materialId!, fileName: widget.files.first.name),
                              transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
                              transitionDuration: const Duration(milliseconds: 300),
                            ));
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3AE86F),
                              border: Border.all(color: const Color(0xFF111111), width: 2),
                              borderRadius: BorderRadius.circular(40),
                              boxShadow: const [BoxShadow(color: Color(0xFF111111), offset: Offset(4, 4), blurRadius: 0)],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.quiz, color: Color(0xFF111111), size: 20),
                                SizedBox(width: 10),
                                Text('Test Your Knowledge', style: TextStyle(fontFamily: 'BlackHanSans', fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111111))),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

// ─── Done Early Dialog ────────────────────────────────────────────────────────

class _DoneEarlyDialog extends StatefulWidget {
  final String userName;
  final String durationText;
  final bool isPatrolMode;
  const _DoneEarlyDialog({required this.userName, required this.durationText, this.isPatrolMode = false});
  @override
  State<_DoneEarlyDialog> createState() => _DoneEarlyDialogState();
}

class _DoneEarlyDialogState extends State<_DoneEarlyDialog> with SingleTickerProviderStateMixin {
  late AnimationController _confettiController;
  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
  }
  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 8))],
            ),
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(width: 64, height: 64, child: CustomPaint(painter: _SmileyPainter())),
                  const SizedBox(height: 16),
                  Text('You did it, ${widget.userName}!', textAlign: TextAlign.center,
                    style: const TextStyle(fontFamily: 'BlackHanSans', fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF111111))),
                  const SizedBox(height: 8),
                  Text('You studied for ${widget.durationText} today. Amazing! 🔥', textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF555555))),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF9E6),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE8C44A), width: 1.5),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Icon(Icons.save_outlined, color: Color(0xFFB8860B), size: 20),
                        SizedBox(width: 10),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Your summary hasn\'t been saved!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF8B6914))),
                            SizedBox(height: 3),
                            Text('Are you sure you don\'t want to save it? You might need it to study later.',
                              style: TextStyle(fontSize: 12, color: Color(0xFF8B6914))),
                          ],
                        )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _DialogButton(label: 'Save Summary', icon: Icons.download_rounded, backgroundColor: const Color(0xFFF2EA05), textColor: const Color(0xFF111111), onTap: () => Navigator.of(context).pop('save')),
                  const SizedBox(height: 12),
                  _DialogButton(label: 'Continue Studying', icon: Icons.menu_book_rounded, backgroundColor: Colors.white, textColor: const Color(0xFF111111), borderColor: const Color(0xFF111111), onTap: () => Navigator.of(context).pop('continue')),
                  const SizedBox(height: 12),
                  if (widget.isPatrolMode)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEEEEE),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFBBBBBB), width: 2),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock, color: Color(0xFF999999), size: 18),
                          SizedBox(width: 8),
                          Text('Exit (Locked — Patrol Mode)', style: TextStyle(color: Color(0xFF999999), fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  else
                    _DialogButton(label: 'Exit', icon: Icons.logout_rounded, backgroundColor: const Color(0xFF111111), textColor: Colors.white, onTap: () => Navigator.of(context).pop('exit')),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _confettiController,
                builder: (_, __) => CustomPaint(painter: _ConfettiPainter(_confettiController.value)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;
  final VoidCallback onTap;
  const _DialogButton({required this.label, required this.icon, required this.backgroundColor, required this.textColor, this.borderColor, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: borderColor ?? backgroundColor, width: 2),
          boxShadow: const [BoxShadow(color: Color(0xFF111111), offset: Offset(3, 3), blurRadius: 0)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 20),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(fontFamily: 'BlackHanSans', fontSize: 16, fontWeight: FontWeight.w700, color: textColor)),
          ],
        ),
      ),
    );
  }
}

class _SmileyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2; final cy = size.height / 2; final r = size.width / 2;
    canvas.drawCircle(Offset(cx, cy), r - 1.5, Paint()..color = const Color(0xFF111111)..style = PaintingStyle.stroke..strokeWidth = 2.5);
    final eyePaint = Paint()..color = const Color(0xFF111111)..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx - r * 0.28, cy - r * 0.18), r * 0.09, eyePaint);
    canvas.drawCircle(Offset(cx + r * 0.28, cy - r * 0.18), r * 0.09, eyePaint);
    canvas.drawArc(Rect.fromCenter(center: Offset(cx, cy + r * 0.08), width: r * 0.9, height: r * 0.55), 0.2, math.pi - 0.4, false,
      Paint()..color = const Color(0xFF111111)..style = PaintingStyle.stroke..strokeWidth = 2.5..strokeCap = StrokeCap.round);
  }
  @override
  bool shouldRepaint(_SmileyPainter old) => false;
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  _ConfettiPainter(this.progress);
  static final List<_ConfettiPiece> _pieces = List.generate(60, (i) {
    final rng = math.Random(i * 13);
    return _ConfettiPiece(x: rng.nextDouble(), startY: -0.05 - rng.nextDouble() * 0.3, speed: 0.25 + rng.nextDouble() * 0.45,
      size: 5 + rng.nextDouble() * 8, angle: rng.nextDouble() * math.pi * 2, rotSpeed: (rng.nextDouble() - 0.5) * 6,
      color: _confettiColors[i % _confettiColors.length], isRect: rng.nextBool(),
      wobble: rng.nextDouble() * math.pi * 2, wobbleSpeed: 1 + rng.nextDouble() * 3);
  });
  static const _confettiColors = [Color(0xFFFF4D4D), Color(0xFF4DFF91), Color(0xFF4DB6FF), Color(0xFFFFD700), Color(0xFFFF69B4), Color(0xFFAD4DFF), Color(0xFF4DFFEE), Color(0xFFFF9F40)];
  @override
  void paint(Canvas canvas, Size size) {
    for (final piece in _pieces) {
      final t = (progress * piece.speed + piece.startY.abs()) % 1.0;
      final y = piece.startY + t * 1.3;
      if (y < 0 || y > 1.15) continue;
      final x = piece.x + math.sin(t * piece.wobbleSpeed * math.pi * 2 + piece.wobble) * 0.04;
      canvas.save();
      canvas.translate(x * size.width, y * size.height);
      canvas.rotate(piece.angle + t * piece.rotSpeed);
      final paint = Paint()..color = piece.color;
      if (piece.isRect) canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: piece.size, height: piece.size * 0.5), paint);
      else canvas.drawCircle(Offset.zero, piece.size * 0.5, paint);
      canvas.restore();
    }
  }
  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}

class _ConfettiPiece {
  final double x, startY, speed, size, angle, rotSpeed, wobble, wobbleSpeed;
  final Color color;
  final bool isRect;
  const _ConfettiPiece({required this.x, required this.startY, required this.speed, required this.size, required this.angle, required this.rotSpeed, required this.color, required this.isRect, required this.wobble, required this.wobbleSpeed});
}

class _DiagonalStripePainter extends CustomPainter {
  final Color stripeColor;
  _DiagonalStripePainter({this.stripeColor = const Color(0x0A000000)});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = stripeColor..strokeWidth = 1;
    const spacing = 20.0;
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), paint);
    }
  }
  @override
  bool shouldRepaint(_DiagonalStripePainter old) => stripeColor != old.stripeColor;
}

class _ArcTimerPainter extends CustomPainter {
  final double progress;
  _ArcTimerPainter({required this.progress});
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const strokeWidth = 14.0;
    const startAngle = -math.pi / 2;
    canvas.drawCircle(center, radius, Paint()..color = const Color(0xFF111111)..strokeWidth = strokeWidth + 4..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
    canvas.drawCircle(center, radius, Paint()..color = const Color(0xFFDDDDDD)..strokeWidth = strokeWidth..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
    if (progress > 0) {
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, 2 * math.pi * progress, false,
        Paint()..color = const Color(0xFF111111)..strokeWidth = strokeWidth + 4..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, 2 * math.pi * progress, false,
        Paint()..color = const Color(0xFF6DC95A)..strokeWidth = strokeWidth..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
    }
  }
  @override
  bool shouldRepaint(_ArcTimerPainter old) => old.progress != progress;
}