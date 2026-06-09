import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:moody_study/services/notification_service.dart';
import 'package:moody_study/services/profile_image_store.dart';
import 'package:moody_study/services/profile_image_provider.dart';
import 'package:moody_study/services/session_expired_notifier.dart';
import 'package:moody_study/services/user_provider.dart';
import 'package:moody_study/services/api_client.dart';
import 'package:moody_study/utils/app_localizations.dart';
import 'screens/schedule_screen.dart';
import 'screens/startup_screen.dart';
import 'screens/theme_selector_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();
  // Load foto profil yang tersimpan dari sesi sebelumnya
  await ProfileImageStore.instance.init();
  await ApiClient.init();
  runApp(const MoodyStudyApp());
}

class MoodyStudyApp extends StatefulWidget {
  const MoodyStudyApp({super.key});

  @override
  State<MoodyStudyApp> createState() => _MoodyStudyAppState();
}

class _MoodyStudyAppState extends State<MoodyStudyApp> {
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  StreamSubscription<void>? _sessionSub;

  @override
  void initState() {
    super.initState();
    _sessionSub = SessionExpiredNotifier.instance.stream.listen((_) {
      // Ambil context dari navigator — sudah di dalam MultiProvider, null-checked di bawah
      final ctx = NotificationService.navigatorKey.currentContext;
      if (ctx == null) return;

      // ignore: use_build_context_synchronously
      final l = AppLocalizations.of(ctx, listen: false);
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(l.errSessionExpired),
          duration: const Duration(seconds: 3),
        ),
      );

      NotificationService.navigatorKey.currentState?.pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const ThemeSelectorScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
        (_) => false,
      );
    });
  }

  @override
  void dispose() {
    _sessionSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 1. Bahasa app — menggantikan LocalizationWrapper + LanguageNotifier lama
        ChangeNotifierProvider(create: (_) => LanguageProvider()),

        // 2. Foto profil user
        ChangeNotifierProvider(create: (_) => ProfileImageProvider()),

        // 3. Data user yang login (token, nama, username, dll)
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: MaterialApp(
        title: 'Moody Study',
        debugShowCheckedModeBanner: false,
        navigatorKey: NotificationService.navigatorKey,
        scaffoldMessengerKey: _scaffoldMessengerKey,
        theme: ThemeData(
          fontFamily: 'BlackHanSans',
          scaffoldBackgroundColor: const Color(0xFF1EE86F),
        ),
        home: const StartupScreen(),
        routes: {
          '/schedule': (context) => const ScheduleScreen(),
        },
      ),
    );
  }
}
