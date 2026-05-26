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
import 'package:path_provider/path_provider.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_pdf_text/flutter_pdf_text.dart';
import 'package:moody_study/screens/oddy_flashcard_screen.dart';
import 'package:moody_study/screens/your_files_screen.dart';
import 'package:moody_study/services/material_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
 
import 'package:moody_study/services/streak_service.dart';
import 'package:moody_study/screens/life_lost_popup.dart';
import 'character_intro_screen.dart';
import 'level_up_screen.dart';
import 'streak_counter_screen.dart';
import 'theme_selector_screen.dart';
 
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
  Timer? _timer;
  bool _running = false;
  bool _savingPdf = false;
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
  int _totalDistractionSeconds = 0; // akumulasi total detik distraksi selama sesi
  bool _showRedFlash = false;
  final AudioPlayer _awayAlarmPlayer = AudioPlayer();
 
  int get _totalSeconds => widget.initialMinutes * 60;
  double get _progress {
    if (_totalSeconds == 0) return 0;
    return (_remaining.inSeconds / _totalSeconds).clamp(0.0, 1.0);
  }
 
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _remaining = Duration(minutes: widget.initialMinutes);
    _loadInitialStreak();
    _loadSummary();
  }
 
  Future<void> _loadInitialStreak() async {
    try {
      final streakInfo = await StreakService.fetchStreak();
      if (!mounted) return;
      setState(() {
        _initialStreak = streakInfo.currentStreak;
        _initialLife = streakInfo.life;
      });
    } catch (_) {
      // If the streak fetch fails, fallback gracefully and avoid forcing the screen.
    }
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
 
    try {
      final response = await MaterialService.summarizeMaterial(
        fileName: file.name,
        originalText: originalText,
      );
      if (!mounted) return;
      setState(() {
        _loadingSummary = false;
        _summary = response.summary;
        _materialId = response.id;
        _summaryError = null;
      });
      _startTimer();
    } catch (e) {
      if (!mounted) return;
      final sanitized = _sanitizeError(e.toString());
      setState(() {
        _loadingSummary = false;
        _summaryError = sanitized;
        _summary = 'Summary failed to load.';
      });
      // Log full error to console for debugging
      // ignore: avoid_print
      print('Gemini summary error: ${e.toString()}');
    }
  }
 
  String _sanitizeError(String raw) {
    var s = raw.replaceAll('<EOL>', '\n');
    // Try to extract a message field from JSON-like errors
    final msgMatch = RegExp('"message"\s*:\s*"([^"]+)"').firstMatch(s);
    if (msgMatch != null) return msgMatch.group(1)!;
    // Fallback: remove braces and long traces
    s = s.replaceAll(RegExp(r'[\{\}\[\]]'), '');
    if (s.length > 200) return s.substring(0, 200) + '...';
    return s;
  }
 
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        final s = _remaining.inSeconds - 1;
        if (s <= 0) {
          _remaining = Duration.zero;
          _running = false;
          t.cancel();
          _showSessionComplete();
        } else {
          _remaining = Duration(seconds: s);
        }
      });
    });
    setState(() => _running = true);
  }
 
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_shouldTrackAway) return;
 
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _startAwayTimer();
    } else if (state == AppLifecycleState.resumed) {
      _cancelAwayTimer();
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

    // Hanya handle kasus user balik SEBELUM alarm trigger (< 30 detik pergi)
    // Kalau alarm sudah trigger (_awayAlarmTriggered == true), cleanup sudah
    // ditangani di _triggerAwayAlarm setelah user pencet "I'm back".
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

    if (_isLibraryLocation) {
      _startFlashEffect();
      // Show popup immediately — flash continues behind the dialog
      await _showReturnPopup(awayDuration);
      _stopFlashEffect();
      _awayTimer?.cancel();
      _awayTimer = null;
      _awayStartTime = null;
      if (mounted) {
        setState(() {
          _awayAlarmTriggered = false;
          _showRedFlash = false;
        });
      }
    } else if (_isHomeLocation) {
      // Play alarm + vibrate first, then show popup immediately
      await _playAwayAlarm();
      await _showReturnPopup(awayDuration);
      // User pressed "I'm back" — stop everything now
      await _stopAwayAlarm();
      _awayStartTime = null;
      if (mounted) {
        setState(() {
          _awayAlarmTriggered = false;
          _showRedFlash = false;
        });
      }
    }
  }
 
  Future<void> _stopAwayAlarm() async {
    // Cancel vibration timer PERTAMA (sync) supaya getaran langsung berhenti
    _vibrationTimer?.cancel();
    _vibrationTimer = null;
    try {
      if (await Vibration.hasVibrator() ?? false) {
        await Vibration.cancel();
      }
    } catch (_) {}

    // Lalu stop audio
    try {
      await _awayAlarmPlayer.stop();
    } catch (_) {}
  }

  void _startFlashEffect() {
    _stopFlashEffect();
    _showRedFlash = true;
    _flashTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted) return;
      setState(() {
        _showRedFlash = !_showRedFlash;
      });
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
    // Akumulasi total detik distraksi
    _totalDistractionSeconds += seconds;
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
            const Text(
              'Hey, come back!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
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
                if (_isLibraryLocation) {
                  _stopFlashEffect();
                }
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
  try {
    await _awayAlarmPlayer.stop();
    await _awayAlarmPlayer.setPlayerMode(PlayerMode.mediaPlayer);
    await _awayAlarmPlayer.setReleaseMode(ReleaseMode.loop);
    await _awayAlarmPlayer.setVolume(1.0);

    try {
      final alarmFile = await _createTempAlarmFile();
      await _awayAlarmPlayer.play(DeviceFileSource(alarmFile.path));
    } catch (e) {
      debugPrint('Failed to play generated alarm file, trying asset fallback: $e');
      await _playAwayAlarmFromAssetFile();
    }

    await _startAwayVibration();
  } catch (e) {
    debugPrint('Away alarm failed: $e');
  }
}

  Future<File> _createTempAlarmFile() async {
    final tempDir = await getTemporaryDirectory();
    final alarmFile = File('${tempDir.path}/away_alarm.wav');
    final waveBytes = _buildAlarmWavBytes(
      frequency: 1000.0,
      durationSeconds: 1.0,
      amplitude: 0.9,
    );
    await alarmFile.writeAsBytes(waveBytes);
    return alarmFile;
  }

  Future<void> _playAwayAlarmFromAssetFile() async {
    final bytes = await rootBundle.load('assets/audio/alarm.wav');
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/away_alarm.wav');
    await tempFile.writeAsBytes(bytes.buffer.asUint8List());

    await _awayAlarmPlayer.play(DeviceFileSource(tempFile.path));
  }

  Future<void> _startAwayVibration() async {
    _vibrationTimer?.cancel();
    _vibrationTimer = null;

    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator ?? false) {
      await Vibration.vibrate(duration: 500);
      _vibrationTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) async {
          try {
            if (await Vibration.hasVibrator() ?? false) {
              await Vibration.vibrate(duration: 500);
            }
          } catch (_) {}
        },
      );
    } else {
      HapticFeedback.vibrate();
      _vibrationTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) async {
          try {
            HapticFeedback.vibrate();
          } catch (_) {}
        },
      );
    }
  }

  Uint8List _buildAlarmWavBytes({
    double frequency = 880.0,
    double durationSeconds = 0.8,
    double amplitude = 0.8,
    int sampleRate = 44100,
  }) {
    final sampleCount = (sampleRate * durationSeconds).round();
    final dataSize = sampleCount * 2;
    final headerSize = 44;
    final totalSize = headerSize + dataSize;
    final bytes = BytesBuilder();
 
    bytes.add(ascii.encode('RIFF'));
    bytes.add(_uint32Bytes(totalSize - 8));
    bytes.add(ascii.encode('WAVE'));
    bytes.add(ascii.encode('fmt '));
    bytes.add(_uint32Bytes(16)); // Subchunk1Size
    bytes.add(_uint16Bytes(1)); // AudioFormat PCM
    bytes.add(_uint16Bytes(1)); // NumChannels mono
    bytes.add(_uint32Bytes(sampleRate));
    bytes.add(_uint32Bytes(sampleRate * 2));
    bytes.add(_uint16Bytes(2)); // BlockAlign
    bytes.add(_uint16Bytes(16));
    bytes.add(ascii.encode('data'));
    bytes.add(_uint32Bytes(dataSize));
 
    for (var i = 0; i < sampleCount; i++) {
      final t = i / sampleRate;
      final value = (32767 * math.sin(2 * math.pi * frequency * t) * amplitude).round();
      bytes.add(_int16Bytes(value));
    }
 
    return bytes.toBytes();
  }
 
  Uint8List _uint16Bytes(int value) {
    final data = ByteData(2);
    data.setUint16(0, value, Endian.little);
    return data.buffer.asUint8List();
  }
 
  Uint8List _int16Bytes(int value) {
    final data = ByteData(2);
    data.setInt16(0, value, Endian.little);
    return data.buffer.asUint8List();
  }
 
  Uint8List _uint32Bytes(int value) {
    final data = ByteData(4);
    data.setUint32(0, value, Endian.little);
    return data.buffer.asUint8List();
  }
 
  void _toggleRunning() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
      return;
    }
 
    _startTimer();
  }
 
  Future<void> _saveCurrentFileAsPdf() async {
    if (widget.files.isEmpty) {
      return;
    }
 
    final file = widget.files.first;
    if (!mounted) return;
 
    setState(() {
      _savingPdf = true;
    });
 
    try {
      final pdfBytes = await _createPdfBytes(file);
      final pdfFileName = _normalizePdfFileName(file.name);
      final base64Content = base64Encode(pdfBytes);
 
      await MaterialService.saveFileAsPdf(
        fileName: pdfFileName,
        fileType: 'pdf',
        base64Content: base64Content,
      );
 
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('File "$pdfFileName" saved to Your Files.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save PDF: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _savingPdf = false;
        });
      }
    }
  }
 
  Future<List<int>> _createPdfBytes(PlatformFile file) async {
    if (file.extension?.toLowerCase() == 'pdf') {
      final raw =
          file.bytes ??
          (file.path != null ? await File(file.path!).readAsBytes() : null);
      if (raw == null || raw.isEmpty) {
        throw Exception('Unable to read source PDF.');
      }
      return raw;
    }
 
    final originalText = await _extractTextFromFile(file);
    if (originalText.trim().isEmpty) {
      throw Exception(
        'No text could be converted from file ${file.name}.',
      );
    }
 
    final pdf = pw.Document();
    final chunks = _splitTextIntoChunks(originalText, 800);
 
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return chunks
              .map(
                (chunk) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Paragraph(
                    text: chunk,
                    style: const pw.TextStyle(fontSize: 12, lineSpacing: 1.4),
                  ),
                ),
              )
              .toList();
        },
      ),
    );
 
    return pdf.save();
  }
 
  List<String> _splitTextIntoChunks(String text, int maxChunkSize) {
    final trimmed = text.trim();
    if (trimmed.length <= maxChunkSize) {
      return [trimmed];
    }
 
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
        if (splitAt <= start) {
          splitAt = end;
        }
        chunks.add(paragraph.substring(start, splitAt).trim());
        start = splitAt + 1;
      }
    }
 
    return chunks;
  }
 
  String _normalizePdfFileName(String fileName) {
    if (fileName.toLowerCase().endsWith('.pdf')) {
      return fileName;
    }
 
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
      ),
    );

    if (action == null || action == 'continue') return;

    SessionResult? sessionResult;
    try {
      sessionResult = await StreakService.completeSession(
        mood: widget.mood,
        location: widget.location,
        durationMinutes: studyDuration.inMinutes,
        focusSeconds: studyDuration.inSeconds,
        distractionSeconds: _totalDistractionSeconds,
      );
    } catch (e) {
      debugPrint('Failed to save session to database: $e');
    }

    if (!mounted) return;

    // Show streak counter screen only when the streak actually grew.
    final shouldShowStreak = sessionResult != null &&
        sessionResult.currentStreak > 0 &&
        (_initialStreak == null || sessionResult.currentStreak > _initialStreak!);

    final previousLife = _initialLife;

    if (shouldShowStreak) {
      await Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => StreakCounterScreen(
            previousStreak: (sessionResult!.currentStreak - 1).clamp(0, sessionResult.currentStreak),
            newStreak: sessionResult.currentStreak,
            userName: widget.userName,
            onContinue: () => Navigator.of(context).pop(),
          ),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
      if (!mounted) return;
    }

    if (sessionResult != null) {
      _initialStreak = sessionResult.currentStreak;
      _initialLife = sessionResult.life;
    }

    // Show level up screen if leveled up
    if (sessionResult != null && sessionResult.leveledUp) {
      await Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => LevelUpScreen(
            newLevel: sessionResult!.newLevel,
            newLevelName: sessionResult.newLevelName ?? _levelName(sessionResult.newLevel),
            xpEarnedInLevel: sessionResult.xpEarnedInLevel,
            userName: widget.userName,
            onContinue: () => Navigator.of(context).pop(),
          ),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
      if (!mounted) return;
    }

    if (sessionResult != null && previousLife != null && sessionResult.life > previousLife) {
      await showLifeRecoveredPopup(context, sessionResult.life);
    }

    if (action == 'save') {
      if (_materialId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Your summary is still preparing. Please wait a moment before saving.',
            ),
          ),
        );
        return;
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const YourFilesScreen(),
        ),
      );
      return;
    }

    if (action == 'exit') {
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => CharacterIntroScreen(
            userName: widget.userName,
            theme: widget.theme,
          ),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
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
      final hh = d.inHours.toString().padLeft(2, '0');
      return '$hh:$mm:$ss';
    }
    return '$mm:$ss';
  }
 
  Future<String> _extractTextFromFile(PlatformFile file) async {
    final extension = file.extension?.toLowerCase() ?? '';
 
    if (extension == 'txt' || extension == 'md' || extension == 'csv') {
      final raw =
          file.bytes ??
          (file.path != null ? await File(file.path!).readAsBytes() : null);
      if (raw != null) {
        return _decodeUtf8(raw);
      }
      return '';
    }
 
    if (extension == 'docx') {
      final preview = await _extractDocxText(file);
      return preview?.trim() ?? '';
    }
 
    if (extension == 'pdf') {
      try {
        final bytes = file.bytes;
        if (bytes != null) {
          final tempPath = await _writeBytesToTempPdf(bytes, file.name);
          try {
            final doc = await PDFDoc.fromPath(tempPath);
            return (await doc.text).trim();
          } finally {
            try {
              await File(tempPath).delete();
            } catch (_) {
              // Ignore cleanup errors.
            }
          }
        }
        if (file.path != null) {
          final doc = await PDFDoc.fromPath(file.path!);
          return (await doc.text).trim();
        }
      } catch (e) {
        debugPrint('PDF text extraction failed: $e');
      }
      return '';
    }
 
    return '';
  }
 
  String _decodeUtf8(List<int> bytes) {
    try {
      return utf8.decode(bytes, allowMalformed: true);
    } catch (_) {
      return '';
    }
  }
 
  Future<String> _writeBytesToTempPdf(List<int> bytes, String originalFileName) async {
    final tempDir = await getTemporaryDirectory();
    final safeName = originalFileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final tempFile = File('${tempDir.path}${Platform.pathSeparator}${safeName.isNotEmpty ? safeName : 'temp_pdf'}.pdf');
    await tempFile.create(recursive: true);
    await tempFile.writeAsBytes(bytes, flush: true);
    return tempFile.path;
  }
 
  Future<String?> _extractDocxText(PlatformFile file) async {
    try {
      final bytes =
          file.bytes ??
          (file.path != null ? await File(file.path!).readAsBytes() : null);
      if (bytes == null) return null;
 
      final archive = ZipDecoder().decodeBytes(bytes);
      ArchiveFile? documentEntry;
      for (final entry in archive.files) {
        if (entry.name == 'word/document.xml') {
          documentEntry = entry;
          break;
        }
      }
 
      if (documentEntry == null || documentEntry.content == null) {
        return null;
      }
 
      final xml = utf8.decode(
        documentEntry.content as List<int>,
        allowMalformed: true,
      );
      final text = _stripXmlText(xml).trim();
      return text.isEmpty ? null : text;
    } catch (_) {
      return null;
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
      if (c == '\x02') {
        inRun = true;
      } else if (c == '\x03') {
        inRun = false;
        buffer.write(' ');
      } else if (inRun) {
        buffer.write(c);
      } else if (c == '\n') {
        buffer.write('\n');
      }
    }
 
    var result = buffer.toString();
    result = result.replaceAll(RegExp(r' {2,}'), ' ');
    result = result.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    result = result.replaceAll(RegExp(r'^ +', multiLine: true), '');
    return result.trim();
  }
 
  Color get _bgColor {
    switch (widget.mood) {
      case 'happy':
        return const Color(0xFFFF8FAB);
      case 'okay':
        return const Color(0xFFFFFFFF);
      case 'sad':
      case 'tired':
        return const Color(0xFF90CAF9);
      default:
        return const Color(0xFFFFFFFF);
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
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _awayTimer?.cancel();
    _stopAwayAlarm();
    _awayAlarmPlayer.dispose();
    super.dispose();
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
            CustomPaint(
              size: Size.infinite,
              painter: _DiagonalStripePainter(stripeColor: _stripeColor),
            ),
            // Red flash overlay for library distraction alert
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Navbar back
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Color(0xFF111111),
                            size: 24,
                          ),
                        ),
                        const Spacer(),
                        if (kDebugMode)
                          IconButton(
                            tooltip: 'Trigger alarm (debug)',
                            onPressed: () async {
                              // allow quick foreground test
                              await _playAwayAlarm();
                            },
                            icon: const Icon(Icons.alarm, color: Colors.red),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
 
                    // Keep going message
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
 
                    // Timer circle
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Arc progress timer
                          CustomPaint(
                            size: const Size(200, 200),
                            painter: _ArcTimerPainter(
                              progress: _loadingSummary ? 1.0 : _progress,
                            ),
                          ),
                          // Center text
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 28),
                                  child: Text(
                                    _formatDuration(_remaining),
                                    style: TextStyle(
                                      fontFamily: 'BlackHanSans',
                                      fontSize: 44,
                                      color: widget.mood == 'okay'
                                          ? Colors.black
                                          : Colors.black87,
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
                                  color: widget.mood == 'okay'
                                      ? Colors.black54
                                      : Colors.black54,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
 
                    // Pause and Done Early buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: _toggleRunning,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: const Color(0xFF111111),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _running ? Icons.pause : Icons.play_arrow,
                                  color: const Color(0xFF111111),
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _running ? 'Pause' : 'Resume',
                                  style: const TextStyle(
                                    fontFamily: 'BlackHanSans',
                                    fontSize: 14,
                                    color: Color(0xFF111111),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: _showSessionComplete,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5E81E),
                              border: Border.all(
                                color: const Color(0xFF111111),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0xFF111111),
                                  offset: Offset(2, 2),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.check,
                                  color: Color(0xFF111111),
                                  size: 18,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Done Early',
                                  style: TextStyle(
                                    fontFamily: 'BlackHanSans',
                                    fontSize: 14,
                                    color: Color(0xFF111111),
                                    letterSpacing: 0.5,
                                  ),
                                ),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE5E5),
                          border: Border.all(
                            color: const Color(0xFFDD2C00),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: const [
                            Icon(
                              Icons.notifications_active,
                              color: Color(0xFFDD2C00),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Alarm is active because you left the app for more than 30 seconds.',
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: Color(0xFF111111),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
 
                    // Material Summary card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: const Color(0xFF111111),
                          width: 3,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0xFF111111),
                            offset: Offset(6, 6),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: const [
                                  Icon(
                                    Icons.description,
                                    size: 20,
                                    color: Color(0xFF111111),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Material Summary',
                                    style: TextStyle(
                                      fontFamily: 'BlackHanSans',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF111111),
                                    ),
                                  ),
                                ],
                              ),
                              if (_loadingSummary)
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(
                                      Color(0xFF1EE86F),
                                    ),
                                  ),
                                )
                              else
                                Text(
                                  _summaryError == null ? 'Ready' : 'Error',
                                  style: const TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 12,
                                    color: Color(0xFFAAAAAA),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_loadingSummary)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Column(
                                children: [
                                  Container(
                                    height: 12,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEEEEEE),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    height: 12,
                                    width: 80,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEEEEEE),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            SingleChildScrollView(
                              child: SizedBox(
                                height: 200,
                                child: SingleChildScrollView(
                                  child: Text(
                                    _summary,
                                    style: const TextStyle(
                                      fontFamily: 'Nunito',
                                      fontSize: 13,
                                      height: 1.6,
                                      color: Color(0xFF444444),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Column(
                      children: [
                        GestureDetector(
                          onTap: (_savingPdf || _loadingSummary || _summaryError != null)
                              ? null
                              : _saveCurrentFileAsPdf,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0E81E),
                              border: Border.all(
                                color: const Color(0xFF111111),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(40),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0xFF111111),
                                  offset: Offset(4, 4),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_savingPdf)
                                  const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(
                                        Color(0xFF111111),
                                      ),
                                    ),
                                  )
                                else if (_loadingSummary || _summaryError != null)
                                  const Icon(
                                    Icons.block,
                                    color: Color(0xFF777777),
                                    size: 20,
                                  )
                                else
                                  const Icon(
                                    Icons.download,
                                    color: Color(0xFF111111),
                                    size: 20,
                                  ),
                                const SizedBox(width: 10),
                                Text(
                                  _savingPdf ? 'Saving PDF...' : 'Save as PDF',
                                  style: const TextStyle(
                                    fontFamily: 'BlackHanSans',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF111111),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              PageRouteBuilder(
                                pageBuilder: (_, __, ___) =>
                                    const YourFilesScreen(),
                                transitionsBuilder: (_, anim, __, child) =>
                                    FadeTransition(opacity: anim, child: child),
                                transitionDuration: const Duration(
                                  milliseconds: 300,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3AA9E8),
                              border: Border.all(
                                color: const Color(0xFF111111),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(40),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0xFF111111),
                                  offset: Offset(4, 4),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.folder,
                                  color: Color(0xFFFFFFFF),
                                  size: 20,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Your Files',
                                  style: TextStyle(
                                    fontFamily: 'BlackHanSans',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFFFFFFF),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        GestureDetector(
                          onTap: () {
                            if (_materialId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Material is not ready yet. Please wait for the summary to finish.',
                                  ),
                                ),
                              );
                              return;
                            }
 
                            Navigator.of(context).push(
                              PageRouteBuilder(
                                pageBuilder: (_, __, ___) =>
                                    OddyFlashcardScreen(
                                      materialId: _materialId!,
                                      fileName: widget.files.first.name,
                                    ),
                                transitionsBuilder: (_, anim, __, child) =>
                                    FadeTransition(opacity: anim, child: child),
                                transitionDuration: const Duration(
                                  milliseconds: 300,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3AE86F),
                              border: Border.all(
                                color: const Color(0xFF111111),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(40),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0xFF111111),
                                  offset: Offset(4, 4),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.quiz,
                                  color: Color(0xFF111111),
                                  size: 20,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Test Your Knowledge',
                                  style: TextStyle(
                                    fontFamily: 'BlackHanSans',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF111111),
                                  ),
                                ),
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
    );
  }
}
 
// ─── Done Early Dialog ────────────────────────────────────────────────────────

class _DoneEarlyDialog extends StatefulWidget {
  final String userName;
  final String durationText;

  const _DoneEarlyDialog({
    required this.userName,
    required this.durationText,
  });

  @override
  State<_DoneEarlyDialog> createState() => _DoneEarlyDialogState();
}

class _DoneEarlyDialogState extends State<_DoneEarlyDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
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
          // White card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                // Drawn smiley icon (no emoji)
                SizedBox(
                  width: 64,
                  height: 64,
                  child: CustomPaint(painter: _SmileyPainter()),
                ),
                const SizedBox(height: 16),
                // Title
                Text(
                  'You did it, ${widget.userName}!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'BlackHanSans',
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111111),
                  ),
                ),
                const SizedBox(height: 8),
                // Subtitle
                Text(
                  'You studied for ${widget.durationText} today. Amazing! 🔥',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF555555),
                  ),
                ),
                const SizedBox(height: 20),
                // Warning box
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your summary hasn\'t been saved!',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color(0xFF8B6914),
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Are you sure you don\'t want to save it? You might need it to study later.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF8B6914),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Save Summary button (yellow, primary)
                _DialogButton(
                  label: 'Save Summary',
                  icon: Icons.download_rounded,
                  backgroundColor: const Color(0xFFF2EA05),
                  textColor: const Color(0xFF111111),
                  onTap: () => Navigator.of(context).pop('save'),
                ),
                const SizedBox(height: 12),
                // Continue Studying button (white / outlined)
                _DialogButton(
                  label: 'Continue Studying',
                  icon: Icons.menu_book_rounded,
                  backgroundColor: Colors.white,
                  textColor: const Color(0xFF111111),
                  borderColor: const Color(0xFF111111),
                  onTap: () => Navigator.of(context).pop('continue'),
                ),
                const SizedBox(height: 12),
                // Exit button (black)
                _DialogButton(
                  label: 'Exit',
                  icon: Icons.logout_rounded,
                  backgroundColor: const Color(0xFF111111),
                  textColor: Colors.white,
                  onTap: () => Navigator.of(context).pop('exit'),
                ),
              ],
            ),
          ),
          ),
          // Confetti overlay (behind card in visual layering but drawn on top via Stack)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _confettiController,
                builder: (_, __) => CustomPaint(
                  painter: _ConfettiPainter(_confettiController.value),
                ),
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

  const _DialogButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.textColor,
    this.borderColor,
    required this.onTap,
  });

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
          border: Border.all(
            color: borderColor ?? backgroundColor,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF111111),
              offset: const Offset(3, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'BlackHanSans',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Smiley Painter ───────────────────────────────────────────────────────────

class _SmileyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    // Circle outline
    final circlePaint = Paint()
      ..color = const Color(0xFF111111)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(Offset(cx, cy), r - 1.5, circlePaint);

    // Eyes
    final eyePaint = Paint()
      ..color = const Color(0xFF111111)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx - r * 0.28, cy - r * 0.18), r * 0.09, eyePaint);
    canvas.drawCircle(Offset(cx + r * 0.28, cy - r * 0.18), r * 0.09, eyePaint);

    // Smile arc
    final smilePaint = Paint()
      ..color = const Color(0xFF111111)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final smileRect = Rect.fromCenter(
      center: Offset(cx, cy + r * 0.08),
      width: r * 0.9,
      height: r * 0.55,
    );
    canvas.drawArc(smileRect, 0.2, math.pi - 0.4, false, smilePaint);
  }

  @override
  bool shouldRepaint(_SmileyPainter old) => false;
}

