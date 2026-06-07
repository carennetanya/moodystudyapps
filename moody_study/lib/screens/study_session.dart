import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:archive/archive.dart';
import 'package:dartz/dartz.dart' hide State;
import 'package:moody_study/core/failure.dart';
import 'package:moody_study/core/exception_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'theme_selector_screen.dart';
import 'active_study_session.dart';

class StudySession extends StatefulWidget {
  final String mood;
  final String location;
  final String userName;
  final AppTheme theme;
  final List<PlatformFile> files;
  final String? initialSubject;   // dari notif jadwal
  final int? initialMinutes;      // durasi dari jadwal (override mood default)

  const StudySession({
    super.key,
    required this.mood,
    this.location = 'home',
    this.userName = 'Friend',
    this.theme = AppTheme.green,
    this.files = const [],
    this.initialSubject,
    this.initialMinutes,
  });

  @override
  State<StudySession> createState() => _StudySessionState();
}

class _StudySessionState extends State<StudySession> {
  late int _minutes;
  late Duration _remaining;
  Timer? _timer;
  bool _running = false;

  // Mutable local copy of files so we can remove entries
  late List<PlatformFile> _files;

  @override
  void initState() {
    super.initState();
    _minutes = widget.initialMinutes ?? _minutesForMood(widget.mood);
    _remaining = Duration(minutes: _minutes);
    _files = List<PlatformFile>.from(widget.files);
  }

  void _adjustDuration(int delta) {
    setState(() {
      _minutes = (_minutes + delta).clamp(1, 180);
      if (!_running) {
        _remaining = Duration(minutes: _minutes);
      }
    });
  }

  int _minutesForMood(String mood) {
    switch (mood) {
      case 'happy':
        return 60;
      case 'okay':
        return 40;
      case 'tired':
        return 25;
      default:
        return 40;
    }
  }

