import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service untuk menyimpan & memverifikasi emergency PIN patrol mode.
/// SharedPreferences instance di-cache biar tidak ada delay berulang.
class PatrolPinService {
  static const _key = 'patrol_emergency_pin';
  static SharedPreferences? _prefs;

  static Future<SharedPreferences> _get() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  static Future<void> savePin(String pin) async {
    // Reset cache dulu biar fresh instance
    _prefs = null;
    final prefs = await _get();
    await prefs.setString(_key, pin);
    await prefs.reload(); // force reload dari disk
    debugPrint('[PatrolPin] PIN saved: ${prefs.getString(_key)}');
  }

  static Future<String?> getPin() async {
    final prefs = await _get();
    return prefs.getString(_key);
  }

  static Future<bool> hasPin() async {
    final prefs = await _get();
    await prefs.reload(); // selalu baca fresh dari disk
    final pin = prefs.getString(_key);
    debugPrint('[PatrolPin] hasPin check: "$pin"');
    return pin != null && pin.length == 4;
  }

  static Future<bool> verifyPin(String input) async {
    final prefs = await _get();
    final saved = prefs.getString(_key);
    return saved != null && saved == input;
  }

  static Future<void> clearPin() async {
    final prefs = await _get();
    await prefs.remove(_key);
  }
}