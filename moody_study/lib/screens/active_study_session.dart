import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:moody_study/services/material_service.dart';

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

class _ActiveStudySessionState extends State<ActiveStudySession> {
  late Duration _remaining;
  Timer? _timer;
  bool _running = false;
  String _summary = '';
  bool _loadingSummary = true;
  String? _summaryError;

  int get _totalSeconds => widget.initialMinutes * 60;
  double get _progress {
    if (_totalSeconds == 0) return 0;
    return (_remaining.inSeconds / _totalSeconds).clamp(0.0, 1.0);
  }

  @override
  void initState() {
    super.initState();
    _remaining = Duration(minutes: widget.initialMinutes);
    _loadSummary();
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
        _summary = 'Tidak ada materi untuk dirangkum.';
      });
      return;
    }

    final file = widget.files.first;
    final originalText = await _extractTextFromFile(file);
    if (originalText.trim().isEmpty) {
      if (!mounted) return;
      setState(() {
        _loadingSummary = false;
        _summary = 'Tidak dapat membaca materi dari file ${file.name}.';
      });
      return;
    }

    try {
      final summary = await MaterialService.summarizeMaterial(
        fileName: file.name,
        originalText: originalText,
      );
      if (!mounted) return;
      setState(() {
        _loadingSummary = false;
        _summary = summary;
      });
      _startTimer();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingSummary = false;
        _summaryError = e.toString();
        _summary = 'Ringkasan gagal dimuat. ${_summaryError ?? ''}';
      });
    }
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

  void _toggleRunning() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
      return;
    }

    _startTimer();
  }

  void _showSessionComplete() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sesi Selesai! 🎉'),
        content: const Text('Bagus! Kamu telah menyelesaikan sesi belajar.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Kembali'),
          ),
        ],
      ),
    );
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
      final raw = file.bytes ??
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
      return ''; // PDF extraction not supported in this version.
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

  Future<String?> _extractDocxText(PlatformFile file) async {
    try {
      final bytes = file.bytes ??
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
    _timer?.cancel();
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
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Navbar back
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: const Icon(Icons.arrow_back, color: Color(0xFF111111), size: 24),
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
                      width: 190,
                      height: 190,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: _loadingSummary ? null : _progress,
                            strokeWidth: 18,
                            color: const Color(0xFF1EE86F),
                            backgroundColor: Colors.white.withOpacity(0.18),
                          ),
                          Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: widget.mood == 'okay' ? Colors.white : Colors.transparent,
                            ),
                            child: Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _formatDuration(_remaining),
                                      style: TextStyle(
                                        fontFamily: 'BlackHanSans',
                                        fontSize: 52,
                                        color: widget.mood == 'okay' ? Colors.black : Colors.white,
                                        height: 1,
                                        shadows: const [
                                          Shadow(
                                            color: Colors.black26,
                                            offset: Offset(1, 1),
                                            blurRadius: 2,
                                          ),
                                        ],
                                      ),
                                      softWrap: false,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'REMAINING',
                                      style: TextStyle(
                                        fontFamily: 'Nunito',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: widget.mood == 'okay' ? Colors.black54 : Colors.white,
                                        letterSpacing: 1.5,
                                        shadows: const [
                                          Shadow(
                                            color: Colors.black26,
                                            offset: Offset(1, 1),
                                            blurRadius: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
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
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                                Icon(Icons.check, color: Color(0xFF111111), size: 18),
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

                    // Material Summary card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFF111111), width: 3),
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
                                  Icon(Icons.description, size: 20, color: Color(0xFF111111)),
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
                                    valueColor: AlwaysStoppedAnimation(Color(0xFF1EE86F)),
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

class _DiagonalStripePainter extends CustomPainter {
  final Color stripeColor;

  _DiagonalStripePainter({
    this.stripeColor = const Color(0x0A000000),
  });

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
