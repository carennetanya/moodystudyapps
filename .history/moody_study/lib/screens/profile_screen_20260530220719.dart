import 'package:flutter/material.dart';
import 'package:moody_study/utils/app_localizations.dart';
import 'package:moody_study/services/profile_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nicknameController;
  late TextEditingController _emailController;
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;

  bool _loadingNickname = false;
  bool _loadingEmail = false;
  bool _loadingPassword = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController();
    _emailController = TextEditingController();
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _loadNickname();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadNickname() async {
    try {
      final result = await ProfileService.getNickname();
      if (mounted) {
        setState(() {
          _nicknameController.text = result['nickname'] as String? ?? '';
        });
      }
    } catch (e) {
      debugPrint('Error loading nickname: $e');
    }
  }

  Future<void> _updateNickname() async {
    if (_nicknameController.text.isEmpty) {
      _showError('Nickname tidak boleh kosong');
      return;
    }

    setState(() {
      _loadingNickname = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await ProfileService.setNickname(_nicknameController.text);
      if (mounted) {
        setState(() {
          _successMessage = 'Nickname berhasil diperbarui!';
          _loadingNickname = false;
        });
        _clearSuccessMessage();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _loadingNickname = false;
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

    setState(() {
      _loadingEmail = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await ProfileService.updateEmail(
        newEmail: _emailController.text,
        password: _currentPasswordController.text,
      );
      if (mounted) {
        setState(() {
          _successMessage = 'Email berhasil diperbarui!';
          _loadingEmail = false;
          _currentPasswordController.clear();
          _emailController.clear();
        });
        _clearSuccessMessage();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _loadingEmail = false;
        });
      }
    }
  }

  Future<void> _updatePassword() async {
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showError('Semua field password harus diisi');
      return;
    }

    if (_newPasswordController.text.length < 6) {
      _showError('Password baru minimal 6 karakter');
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showError('Password baru tidak cocok');
      return;
    }

    setState(() {
      _loadingPassword = true;
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
          _loadingPassword = false;
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
          _loadingPassword = false;
        });
      }
    }
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'BlackHanSans',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111111),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF111111),
                width: 2,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF111111),
                width: 2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF1EE86F),
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          style: const TextStyle(fontFamily: 'Nunito', fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
    required bool isLoading,
    required VoidCallback onSubmit,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFF111111), width: 2),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF111111),
            offset: Offset(4, 4),
            blurRadius: 0,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'BlackHanSans',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 16),
          ...children,
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF2EA05),
                foregroundColor: const Color(0xFF111111),
                disabledBackgroundColor: Colors.grey,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(
                    color: Color(0xFF111111),
                    width: 2,
                  ),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Color(0xFF111111)),
                      ),
                    )
                  : const Text(
                      'Simpan',
                      style: TextStyle(
                        fontFamily: 'BlackHanSans',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
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
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
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
                          fontSize: 13,
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
                          fontSize: 13,
                          color: Color(0xFF111111),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            _buildSection(
              title: '👤 Ubah Nickname',
              isLoading: _loadingNickname,
              onSubmit: _updateNickname,
              children: [
                _buildTextField(
                  controller: _nicknameController,
                  label: 'Nickname',
                  hint: 'Masukkan nickname baru',
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: '📧 Ubah Email',
              isLoading: _loadingEmail,
              onSubmit: _updateEmail,
              children: [
                _buildTextField(
                  controller: _emailController,
                  label: 'Email Baru',
                  keyboardType: TextInputType.emailAddress,
                  hint: 'Masukkan email baru',
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _currentPasswordController,
                  label: 'Password Saat Ini',
                  obscureText: true,
                  hint: 'Masukkan password untuk konfirmasi',
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: '🔐 Ubah Password',
              isLoading: _loadingPassword,
              onSubmit: _updatePassword,
              children: [
                _buildTextField(
                  controller: _currentPasswordController,
                  label: 'Password Saat Ini',
                  obscureText: true,
                  hint: 'Masukkan password saat ini',
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _newPasswordController,
                  label: 'Password Baru',
                  obscureText: true,
                  hint: 'Minimal 6 karakter',
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _confirmPasswordController,
                  label: 'Konfirmasi Password',
                  obscureText: true,
                  hint: 'Ulangi password baru',
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
