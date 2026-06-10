import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:dartz/dartz.dart' hide State;
import 'package:moody_study/core/failure.dart';
import 'package:moody_study/core/exception_handler.dart';
import 'package:moody_study/core/error/exception_mapper.dart';
import 'package:moody_study/core/error/failures.dart';
import 'package:moody_study/utils/app_localizations.dart';
import 'package:moody_study/utils/input_formatters.dart';
import 'package:moody_study/services/profile_service.dart';
import 'package:moody_study/services/profile_image_provider.dart';
import 'package:moody_study/services/user_provider.dart';
import 'package:moody_study/services/validation_service.dart';
import 'theme_selector_screen.dart';
import '../services/patrol_pin_service.dart';
import '../widgets/patrol_pin_dialog.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _emailPasswordController;
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;

  // Original values to detect changes
  String _originalName = '';
  String _originalUsername = '';

  // Per-field inline errors
  String? _nameError;
  String? _usernameError;
  String? _emailError;

  // Async check state
  bool _isUsernameChecking = false;
  bool _isEmailChecking = false;
  bool _isOffline = false;

  // Debounce timers
  Timer? _usernameDebounce;
  Timer? _emailDebounce;

  bool _isLoading = false;       // avatar upload only
  bool _isSavingName = false;    // profile (name + username)
  bool _isSavingEmail = false;   // email update
  bool _isSavingPassword = false; // password update
  bool _hasPin = false;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  String? _errorMessage;
  String? _successMessage;

  Uint8List? _pendingImageBytes;
  String? _pendingImageMime;

  static final _usernameRegex = RegExp(r'^[a-z0-9._-]+$');
  static final _emailRegex =
      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

  @override
  void initState() {
    super.initState();
    _loadPinStatus();
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
    _usernameDebounce?.cancel();
    _emailDebounce?.cancel();
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _emailPasswordController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ─── Profile change detection ───────────────────────────────────────────────

  bool get _profileHasChanges =>
      _nameController.text.trim() != _originalName ||
      _usernameController.text != _originalUsername;

  bool get _profileCanSave =>
      !_isSavingName &&
      _profileHasChanges &&
      _nameError == null &&
      _usernameError == null &&
      !_isUsernameChecking &&
      !_isOffline &&
      _nameController.text.trim().isNotEmpty &&
      _usernameController.text.isNotEmpty;

  // ─── Load profile ────────────────────────────────────────────────────────────

  Future<Either<Failure, void>> _fetchProfile() async {
    try {
      final userProvider = context.read<UserProvider>();
      await userProvider.refreshUserInfo();
      if (mounted) {
        final name = userProvider.name ?? '';
        final username = userProvider.username ?? '';
        setState(() {
          _nameController.text = name;
          _usernameController.text = username;
          _originalName = name;
          _originalUsername = username;
        });
      }
      if (!mounted) return const Right(null);
      final imageProvider = context.read<ProfileImageProvider>();
      if (imageProvider.imageBytes == null) {
        final info = await ProfileService.getUserInfo();
        final avatarUrl = info['avatarUrl'] as String?;
        if (avatarUrl != null && avatarUrl.isNotEmpty) {
          await _loadAvatarFromUrl(avatarUrl);
        }
      }
      return const Right(null);
    } catch (e) {
      return Left(ServiceFailure(sanitizeException(e)));
    }
  }

  Future<void> _loadProfile() async {
    final userProvider = context.read<UserProvider>();
    final name = userProvider.name ?? '';
    final username = userProvider.username ?? '';
    _nameController.text = name;
    _usernameController.text = username;
    _originalName = name;
    _originalUsername = username;
    (await _fetchProfile()).fold(
      (f) => debugPrint('Error loading profile: ${f.message}'),
      (_) {},
    );
  }

  Future<Either<Failure, void>> _loadAvatarFromUrl(String url) async {
    try {
      Uint8List bytes;
      if (url.startsWith('data:')) {
        final commaIdx = url.indexOf(',');
        if (commaIdx < 0) return const Right(null);
        bytes = base64Decode(url.substring(commaIdx + 1));
      } else {
        final fetched = await _httpGet(url);
        bytes = fetched.getOrElse(() => Uint8List(0));
      }
      if (!mounted) return const Right(null);
      await context.read<ProfileImageProvider>().saveBytes(bytes);
      if (mounted) setState(() {});
      return const Right(null);
    } catch (e) {
      return Left(StorageFailure(sanitizeException(e)));
    }
  }

  Future<Either<Failure, Uint8List>> _httpGet(String url) async {
    try {
      final uri = Uri.parse(url);
      final client = HttpClient();
      final request = await client.getUrl(uri);
      final response = await request.close();
      if (response.statusCode != 200) {
        client.close();
        return Left(NetworkFailure('HTTP ${response.statusCode}'));
      }
      final bytes = <int>[];
      await for (final chunk in response) {
        bytes.addAll(chunk);
      }
      client.close();
      return Right(Uint8List.fromList(bytes));
    } catch (e) {
      return Left(NetworkFailure(sanitizeException(e)));
    }
  }

  // ─── Validation helpers ─────────────────────────────────────────────────────

  void _onNameChanged(String v) {
    final l = AppLocalizations.of(context, listen: false);
    setState(() {
      _nameError = v.trim().length > 30 ? l.validationNameTooLong : null;
    });
  }

  void _onUsernameChanged(String v) {
    _usernameDebounce?.cancel();
    final l = AppLocalizations.of(context, listen: false);

    if (v.isEmpty) {
      setState(() {
        _usernameError = null;
        _isUsernameChecking = false;
      });
      return;
    }

    String? err;
    if (v.length < 3) {
      err = l.validationUsernameTooShort;
    } else if (v.length > 16) {
      err = l.validationUsernameTooLong;
    } else if (!_usernameRegex.hasMatch(v)) {
      err = l.validationUsernameFormat;
    }

    if (err != null) {
      setState(() {
        _usernameError = err;
        _isUsernameChecking = false;
      });
      return;
    }

    // Format OK and unchanged → no need to check
    if (v == _originalUsername) {
      setState(() {
        _usernameError = null;
        _isUsernameChecking = false;
      });
      return;
    }

    setState(() {
      _usernameError = null;
      _isUsernameChecking = true;
    });
    _usernameDebounce = Timer(
      const Duration(milliseconds: 500),
      () => _checkUsername(v),
    );
  }

  void _onEmailChanged(String v) {
    _emailDebounce?.cancel();
    final l = AppLocalizations.of(context, listen: false);

    if (v.isEmpty) {
      setState(() {
        _emailError = null;
        _isEmailChecking = false;
      });
      return;
    }

    if (v.contains(' ')) {
      setState(() {
        _emailError = l.validationEmailContainsSpace;
        _isEmailChecking = false;
      });
      return;
    }
    if (!_emailRegex.hasMatch(v)) {
      setState(() {
        _emailError = l.validationEmailFormat;
        _isEmailChecking = false;
      });
      return;
    }

    setState(() {
      _emailError = null;
      _isEmailChecking = true;
    });
    _emailDebounce = Timer(
      const Duration(milliseconds: 500),
      () => _checkEmail(v),
    );
  }

  // ─── Async uniqueness checks (excludeSelf=true) ──────────────────────────────

  Future<void> _checkUsername(String username) async {
    if (!mounted) return;
    final l = AppLocalizations.of(context, listen: false);
    final result =
        await ValidationService.checkUsername(username, excludeSelf: true);
    if (!mounted) return;
    result.fold(
      (failure) {
        final offline = failure is NetworkOfflineFailure ||
            failure is NetworkTimeoutFailure;
        setState(() {
          _isUsernameChecking = false;
          if (offline) _isOffline = true;
        });
      },
      (check) {
        setState(() {
          _isUsernameChecking = false;
          _isOffline = false;
          if (!check.available) {
            _usernameError = l.validationUsernameAlreadyTaken;
          }
        });
      },
    );
  }

  Future<void> _checkEmail(String email) async {
    if (!mounted) return;
    final l = AppLocalizations.of(context, listen: false);
    final result =
        await ValidationService.checkEmail(email, excludeSelf: true);
    if (!mounted) return;
    result.fold(
      (failure) {
        final offline = failure is NetworkOfflineFailure ||
            failure is NetworkTimeoutFailure;
        setState(() {
          _isEmailChecking = false;
          if (offline) _isOffline = true;
        });
      },
      (check) {
        setState(() {
          _isEmailChecking = false;
          _isOffline = false;
          if (!check.available) {
            _emailError = l.validationEmailAlreadyRegistered;
          }
        });
      },
    );
  }

  // ─── Avatar ──────────────────────────────────────────────────────────────────

  Future<Either<Failure, void>> _doPickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return const Right(null);
      final pickedFile = result.files.single;
      final bytes = pickedFile.bytes;
      if (bytes == null) return Left(StorageFailure('Gagal membaca file gambar'));
      final sizeInMB = bytes.lengthInBytes / (1024 * 1024);
      if (sizeInMB > 2) return Left(StorageFailure('Ukuran foto maksimal 2MB'));
      final ext = (pickedFile.extension ?? 'jpg').toLowerCase();
      final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
      setState(() {
        _pendingImageBytes = bytes;
        _pendingImageMime = mime;
      });
      return const Right(null);
    } catch (e) {
      return Left(StorageFailure(sanitizeException(e)));
    }
  }

  Future<void> _pickImage() async {
    (await _doPickImage()).fold(
      (f) {
        debugPrint('Pick image error: ${f.message}');
        _showError(f.message);
      },
      (_) => _showSuccess('Foto berhasil dipilih'),
    );
  }

  Future<Either<Failure, void>> _doUploadAvatar(
      Uint8List bytes, String mime) async {
    try {
      final base64Image = 'data:$mime;base64,${base64Encode(bytes)}';
      await ProfileService.updateAvatar(base64Image);
      if (!mounted) return const Right(null);
      await context.read<ProfileImageProvider>().saveBytes(bytes);
      return const Right(null);
    } catch (e) {
      return Left(ServiceFailure(sanitizeException(e)));
    }
  }

  Future<void> _uploadAvatar() async {
    final imageProvider = context.read<ProfileImageProvider>();
    final displayBytes = _pendingImageBytes ?? imageProvider.imageBytes;

    if (displayBytes == null) {
      _showError('Pilih foto terlebih dahulu');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final mime = _pendingImageMime ?? 'image/jpeg';
    final result = await _doUploadAvatar(_pendingImageBytes!, mime);
    if (!mounted) return;
    result.fold(
      (f) => setState(() {
        _errorMessage = f.message;
        _isLoading = false;
      }),
      (_) {
        setState(() {
          _successMessage = 'Foto profil berhasil diperbarui!';
          _isLoading = false;
          _pendingImageBytes = null;
          _pendingImageMime = null;
        });
        _clearSuccessMessage();
      },
    );
  }

  // ─── Update profile (name + username) ───────────────────────────────────────

  Future<void> _updateProfile() async {
    final l = AppLocalizations.of(context, listen: false);
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = l.validationNameEmpty);
      return;
    }
    if (!_profileCanSave) return;

    setState(() {
      _isSavingName = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await ProfileService.updateName(name);
      await ProfileService.updateUsername(_usernameController.text);
      if (!mounted) return;
      final userProvider = context.read<UserProvider>();
      userProvider.updateName(name);
      userProvider.updateUsername(_usernameController.text);
      setState(() {
        _originalName = name;
        _originalUsername = _usernameController.text;
        _successMessage = 'Profil berhasil diperbarui!';
        _isSavingName = false;
      });
      _clearSuccessMessage();
    } catch (e) {
      if (!mounted) return;
      final failure = ExceptionMapper.map(e);
      if (failure.messageKey == 'validation.username.taken') {
        setState(() {
          _usernameError = l.validationUsernameAlreadyTaken;
          _isSavingName = false;
        });
      } else {
        setState(() {
          _errorMessage = failure.localizedMessage(context);
          _isSavingName = false;
        });
      }
    }
  }

  // ─── Update email ────────────────────────────────────────────────────────────

  Future<void> _updateEmail() async {
    final l = AppLocalizations.of(context, listen: false);
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() => _emailError = l.validationEmailEmpty);
      return;
    }
    if (_emailError != null || _isEmailChecking || _isOffline) return;
    if (_emailPasswordController.text.isEmpty) {
      _showError('Password harus diisi untuk konfirmasi');
      return;
    }

    setState(() {
      _isSavingEmail = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final data = await ProfileService.updateEmail(
        newEmail: email,
        password: _emailPasswordController.text,
      );
      if (!mounted) return;
      final userProvider = context.read<UserProvider>();
      userProvider.updateEmail(email);
      final newToken = data['token'] as String?;
      if (newToken != null && newToken.isNotEmpty) {
        userProvider.updateToken(newToken);
      }
      setState(() {
        _successMessage = 'Email berhasil diperbarui!';
        _isSavingEmail = false;
        _emailController.clear();
        _emailPasswordController.clear();
        _emailError = null;
      });
      _clearSuccessMessage();
    } catch (e) {
      if (!mounted) return;
      final failure = ExceptionMapper.map(e);
      if (failure.messageKey == 'validation.email.taken') {
        setState(() {
          _emailError = l.validationEmailAlreadyRegistered;
          _isSavingEmail = false;
        });
      } else {
        setState(() {
          _errorMessage = failure.localizedMessage(context);
          _isSavingEmail = false;
        });
      }
    }
  }

  // ─── Update password (untouched per spec) ────────────────────────────────────

  Future<Either<Failure, void>> _doUpdatePassword(
      String current, String newPw, String confirm) async {
    try {
      await ProfileService.updatePassword(
        currentPassword: current,
        newPassword: newPw,
        confirmPassword: confirm,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServiceFailure(sanitizeException(e)));
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
      _isSavingPassword = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final result = await _doUpdatePassword(
      _currentPasswordController.text,
      _newPasswordController.text,
      _confirmPasswordController.text,
    );
    if (!mounted) return;
    result.fold(
      (f) => setState(() {
        _errorMessage = f.message;
        _isSavingPassword = false;
      }),
      (_) {
        setState(() {
          _successMessage = 'Password berhasil diperbarui!';
          _isSavingPassword = false;
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
        });
        _clearSuccessMessage();
      },
    );
  }

  // ─── PIN ─────────────────────────────────────────────────────────────────────

  Future<void> _loadPinStatus() async {
    final has = await PatrolPinService.hasPin();
    if (mounted) setState(() => _hasPin = has);
  }

  Future<void> _showPinOptions() async {
    final mode =
        _hasPin ? PatrolPinDialogMode.change : PatrolPinDialogMode.setup;
    final ok = await showPatrolPinDialog(context, mode);
    if (ok) {
      setState(() => _hasPin = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ PIN patrol berhasil disimpan!'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  // ─── Logout ──────────────────────────────────────────────────────────────────

  Future<void> _logout() async {
    FocusScope.of(context).unfocus();
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
              context.read<UserProvider>().logout();
              await context.read<ProfileImageProvider>().clear();
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
            child:
                const Text('Keluar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

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

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final profileImageBytes = context.watch<ProfileImageProvider>().imageBytes;
    final displayImageBytes = _pendingImageBytes ?? profileImageBytes;

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
          'Edit Profil',
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
            // ── Offline banner ────────────────────────────────────────────
            if (_isOffline)
              _ProfileOfflineBanner(message: l.bannerOffline),

            // ── Global error / success ────────────────────────────────────
            if (_errorMessage != null)
              _StatusBanner(
                  message: _errorMessage!, isError: true),
            if (_successMessage != null)
              _StatusBanner(
                  message: _successMessage!, isError: false),

            // ── Avatar card ───────────────────────────────────────────────
            _buildAvatarCard(displayImageBytes),
            const SizedBox(height: 20),

            // ── Profile card (name + username) ────────────────────────────
            _buildProfileCard(l),
            const SizedBox(height: 20),

            // ── Email card ────────────────────────────────────────────────
            _buildEmailCard(l),
            const SizedBox(height: 20),

            // ── Password + PIN + logout card ──────────────────────────────
            _buildPasswordCard(l),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ─── Avatar card ─────────────────────────────────────────────────────────────

  Widget _buildAvatarCard(Uint8List? displayImageBytes) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFF111111), width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border:
                    Border.all(color: const Color(0xFF1EE86F), width: 3),
                color: const Color(0xFFF0F0F0),
              ),
              child: ClipOval(
                child: displayImageBytes != null
                    ? Image.memory(displayImageBytes,
                        fit: BoxFit.cover, width: 100, height: 100)
                    : const Icon(Icons.person,
                        size: 50, color: Color(0xFF999999)),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _pickImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF111111),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Pilih Foto',
                  style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 8),
            const Text('Gambar rasio 1:1, maks 2MB',
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 11,
                    color: Color(0xFF999999))),
            if (_pendingImageBytes != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _uploadAvatar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF2EA05),
                    foregroundColor: const Color(0xFF111111),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 14,
                          width: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(
                                  Color(0xFF111111))))
                      : const Text('Upload Foto',
                          style: TextStyle(
                              fontFamily: 'BlackHanSans',
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Profile card ─────────────────────────────────────────────────────────────

  Widget _buildProfileCard(AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFF111111), width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildTextField(
            controller: _nameController,
            label: 'Nama Lengkap',
            hint: 'Masukkan nama Anda',
            enabled: !_isOffline,
            errorText: _nameError,
            onChanged: _onNameChanged,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _usernameController,
            label: 'Username',
            hint: 'Masukkan username Anda',
            enabled: !_isOffline,
            errorText: _usernameError,
            isChecking: _isUsernameChecking,
            inputFormatters: [
              LowercaseTextInputFormatter(),
              NoSpaceTextInputFormatter(),
            ],
            onChanged: _onUsernameChanged,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _profileCanSave ? _updateProfile : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF2EA05),
                foregroundColor: const Color(0xFF111111),
                disabledBackgroundColor: Colors.grey.shade300,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: _profileCanSave
                        ? const Color(0xFF111111)
                        : Colors.grey.shade400,
                    width: 1,
                  ),
                ),
              ),
              child: _isSavingName
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation(Color(0xFF111111))))
                  : const Text('Simpan Perubahan',
                      style: TextStyle(
                          fontFamily: 'BlackHanSans',
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Email card ───────────────────────────────────────────────────────────────

  Widget _buildEmailCard(AppLocalizations l) {
    final canSaveEmail = !_isSavingEmail &&
        _emailController.text.isNotEmpty &&
        _emailError == null &&
        !_isEmailChecking &&
        !_isOffline &&
        _emailPasswordController.text.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFF111111), width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ubah Email',
              style: TextStyle(
                  fontFamily: 'BlackHanSans',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111111))),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _emailController,
            label: 'Email Baru',
            keyboardType: TextInputType.emailAddress,
            hint: 'Masukkan email baru',
            enabled: !_isOffline,
            errorText: _emailError,
            isChecking: _isEmailChecking,
            inputFormatters: [LowercaseEmailFormatter()],
            onChanged: _onEmailChanged,
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
              onPressed: canSaveEmail ? _updateEmail : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF2EA05),
                foregroundColor: const Color(0xFF111111),
                disabledBackgroundColor: Colors.grey.shade300,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: canSaveEmail
                        ? const Color(0xFF111111)
                        : Colors.grey.shade400,
                    width: 1,
                  ),
                ),
              ),
              child: _isSavingEmail
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation(Color(0xFF111111))))
                  : const Text('Ubah Email',
                      style: TextStyle(
                          fontFamily: 'BlackHanSans',
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Password + PIN + logout card ────────────────────────────────────────────

  Widget _buildPasswordCard(AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFF111111), width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ubah Password',
              style: TextStyle(
                  fontFamily: 'BlackHanSans',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111111))),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _currentPasswordController,
            label: 'Password Saat Ini',
            obscureText: !_showCurrentPassword,
            hint: 'Masukkan password saat ini',
            suffixIcon: GestureDetector(
              onTap: () =>
                  setState(() => _showCurrentPassword = !_showCurrentPassword),
              child: Icon(
                  _showCurrentPassword
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: const Color(0xFF111111),
                  size: 18),
            ),
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _newPasswordController,
            label: 'Password Baru',
            obscureText: !_showNewPassword,
            hint: 'Minimal 6 karakter',
            suffixIcon: GestureDetector(
              onTap: () =>
                  setState(() => _showNewPassword = !_showNewPassword),
              child: Icon(
                  _showNewPassword ? Icons.visibility : Icons.visibility_off,
                  color: const Color(0xFF111111),
                  size: 18),
            ),
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _confirmPasswordController,
            label: 'Konfirmasi Password',
            obscureText: !_showConfirmPassword,
            hint: 'Ulangi password baru',
            suffixIcon: GestureDetector(
              onTap: () =>
                  setState(() => _showConfirmPassword = !_showConfirmPassword),
              child: Icon(
                  _showConfirmPassword
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: const Color(0xFF111111),
                  size: 18),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSavingPassword ? null : _updatePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF2EA05),
                foregroundColor: const Color(0xFF111111),
                disabledBackgroundColor: Colors.grey,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(
                      color: Color(0xFF111111), width: 1),
                ),
              ),
              child: _isSavingPassword
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation(Color(0xFF111111))))
                  : const Text('Simpan Password',
                      style: TextStyle(
                          fontFamily: 'BlackHanSans',
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 20),

          // ── Patrol PIN ────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9E6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE8C44A), width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2EA05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: const Color(0xFF111111), width: 2),
                      ),
                      child: const Icon(Icons.shield_rounded,
                          size: 16, color: Color(0xFF111111)),
                    ),
                    const SizedBox(width: 10),
                    const Text('Patrol Mode PIN',
                        style: TextStyle(
                            fontFamily: 'BlackHanSans',
                            fontSize: 14,
                            color: Color(0xFF111111))),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _hasPin
                            ? Colors.green.shade100
                            : Colors.red.shade100,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _hasPin ? Colors.green : Colors.red,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        _hasPin ? 'Aktif' : 'Belum diset',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _hasPin
                              ? Colors.green.shade700
                              : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'PIN ini dipakai kalau kamu perlu keluar darurat saat patrol mode aktif (3x distraksi).',
                  style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      color: Color(0xFF888888)),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _showPinOptions,
                    icon: Icon(
                        _hasPin ? Icons.edit_rounded : Icons.add_rounded,
                        size: 16),
                    label: Text(
                        _hasPin ? 'Ganti PIN' : 'Set PIN Sekarang',
                        style: const TextStyle(
                            fontFamily: 'BlackHanSans', fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF111111),
                      side: const BorderSide(
                          color: Color(0xFF111111), width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _logout,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFDD2C00), width: 2),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Keluar',
                  style: TextStyle(
                      fontFamily: 'BlackHanSans',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFDD2C00))),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Reusable field builder ───────────────────────────────────────────────────

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    String? hint,
    Widget? suffixIcon,
    String? errorText,
    bool isChecking = false,
    List<dynamic>? inputFormatters,
    bool enabled = true,
    ValueChanged<String>? onChanged,
  }) {
    final hasError = errorText != null;
    final borderColor = hasError
        ? const Color(0xFFDD2C00)
        : const Color(0xFF111111);

    Widget? resolvedSuffix;
    if (isChecking) {
      resolvedSuffix = const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
            strokeWidth: 2, color: Color(0xFF111111)),
      );
    } else if (suffixIcon != null) {
      resolvedSuffix = suffixIcon;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontFamily: 'BlackHanSans',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111111))),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          readOnly: !enabled,
          onChanged: onChanged,
          inputFormatters: inputFormatters != null
              ? List.castFrom(inputFormatters)
              : null,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: resolvedSuffix,
            filled: true,
            fillColor: enabled ? Colors.white : const Color(0xFFF0F0F0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: borderColor, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: borderColor, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: hasError
                    ? const Color(0xFFDD2C00)
                    : const Color(0xFF1EE86F),
                width: 2,
              ),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 12,
            color: enabled
                ? const Color(0xFF111111)
                : const Color(0xFF999999),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 2),
            child: Text(
              errorText,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFFDD2C00),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Offline banner ───────────────────────────────────────────────────────────

class _ProfileOfflineBanner extends StatelessWidget {
  final String message;
  const _ProfileOfflineBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE5E5),
        border: Border.all(color: const Color(0xFFDD2C00), width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded,
              size: 18, color: Color(0xFFDD2C00)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111111),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Status banner (error / success) ─────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  final String message;
  final bool isError;
  const _StatusBanner({required this.message, required this.isError});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isError
            ? const Color(0xFFFFE5E5)
            : const Color(0xFFE5FFE5),
        border: Border.all(
          color: isError ? const Color(0xFFDD2C00) : const Color(0xFF1EE86F),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: isError ? const Color(0xFFDD2C00) : const Color(0xFF1EE86F),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
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
    );
  }
}