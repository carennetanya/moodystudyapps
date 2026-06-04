import 'package:dio/dio.dart';
import 'api_client.dart';

class ProfileService {
  static Future<Map<String, dynamic>> getUserInfo() async {
    final res = await ApiClient.dio.get('/api/profile/info');
    return res.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updateName(String name) async {
    final res = await ApiClient.dio.post('/api/profile/update-name', data: {'name': name});
    return res.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updateUsername(String username) async {
    final res = await ApiClient.dio.post('/api/profile/update-username', data: {'username': username});
    return res.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updateAvatar(String avatarUrl) async {
    final res = await ApiClient.dio.post('/api/profile/update-avatar', data: {'avatarUrl': avatarUrl});
    return res.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getNickname() async {
    final res = await ApiClient.dio.get('/api/profile/nickname');
    return res.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> setNickname(String nickname) async {
    final res = await ApiClient.dio.post('/api/profile/nickname', data: {'nickname': nickname});
    return res.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updateEmail({
    required String newEmail,
    required String password,
  }) async {
    final res = await ApiClient.dio.put(
      '/api/auth/update-email',
      data: {'newEmail': newEmail, 'password': password},
    );
    final body = res.data as Map<String, dynamic>;
    // Token baru dari backend langsung disimpan via ApiClient
    final newToken = body['token'] as String?;
    if (newToken != null && newToken.isNotEmpty) {
      await ApiClient.setToken(newToken);
    }
    return body;
  }

  static Future<Map<String, dynamic>> updatePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final res = await ApiClient.dio.put(
      '/api/auth/update-password',
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      },
    );
    return res.data as Map<String, dynamic>;
  }
}