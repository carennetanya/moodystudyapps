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
    throw Exception('Gagal memuat informasi profil. Silakan coba lagi.');
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

    throw Exception('Gagal memperbarui nama. Silakan coba lagi.');
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

    throw Exception('Gagal memperbarui username. Silakan coba lagi.');
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

    throw Exception('Gagal mengunggah foto profil. Silakan coba lagi.');
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
    throw Exception('Gagal memuat nickname. Silakan coba lagi.');
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

    throw Exception('Gagal memperbarui nickname. Silakan coba lagi.');
  }

  // updateEmail: backend now returns AuthResponse with a new token.
  // We must save the new JWT token immediately so all subsequent requests use it.
>>>>>>> 47e58ec (Trials Try Catch)
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

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
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

    throw Exception('Gagal mengubah email. Silakan coba lagi.');

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

    throw Exception('Gagal mengubah password. Silakan coba lagi.');

  }
}