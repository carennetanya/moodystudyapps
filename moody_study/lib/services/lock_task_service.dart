import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service untuk mengaktifkan/menonaktifkan Android Lock Task Mode (kiosk).
/// Membutuhkan device owner setup via ADB sekali saja.
class LockTaskService {
  static const _channel = MethodChannel('com.example.moody_study/lock_task');

  /// Aktifkan lock task mode — nav bar, recent apps, home button semua terkunci
  static Future<bool> startLock() async {
    try {
      final result = await _channel.invokeMethod<bool>('startLockTask');
      debugPrint('[LockTask] started: $result');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('[LockTask] startLock error: ${e.message}');
      return false;
    }
  }

  /// Nonaktifkan lock task mode
  static Future<bool> stopLock() async {
    try {
      final result = await _channel.invokeMethod<bool>('stopLockTask');
      debugPrint('[LockTask] stopped: $result');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('[LockTask] stopLock error: ${e.message}');
      return false;
    }
  }

  /// Cek apakah sedang dalam lock task mode
  static Future<bool> isLocked() async {
    try {
      final result = await _channel.invokeMethod<bool>('isInLockTask');
      return result ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }
}