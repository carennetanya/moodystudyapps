import 'package:flutter/material.dart';
import 'screens/theme_selector_screen.dart';

void main() {
  runApp(const MoodyStudyApp());
}

class MoodyStudyApp extends StatelessWidget {
  const MoodyStudyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Moody Study',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'BlackHanSans',
        scaffoldBackgroundColor: const Color(0xFF1EE86F),
      ),
      home: const ThemeSelectorScreen(),
    );
  }
}
