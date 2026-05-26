import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'theme_selector_screen.dart';
import 'study_session.dart';
import '../utils/app_localizations.dart';

class UploadScreen extends StatefulWidget {
  final String mood;
  final String location;
  final String userName;
  final AppTheme theme;

  const UploadScreen({
    super.key,
    required this.mood,
    required this.location,
    this.userName = 'Friend',
    this.theme = AppTheme.green,
  });

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final List<PlatformFile> _files = [];

  // Background sesuai mood
  Color get _bgColor {
    switch (widget.mood) {
      case 'happy':
        return const Color(0xFFFF8FAB); // pink
      case 'okay':
        return const Color(0xFFFFFFFF); // putih
      case 'sad':
      case 'tired':
        return const Color(0xFF90CAF9); // biru
      default:
        return const Color(0xFFFF8FAB);
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
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _onDone() {
    debugPrint('Done tapped. Files: $_files, Mood: ${widget.mood}, Location: ${widget.location}');
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => StudySession(
          mood: widget.mood,
          location: widget.location,
          userName: widget.userName,
          theme: widget.theme,
          files: _files,
        ),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      color: _bgColor,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Diagonal stripe bg
            CustomPaint(
              size: Size.infinite,
              painter: _DiagonalStripePainter(stripeColor: _stripeColor),
            ),

            // Navbar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 16, right: 16, top: 6, bottom: 2),
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.topLeft,
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: const Color(0xFF111111), width: 2),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: const [
                                BoxShadow(color: Color(0xFF111111), offset: Offset(2, 2), blurRadius: 0),
                              ],
                            ),
                            child: const Icon(Icons.arrow_back, size: 20, color: Color(0xFF111111)),
                          ),
                        ),
                      ),
                      const Align(
                        alignment: Alignment.topRight,
                        child: _LogoBadge(),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Main content
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 56), // navbar space

                        // Hello username
                        Text(
                          l.uploadGreeting(widget.userName),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'BlackHanSans',
                            fontSize: 32,
                            color: Color(0xFF111111),
                            letterSpacing: 0.5,
                            shadows: [
                              Shadow(
                                  color: Colors.white,
                                  offset: Offset(-2, -2),
                                  blurRadius: 0),
                              Shadow(
                                  color: Colors.white,
                                  offset: Offset(2, -2),
                                  blurRadius: 0),
                              Shadow(
                                  color: Colors.white,
                                  offset: Offset(-2, 2),
                                  blurRadius: 0),
                              Shadow(
                                  color: Colors.white,
                                  offset: Offset(2, 2),
                                  blurRadius: 0),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Subtitle
                        Text(
                          l.uploadSubtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'BlackHanSans',
                            fontSize: 13,
                            color: Color(0xFF444444),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Upload box
                        Expanded(
                          child: _UploadBox(
                            files: _files,
                            onFilesChanged: (files) =>
                                setState(() => _files
                                  ..clear()
                                  ..addAll(files)),
                            onFileRemoved: (index) =>
                                setState(() => _files.removeAt(index)),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Done button
                        _DoneButton(
                          fileCount: _files.length,
                          onTap: _onDone,
                        ),
                        const SizedBox(height: 12),

                        // AI quota note
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline,
                                size: 14, color: Color(0xFFE05555)),
                            const SizedBox(width: 6),
                            Flexible(
                              child: RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  style: const TextStyle(
                                    fontFamily: 'BlackHanSans',
                                    fontSize: 11,
                                    color: Color(0xFFE05555),
                                    height: 1.5,
                                  ),
                                  children: [
                                    TextSpan(text: l.upload20AI),
                                    TextSpan(
                                      text: l.uploadOfflineMode,
                                      style: const TextStyle(
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Upload Box ────────────────────────────────────────────────────
class _UploadBox extends StatefulWidget {
  final List<PlatformFile> files;
  final void Function(List<PlatformFile>) onFilesChanged;
  final void Function(int) onFileRemoved;

  const _UploadBox({
    required this.files,
    required this.onFilesChanged,
    required this.onFileRemoved,
  });

  @override
  State<_UploadBox> createState() => _UploadBoxState();
}

class _UploadBoxState extends State<_UploadBox> {
  bool _isLoading = false;

  Future<void> _pickFiles() async {
    setState(() => _isLoading = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'txt'],
        withData: true,   // ← wajib agar file.bytes tersedia untuk preview
      );
      if (result != null && result.files.isNotEmpty) {
        final merged = [...widget.files];
        for (final f in result.files) {
          // hindari duplikat nama
          if (!merged.any((e) => e.name == f.name)) {
            merged.add(f);
          }
        }
        widget.onFilesChanged(merged);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _pickFiles,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            // Dashed border overlay
            Positioned.fill(
              child: CustomPaint(
                painter: _DashedBorderPainter(),
              ),
            ),

            // Content
            widget.files.isEmpty
                ? Center(
                    child: _isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(40),
                            child: CircularProgressIndicator(
                              color: Color(0xFF111111),
                              strokeWidth: 3,
                            ),
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.insert_drive_file_outlined,
                                size: 48,
                                color: Color(0xFF888888),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                AppLocalizations.of(context).uploadClickFiles,
                                style: const TextStyle(
                                  fontFamily: 'BlackHanSans',
                                  fontSize: 17,
                                  color: Color(0xFF111111),
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                AppLocalizations.of(context).uploadFormats,
                                style: const TextStyle(
                                  fontFamily: 'BlackHanSans',
                                  fontSize: 13,
                                  color: Color(0xFF888888),
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AppLocalizations.of(context).uploadMaxSize,
                                style: const TextStyle(
                                  fontFamily: 'BlackHanSans',
                                  fontSize: 12,
                                  color: Color(0xFFAAAAAA),
                                ),
                              ),
                            ],
                          ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // File list
                        ...widget.files.asMap().entries.map((entry) {
                          final i = entry.key;
                          final f = entry.value;
                          final sizeStr = f.size > 0
                              ? '${(f.size / 1024 / 1024).toStringAsFixed(1)} MB'
                              : '';
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                  color: const Color(0xFF111111), width: 2),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0xFF111111),
                                  offset: Offset(3, 3),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.insert_drive_file_outlined,
                                    size: 20, color: Color(0xFF555555)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        f.name,
                                        style: const TextStyle(
                                          fontFamily: 'BlackHanSans',
                                          fontSize: 13,
                                          color: Color(0xFF222222),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (sizeStr.isNotEmpty)
                                        Text(
                                          sizeStr,
                                          style: const TextStyle(
                                            fontFamily: 'BlackHanSans',
                                            fontSize: 11,
                                            color: Color(0xFF888888),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => widget.onFileRemoved(i),
                                  child: const Icon(Icons.close,
                                      size: 18, color: Color(0xFF888888)),
                                ),
                              ],
                            ),
                          );
                        }),
                        // Add more button
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _pickFiles,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              border: Border.all(
                                  color: const Color(0xFF111111), width: 2),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add, size: 16,
                                    color: Color(0xFF111111)),
                                SizedBox(width: 4),
                                Text(
                                  'Add more',
                                  style: TextStyle(
                                    fontFamily: 'BlackHanSans',
                                    fontSize: 12,
                                    color: Color(0xFF111111),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

// ── Done Button ───────────────────────────────────────────────────
class _DoneButton extends StatefulWidget {
  final int fileCount;
  final VoidCallback onTap;

  const _DoneButton({required this.fileCount, required this.onTap});

  @override
  State<_DoneButton> createState() => _DoneButtonState();
}

class _DoneButtonState extends State<_DoneButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final hasFiles = widget.fileCount > 0;
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
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: hasFiles ? const Color(0xFF111111) : const Color(0xFFCCCCCC),
          borderRadius: BorderRadius.circular(999),
          boxShadow: _pressed
              ? []
              : [
                  BoxShadow(
                    color: hasFiles
                        ? const Color(0xFF111111)
                        : const Color(0xFFAAAAAA),
                    offset: const Offset(4, 4),
                    blurRadius: 0,
                  ),
                ],
        ),
        child: Center(
          child: Text(
            AppLocalizations.of(context).uploadDoneCount(widget.fileCount),
            style: TextStyle(
              fontFamily: 'BlackHanSans',
              fontSize: 16,
              letterSpacing: 1,
              color: hasFiles ? Colors.white : const Color(0xFF888888),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Logo Badge ────────────────────────────────────────────────────
class _LogoBadge extends StatelessWidget {
  const _LogoBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFF111111), width: 2.0),
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [
          BoxShadow(
              color: Color(0xFF111111), offset: Offset(3, 3), blurRadius: 0),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()..scale(-1.0, 1.0),
            child: Image.asset(
              'assets/images/logo.png',
              width: 28,
              height: 28,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const Text('🎓', style: TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 4),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('moody',
                  style: TextStyle(
                      fontFamily: 'BlackHanSans',
                      fontSize: 14,
                      color: Color(0xFF111111),
                      height: 1.1)),
              Text('study',
                  style: TextStyle(
                      fontFamily: 'BlackHanSans',
                      fontSize: 10,
                      color: Color(0xFF555555),
                      letterSpacing: 1.5,
                      height: 1.1)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Dashed Border Painter ─────────────────────────────────────────
class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF111111)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    const dashW = 10.0;
    const gapW = 7.0;
    const r = 20.0;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(r),
      ));

    final metrics = path.computeMetrics().first;
    double dist = 0;
    bool drawing = true;
    while (dist < metrics.length) {
      final len = drawing ? dashW : gapW;
      if (drawing) {
        canvas.drawPath(
          metrics.extractPath(dist, dist + len),
          paint,
        );
      }
      dist += len;
      drawing = !drawing;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
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
      canvas.drawLine(
          Offset(i, 0), Offset(i + size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DiagonalStripePainter old) =>
      old.stripeColor != stripeColor;
}