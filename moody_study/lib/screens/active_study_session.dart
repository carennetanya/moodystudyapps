import 'dart:async';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
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

  @override
  void initState() {
    super.initState();
    _remaining = Duration(minutes: widget.initialMinutes);
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    // For now, show a placeholder summary
    // In real implementation, fetch from backend API
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        _loadingSummary = false;
        _summary = widget.files.isNotEmpty
            ? '''📚 **${widget.files.first.name}**

Ringkasan Materi:
• Konsep utama telah diidentifikasi dan dijelaskan
• Poin-poin penting sudah disarikan dengan baik
• Struktur materi terorganisir dengan jelas
• Siap untuk pembelajaran mendalam

Fokus belajar: Pahami konsep dasar terlebih dahulu, lalu berlanjut ke aplikasi praktis.'''
            : 'Tidak ada materi untuk dirangkum.';
      });
    }
  }

  void _toggleRunning() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
      return;
    }

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
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF1EE86F),
                          width: 4,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _formatDuration(_remaining),
                              style: const TextStyle(
                                fontFamily: 'BlackHanSans',
                                fontSize: 48,
                                color: Color(0xFF111111),
                                height: 1,
                              ),
                            ),
                            const Text(
                              'REMAINING',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFAAAAAA),
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
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
                                const Text(
                                  'Summarizing..',
                                  style: TextStyle(
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
