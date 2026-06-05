import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../core/error/exception_mapper.dart';
import '../core/error/failures.dart';
import '../models/auth_user.dart';
import 'api_client.dart';

class AuthService {
  static String? get token => ApiClient.hasToken ? ApiClient.currentToken : null;
  static set token(String? value) {
    if (value != null) {
      ApiClient.setToken(value);
    } else {
      ApiClient.clearToken();
    }
  }

  static Future<Either<AppFailure, AuthUser>> register({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final res = await ApiClient.dio.post(
        '/api/auth/register',
        data: {'name': name, 'username': username, 'email': email, 'password': password},
      );
      final body = res.data as Map<String, dynamic>;
      final receivedToken = body['token'] as String?;
      if (receivedToken != null) await ApiClient.setToken(receivedToken);
      return right(AuthUser(
        token: receivedToken ?? '',
        name: body['name'] as String?,
        username: body['username'] as String?,
        email: email,
      ));
    } on DioException catch (e) {
      return left(ExceptionMapper.mapAuth(e));
    }
  }

  static Future<Either<AppFailure, AuthUser>> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await ApiClient.dio.post(
        '/api/auth/login',
        data: {'email': email, 'password': password},
      );
      final body = res.data as Map<String, dynamic>;
      final receivedToken = body['token'] as String?;
      if (receivedToken != null) await ApiClient.setToken(receivedToken);
      return right(AuthUser(
        token: receivedToken ?? '',
        name: body['name'] as String?,
        username: body['username'] as String?,
        email: email,
      ));
    } on DioException catch (e) {
      return left(ExceptionMapper.mapAuth(e));
    }
  }

  static Future<void> logout() async {
    await ApiClient.clearToken();
  }
}
