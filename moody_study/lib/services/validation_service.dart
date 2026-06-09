import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import 'api_client.dart';
import '../core/error/exception_mapper.dart';
import '../core/error/failures.dart';

/// Result dari endpoint check-username / check-email.
class CheckResult {
  final bool available;

  /// Key dari backend (e.g. "validation.username.taken") atau null kalau available.
  final String? reason;

  const CheckResult({required this.available, this.reason});

  factory CheckResult.fromJson(Map<String, dynamic> json) => CheckResult(
        available: json['available'] as bool? ?? false,
        reason: json['reason'] as String?,
      );
}

/// Async uniqueness check ke backend.
///
/// [excludeSelf] = false → endpoint publik (/api/auth/check-*)
///                          Pakai saat register (user belum punya token)
/// [excludeSelf] = true  → endpoint JWT (/api/profile/check-*-available)
///                          Pakai saat edit profile (exclude user sendiri)
///
/// Timeout per call: 5 detik.
/// Error jaringan → Left(NetworkOfflineFailure / NetworkTimeoutFailure)
class ValidationService {
  ValidationService._();

  static const _timeout = Duration(seconds: 5);

  static Future<Either<AppFailure, CheckResult>> checkEmail(
    String email, {
    bool excludeSelf = false,
  }) {
    final path = excludeSelf
        ? '/api/profile/check-email-available'
        : '/api/auth/check-email';
    return _doCheck(path, 'email', email);
  }

  static Future<Either<AppFailure, CheckResult>> checkUsername(
    String username, {
    bool excludeSelf = false,
  }) {
    final path = excludeSelf
        ? '/api/profile/check-username-available'
        : '/api/auth/check-username';
    return _doCheck(path, 'username', username);
  }

  // ─── Internal ─────────────────────────────────────────────────────────────

  static Future<Either<AppFailure, CheckResult>> _doCheck(
    String path,
    String param,
    String value,
  ) async {
    try {
      final res = await ApiClient.dio.get(
        path,
        queryParameters: {param: value},
        options: Options(
          sendTimeout: _timeout,
          receiveTimeout: _timeout,
        ),
      );
      final data = res.data as Map<String, dynamic>;
      return Right(CheckResult.fromJson(data));
    } on DioException catch (e) {
      return Left(ExceptionMapper.map(e));
    } catch (e) {
      return Left(ExceptionMapper.map(e));
    }
  }
}
