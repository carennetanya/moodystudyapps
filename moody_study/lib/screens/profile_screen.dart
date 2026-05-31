import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:moody_study/utils/app_localizations.dart';
import 'package:moody_study/services/profile_service.dart';
import 'package:moody_study/services/auth_service.dart';
import 'package:moody_study/services/profile_image_store.dart';
import 'theme_selector_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _emailPasswordController;
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;

  bool _isLoading = false;
  bool _isPasswordLoading = false;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  String? _errorMessage;
  String? _successMessage;

  // Bytes foto yang dipilih tapi belum diupload
  Uint8List? _pendingImageBytes;
  String? _pendingImageMime;

  // Foto yang ditampilkan: pending dulu, fallback ke store (persisted)
  Uint8List? get _selectedImageBytes =>
      _pendingImageBytes ?? ProfileImageStore.instance.imageBytes.value;
  String? get _selectedImageMime => _pendingImageMime;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _usernameController = TextEditingController();
    _emailController = TextEditingController();
    _emailPasswordController = TextEditingController();
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _emailPasswordController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final result = await ProfileService.getUserInfo();
      if (mounted) {
        setState(() {
          _nameController.text = result['name'] as String? ?? '';
          _usernameController.text = result['username'] as String? ?? '';
        });
      }

      // Jika belum ada foto lokal, coba load dari avatarUrl backend
      if (ProfileImageStore.instance.imageBytes.value == null) {
        final avatarUrl = result['avatarUrl'] as String?;
        if (avatarUrl != null && avatarUrl.isNotEmpty) {
          await _loadAvatarFromUrl(avatarUrl);
        }
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
  }

  /// Decode base64 data-URL atau fetch HTTP URL lalu simpan ke store
  Future<void> _loadAvatarFromUrl(String url) async {
    try {
      Uint8List bytes;
      if (url.startsWith('data:')) {
        // Format: data:image/jpeg;base64,....
        final commaIdx = url.indexOf(',');
        if (commaIdx < 0) return;
        bytes = base64Decode(url.substring(commaIdx + 1));
      } else {
        // HTTP URL — fetch dulu
        final import_http = await _httpGet(url);
        if (import_http == null) return;
        bytes = import_http;
      }
      await ProfileImageStore.instance.saveBytes(bytes);
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error loading avatar from url: $e');
    }
  }

  Future<Uint8List?> _httpGet(String url) async {
    try {
      // ignore: depend_on_referenced_packages
      final uri = Uri.parse(url);
      final client = HttpClient();
      final request = await client.getUrl(uri);
      final response = await request.close();
      if (response.statusCode != 200) return null;
      final bytes = <int>[];
      await for (final chunk in response) {
        bytes.addAll(chunk);
      }
      client.close();
      return Uint8List.fromList(bytes);
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final pickedFile = result.files.single;
      final bytes = pickedFile.bytes;

      if (bytes == null) {
        _showError('Gagal membaca file gambar');
        return;
      }

      // Check size: 2MB max
      final sizeInMB = bytes.lengthInBytes / (1024 * 1024);
      if (sizeInMB > 2) {
        _showError('Ukuran foto maksimal 2MB');
        return;
      }

      // Determine MIME type from extension
      final ext = (pickedFile.extension ?? 'jpg').toLowerCase();
      final mime = ext == 'png' ? 'image/png' : 'image/jpeg';

      setState(() {
        _pendingImageBytes = bytes;
        _pendingImageMime = mime;
      });

      _showSuccess('Foto berhasil dipilih');
    } catch (e) {
      debugPrint('Pick image error: $e');
      _showError('Gagal memilih foto');
    }
  }

  Future<void> _uploadAvatar() async {
    if (_selectedImageBytes == null) {
      _showError('Pilih foto terlebih dahulu');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final mime = _selectedImageMime ?? 'image/jpeg';
      final base64Image = 'data:$mime;base64,${base64Encode(_selectedImageBytes!)}';

      await ProfileService.updateAvatar(base64Image);

      // Simpan ke persistent store supaya icon bottom nav & sesi berikutnya update
      await ProfileImageStore.instance.saveBytes(_pendingImageBytes!);

      if (mounted) {
        setState(() {
          _successMessage = 'Foto profil berhasil diperbarui!';
          _isLoading = false;
          // Pending bytes sudah di-persist, bersihkan pending
          _pendingImageBytes = null;
          _pendingImageMime = null;
        });
        _clearSuccessMessage();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateProfile() async {
    if (_nameController.text.isEmpty) {
      _showError('Nama tidak boleh kosong');
      return;
    }

    if (_usernameController.text.isEmpty) {
      _showError('Username tidak boleh kosong');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await ProfileService.updateName(_nameController.text);
      await ProfileService.updateUsername(_usernameController.text);

      if (mounted) {
        setState(() {
          _successMessage = 'Profil berhasil diperbarui!';
          _isLoading = false;
        });
        _clearSuccessMessage();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateEmail() async {
    if (_emailController.text.isEmpty) {
      _showError('Email tidak boleh kosong');
      return;
    }

    if (!_isValidEmail(_emailController.text)) {
      _showError('Format email tidak valid');
      return;
    }

    if (_emailPasswordController.text.isEmpty) {
      _showError('Password harus diisi untuk konfirmasi');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await ProfileService.updateEmail(
        newEmail: _emailController.text,
        password: _emailPasswordController.text,
      );
      if (mounted) {
        setState(() {
          _successMessage = 'Email berhasil diperbarui!';
          _isLoading = false;
          _emailController.clear();
          _emailPasswordController.clear();
        });
        _clearSuccessMessage();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updatePassword() async {
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showError('Semua field harus diisi');
      return;
    }

    if (_newPasswordController.text.length < 6) {
      _showError('Password minimal 6 karakter');
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showError('Password tidak cocok');
      return;
    }

    setState(() {
      _isPasswordLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await ProfileService.updatePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
        confirmPassword: _confirmPasswordController.text,
      );
      if (mounted) {
        setState(() {
          _successMessage = 'Password berhasil diperbarui!';
          _isPasswordLoading = false;
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
        });
        _clearSuccessMessage();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isPasswordLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    // Unfocus semua TextField dulu untuk mencegah error DomElement
    FocusScope.of(context).unfocus();

    // Tunggu sebentar agar unfocus selesai sebelum dialog muncul
    await Future.delayed(const Duration(milliseconds: 100));

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await AuthService.logout();
              // Hapus foto cache saat logout
              await ProfileImageStore.instance.clear();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => const ThemeSelectorScreen(),
                    transitionsBuilder: (_, anim, __, child) =>
                        FadeTransition(opacity: anim, child: child),
                    transitionDuration: const Duration(milliseconds: 400),
                  ),
                  (route) => false,
                );
              }
            },
            child: const Text('Keluar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }

  void _showError(String message) {
    setState(() => _errorMessage = message);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _errorMessage = null);
    });
  }

  void _showSuccess(String message) {
    setState(() => _successMessage = message);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _successMessage = null);
    });
  }

  void _clearSuccessMessage() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _successMessage = null);
    });
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    String? hint,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'BlackHanSans',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111111),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFF111111),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFF111111),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFF1EE86F),
                width: 2,
              ),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          style: const TextStyle(fontFamily: 'Nunito', fontSize: 12),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2EA05),
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const Icon(Icons.arrow_back, color: Color(0xFF111111)),
        ),
        title: Text(
          l.navProfile,
          style: const TextStyle(
            fontFamily: 'BlackHanSans',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111111),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE5E5),
                  border: Border.all(
                    color: const Color(0xFFDD2C00),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Color(0xFFDD2C00),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 12,
                          color: Color(0xFF111111),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (_successMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5FFE5),
                  border: Border.all(
                    color: const Color(0xFF1EE86F),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      color: Color(0xFF1EE86F),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _successMessage!,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 12,
                          color: Color(0xFF111111),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFF111111), width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Center(
                    child: Column(
                      children: [
                        // Avatar lingkaran
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF1EE86F),
                              width: 3,
                            ),
                            color: const Color(0xFFF0F0F0),
                          ),
                          child: ClipOval(
                            child: _selectedImageBytes != null
                                ? Image.memory(
                                    _selectedImageBytes!,
                                    fit: BoxFit.cover,
                                    width: 100,
                                    height: 100,
                                  )
                                : const Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Color(0xFF999999),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _pickImage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF111111),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Pilih Foto',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Gambar rasio 1:1, maks 2MB',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 11,
                            color: Color(0xFF999999),
                          ),
                        ),
                        if (_selectedImageBytes != null) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _uploadAvatar,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF2EA05),
                                foregroundColor: const Color(0xFF111111),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 14,
                                      width: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(
                                          Color(0xFF111111),
                                        ),
                                      ),
                                    )
                                  : const Text(
                                      'Upload Foto',
                                      style: TextStyle(
                                        fontFamily: 'BlackHanSans',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _nameController,
                    label: 'Nama Lengkap',
                    hint: 'Masukkan nama Anda',
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _usernameController,
                    label: 'Username',
                    hint: 'Masukkan username Anda',
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF2EA05),
                        foregroundColor: const Color(0xFF111111),
                        disabledBackgroundColor: Colors.grey,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(
                            color: Color(0xFF111111),
                            width: 1,
                          ),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(Color(0xFF111111)),
                              ),
                            )
                          : const Text(
                              'Simpan Perubahan',
                              style: TextStyle(
                                fontFamily: 'BlackHanSans',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFF111111), width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ubah Email',
                    style: TextStyle(
                      fontFamily: 'BlackHanSans',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111111),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _emailController,
                    label: 'Email Baru',
                    keyboardType: TextInputType.emailAddress,
                    hint: 'Masukkan email baru',
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _emailPasswordController,
                    label: 'Password',
                    obscureText: true,
                    hint: 'Masukkan password Anda',
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _updateEmail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF2EA05),
                        foregroundColor: const Color(0xFF111111),
                        disabledBackgroundColor: Colors.grey,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(
                            color: Color(0xFF111111),
                            width: 1,
                          ),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(Color(0xFF111111)),
                              ),
                            )
                          : const Text(
                              'Ubah Email',
                              style: TextStyle(
                                fontFamily: 'BlackHanSans',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFF111111), width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ubah Password',
                    style: TextStyle(
                      fontFamily: 'BlackHanSans',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111111),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _currentPasswordController,
                    label: 'Password Saat Ini',
                    obscureText: !_showCurrentPassword,
                    hint: 'Masukkan password saat ini',
                    suffixIcon: GestureDetector(
                      onTap: () {
                        setState(() =>
                            _showCurrentPassword = !_showCurrentPassword);
                      },
                      child: Icon(
                        _showCurrentPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: const Color(0xFF111111),
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _newPasswordController,
                    label: 'Password Baru',
                    obscureText: !_showNewPassword,
                    hint: 'Minimal 6 karakter',
                    suffixIcon: GestureDetector(
                      onTap: () {
                        setState(() => _showNewPassword = !_showNewPassword);
                      },
                      child: Icon(
                        _showNewPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: const Color(0xFF111111),
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _confirmPasswordController,
                    label: 'Konfirmasi Password',
                    obscureText: !_showConfirmPassword,
                    hint: 'Ulangi password baru',
                    suffixIcon: GestureDetector(
                      onTap: () {
                        setState(
                            () => _showConfirmPassword = !_showConfirmPassword);
                      },
                      child: Icon(
                        _showConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: const Color(0xFF111111),
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isPasswordLoading ? null : _updatePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF2EA05),
                        foregroundColor: const Color(0xFF111111),
                        disabledBackgroundColor: Colors.grey,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(
                            color: Color(0xFF111111),
                            width: 1,
                          ),
                        ),
                      ),
                      child: _isPasswordLoading
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(Color(0xFF111111)),
                              ),
                            )
                          : const Text(
                              'Simpan Password',
                              style: TextStyle(
                                fontFamily: 'BlackHanSans',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _logout,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color(0xFFDD2C00),
                          width: 2,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Keluar',
                        style: TextStyle(
                          fontFamily: 'BlackHanSans',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFDD2C00),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}