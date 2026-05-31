import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'api_config.dart';

class ProfileService {
  static String get baseUrl => ApiConfig.baseUrl;

  static Future<Map<String, dynamic>> getUserInfo() async {
    final uri = Uri.parse('$baseUrl/api/profile/info');
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AuthService.token}',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to get user info');
  }

  static Future<Map<String, dynamic>> updateName(String name) async {
    final uri = Uri.parse('$baseUrl/api/profile/update-name');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AuthService.token}',
      },
      body: jsonEncode({'name': name}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic> && body['message'] is String) {
        throw Exception(body['message'] as String);
      }
    } catch (e) {
      if (e is Exception) rethrow;
    }

    throw Exception('Failed to update name');
  }

  static Future<Map<String, dynamic>> updateUsername(String username) async {
    final uri = Uri.parse('$baseUrl/api/profile/update-username');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AuthService.token}',
      },
      body: jsonEncode({'username': username}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic> && body['message'] is String) {
        throw Exception(body['message'] as String);
      }
    } catch (e) {
      if (e is Exception) rethrow;
    }

    throw Exception('Failed to update username');
  }

  static Future<Map<String, dynamic>> updateAvatar(String avatarUrl) async {
    final uri = Uri.parse('$baseUrl/api/profile/update-avatar');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AuthService.token}',
      },
      body: jsonEncode({'avatarUrl': avatarUrl}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic> && body['message'] is String) {
        throw Exception(body['message'] as String);
      }
    } catch (e) {
      if (e is Exception) rethrow;
    }

    throw Exception('Failed to update avatar');
  }

  static Future<Map<String, dynamic>> getNickname() async {
    final uri = Uri.parse('$baseUrl/api/profile/nickname');
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AuthService.token}',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to get nickname');
  }

  static Future<Map<String, dynamic>> setNickname(String nickname) async {
    final uri = Uri.parse('$baseUrl/api/profile/nickname');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AuthService.token}',
      },
      body: jsonEncode({'nickname': nickname}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic> && body['message'] is String) {
        throw Exception(body['message'] as String);
      }
    } catch (e) {
      if (e is Exception) rethrow;
    }

    throw Exception('Failed to update nickname');
  }

  // updateEmail: backend now returns AuthResponse with a new token.
  // We must save the new token immediately so all subsequent requests use it.
  static Future<Map<String, dynamic>> updateEmail({
    required String newEmail,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/api/auth/update-email');
    final response = await http.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AuthService.token}',
      },
      body: jsonEncode({
        'newEmail': newEmail,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;

      // Save the new JWT token — this is critical.
      // Without this, the next request after email change will 401/403
      // because the old token references the old email.
      final newToken = body['token'] as String?;
      if (newToken != null && newToken.isNotEmpty) {
        AuthService.token = newToken;
      }

      return body;
    }

    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic> && body['message'] is String) {
        throw Exception(body['message'] as String);
      }
    } catch (e) {
      if (e is Exception) rethrow;
    }

    throw Exception('Gagal mengubah email');
  }

  static Future<Map<String, dynamic>> updatePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final uri = Uri.parse('$baseUrl/api/auth/update-password');
    final response = await http.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AuthService.token}',
      },
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic> && body['message'] is String) {
        throw Exception(body['message'] as String);
      }
    } catch (e) {
      if (e is Exception) rethrow;
    }

    throw Exception('Gagal mengubah password');
  }
}
