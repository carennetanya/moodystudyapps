import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/patrol_pin_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PATROL PIN DIALOG — shared widget dipakai di 3 tempat:
//   1. Register screen  → mode: PatrolPinDialogMode.setup
//   2. Profile screen   → mode: PatrolPinDialogMode.change
//   3. Active session   → mode: PatrolPinDialogMode.verify
// ─────────────────────────────────────────────────────────────────────────────

enum PatrolPinDialogMode { setup, change, verify }

/// Returns true kalau berhasil (setup/change: PIN tersimpan, verify: PIN benar)
Future<bool> showPatrolPinDialog(
  BuildContext context,
  PatrolPinDialogMode mode,
) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: mode != PatrolPinDialogMode.verify,
    builder: (_) => _PatrolPinDialog(mode: mode),
  );
  return result ?? false;
}

class _PatrolPinDialog extends StatefulWidget {
  final PatrolPinDialogMode mode;
  const _PatrolPinDialog({required this.mode});

  @override
  State<_PatrolPinDialog> createState() => _PatrolPinDialogState();
}

class _PatrolPinDialogState extends State<_PatrolPinDialog>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  String? _errorMsg;
  bool _isLoading = false;
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _shake() {
    _shakeCtrl.forward(from: 0);
    HapticFeedback.vibrate();
  }

  void _onKeyTap(String digit) {
    final current = _isConfirming ? _confirmPin : _pin;
    if (current.length >= 4) return;
    setState(() {
      _errorMsg = null;
      if (_isConfirming) {
        _confirmPin = _confirmPin + digit;
      } else {
        _pin = _pin + digit;
      }
    });
    if ((_isConfirming ? _confirmPin : _pin).length == 4) {
      _onPinComplete();
    }
  }

  void _onDelete() {
    setState(() {
      _errorMsg = null;
      if (_isConfirming) {
        if (_confirmPin.isNotEmpty) _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
      } else {
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
      }
    });
  }

  Future<void> _onPinComplete() async {
    if (widget.mode == PatrolPinDialogMode.verify) {
      final ok = await PatrolPinService.verifyPin(_pin);
      if (ok) {
        if (mounted) Navigator.of(context).pop(true);
      } else {
        setState(() {
          _pin = '';
          _errorMsg = 'PIN salah. Coba lagi.';
        });
        _shake();
      }
      return;
    }

    // Setup / Change mode
    if (!_isConfirming) {
      setState(() => _isConfirming = true);
      return;
    }

    // Konfirmasi
    if (_pin == _confirmPin) {
      // Save tanpa loading state — SharedPreferences sangat cepat
      PatrolPinService.savePin(_pin); // fire and forget, no await
      if (mounted) Navigator.of(context).pop(true);
    } else {
      setState(() {
        _confirmPin = '';
        _errorMsg = 'PIN tidak cocok. Coba lagi.';
      });
      _shake();
    }
  }

  String get _title {
    switch (widget.mode) {
      case PatrolPinDialogMode.setup:
        return _isConfirming ? 'Konfirmasi PIN' : 'Buat PIN Darurat';
      case PatrolPinDialogMode.change:
        return _isConfirming ? 'Konfirmasi PIN Baru' : 'PIN Baru';
      case PatrolPinDialogMode.verify:
        return '🔒 Masukkan PIN Darurat';
    }
  }

  String get _subtitle {
    switch (widget.mode) {
      case PatrolPinDialogMode.setup:
        return _isConfirming
            ? 'Ulangi PIN yang sama'
            : 'PIN ini dipakai kalau kamu butuh keluar\nsaat patrol mode aktif';
      case PatrolPinDialogMode.change:
        return _isConfirming ? 'Ulangi PIN baru' : 'Masukkan PIN baru (4 digit)';
      case PatrolPinDialogMode.verify:
        return 'Masukkan PIN darurat untuk keluar\ndari sesi belajar';
    }
  }

  @override
  Widget build(BuildContext context) {
    final activePin = _isConfirming ? _confirmPin : _pin;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
      child: AnimatedBuilder(
        animation: _shakeAnim,
        builder: (_, child) => Transform.translate(
          offset: Offset(
            _shakeAnim.value * 8 * ((_shakeCtrl.value * 10).round().isEven ? 1 : -1),
            0,
          ),
          child: child,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFF111111), width: 3),
            boxShadow: const [
              BoxShadow(color: Color(0xFF111111), offset: Offset(6, 6)),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: widget.mode == PatrolPinDialogMode.verify
                      ? Colors.red
                      : const Color(0xFFF2EA05),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF111111), width: 3),
                  boxShadow: const [
                    BoxShadow(color: Color(0xFF111111), offset: Offset(3, 3)),
                  ],
                ),
                child: Icon(
                  widget.mode == PatrolPinDialogMode.verify
                      ? Icons.lock_open_rounded
                      : Icons.shield_rounded,
                  color: widget.mode == PatrolPinDialogMode.verify
                      ? Colors.white
                      : const Color(0xFF111111),
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _title,
                style: const TextStyle(
                  fontFamily: 'BlackHanSans',
                  fontSize: 20,
                  color: Color(0xFF111111),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  color: Color(0xFF666666),
                ),
              ),
              const SizedBox(height: 24),

              // PIN dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  final filled = i < activePin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled ? const Color(0xFF111111) : Colors.transparent,
                      border: Border.all(
                        color: const Color(0xFF111111),
                        width: 2.5,
                      ),
                    ),
                  );
                }),
              ),

              // Error
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child: _errorMsg != null
                    ? Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          _errorMsg!,
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 13,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              const SizedBox(height: 20),

              // Numpad
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(
                    color: Color(0xFF111111),
                    strokeWidth: 3,
                  ),
                )
              else
                _buildNumpad(),

              if (widget.mode != PatrolPinDialogMode.verify) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text(
                    'Lewati dulu',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      color: Color(0xFF999999),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumpad() {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', 'del'],
    ];
    return Column(
      children: keys.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((k) {
              if (k.isEmpty) return const SizedBox(width: 72, height: 56);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _NumKey(
                  label: k,
                  onTap: k == 'del' ? _onDelete : () => _onKeyTap(k),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}

class _NumKey extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _NumKey({required this.label, required this.onTap});

  @override
  State<_NumKey> createState() => _NumKeyState();
}

class _NumKeyState extends State<_NumKey> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDel = widget.label == 'del';
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: 72,
        height: 56,
        transform: Matrix4.translationValues(
          _pressed ? 2 : 0,
          _pressed ? 2 : 0,
          0,
        ),
        decoration: BoxDecoration(
          color: isDel ? const Color(0xFFF5F5F5) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF111111), width: 2.5),
          boxShadow: _pressed
              ? const [BoxShadow(color: Color(0xFF111111), offset: Offset(1, 1))]
              : const [BoxShadow(color: Color(0xFF111111), offset: Offset(3, 3))],
        ),
        child: Center(
          child: isDel
              ? const Icon(Icons.backspace_outlined, size: 20, color: Color(0xFF111111))
              : Text(
                  widget.label,
                  style: const TextStyle(
                    fontFamily: 'BlackHanSans',
                    fontSize: 22,
                    color: Color(0xFF111111),
                  ),
                ),
        ),
      ),
    );
  }
}