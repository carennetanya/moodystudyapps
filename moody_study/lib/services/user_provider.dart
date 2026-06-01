import 'package:flutter/foundation.dart';
import 'auth_service.dart';
import 'profile_service.dart';

/// Menyimpan state user yang login: token, username, nama, dsb.
///
/// Daftarkan di main.dart dengan ChangeNotifierProvider.
///
/// Cara pakai:
///   // Baca data
///   final user = context.watch<UserProvider>();
///   Text(user.username ?? 'Guest')
///
///   // Panggil aksi (tidak butuh rebuild)
///   context.read<UserProvider>().login(email, password);
class UserProvider extends ChangeNotifier {
  String? _token;
  String? _username;
  String? _name;
  String? _email;
  bool _isLoading = false;
  String? _errorMessage;

  // ─── Getters ────────────────────────────────────────────────────
  String? get token => _token;
  String? get username => _username;
  String? get name => _name;
  String? get email => _email;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _token != null;
  String? get errorMessage => _errorMessage;

  // ─── Auth ────────────────────────────────────────────────────────

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _errorMessage = null;
    try {
      final result = await AuthService.login(email: email, password: password);
      _token = result['token'] as String?;
      _name = result['name'] as String?;
      _username = result['username'] as String?;
      _email = email;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    _errorMessage = null;
    try {
      final result = await AuthService.register(
        name: name,
        username: username,
        email: email,
        password: password,
      );
      _token = result['token'] as String?;
      _name = name;
      _username = username;
      _email = email;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void logout() {
    AuthService.logout();
    _token = null;
    _username = null;
    _name = null;
    _email = null;
    _errorMessage = null;
    notifyListeners();
  }

  // ─── Profile updates ─────────────────────────────────────────────

  /// Muat ulang info user dari server (nama, username).
  Future<void> refreshUserInfo() async {
    try {
      final info = await ProfileService.getUserInfo();
      _name = info['name'] as String?;
      _username = info['username'] as String?;
      notifyListeners();
    } catch (e) {
      debugPrint('[UserProvider] refreshUserInfo error: $e');
    }
  }

  void updateUsername(String newUsername) {
    _username = newUsername;
    notifyListeners();
  }

  void updateName(String newName) {
    _name = newName;
    notifyListeners();
  }

  void updateEmail(String newEmail) {
    _email = newEmail;
    notifyListeners();
  }

  /// Update token setelah operasi yang mengembalikan token baru (misal update email).
  void updateToken(String newToken) {
    _token = newToken;
    AuthService.token = newToken;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ─── Internal ────────────────────────────────────────────────────
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}