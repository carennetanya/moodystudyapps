import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_config.dart';
import '../utils/app_localizations.dart';

/// Singleton Dio client dengan interceptor lengkap:
///   1. JWT injection otomatis di setiap request
///   2. Error normalization → ApiException
///   3. Token persist ke SharedPreferences (survive app restart)
///
/// Cara pakai di service:
///   final res = await ApiClient.dio.get('/api/profile/info');
///   final res = await ApiClient.dio.post('/api/quiz/generate', data: {...});
///
/// Saat login/logout, update token via:
///   await ApiClient.setToken('eyJ...');
///   await ApiClient.clearToken();
class ApiClient {
  ApiClient._();

  static const _tokenKey = 'jwt_token';

  static Dio? _dio;
  static String? _token;

  /// Inisialisasi: load token dari storage, setup Dio + interceptors.
  /// Panggil sekali di main() sebelum runApp().
  ///
  /// ```dart
  /// await ApiClient.init();
  /// runApp(const MyApp());
  /// ```
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    _dio = _buildDio();
  }

  /// Dio instance siap pakai. Pastikan [init] sudah dipanggil.
  static Dio get dio {
    assert(_dio != null, 'ApiClient.init() belum dipanggil di main()');
    return _dio!;
  }

  /// Simpan token baru (setelah login / update email).
  static Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// Hapus token (saat logout).
  static Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  /// Cek apakah token tersedia (user sudah login).
  static bool get hasToken => _token != null && _token!.isNotEmpty;
  static String? get currentToken => _token;

  // ─── Internal ────────────────────────────────────────────────────────────

  static Dio _buildDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(_AuthInterceptor());
    dio.interceptors.add(_ErrorInterceptor());

    // Uncomment untuk debug log di development:
    // dio.interceptors.add(LogInterceptor(responseBody: true));

    return dio;
  }
}

// ─── Interceptor 1: JWT Injection ────────────────────────────────────────────

class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = ApiClient._token;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

// ─── Interceptor 2: Error Normalization ──────────────────────────────────────

class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Ubah semua DioException → ApiException yang seragam
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: ApiException.fromDioException(err),
        type: err.type,
        response: err.response,
      ),
    );
  }
}

// ─── ApiException: error terpusat ────────────────────────────────────────────

/// Exception yang dilempar oleh semua service yang pakai [ApiClient].
///
/// Carry [messageKey] (key i18n dari backend, format "validation.xxx.yyy")
/// dan [fallbackMessage] (key generic untuk network/server error).
///
/// ```dart
/// try {
///   final res = await ApiClient.dio.get('/api/profile/info');
/// } on DioException catch (e) {
///   final err = e.error as ApiException;
///   final msg = err.localizedMessage(context); // pesan user-friendly
///   print(err.statusCode);                     // nullable int
/// }
/// ```
class ApiException implements Exception {
  /// Key i18n dari body backend (`"validation.xxx.yyy"`), atau null kalau
  /// tidak ada body terstruktur.
  final String? messageKey;

  /// Key generic fallback untuk error jaringan/server — selalu non-null.
  final String fallbackMessage;

  final int? statusCode;

  const ApiException({
    this.messageKey,
    required this.fallbackMessage,
    this.statusCode,
  });

  factory ApiException.fromDioException(DioException err) {
    final response = err.response;
    final statusCode = response?.statusCode;

    // Ambil key i18n dari body backend — hanya kalau format "validation.*"
    String? key;
    try {
      final data = response?.data;
      if (data is Map<String, dynamic>) {
        final raw = data['error'] as String?;
        if (raw != null && raw.startsWith('validation.')) {
          key = raw;
        }
      }
    } catch (_) {}

    return ApiException(
      messageKey: key,
      fallbackMessage: _genericFallback(err.type, statusCode),
      statusCode: statusCode,
    );
  }

  static String _genericFallback(DioExceptionType type, int? statusCode) {
    return switch (type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        'errors.network.timeout',
      DioExceptionType.connectionError => 'errors.network.offline',
      DioExceptionType.badResponse => switch (statusCode) {
          401 || 403 => 'errors.session.expired',
          404 => 'errors.notFound',
          500 || 502 || 503 => 'errors.server.problem',
          _ => 'errors.unknown',
        },
      _ => 'errors.unknown',
    };
  }

  /// Resolve ke pesan ramah berdasarkan bahasa aktif.
  /// Panggil dari UI layer dengan BuildContext.
  String localizedMessage(BuildContext context) {
    final l = AppLocalizations.of(context, listen: false);
    return l.errorByKey(messageKey ?? fallbackMessage);
  }

  @override
  String toString() => 'ApiException($statusCode): key=$messageKey, fallback=$fallbackMessage';
}