import 'package:flutter/material.dart';

class SoundWarning extends StatefulWidget {
  const SoundWarning({super.key});

  @override
  State<SoundWarning> createState() => _SoundWarningState();
}

class _SoundWarningState extends State<SoundWarning>
    with SingleTickerProviderStateMixin {
  late AnimationController _blinkController;
  late Animation<double> _blink;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _blink = Tween<double>(begin: 1.0, end: 0.2).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );
    // blink 4 times (after 0.8s delay, matching Vue)
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _blinkController.repeat(reverse: true, count: 4);
    });
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = MediaQuery.of(context).size.width <= 480 ? 12.0 : 16.0;

    return FadeTransition(
      opacity: _blink,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.volume_up, color: Color(0xFFFF0015), size: 24),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This app includes sound.',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w700,
                  fontSize: fontSize + 2,
                  color: const Color(0xFFFF0015),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Please check your audio settings.',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w500,
                  fontSize: fontSize,
                  color: const Color(0xFFFF0015),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
