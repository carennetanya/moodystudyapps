import 'package:flutter/material.dart';

class SubTagline extends StatefulWidget {
  final bool show;

  const SubTagline({super.key, required this.show});

  @override
  State<SubTagline> createState() => _SubTaglineState();
}

class _SubTaglineState extends State<SubTagline>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<double> _scale;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _opacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _scale = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(SubTagline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show && !oldWidget.show) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = _responsiveFontSize(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _opacity,
          child: SlideTransition(
            position: _slide,
            child: ScaleTransition(scale: _scale, child: child),
          ),
        );
      },
      child: Stack(
        children: [
          // stroke layer
          Text(
            'Stay Focus, Stay Smarter.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'BlackHanSans',
              fontSize: fontSize,
              letterSpacing: 3,
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 6
                ..strokeJoin = StrokeJoin.round
                ..color = const Color(0xFF111111),
            ),
          ),
          // fill layer
          Text(
            'Stay Focus, Stay Smarter.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'BlackHanSans',
              fontSize: fontSize,
              color: const Color(0xFFFFD700),
              letterSpacing: 3,
              shadows: const [
                Shadow(
                  color: Color(0xFF111111),
                  offset: Offset(3, 3),
                  blurRadius: 0,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _responsiveFontSize(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w <= 480) return (w * 0.038).clamp(12.0, 18.0);
    if (w <= 768) return (w * 0.035).clamp(14.0, 22.0);
    return (w * 0.03).clamp(18.0, 28.0);
  }
}
