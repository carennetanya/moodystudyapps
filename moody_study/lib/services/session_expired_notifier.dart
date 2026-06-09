import 'dart:async';

/// Singleton yang membroadcast event saat sesi user expire di tengah pakai app.
///
/// Lifecycle:
///   - Setelah bootstrap sukses → panggil [activate()]
///   - _ErrorInterceptor detect 401 saat active → [notify()] broadcast event
///   - Listener di root app terima event → tampil snackbar + navigate ke login
///   - [notify()] auto-deactivate setelah broadcast (cegah duplicate)
class SessionExpiredNotifier {
  SessionExpiredNotifier._();
  static final instance = SessionExpiredNotifier._();

  final _controller = StreamController<void>.broadcast();
  Stream<void> get stream => _controller.stream;

  bool _active = false;

  /// Aktifkan setelah user berhasil login / bootstrap sukses.
  void activate() => _active = true;

  /// Nonaktifkan saat kembali ke login flow.
  void deactivate() => _active = false;

  /// Broadcast event session expired. No-op kalau belum di-activate atau sudah notify.
  void notify() {
    if (_active) {
      _active = false; // cegah duplicate notification
      _controller.add(null);
    }
  }
}
