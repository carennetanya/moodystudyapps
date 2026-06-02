import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:http/http.dart' as http;

import '../core/failure.dart';
import '../models/auth_user.dart';
import 'api_config.dart';

class AuthService {
  static String? token;

  static String get baseUrl => ApiConfig.baseUrl;

  static Future<Either<AuthFailure, AuthUser>> register({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/api/auth/register');
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'username': username,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final receivedToken = body['token'] as String?;
        if (receivedToken != null) {
          token = receivedToken;
        }
        return right(AuthUser(
          token: receivedToken ?? '',
          name: body['name'] as String?,
          username: body['username'] as String?,
          email: email,
        ));
      }

      return left(_parseFailure(response, 'Register failed. Kode: ${response.statusCode}.'));
    } catch (e) {
      return left(const AuthFailure('Tidak dapat terhubung ke server.'));
    }
  }

  static Future<Either<AuthFailure, AuthUser>> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/api/auth/login');
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final receivedToken = body['token'] as String?;
        if (receivedToken != null) {
          token = receivedToken;
        }
        return right(AuthUser(
          token: receivedToken ?? '',
          name: body['name'] as String?,
          username: body['username'] as String?,
          email: email,
        ));
      }

      return left(_parseFailure(response, 'Login failed. Kode: ${response.statusCode}.'));
    } catch (e) {
      return left(const AuthFailure('Tidak dapat terhubung ke server.'));
    }
  }

  static AuthFailure _parseFailure(http.Response response, String fallback) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic> && body['message'] is String) {
        return AuthFailure(body['message'] as String);
      }
    } catch (_) {
      // ignore parse errors
    }
    return AuthFailure(fallback);
  }

  static Future<void> logout() async {
    token = null;
  }
}