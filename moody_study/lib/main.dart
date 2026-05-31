import 'package:flutter/material.dart';
import 'package:moody_study/services/notification_service.dart';
import 'screens/schedule_screen.dart';
import 'screens/theme_selector_screen.dart';
import 'utils/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MoodyStudyApp());
}

class MoodyStudyApp extends StatefulWidget {
  const MoodyStudyApp({super.key});

  @override
  State<MoodyStudyApp> createState() => _MoodyStudyAppState();
}

class _MoodyStudyAppState extends State<MoodyStudyApp> {
  AppLanguage _language = AppLanguage.id;

  @override
  void initState() {
    super.initState();
    // Init SETELAH widget tree siap supaya navigatorKey.currentState tidak null
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.instance.init();
    });
  }

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
          navigatorKey: NotificationService.navigatorKey,
          theme: ThemeData(
            fontFamily: 'BlackHanSans',
            scaffoldBackgroundColor: const Color(0xFF1EE86F),
          ),
          home: const ThemeSelectorScreen(),
          routes: {
            '/schedule': (context) => const ScheduleScreen(),
          },
        ),
      ),
    );
  }
}

/// LanguageNotifier didefinisikan di utils/app_localizations.dart
/// dan diimport di atas. Tidak perlu redefinisi di sini.