// ─── Confetti Painter ─────────────────────────────────────────────────────────

class _ConfettiPainter extends CustomPainter {
  final double progress;

  _ConfettiPainter(this.progress);

  static final _rng = math.Random(42);

  static final List<_ConfettiPiece> _pieces = List.generate(60, (i) {
    final rng = math.Random(i * 13);
    return _ConfettiPiece(
      x: rng.nextDouble(),
      startY: -0.05 - rng.nextDouble() * 0.3,
      speed: 0.25 + rng.nextDouble() * 0.45,
      size: 5 + rng.nextDouble() * 8,
      angle: rng.nextDouble() * math.pi * 2,
      rotSpeed: (rng.nextDouble() - 0.5) * 6,
      color: _confettiColors[i % _confettiColors.length],
      isRect: rng.nextBool(),
      wobble: rng.nextDouble() * math.pi * 2,
      wobbleSpeed: 1 + rng.nextDouble() * 3,
    );
  });

  static const _confettiColors = [
    Color(0xFFFF4D4D),
    Color(0xFF4DFF91),
    Color(0xFF4DB6FF),
    Color(0xFFFFD700),
    Color(0xFFFF69B4),
    Color(0xFFAD4DFF),
    Color(0xFF4DFFEE),
    Color(0xFFFF9F40),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final piece in _pieces) {
      final t = (progress * piece.speed + piece.startY.abs()) % 1.0;
      final y = piece.startY + t * 1.3;
      if (y < 0 || y > 1.15) continue;

      final x = piece.x + math.sin(t * piece.wobbleSpeed * math.pi * 2 + piece.wobble) * 0.04;
      final px = x * size.width;
      final py = y * size.height;
      final rotation = piece.angle + t * piece.rotSpeed;

      final paint = Paint()..color = piece.color;

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(rotation);

      if (piece.isRect) {
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: piece.size, height: piece.size * 0.5),
          paint,
        );
      } else {
        canvas.drawCircle(Offset.zero, piece.size * 0.5, paint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}

class _ConfettiPiece {
  final double x;
  final double startY;
  final double speed;
  final double size;
  final double angle;
  final double rotSpeed;
  final Color color;
  final bool isRect;
  final double wobble;
  final double wobbleSpeed;

  const _ConfettiPiece({
    required this.x,
    required this.startY,
    required this.speed,
    required this.size,
    required this.angle,
    required this.rotSpeed,
    required this.color,
    required this.isRect,
    required this.wobble,
    required this.wobbleSpeed,
  });
}

// ─────────────────────────────────────────────────────────────────────────────

class _DiagonalStripePainter extends CustomPainter {
  final Color stripeColor;
 
  _DiagonalStripePainter({this.stripeColor = const Color(0x0A000000)});
 
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = stripeColor
      ..strokeWidth = 1;
 
    const spacing = 20.0;
 
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }
 
  @override
  bool shouldRepaint(_DiagonalStripePainter oldDelegate) =>
      stripeColor != oldDelegate.stripeColor;
}
 
class _ArcTimerPainter extends CustomPainter {
  final double progress;
  _ArcTimerPainter({required this.progress});
 
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const strokeWidth = 14.0;
    const startAngle = -math.pi / 2; // top
 
    // Background track (black outline full circle)
    final trackOutlinePaint = Paint()
      ..color = const Color(0xFF111111)
      ..strokeWidth = strokeWidth + 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackOutlinePaint);
 
    // Background track (light gray fill)
    final trackPaint = Paint()
      ..color = const Color(0xFFDDDDDD)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);
 
    // Progress arc outline (black)
    if (progress > 0) {
      final arcOutlinePaint = Paint()
        ..color = const Color(0xFF111111)
        ..strokeWidth = strokeWidth + 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        2 * math.pi * progress,
        false,
        arcOutlinePaint,
      );
 
      // Progress arc green fill
      final arcPaint = Paint()
        ..color = const Color(0xFF6DC95A)
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        2 * math.pi * progress,
        false,
        arcPaint,
      );
    }
  }
 
  @override
  bool shouldRepaint(_ArcTimerPainter old) => old.progress != progress;
}