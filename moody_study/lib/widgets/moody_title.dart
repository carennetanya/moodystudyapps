import 'package:flutter/material.dart';

/// Replicates the Vue MoodyTitle animation:
/// 1. 4 dots bounce in one by one
/// 2. Dots merge (gap collapses)
/// 3. Each dot morphs into text chunk: "Moo" "dy" "Stu" "dy"
/// 4. Idle float animation
class MoodyTitle extends StatefulWidget {
  final VoidCallback onDone;

  const MoodyTitle({super.key, required this.onDone});

  @override
  State<MoodyTitle> createState() => _MoodyTitleState();
}

class _MoodyTitleState extends State<MoodyTitle> with TickerProviderStateMixin {
  static const List<String> _chunks = ['Moo', 'dy', 'Stu', 'dy'];

  // Per-dot shown/morphed states
  final List<bool> _shown = [false, false, false, false];
  final List<bool> _morphed = [false, false, false, false];
  bool _merged = false;
  bool _idleFloat = false;

  // Dot appear controllers
  late List<AnimationController> _dotControllers;
  late List<Animation<double>> _dotScales;
  late List<Animation<double>> _dotOpacities;

  // Morph controllers (dot → text)
  late List<AnimationController> _morphControllers;
  late List<Animation<double>> _morphBorderRadius;
  late List<Animation<double>> _morphOpacity;
  late List<Animation<double>> _morphScale;

  // Idle float
  late AnimationController _floatController;
  late Animation<double> _floatOffset;

  // Gap (merged) controller
  late AnimationController _gapController;
  late Animation<double> _gap; // 28 → 0

  @override
  void initState() {
    super.initState();

    // -- dot appear animations --
    _dotControllers = List.generate(
      4,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      ),
    );
    _dotScales = _dotControllers
        .map((c) => Tween<double>(begin: 0.3, end: 1.0).animate(
              CurvedAnimation(parent: c, curve: Curves.elasticOut),
            ))
        .toList();
    _dotOpacities = _dotControllers
        .map((c) => Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(parent: c, curve: Curves.easeIn),
            ))
        .toList();

    // -- gap collapse --
    _gapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _gap = Tween<double>(begin: 28, end: 0).animate(
      CurvedAnimation(parent: _gapController, curve: Curves.easeInOut),
    );

    // -- morph animations --
    _morphControllers = List.generate(
      4,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 550),
      ),
    );
    _morphBorderRadius = _morphControllers
        .map((c) => Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(parent: c, curve: Curves.easeInOut),
            ))
        .toList();
    _morphOpacity = _morphControllers
        .map((c) => Tween<double>(begin: 1.0, end: 1.0).animate(c))
        .toList();
    _morphScale = _morphControllers
        .map((c) => Tween<double>(begin: 1.0, end: 1.0).animate(c))
        .toList();

    // -- idle float --
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _floatOffset = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 800));

    // dots appear one by one
    for (int i = 0; i < 4; i++) {
      if (!mounted) return;
      setState(() => _shown[i] = true);
      _dotControllers[i].forward();
      await Future.delayed(const Duration(milliseconds: 220));
    }

    await Future.delayed(const Duration(milliseconds: 700));

    // collapse gap
    if (!mounted) return;
    setState(() => _merged = true);
    _gapController.forward();

    await Future.delayed(const Duration(milliseconds: 400));

    // morph dots to text
    for (int i = 0; i < 4; i++) {
      if (!mounted) return;
      setState(() => _morphed[i] = true);
      _morphControllers[i].forward();
      await Future.delayed(const Duration(milliseconds: 80));
    }

    await Future.delayed(const Duration(milliseconds: 900));

    // idle float
    if (!mounted) return;
    setState(() => _idleFloat = true);
    _floatController.repeat(reverse: true);

    widget.onDone();
  }

  @override
  void dispose() {
    for (final c in _dotControllers) {
      c.dispose();
    }
    for (final c in _morphControllers) {
      c.dispose();
    }
    _gapController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  // Dot size responsif berdasarkan lebar layar
  // 4 dots + 3 gaps (28px) harus muat: (w - padding) / ~5.5
  double _dotSize(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return ((w - 32) / 5.5).clamp(50.0, 90.0);
  }

  Widget _buildDot(int i) {
    final chunk = _chunks[i];
    final isMorphed = _morphed[i];

    return AnimatedBuilder(
      animation: Listenable.merge([
        _dotControllers[i],
        _morphControllers[i],
        _gapController,
      ]),
      builder: (context, child) {
        final morphT = _morphControllers[i].value;
        final dotSize = _dotSize(context);

        // Interpolate border radius: 50% (circle) → 24px rect
        final borderRadius = lerpDouble(dotSize / 2, 24.0, morphT)!;

        // Background & border fade out on morph
        final bgOpacity = (1.0 - morphT).clamp(0.0, 1.0);
        final boxColor = Color.lerp(
          Colors.white,
          Colors.transparent,
          morphT,
        )!;
        final borderColor = Color.lerp(
          const Color(0xFF111111),
          Colors.transparent,
          morphT,
        )!;
        final shadowOpacity = bgOpacity;

        // Size: dot responsif, morphed adalah auto width × dotSize*1.33
        final height = lerpDouble(dotSize, dotSize * 1.33, morphT)!;

        return ScaleTransition(
          scale: _dotScales[i],
          child: FadeTransition(
            opacity: _dotOpacities[i],
            child: AnimatedContainer(
              duration: Duration.zero,
              width: isMorphed ? null : dotSize,
              height: height,
              decoration: BoxDecoration(
                color: boxColor,
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color: borderColor,
                  width: 5 * bgOpacity,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(17, 17, 17, shadowOpacity),
                    offset: const Offset(6, 6),
                    blurRadius: 0,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: isMorphed
                  ? Stack(
                      children: [
                        // stroke/border layer
                        Text(
                          chunk,
                          style: TextStyle(
                            fontFamily: 'BlackHanSans',
                            fontSize: _fontSize(context),
                            letterSpacing: 0,
                            foreground: Paint()
                              ..style = PaintingStyle.stroke
                              ..strokeWidth = 8
                              ..strokeJoin = StrokeJoin.round
                              ..color = const Color(0xFF111111),
                          ),
                        ),
                        // fill layer
                        Text(
                          chunk,
                          style: TextStyle(
                            fontFamily: 'BlackHanSans',
                            fontSize: _fontSize(context),
                            color: Colors.white,
                            letterSpacing: 0,
                            shadows: const [
                              Shadow(
                                color: Color(0xFF111111),
                                offset: Offset(5, 5),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : null,
            ),
          ),
        );
      },
    );
  }

  double _fontSize(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w <= 480) return (w * 0.105).clamp(52.0, 96.0);
    return (w * 0.12).clamp(68.0, 120.0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        final offset = _idleFloat ? _floatOffset.value : 0.0;
        return Transform.translate(
          offset: Offset(0, offset),
          child: child,
        );
      },
      child: AnimatedBuilder(
        animation: _gapController,
        builder: (context, child) {
          final gap = _merged ? _gap.value : 28.0;
          return FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDot(0),
                SizedBox(width: gap),
                _buildDot(1),
                // Space between "Moody" and "Study"
                SizedBox(width: _morphed[1] ? 18 : gap),
                _buildDot(2),
                SizedBox(width: gap),
                _buildDot(3),
              ],
            ),
          );
        },
      ),
    );
  }
}

double? lerpDouble(double a, double b, double t) {
  return a + (b - a) * t;
}