  Color _bgColorForMood(String mood) {
    switch (mood) {
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

  String _motivationalMessageForMood(String mood) {
    switch (mood) {
      case 'happy':
        return "You're in a great mood! Let's channel that energy! 🚀";
      case 'okay':
        return "Taking it steady. You got this! 💪";
      case 'tired':
        return "Take it slow. Small steps count! ✨";
      default:
        return "Let's do this! 🎯";
    }
  }

  Color _stripeColorForMood(String mood) {
    switch (mood) {
      case 'okay':
        return Colors.black.withOpacity(0.04);
      default:
        return Colors.black.withOpacity(0.06);
    }
  }

  bool _pickingFiles = false;

  Future<void> _pickFiles() async {
    if (_pickingFiles) return;
    setState(() => _pickingFiles = true);
    try {
      await FilePicker.platform.clearTemporaryFiles();
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'txt'],
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() => _files = [result.files.first]);
      }
    } finally {
      if (mounted) setState(() => _pickingFiles = false);
    }
  }

  void _toggleRunning() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => ActiveStudySession(
          mood: widget.mood,
          location: widget.location,
          userName: widget.userName,
          theme: widget.theme,
          files: _files,
          initialMinutes: _minutes,
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _format(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      final hh = d.inHours.toString().padLeft(2, '0');
      return '$hh:$mm:$ss';
    }
    return '$mm:$ss';
  }

  /// Remove a file from the list with a confirmation snackbar
  void _removeFile(int index) {
    final removed = _files[index];
    setState(() {
      _files.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${removed.name} removed',
          style: const TextStyle(fontFamily: 'Nunito'),
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = _bgColorForMood(widget.mood);
    final stripeColor = _stripeColorForMood(widget.mood);
    final totalSize = _files.fold<int>(0, (sum, file) => sum + (file.size ?? 0));
    final totalSizeStr = _formatFileSize(totalSize);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      color: bg,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            CustomPaint(
              size: Size.infinite,
              painter: _DiagonalStripePainter(stripeColor: stripeColor),
            ),

            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Navbar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: const Icon(Icons.arrow_back, color: Color(0xFF111111), size: 24),
                        ),
                        const SizedBox(width: 24),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // TODAY'S STUDY SESSION card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFF111111), width: 3),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0xFF111111),
                            offset: Offset(6, 6),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            "TODAY'S STUDY SESSION",
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFAAAAAA),
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () => _adjustDuration(-5),
                                child: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE5E81E),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFF111111), width: 2),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      '−',
                                      style: TextStyle(
                                        fontFamily: 'BlackHanSans',
                                        fontSize: 28,
                                        color: Color(0xFF111111),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 24),
                              Column(
                                children: [
                                  Text(
                                    '$_minutes',
                                    style: const TextStyle(
                                      fontFamily: 'BlackHanSans',
                                      fontSize: 64,
                                      color: Color(0xFF111111),
                                      height: 1,
                                    ),
                                  ),
                                  const Text(
                                    'min',
                                    style: TextStyle(
                                      fontFamily: 'Nunito',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF111111),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 24),
                              GestureDetector(
                                onTap: () => _adjustDuration(5),
                                child: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE5E81E),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFF111111), width: 2),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      '+',
                                      style: TextStyle(
                                        fontFamily: 'BlackHanSans',
                                        fontSize: 28,
                                        color: Color(0xFF111111),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          Text(
                            'RECOMMENDED FOR YOUR MOOD',
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFAAAAAA),
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 8),

                          Text(
                            _motivationalMessageForMood(widget.mood),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111111),
                            ),
                          ),
                          const SizedBox(height: 12),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE5E81E),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE5E81E),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF111111).withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── File cards ──────────────────────────────────────────
                    if (_files.isNotEmpty) ...[
                      // Header row: total size label
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Text(
                              '${_files.length} file${_files.length > 1 ? 's' : ''} · $totalSizeStr total',
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFAAAAAA),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // One card per file
                      ...List.generate(_files.length, (i) {
                        final file = _files[i];
                        return Padding(
                          padding: EdgeInsets.only(bottom: i < _files.length - 1 ? 10 : 0),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: const Color(0xFF111111), width: 3),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                // File icon
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5F5F5),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFF111111), width: 1.5),
                                  ),
                                  child: const Icon(
                                    Icons.insert_drive_file_outlined,
                                    size: 18,
                                    color: Color(0xFF555555),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Name + size
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        file.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontFamily: 'BlackHanSans',
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF111111),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _formatFileSize(file.size ?? 0),
                                        style: const TextStyle(
                                          fontFamily: 'Nunito',
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFFAAAAAA),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // READY button (preview)
                                GestureDetector(
                                  onTap: () => _showFilePreview(file),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1EE86F),
                                      border: Border.all(color: const Color(0xFF111111), width: 2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      'READY',
                                      style: TextStyle(
                                        fontFamily: 'BlackHanSans',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF111111),
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Remove (×) button
                                GestureDetector(
                                  onTap: () => _removeFile(i),
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFEEEE),
                                      border: Border.all(color: const Color(0xFF111111), width: 2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Color(0xFFCC2222),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],

                    const SizedBox(height: 28),

                    // Upload file material (selalu tampil)
                    GestureDetector(
                      onTap: _pickingFiles ? null : _pickFiles,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFFFF),
                          border: Border.all(color: const Color(0xFF111111), width: 2),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0xFF111111),
                              offset: Offset(3, 3),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: Center(
                          child: _pickingFiles
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF111111)),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.upload_file_rounded, color: Color(0xFF111111), size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Tambah Materi',
                                      style: TextStyle(
                                        fontFamily: 'BlackHanSans',
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF111111),
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Start Studying button
                    GestureDetector(
                      onTap: _toggleRunning,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5E81E),
                          border: Border.all(color: const Color(0xFF111111), width: 3),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0xFF111111),
                              offset: Offset(4, 4),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.play_arrow, color: Color(0xFF111111), size: 24),
                              SizedBox(width: 8),
                              Text(
                                'Start Studying',
                                style: TextStyle(
                                  fontFamily: 'BlackHanSans',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF111111),
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _showFilePreview(PlatformFile file) async {
    // Show loading indicator while reading
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final content = await _readPreviewContent(file);

    if (!mounted) return;
    Navigator.of(context).pop(); // close loading

    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF111111), width: 3),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dialog title
              Row(
                children: [
                  const Icon(Icons.insert_drive_file_outlined, size: 20, color: Color(0xFF555555)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      file.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'BlackHanSans',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111111),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(height: 2, color: const Color(0xFF111111)),
              const SizedBox(height: 12),

              // Content
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: SingleChildScrollView(
                  child: Text(
                    content,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 13,
                      height: 1.6,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Close button
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111111),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontFamily: 'BlackHanSans',
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<Either<Failure, String?>> _tryReadTextBytes(PlatformFile file) async {
    try {
      final raw = file.bytes ?? (file.path != null ? await File(file.path!).readAsBytes() : null);
      if (raw == null) return const Right(null);
      return _decodeUtf8(raw).fold(
        (f) => Left(f),
        (s) => Right<Failure, String?>(s),
      );
    } catch (e) {
      return Left(StorageFailure(sanitizeException(e)));
    }
  }

  Future<String> _readPreviewContent(PlatformFile file) async {
    final extension = file.extension?.toLowerCase() ?? '';

    if (extension == 'txt' || extension == 'md' || extension == 'csv') {
      final result = await _tryReadTextBytes(file);
      return result.fold(
        (_) => 'Unable to read text preview from this file.',
        (text) => text ?? 'Unable to read text preview from this file.',
      );
    }

    if (extension == 'docx') {
      final preview = await _extractDocxText(file);
      return preview.fold(
        (_) => 'Could not extract text from this DOCX file.\nFile name: ${file.name}',
        (text) => (text != null && text.trim().isNotEmpty)
            ? text.trim()
            : 'Could not extract text from this DOCX file.\nFile name: ${file.name}',
      );
    }

    if (extension == 'pdf') {
      return 'Preview for PDF files is not supported yet.\n\nFile name: ${file.name}';
    }

    return 'Preview is not available for this file type.\n\nFile name: ${file.name}';
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
      final List<int>? bytes = file.bytes != null
          ? file.bytes!
          : (file.path != null ? await File(file.path!).readAsBytes() : null);

      if (bytes == null) return const Right(null);

      final archive = ZipDecoder().decodeBytes(bytes);

      ArchiveFile? documentEntry;
      for (final entry in archive.files) {
        if (entry.name == 'word/document.xml') {
          documentEntry = entry;
          break;
        }
      }
      if (documentEntry == null) return const Right(null);

      final content = documentEntry.content;
      if (content == null) return const Right(null);

      final xml = utf8.decode(content is List<int> ? content : List<int>.from(content), allowMalformed: true);
      final text = _stripXmlText(xml).trim();
      return Right(text.isEmpty ? null : text);
    } catch (e) {
      return Left(StorageFailure(sanitizeException(e)));
    }
  }

  String _stripXmlText(String xml) {
    // Normalize line endings
    var text = xml.replaceAll(RegExp(r'\r\n|\r'), '\n');

    // Mark paragraph boundaries before stripping tags
    text = text.replaceAll(RegExp(r'</w:p>', caseSensitive: false), '\n');

    // Mark <w:t> open/close with sentinel chars so we know what's real text
    text = text.replaceAll(RegExp(r'<w:t[^>]*>'), '\x02');
    text = text.replaceAll(RegExp(r'</w:t>', caseSensitive: false), '\x03');

    // Strip ALL XML tags including those with multiline attributes
    text = text.replaceAll(RegExp(r'<[^>]*>', dotAll: true), '');

    // Walk the result: only keep content between \x02 and \x03 (real text runs)
    // and newlines (paragraph breaks). Discard stray attribute remnants.
    final buffer = StringBuffer();
    bool inRun = false;
    for (int i = 0; i < text.length; i++) {
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
}

// ── Diagonal Stripe Painter ──────────────────────────────────────────
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