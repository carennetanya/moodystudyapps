import 'dart:async';

import 'package:flutter/material.dart';
import 'theme_selector_screen.dart';

class StudySession extends StatefulWidget {
  final String mood;
  final String userName;
  final AppTheme theme;

  const StudySession({
    super.key,
    required this.mood,
    this.userName = 'Friend',
    this.theme = AppTheme.green,
  });

  @override
  State<StudySession> createState() => _StudySessionState();
}

class _StudySessionState extends State<StudySession> {
  late int _minutes; // total minutes for the session
  late Duration _remaining;
  Timer? _timer;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _minutes = _minutesForMood(widget.mood);
    _remaining = Duration(minutes: _minutes);
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
        return const Color(0xFFFFF3E0);
      case 'okay':
        return const Color(0xFFFFFFFF);
      case 'tired':
        return const Color(0xFFE3F2FD);
      default:
        return const Color(0xFFFFFFFF);
    }
  }

  void _toggleRunning() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
      return;
    }

    if (_remaining.inSeconds <= 0) {
      setState(() => _remaining = Duration(minutes: _minutes));
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        final s = _remaining.inSeconds - 1;
        if (s <= 0) {
          _remaining = Duration.zero;
          _running = false;
          t.cancel();
        } else {
          _remaining = Duration(seconds: s);
        }
      });
    });
    setState(() => _running = true);
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
      return '\$hh:\$mm:\$ss';
    }
    return '\$mm:\$ss';
  }

  @override
  Widget build(BuildContext context) {
    final bg = _bgColorForMood(widget.mood);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      color: bg,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: const Text('Study Session', style: TextStyle(color: Color(0xFF111111))),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF111111)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 8),
                Text(
                  'Mood: ${widget.mood}',
                  style: const TextStyle(
                    fontFamily: 'BlackHanSans',
                    fontSize: 18,
                    color: Color(0xFF222222),
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _format(_remaining),
                          style: const TextStyle(
                            fontFamily: 'BlackHanSans',
                            fontSize: 56,
                            color: Color(0xFF111111),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Total: $_minutes minutes',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF444444),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _toggleRunning,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF111111),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              _running ? 'Pause' : 'Start',
                              style: const TextStyle(
                                color: Color(0xFFE5E81E),
                                fontFamily: 'BlackHanSans',
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          _timer?.cancel();
                          setState(() {
                            _running = false;
                            _remaining = Duration(minutes: _minutes);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF111111), width: 2),
                          ),
                          child: const Center(
                            child: Text(
                              'Reset',
                              style: TextStyle(
                                color: Color(0xFF111111),
                                fontFamily: 'BlackHanSans',
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
