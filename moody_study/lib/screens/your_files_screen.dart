import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:moody_study/models/saved_file.dart';
import 'package:moody_study/services/material_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class YourFilesScreen extends StatefulWidget {
  const YourFilesScreen({super.key});

  @override
  State<YourFilesScreen> createState() => _YourFilesScreenState();
}

class _YourFilesScreenState extends State<YourFilesScreen> {
  bool _loading = true;
  String? _error;
  List<SavedFile> _files = [];

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final files = await MaterialService.fetchSavedFiles();
      if (mounted) {
        setState(() {
          _files = files;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<Directory> _resolveTempDirectory() async {
    if (kIsWeb) {
      throw UnsupportedError('Tidak mendukung operasi file sementara di web.');
    }

    try {
      return await getTemporaryDirectory();
    } on MissingPluginException {
      return Directory.systemTemp;
    } catch (_) {
      return Directory.systemTemp;
    }
  }

  Future<void> _openFile(SavedFile file) async {
    if (kIsWeb) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Membuka file tidak didukung pada web.')),
      );
      return;
    }

    try {
      final bytes = base64Decode(file.content);
      final tempDir = await _resolveTempDirectory();
      final safeName = file.fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final filePath = '${tempDir.path}/$safeName';
      final out = File(filePath);
      await out.writeAsBytes(bytes, flush: true);
      if (!mounted) return;
      await OpenFile.open(filePath);
    } on UnsupportedError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Operasi tidak didukung.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuka file: ${e.toString()}')),
      );
    }
  }

  Future<void> _confirmDelete(SavedFile file) async {
    final ok = await showDialog<bool?>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Hapus file'),
        content: Text('Hapus "${file.fileName}" dari Your Files?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(c).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (ok == true) {
      try {
        await MaterialService.deleteSavedFile(file.id);
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('File dihapus.')));
        await _loadFiles();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _renameFile(SavedFile file) async {
    final controller = TextEditingController(text: file.fileName);
    final ok = await showDialog<bool?>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Ganti nama file'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Nama file'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(c).pop(true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (ok == true) {
      final newName = controller.text.trim();
      if (newName.isEmpty) return;
      try {
        await MaterialService.renameSavedFile(
          id: file.id,
          newFileName: newName,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Nama file diperbarui.')));
        await _loadFiles();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal ganti nama: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        title: const Text(
          'Your Files',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (_loading) ...[
                const SizedBox(height: 24),
                const Center(child: CircularProgressIndicator()),
              ] else if (_error != null) ...[
                const SizedBox(height: 24),
                Text(
                  'Gagal memuat file: $_error',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadFiles,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF111111),
                  ),
                  child: const Text('Muat ulang'),
                ),
              ] else if (_files.isEmpty) ...[
                const SizedBox(height: 24),
                const Text(
                  'Belum ada file yang disimpan. Simpan PDF terlebih dahulu.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ] else ...[
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadFiles,
                    child: ListView.separated(
                      itemCount: _files.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final file = _files[index];
                        final savedAt = file.savedAt.replaceAll('T', ' ');
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFDDDDDD)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x11000000),
                                blurRadius: 6,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0E81E),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    file.fileType.toUpperCase(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF111111),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      file.fileName,
                                      style: const TextStyle(
                                        fontFamily: 'BlackHanSans',
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      savedAt,
                                      style: const TextStyle(
                                        fontFamily: 'Nunito',
                                        fontSize: 12,
                                        color: Color(0xFF666666),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextButton(
                                    onPressed: () => _openFile(file),
                                    child: const Text('Open'),
                                  ),
                                  IconButton(
                                    onPressed: () => _renameFile(file),
                                    icon: const Icon(Icons.edit, size: 18),
                                  ),
                                  IconButton(
                                    onPressed: () => _confirmDelete(file),
                                    icon: const Icon(Icons.close, size: 18),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
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
}
