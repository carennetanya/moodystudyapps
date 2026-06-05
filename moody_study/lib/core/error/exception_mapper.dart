import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../services/api_client.dart';
import 'failures.dart';

/// Memetakan exception mentah ke [AppFailure] yang typed.
///
/// Gunakan di repository/service layer:
/// ```dart
/// } catch (e) {
///   return Left(ExceptionMapper.map(e));
/// }
/// ```
class ExceptionMapper {
  ExceptionMapper._();

  static AppFailure map(Object e) {
    if (e is MissingPluginException) {
      debugLog(e);
      return const SpotifySdkNotInitializedFailure();
    }
    if (e is PlatformException) {
      debugLog(e);
      return _mapPlatformException(e);
    }
    if (e is SocketException) {
      debugLog(e);
      return const NetworkOfflineFailure();
    }
    if (e is TimeoutException) {
      debugLog(e);
      return const NetworkTimeoutFailure();
    }
    if (e is DioException) {
      debugLog(e);
      return _mapDio(e);
    }
    debugLog(e);
    return UnknownFailure(e.toString());
  }

  static AppFailure _mapPlatformException(PlatformException e) {
    final code = e.code.toLowerCase();
    final msg = (e.message ?? '').toLowerCase();
    if (code.contains('couldnotfindspotifyapp') ||
        msg.contains('not installed') ||
        msg.contains('couldnotfindspotifyapp')) {
      return const SpotifySdkNotInitializedFailure();
    }
    if (msg.contains('user closed') ||
        msg.contains('authentication') ||
        code.contains('authentication')) {
      return const SpotifyAuthCancelledFailure();
    }
    return const SpotifyConnectionFailure();
  }

  /// Gunakan di auth context (login/register) di mana 400 = kredensial salah.
  static AppFailure mapAuth(Object e) {
    if (e is DioException) {
      final status = e.response?.statusCode;
      if (status == 400) return const InvalidCredentialsFailure();
      if (status == 429) return const TooManyRequestsFailure();
    }
    return map(e);
  }

  // ─── Internal ─────────────────────────────────────────────────────────────

  static AppFailure _mapDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkTimeoutFailure();
      case DioExceptionType.connectionError:
        return const NetworkOfflineFailure();
      case DioExceptionType.badResponse:
        return _mapStatus(e);
      default:
        final apiErr = e.error;
        return UnknownFailure(
          apiErr is ApiException ? apiErr.toString() : e.toString(),
        );
    }
  }

  static AppFailure _mapStatus(DioException e) {
    final status = e.response?.statusCode;
    return switch (status) {
      401 || 403 => const SessionExpiredFailure(),
      429 => const TooManyRequestsFailure(),
      _ when status != null && status >= 500 => ServerFailure(status),
      _ => UnknownFailure('HTTP $status'),
    };
  }

  static void debugLog(Object e) {
    debugPrint('[ExceptionMapper] ${e.runtimeType}: $e');
  }
}
