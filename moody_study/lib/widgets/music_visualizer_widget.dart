import 'dart:math';
import 'package:flutter/material.dart';

class MusicVisualizerWidget extends StatefulWidget {
  final bool show;
  final bool isPlaying;
  final bool isDark;
  final VoidCallback onToggle;

  const MusicVisualizerWidget({
    super.key,
    required this.show,
    required this.isPlaying,
    required this.onToggle,
    this.isDark = false,
  });

  @override
  State<MusicVisualizerWidget> createState() => _MusicVisualizerWidgetState();
}

class _MusicVisualizerWidgetState extends State<MusicVisualizerWidget>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late Animation<double> _entryOpacity;
  late Animation<Offset> _entrySlide;

  late AnimationController _barController;

  final List<double> _barFreq = [1.8, 2.5, 1.4, 2.1];
  final List<double> _barPhase = [0.0, pi * 0.6, pi, pi * 1.4];
  static const double _minH = 6;
  static const double _maxH = 36;

  bool _pressed = false;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _entryOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeIn),
    );
    _entrySlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryController,
      curve: const Cubic(0.34, 1.56, 0.64, 1),
    ));

    _barController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    if (widget.show) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) _entryController.forward();
      });
    }
  }

  @override
  void didUpdateWidget(MusicVisualizerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show && !oldWidget.show) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) _entryController.forward();
      });
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
    _barController.dispose();
    super.dispose();
  }

  double _barHeight(int i, double t) {
    if (!widget.isPlaying) return _minH;
    final sine = (sin(t * _barFreq[i] * pi * 2 + _barPhase[i]) + 1) / 2;
    return _minH + sine * (_maxH - _minH);
  }

  @override
  Widget build(BuildContext context) {
    final barColor =
        widget.isDark ? const Color(0xFF1EE86F) : const Color(0xFF111111);

    return Positioned(
      bottom: 20,
      right: 20,
      child: FadeTransition(
        opacity: _entryOpacity,
        child: SlideTransition(
          position: _entrySlide,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque, // ← fix utama: selalu tangkap tap
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) {
              setState(() => _pressed = false);
              widget.onToggle();
            },
            onTapCancel: () => setState(() => _pressed = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              transform: Matrix4.translationValues(
                _pressed ? 2 : 0,
                _pressed ? 2 : 0,
                0,
              ),
              // padding besar supaya area tap selalu cukup
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: 44,
                height: 44,
                child: AnimatedBuilder(
                  animation: _barController,
                  builder: (context, _) {
                    final t = _barController.value * 10.0;
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (i) {
                        final h = _barHeight(i, t);
                        final isMuted = !widget.isPlaying;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: AnimatedContainer(
                            duration: Duration(
                              milliseconds: isMuted ? 300 : 0,
                            ),
                            width: 7,
                            height: isMuted ? 7 : h,
                            decoration: BoxDecoration(
                              color: barColor,
                              borderRadius: BorderRadius.circular(
                                isMuted ? 3.5 : 2,
                              ),
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
