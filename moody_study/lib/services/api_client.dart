import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_config.dart';

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
/// ```dart
/// try {
///   final res = await ApiClient.dio.get('/api/profile/info');
/// } on DioException catch (e) {
///   final err = e.error as ApiException;
///   print(err.message);   // pesan user-friendly
///   print(err.statusCode); // nullable int
/// }
/// ```
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? serverMessage;

  const ApiException({
    required this.message,
    this.statusCode,
    this.serverMessage,
  });

  factory ApiException.fromDioException(DioException err) {
    final response = err.response;
    final statusCode = response?.statusCode;

    // Coba ambil pesan dari body backend
    String? serverMsg;
    try {
      final data = response?.data;
      if (data is Map<String, dynamic>) {
        serverMsg = data['message'] as String? ??
            data['error'] as String?;
      }
    } catch (_) {}

    // Pesan user-friendly berdasarkan status code
    final message = _humanMessage(err.type, statusCode, serverMsg);

    return ApiException(
      message: message,
      statusCode: statusCode,
      serverMessage: serverMsg,
    );
  }

  static String _humanMessage(
    DioExceptionType type,
    int? statusCode,
    String? serverMsg,
  ) {
    // Gunakan pesan server kalau ada dan bukan pesan teknis
    if (serverMsg != null && serverMsg.isNotEmpty) return serverMsg;

    switch (type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Koneksi timeout. Periksa jaringan kamu.';
      case DioExceptionType.connectionError:
        return 'Tidak dapat terhubung ke server.';
      case DioExceptionType.badResponse:
        return switch (statusCode) {
          400 => 'Request tidak valid.',
          401 => 'Sesi habis, silakan login ulang.',
          403 => 'Kamu tidak punya akses ke fitur ini.',
          404 => 'Data tidak ditemukan.',
          422 => 'Data yang dikirim tidak sesuai.',
          429 => 'Terlalu banyak request. Coba lagi sebentar.',
          500 || 502 || 503 => 'Server sedang bermasalah. Coba lagi nanti.',
          _ => 'Terjadi kesalahan (kode: $statusCode).',
        };
      default:
        return 'Terjadi kesalahan yang tidak diketahui.';
    }
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}