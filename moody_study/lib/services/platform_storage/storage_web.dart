// Implementasi web: gunakan localStorage dari dart:html
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';

const _key = 'profile_avatar_b64';

Future<void> platformSave(Uint8List bytes) async {
  html.window.localStorage[_key] = base64Encode(bytes);
}

Future<Uint8List?> platformLoad() async {
  final raw = html.window.localStorage[_key];
  if (raw == null || raw.isEmpty) return null;
  return base64Decode(raw);
}

Future<void> platformClear() async {
  html.window.localStorage.remove(_key);
}