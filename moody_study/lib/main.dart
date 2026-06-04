import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:moody_study/services/notification_service.dart';
import 'package:moody_study/services/profile_image_store.dart';
import 'package:moody_study/services/profile_image_provider.dart';
import 'package:moody_study/services/user_provider.dart';
import 'package:moody_study/services/api_client.dart';
import 'package:moody_study/utils/app_localizations.dart';
import 'screens/schedule_screen.dart';
import 'screens/theme_selector_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();
  // Load foto profil yang tersimpan dari sesi sebelumnya
  await ProfileImageStore.instance.init();
  await ApiClient.init(); 
  runApp(const MoodyStudyApp());
}

class MoodyStudyApp extends StatelessWidget {
  const MoodyStudyApp({super.key});

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
        theme: ThemeData(
          fontFamily: 'BlackHanSans',
          scaffoldBackgroundColor: const Color(0xFF1EE86F),
        ),
        home: const ThemeSelectorScreen(),
        routes: {
          '/schedule': (context) => const ScheduleScreen(),
        },
      ),
    );
  }
}
