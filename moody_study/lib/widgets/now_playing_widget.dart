import 'package:flutter/material.dart';

class NowPlayingWidget extends StatefulWidget {
  final bool show;
  final String songName;
  final bool isPlaying;

  const NowPlayingWidget({
    super.key,
    required this.show,
    this.songName = 'good.mp3',
    this.isPlaying = true,
  });

  @override
  State<NowPlayingWidget> createState() => _NowPlayingWidgetState();
}

class _NowPlayingWidgetState extends State<NowPlayingWidget>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  late AnimationController _dotController;
  late AnimationController _noteController;
  late Animation<double> _noteBounce;

  @override
  void initState() {
    super.initState();

    // Slide in dari ATAS
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -2.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: const Cubic(0.34, 1.56, 0.64, 1),
      ),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeIn),
    );

    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _noteController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _noteBounce = Tween<double>(begin: 0, end: -5).animate(
      CurvedAnimation(parent: _noteController, curve: Curves.easeInOut),
    );

    if (widget.show) {
      _slideController.forward();
    }
  }

  @override
  void didUpdateWidget(NowPlayingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show && !oldWidget.show) {
      _slideController.forward();
    } else if (!widget.show && oldWidget.show) {
      _slideController.reverse();
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _dotController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = widget.isPlaying;
    final accentColor =
        isPlaying ? const Color(0xFF1EE86F) : const Color(0xFFAAAAAA);

    return Positioned(
      top: 16,          // ← pindah ke atas
      left: 0,
      right: 0,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: Center(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                border: Border.all(color: accentColor, width: 3),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: accentColor,
                    offset: const Offset(5, 5),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // TOP ROW: note + label + dots
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Bouncing note
                      AnimatedBuilder(
                        animation: _noteBounce,
                        builder: (context, child) => Transform.translate(
                          offset:
                              Offset(0, isPlaying ? _noteBounce.value : 0),
                          child: Transform.rotate(
                            angle: isPlaying ? -0.15 : 0,
                            child: Text(
                              isPlaying ? '🎵' : '🎶',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isPlaying ? 'NOW PLAYING' : 'SONG INFO',
                        style: TextStyle(
                          fontFamily: 'BlackHanSans',
                          fontSize: 12,
                          color: accentColor,
                          letterSpacing: 2,
                        ),
                      ),
                      if (isPlaying) ...[
                        const SizedBox(width: 4),
                        _BlinkingDots(
                            controller: _dotController,
                            color: accentColor),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Song name
                  Text(
                    widget.songName,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BlinkingDots extends StatelessWidget {
  final AnimationController controller;
  final Color color;

  const _BlinkingDots({required this.controller, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i * 0.25;
            final t = (controller.value + delay) % 1.0;
            final opacity =
                (t < 0.5) ? 1.0 : (1.0 - (t - 0.5) * 2).clamp(0.2, 1.0);
            return Text(
              '.',
              style: TextStyle(
                fontSize: 16,
                color: color.withOpacity(opacity),
                fontWeight: FontWeight.bold,
              ),
            );
          }),
        );
      },
    );
  }
}
