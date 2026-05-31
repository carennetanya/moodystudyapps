import 'dart:typed_data';
import 'package:flutter/foundation.dart';

// Conditional import: web pakai localStorage, mobile/desktop pakai file IO
import 'platform_storage/storage_io.dart'
    if (dart.library.html) 'platform_storage/storage_web.dart';

/// Singleton store untuk foto profil user.
///
/// - Web     → disimpan di `window.localStorage` (bertahan antar sesi browser)
/// - Mobile  → disimpan sebagai file di documents directory
/// - Expose [imageBytes] sebagai [ValueNotifier] → widget auto-update reaktif
///
/// Cara pakai:
///   await ProfileImageStore.instance.init();   // panggil di main()
///   await ProfileImageStore.instance.saveBytes(bytes);
///   await ProfileImageStore.instance.clear();  // saat logout
///
///   ValueListenableBuilder<Uint8List?>(
///     valueListenable: ProfileImageStore.instance.imageBytes,
///     builder: (_, bytes, __) { ... },
///   )
class ProfileImageStore {
  ProfileImageStore._();
  static final ProfileImageStore instance = ProfileImageStore._();

  final ValueNotifier<Uint8List?> imageBytes = ValueNotifier(null);

  bool _initialized = false;

  /// Muat foto tersimpan saat app start. Idempotent.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final bytes = await platformLoad();
      if (bytes != null) imageBytes.value = bytes;
    } catch (e) {
      debugPrint('[ProfileImageStore] init error: $e');
    }
  }

  /// Simpan bytes baru dan notify semua listener.
  Future<void> saveBytes(Uint8List bytes) async {
    try {
      await platformSave(bytes);
      imageBytes.value = bytes;
    } catch (e) {
      debugPrint('[ProfileImageStore] saveBytes error: $e');
      // Walau gagal persist, tetap update notifier supaya UI update
      imageBytes.value = bytes;
    }
  }

  /// Hapus foto tersimpan (saat logout).
  Future<void> clear() async {
    try {
      await platformClear();
    } catch (e) {
      debugPrint('[ProfileImageStore] clear error: $e');
    }
    imageBytes.value = null;
  }
}