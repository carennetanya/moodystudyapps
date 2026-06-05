import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

import '../core/error/failures.dart';
import '../models/auth_user.dart';
import 'auth_service.dart';
import 'profile_service.dart';

/// Menyimpan state user yang login: token, username, nama, dsb.
///
/// Daftarkan di main.dart dengan ChangeNotifierProvider.
class UserProvider extends ChangeNotifier {
  String? _token;
  String? _username;
  String? _name;
  String? _email;
  bool _isLoading = false;

  // ─── Getters ────────────────────────────────────────────────────
  String? get token => _token;
  String? get username => _username;
  String? get name => _name;
  String? get email => _email;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _token != null;

  // ─── Auth ────────────────────────────────────────────────────────

  Future<Either<AppFailure, AuthUser>> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);

    final result = await AuthService.login(email: email, password: password);
    return result.fold(
      (failure) {
        _setLoading(false);
        return left(failure);
      },
      (user) {
        _token = user.token;
        _name = user.name;
        _username = user.username;
        _email = user.email;
        _setLoading(false);
        notifyListeners();
        return right(user);
      },
    );
  }

  Future<Either<AppFailure, AuthUser>> register({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    _setLoading(true);

    final result = await AuthService.register(
      name: name,
      username: username,
      email: email,
      password: password,
    );
    return result.fold(
      (failure) {
        _setLoading(false);
        return left(failure);
      },
      (user) {
        _token = user.token;
        _name = name;
        _username = username;
        _email = email;
        _setLoading(false);
        notifyListeners();
        return right(user);
      },
    );
  }

  void logout() {
    AuthService.logout();
    _token = null;
    _username = null;
    _name = null;
    _email = null;
    notifyListeners();
  }

  // ─── Profile updates ─────────────────────────────────────────────

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

  void updateToken(String newToken) {
    _token = newToken;
    AuthService.token = newToken;
    notifyListeners();
  }

  // ─── Internal ────────────────────────────────────────────────────
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
