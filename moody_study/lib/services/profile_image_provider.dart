import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'profile_image_store.dart';

/// ChangeNotifier wrapper untuk ProfileImageStore.
///
/// Menggantikan pemakaian ValueListenableBuilder secara langsung.
/// Daftarkan di main.dart dengan ChangeNotifierProvider.
///
/// Cara pakai di widget:
///   final imageBytes = context.watch<ProfileImageProvider>().imageBytes;
class ProfileImageProvider extends ChangeNotifier {
  ProfileImageProvider() {
    // Dengarkan ValueNotifier dari singleton store
    ProfileImageStore.instance.imageBytes.addListener(_onImageChanged);
  }

  void _onImageChanged() {
    notifyListeners();
  }

  /// Bytes foto profil saat ini. Null jika belum ada foto.
  Uint8List? get imageBytes => ProfileImageStore.instance.imageBytes.value;

  /// Simpan foto profil baru.
  Future<void> saveBytes(Uint8List bytes) async {
    await ProfileImageStore.instance.saveBytes(bytes);
    // notifyListeners() dipanggil otomatis via _onImageChanged
  }

  /// Hapus foto profil (saat logout).
  Future<void> clear() async {
    await ProfileImageStore.instance.clear();
  }

  @override
  void dispose() {
    ProfileImageStore.instance.imageBytes.removeListener(_onImageChanged);
    super.dispose();
  }
}
