import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NameFormOverlay extends StatefulWidget {
  final bool show;
  final bool isDark;
  final void Function(String name) onSubmit;

  const NameFormOverlay({
    super.key,
    required this.show,
    required this.onSubmit,
    this.isDark = false,
  });

  @override
  State<NameFormOverlay> createState() => _NameFormOverlayState();
}

class _NameFormOverlayState extends State<NameFormOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _overlayOpacity;
  late Animation<double> _formScale;
  late Animation<Offset> _formSlide;

  final TextEditingController _nameController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isFadingOut = false;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _overlayOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _formScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
          parent: _controller, curve: const Cubic(0.34, 1.56, 0.64, 1)),
    );
    _formSlide = Tween<Offset>(
      begin: const Offset(0, -0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(NameFormOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show && !oldWidget.show) {
      // Show after 2s delay (matching Vue: 3000ms → we use 2000ms for Flutter)
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) {
          setState(() => _isVisible = true);
          _controller.forward().then((_) {
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) _focusNode.requestFocus();
            });
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isFadingOut = true);
    _controller.reverse().then((_) {
      if (mounted) {
        widget.onSubmit(name);
        _nameController.clear();
        setState(() {
          _isVisible = false;
          _isFadingOut = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    final bool hasText = _nameController.text.trim().isNotEmpty;

    return AnimatedBuilder(
      animation: _overlayOpacity,
      builder: (context, child) {
        return Positioned.fill(
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Container(
              color: Colors.black
                  .withOpacity(0.3 * _overlayOpacity.value),
              child: child,
            ),
          ),
        );
      },
      child: Center(
        child: ScaleTransition(
          scale: _formScale,
          child: SlideTransition(
            position: _formSlide,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFF111111), width: 4),
                borderRadius: BorderRadius.circular(32),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xFF111111),
                    offset: Offset(12, 12),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Greeting
                  Text(
                    'Hello there!\nWhat can i call you?',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'BlackHanSans',
                      fontSize: 28,
                      color: Color(0xFF111111),
                      height: 1.3,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Input
                  _NameInput(
                    controller: _nameController,
                    focusNode: _focusNode,
                    onSubmitted: (_) => _submit(),
                    onChanged: (_) => setState(() {}),
                  ),

                  const SizedBox(height: 20),

                  // Continue button
                  _ContinueButton(
                    enabled: hasText,
                    onTap: _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NameInput extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onSubmitted;
  final ValueChanged<String> onChanged;

  const _NameInput({
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
    required this.onChanged,
  });

  @override
  State<_NameInput> createState() => _NameInputState();
}

class _NameInputState extends State<_NameInput> {
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(() {
      setState(() => _isFocused = widget.focusNode.hasFocus);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: _isFocused ? Colors.white : const Color(0xFFF5F5F5),
        border: Border.all(
          color: const Color(0xFF111111),
          width: 3,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: const Color(0xFF111111).withOpacity(0.1),
                  blurRadius: 0,
                  spreadRadius: 3,
                ),
              ]
            : [],
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        onSubmitted: widget.onSubmitted,
        onChanged: widget.onChanged,
        textInputAction: TextInputAction.done,
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 17,
          color: Color(0xFF111111),
        ),
        decoration: const InputDecoration(
          hintText: 'your name...',
          hintStyle: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 17,
            color: Color(0xFF999999),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
    );
  }
}

class _ContinueButton extends StatefulWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _ContinueButton({required this.enabled, required this.onTap});

  @override
  State<_ContinueButton> createState() => _ContinueButtonState();
}

class _ContinueButtonState extends State<_ContinueButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: widget.enabled
          ? (_) {
              setState(() => _pressed = false);
              widget.onTap();
            }
          : null,
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        transform: Matrix4.translationValues(
          _pressed ? 2 : 0,
          _pressed ? 2 : 0,
          0,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
        decoration: BoxDecoration(
          color: widget.enabled
              ? const Color(0xFF111111)
              : const Color(0xFF111111).withOpacity(0.4),
          border: Border.all(
            color: widget.enabled
                ? const Color(0xFF111111)
                : const Color(0xFF111111).withOpacity(0.4),
            width: 3,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: (widget.enabled && !_pressed)
              ? const [
                  BoxShadow(
                    color: Color(0xFF111111),
                    offset: Offset(6, 6),
                    blurRadius: 0,
                  )
                ]
              : widget.enabled
                  ? const [
                      BoxShadow(
                        color: Color(0xFF111111),
                        offset: Offset(2, 2),
                        blurRadius: 0,
                      )
                    ]
                  : [],
        ),
        child: Text(
          'CONTINUE',
          style: TextStyle(
            fontFamily: 'BlackHanSans',
            fontSize: 18,
            letterSpacing: 1,
            color: widget.enabled
                ? Colors.white
                : Colors.white.withOpacity(0.5),
          ),
        ),
      ),
    );
  }
}
