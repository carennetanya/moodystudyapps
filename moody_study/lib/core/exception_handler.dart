import 'dart:async';
import 'dart:io';

String sanitizeException(Object e) {
  if (e is SocketException) {
    return 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
  }
  if (e is TimeoutException) {
    return 'Koneksi timeout. Silakan coba beberapa saat lagi.';
  }
  if (e is FormatException) {
    return 'Terjadi kesalahan format data dari server.';
  }
  if (e is HandshakeException) {
    return 'Koneksi tidak aman. Silakan coba lagi.';
  }
  if (e is HttpException) {
    return 'Terjadi kesalahan HTTP. Silakan coba lagi.';
  }

  final raw = e.toString();

  // Ekstrak pesan dari "Exception: <pesan>" saja
  final cleaned = raw.startsWith('Exception: ')
      ? raw.substring('Exception: '.length).trim()
      : raw;

  // Jika masih mengandung detail teknis, kembalikan pesan generik
  const technicalMarkers = [
    'SocketException',
    'ClientException',
    'HttpException',
    'FormatException',
    'TimeoutException',
    'HandshakeException',
    'DioException',
    'PathNotFoundException',
    'FileSystemException',
    'address =',
    'errno =',
    'port =',
    'uri=http',
    'uri=https',
    'localhost',
    '127.0.0.1',
  ];
  final lc = cleaned.toLowerCase();
  final hasIp = RegExp(r'\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}').hasMatch(cleaned);

  if (hasIp || technicalMarkers.any((m) => cleaned.contains(m) || lc.contains(m.toLowerCase()))) {
    return 'Terjadi kesalahan koneksi. Silakan coba lagi.';
  }

  return cleaned.isNotEmpty ? cleaned : 'Terjadi kesalahan. Silakan coba lagi.';
}
