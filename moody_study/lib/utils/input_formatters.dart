import 'package:flutter/services.dart';

/// Converts every character to lowercase while preserving cursor position.
/// Use for username and email fields.
class LowercaseTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final lowered = newValue.text.toLowerCase();
    if (lowered == newValue.text) return newValue;
    return newValue.copyWith(
      text: lowered,
      selection: newValue.selection,
      composing: newValue.composing,
    );
  }
}

/// Rejects any input that would introduce a space character.
/// Returns oldValue unchanged when the new text contains a space.
/// Use for username only (email allows spaces so they can be flagged inline).
class NoSpaceTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.contains(' ')) return oldValue;
    return newValue;
  }
}

/// Lowercases every character but allows spaces through so the inline
/// validator can surface "email cannot contain spaces" to the user.
/// Use for email fields only.
class LowercaseEmailFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final lowered = newValue.text.toLowerCase();
    if (lowered == newValue.text) return newValue;
    return newValue.copyWith(
      text: lowered,
      selection: newValue.selection,
      composing: newValue.composing,
    );
  }
}
