import 'package:flutter/material.dart';
import 'screens/theme_selector_screen.dart';
import 'utils/app_localizations.dart';

void main() {
  runApp(const MoodyStudyApp());
}

class MoodyStudyApp extends StatefulWidget {
  const MoodyStudyApp({super.key});

  @override
  State<MoodyStudyApp> createState() => _MoodyStudyAppState();
}

class _MoodyStudyAppState extends State<MoodyStudyApp> {
  AppLanguage _language = AppLanguage.id;

  void _toggleLanguage() {
    setState(() {
      _language = _language == AppLanguage.id ? AppLanguage.en : AppLanguage.id;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LocalizationWrapper(
      language: _language,
      child: LanguageNotifier(
        language: _language,
        onToggle: _toggleLanguage,
        child: MaterialApp(
          title: 'Moody Study',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            fontFamily: 'BlackHanSans',
            scaffoldBackgroundColor: const Color(0xFF1EE86F),
          ),
          home: const ThemeSelectorScreen(),
        ),
      ),
    );
  }
}

/// LanguageNotifier didefinisikan di utils/app_localizations.dart
/// dan diimport di atas. Tidak perlu redefinisi di sini.