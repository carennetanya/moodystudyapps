// Implementasi mobile/desktop: gunakan file di documents directory
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

const _fileName = 'profile_avatar.jpg';

Future<File> _file() async {
  final dir = await getApplicationDocumentsDirectory();
  return File('${dir.path}/$_fileName');
}

Future<void> platformSave(Uint8List bytes) async {
  final f = await _file();
  await f.writeAsBytes(bytes, flush: true);
}

Future<Uint8List?> platformLoad() async {
  final f = await _file();
  if (!await f.exists()) return null;
  final bytes = await f.readAsBytes();
  return bytes.isEmpty ? null : bytes;
}

Future<void> platformClear() async {
  final f = await _file();
  if (await f.exists()) await f.delete();
}