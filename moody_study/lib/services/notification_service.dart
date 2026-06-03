import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:moody_study/screens/study_session.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Top-level function — wajib di luar class untuk background isolate
@pragma('vm:entry-point')
void _onNotificationTapBackground(NotificationResponse response) {
  // Background tap — tidak bisa navigasi langsung, tapi payload sudah tersimpan
  // dan akan dihandle saat app dibuka lewat getNotificationAppLaunchDetails
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// GlobalKey untuk navigasi dari luar context (waktu notif di-tap)
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  Future<void> init() async {
    if (_initialized) return;

    tzdata.initializeTimeZones();

    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestSoundPermission: true,
      requestBadgePermission: true,
    );
    final settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
      onDidReceiveBackgroundNotificationResponse: _onNotificationTapBackground,
    );

    // Handle notif yang di-tap saat app dalam kondisi terminated
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp == true &&
        launchDetails?.notificationResponse?.payload != null) {
      // Log for debugging
      debugPrint('App launched from notification with payload: ${launchDetails!.notificationResponse!.payload}');
      // Delay lebih panjang — navigator butuh waktu render full widget tree
      Future.delayed(const Duration(milliseconds: 1000), () {
        _handlePayload(launchDetails.notificationResponse!.payload!);
      });
    }

    _initialized = true;
  }

  void _onNotificationTap(NotificationResponse response) {
    debugPrint('Notification tapped, payload: ${response.payload}');
    if (response.payload != null && response.payload!.isNotEmpty) {
      // Delay untuk memastikan navigator siap
      Future.delayed(const Duration(milliseconds: 500), () {
        _handlePayload(response.payload!);
      });
    } else {
      debugPrint('Notification payload empty or null');
    }
  }

  void _handlePayload(String payload) {
    try {
      debugPrint('Handling notification payload: $payload');
      if (payload.isEmpty) {
        debugPrint('Payload empty, navigating to /schedule');
        navigatorKey.currentState?.pushNamed('/schedule');
        return;
      }

      final data = jsonDecode(payload) as Map<String, dynamic>;
      final subject = data['subject'] as String? ?? 'Sesi Belajar';
      final mood = data['mood'] as String? ?? 'happy';
      final location = data['location'] as String? ?? 'home';
      final duration = data['durationMinutes'] as int? ?? 60;

      debugPrint('Parsed payload -> subject: $subject, mood: $mood, location: $location, duration: $duration');

      final navigator = navigatorKey.currentState;
      if (navigator == null) {
        debugPrint('Navigator not ready — cannot navigate');
        return;
      }

      navigator.push(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => StudySession(
            mood: mood,
            location: location,
            userName: 'Friend',
            files: const [],
            initialSubject: subject,
            initialMinutes: duration,
          ),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } catch (e, st) {
      debugPrint('Error handling payload: $e');
      debugPrint('$st');
      // Payload invalid atau error parsing — fallback ke schedule screen
      final navigator = navigatorKey.currentState;
      if (navigator != null) {
        navigator.pushNamed('/schedule');
      }
    }
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    if (!_initialized) await init();

    final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);
    if (tzDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    const androidDetails = AndroidNotificationDetails(
  'study_schedule_channel',
  'Study Schedule Reminders',
  channelDescription: 'Reminds the user about a scheduled study session',
  importance: Importance.max,
  priority: Priority.max,
  playSound: true,
  sound: RawResourceAndroidNotificationSound('alarm'), // ← tambah ini
  enableVibration: true,
  fullScreenIntent: true,
);
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzDate,
      platformDetails,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.wallClockTime,
    );
  }

  Future<void> scheduleStudyNotification(
    int id,
    String subject,
    DateTime scheduledDate, {
    String mood = 'happy',
    String location = 'home',
    int durationMinutes = 60,
  }) async {
    // Embed semua data yang dibutuhkan di payload (JSON encoded)
    final payload = jsonEncode({
      'id': id,
      'subject': subject,
      'mood': mood,
      'location': location,
      'durationMinutes': durationMinutes,
    });

    await scheduleNotification(
      id: id,
      title: '📚 Waktunya belajar!',
      body: '$subject — yuk mulai sesinya!',
      scheduledDate: scheduledDate,
      payload: payload,
    );
  }

  Future<void> cancelNotification(int id) async {
    if (!_initialized) await init();
    await _plugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    if (!_initialized) await init();
    await _plugin.cancelAll();
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (!_initialized) await init();
    return await _plugin.pendingNotificationRequests();
  }
}