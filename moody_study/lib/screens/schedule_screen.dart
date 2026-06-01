import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:file_picker/file_picker.dart';
import 'package:moody_study/services/notification_service.dart';
import 'package:moody_study/services/schedule_service.dart';
import 'package:moody_study/utils/app_localizations.dart';

// ── Color Palette (Moody Study Theme) ─────────────────────────────
const _kBg = Color(0xFFF5F5F0);
const _kBlack = Color(0xFF111111);
const _kYellow = Color(0xFFE5E81E);
const _kWhite = Color(0xFFFFFFFF);
const _kDoneGreen = Color(0xFF2ECC71);
const _kRed = Color(0xFFFF3B5C);
const _kPurple = Color(0xFF7C3AED);
const _kPurpleLight = Color(0xFFEDE9FE);

// ── Neobrutalist helpers ───────────────────────────────────────────
BoxDecoration _neoBox({
  Color bg = _kWhite,
  double radius = 12,
  double shadowOffset = 3,
}) =>
    BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: _kBlack, width: 2),
      boxShadow: [
        BoxShadow(
          color: _kBlack,
          offset: Offset(shadowOffset, shadowOffset),
          blurRadius: 0,
        ),
      ],
    );

InputDecoration _neoInput(String label) => InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        fontFamily: 'Nunito',
        fontWeight: FontWeight.w700,
        color: _kBlack,
        fontSize: 13,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      filled: true,
      fillColor: _kWhite,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _kBlack, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _kYellow, width: 2.5),
      ),
    );

// ── AI-generated schedule item (before save) ──────────────────────
class _AiScheduleItem {
  String subject;
  String studyDate;
  String startTime;
  String endTime;
  String? location;

  _AiScheduleItem({
    required this.subject,
    required this.studyDate,
    required this.startTime,
    required this.endTime,
    this.location,
  });
}

// ── Main Screen ────────────────────────────────────────────────────
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late Future<List<ScheduleItem>> _schedulesFuture;

  @override
  void initState() {
    super.initState();
    _refreshSchedules();
  }

  void _refreshSchedules() {
    setState(() {
      _schedulesFuture = ScheduleService.fetchSchedules();
    });
  }

  // ── Mode Selector Dialog ───────────────────────────────────────
  Future<void> _showModeSelector() async {
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: _neoBox(bg: _kBg, radius: 16, shadowOffset: 4),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _kYellow,
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: _kBlack, width: 1.5),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Tambah Jadwal',
                    style: TextStyle(
                      fontFamily: 'BlackHanSans',
                      fontSize: 20,
                      color: _kBlack,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Pilih cara mau atur jadwalnya',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  color: Color(0xFF666666),
                ),
              ),
              const SizedBox(height: 20),

              // Manual mode card
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                  _showCreateScheduleDialog();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: _neoBox(bg: _kWhite, radius: 12, shadowOffset: 3),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: _neoBox(bg: _kYellow, radius: 10, shadowOffset: 2),
                        child: const Icon(Icons.edit_calendar_rounded, color: _kBlack, size: 24),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Atur Sendiri',
                              style: TextStyle(
                                fontFamily: 'BlackHanSans',
                                fontSize: 16,
                                color: _kBlack,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Input jadwal secara manual satu per satu',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 12,
                                color: Color(0xFF666666),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: _kBlack),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Oddy AI mode card
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                  _showOddyModeDialog();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: _neoBox(bg: _kPurpleLight, radius: 12, shadowOffset: 3),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: _neoBox(bg: _kPurple, radius: 10, shadowOffset: 2),
                        child: const Icon(Icons.auto_awesome_rounded, color: _kWhite, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Pilih Oddy',
                                  style: TextStyle(
                                    fontFamily: 'BlackHanSans',
                                    fontSize: 16,
                                    color: _kBlack,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const _AiBadge(),
                              ],
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Input mata pelajaran, Oddy atur jadwalnya otomatis',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 12,
                                color: Color(0xFF666666),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: _kBlack),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Oddy AI Mode ───────────────────────────────────────────────
  Future<void> _showOddyModeDialog() async {
    final subjectListController = TextEditingController();
    final bulkController = TextEditingController();
    final List<String> subjects = [];
    String inputMode = 'single'; // 'single' | 'bulk' | 'upload'
    String? uploadedFileName;
    String? uploadedFileContent;
    String? uploadedFilePath; // path for pdf/docx (sent to backend)
    bool isProcessingFile = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Container(
            decoration: _neoBox(bg: _kBg, radius: 16, shadowOffset: 4),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height -
                  MediaQuery.of(ctx).viewInsets.bottom -
                  48,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _kPurple,
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: _kBlack, width: 1.5),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Asisten Oddy',
                      style: TextStyle(
                        fontFamily: 'BlackHanSans',
                        fontSize: 20,
                        color: _kBlack,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const _AiBadge(),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Masukin mata pelajaran/matkul kamu dulu',
                  style: TextStyle(fontFamily: 'Nunito', fontSize: 13, color: Color(0xFF666666)),
                ),
                const SizedBox(height: 16),

                // Toggle input mode
                Row(
                  children: [
                    _ModeTabButton(
                      label: 'Satu-satu',
                      isLeft: true,
                      isRight: false,
                      active: inputMode == 'single',
                      onTap: () => setS(() => inputMode = 'single'),
                    ),
                    _ModeTabButton(
                      label: 'Sekaligus',
                      isLeft: false,
                      isRight: false,
                      active: inputMode == 'bulk',
                      onTap: () => setS(() => inputMode = 'bulk'),
                    ),
                    _ModeTabButton(
                      label: 'Upload File',
                      isLeft: false,
                      isRight: true,
                      active: inputMode == 'upload',
                      onTap: () => setS(() => inputMode = 'upload'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Input area
                if (inputMode == 'single') ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: subjectListController,
                          style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, color: _kBlack),
                          decoration: _neoInput('Nama mata pelajaran / matkul'),
                          onSubmitted: (v) {
                            if (v.trim().isNotEmpty) {
                              setS(() {
                                subjects.add(v.trim());
                                subjectListController.clear();
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          if (subjectListController.text.trim().isNotEmpty) {
                            setS(() {
                              subjects.add(subjectListController.text.trim());
                              subjectListController.clear();
                            });
                          }
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: _neoBox(bg: _kYellow, radius: 10, shadowOffset: 2),
                          child: const Icon(Icons.add_rounded, color: _kBlack),
                        ),
                      ),
                    ],
                  ),
                ] else if (inputMode == 'bulk') ...[
                  TextField(
                    controller: bulkController,
                    maxLines: 3,
                    style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, color: _kBlack),
                    decoration: _neoInput('Matematika, Fisika, Kimia, ...').copyWith(
                      hintText: 'Pisahkan dengan koma',
                      hintStyle: const TextStyle(fontFamily: 'Nunito', color: Color(0xFFAAAAAA), fontSize: 12),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      final items = bulkController.text
                          .split(',')
                          .map((s) => s.trim())
                          .where((s) => s.isNotEmpty)
                          .toList();
                      setS(() {
                        for (final item in items) {
                          if (!subjects.contains(item)) subjects.add(item);
                        }
                        bulkController.clear();
                      });
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: _neoBox(bg: _kYellow, radius: 8, shadowOffset: 2),
                      alignment: Alignment.center,
                      child: const Text(
                        'Tambah Semua',
                        style: TextStyle(fontFamily: 'BlackHanSans', fontSize: 13, color: _kBlack),
                      ),
                    ),
                  ),
                ] else ...[
                  // Upload File section
                  GestureDetector(
                    onTap: () async {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['txt', 'csv', 'pdf', 'docx'],
                        withData: false, // never load bytes into memory
                      );
                      if (result != null && result.files.isNotEmpty) {
                        final file = result.files.first;
                        final ext = file.name.split('.').last.toLowerCase();
                        setS(() {
                          uploadedFileName = file.name;
                          uploadedFilePath = file.path;
                          // txt/csv content can be read from path
                          uploadedFileContent = (ext == 'txt' || ext == 'csv')
                              ? 'text' // marker: needs path-based read
                              : null;  // pdf/docx: backend handles it
                        });
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: uploadedFileName != null ? _kPurpleLight : _kWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: uploadedFileName != null ? _kPurple : _kBlack.withOpacity(0.3),
                          width: 2,
                          style: uploadedFileName != null ? BorderStyle.solid : BorderStyle.solid,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            uploadedFileName != null ? Icons.check_circle_rounded : Icons.upload_file_rounded,
                            size: 40,
                            color: uploadedFileName != null ? _kPurple : _kBlack.withOpacity(0.4),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            uploadedFileName != null ? uploadedFileName! : 'Tap untuk upload file jadwal',
                            style: TextStyle(
                              fontFamily: 'BlackHanSans',
                              fontSize: 13,
                              color: uploadedFileName != null ? _kPurple : _kBlack.withOpacity(0.5),
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            uploadedFileName != null ? 'Ketuk untuk ganti file' : 'Format: .txt .csv .pdf .docx',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 11,
                              color: _kBlack.withOpacity(0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (uploadedFileName != null) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: isProcessingFile
                          ? null
                          : () async {
                              if (uploadedFilePath == null) return;
                              setS(() => isProcessingFile = true);
                              try {
                                final parsed = await ScheduleService.parseSubjectsFromFile(
                                  uploadedFilePath!,
                                  uploadedFileName!,
                                );
                                setS(() {
                                  for (final item in parsed) {
                                    if (!subjects.contains(item)) subjects.add(item);
                                  }
                                  uploadedFileName = null;
                                  uploadedFilePath = null;
                                  uploadedFileContent = null;
                                  isProcessingFile = false;
                                  inputMode = 'single';
                                });
                              } catch (e) {
                                setS(() => isProcessingFile = false);
                                _showErrorSnack('Gagal proses file: $e');
                              }
                            },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: _neoBox(bg: _kPurple, radius: 8, shadowOffset: 2),
                        alignment: Alignment.center,
                        child: isProcessingFile
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: _kWhite,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.auto_awesome_rounded, size: 15, color: _kWhite),
                                  SizedBox(width: 6),
                                  Text(
                                    'Proses File',
                                    style: TextStyle(
                                      fontFamily: 'BlackHanSans',
                                      fontSize: 13,
                                      color: _kWhite,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ],

                const SizedBox(height: 12),

                // Subject chips list
                if (subjects.isNotEmpty) ...[
                  Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: subjects.map((s) => ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 220),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: _kPurpleLight,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _kPurple, width: 1.5),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    s,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'Nunito',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                      color: _kPurple,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () => setS(() => subjects.remove(s)),
                                  child: const Icon(Icons.close_rounded, size: 14, color: _kPurple),
                                ),
                              ],
                            ),
                          ),
                        )).toList(),
                  ),
                  const SizedBox(height: 12),
                ],

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(ctx).pop(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: _neoBox(bg: _kWhite, radius: 8),
                          alignment: Alignment.center,
                          child: const Text(
                            'Batal',
                            style: TextStyle(fontFamily: 'BlackHanSans', fontSize: 14, color: _kBlack),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: subjects.isEmpty
                            ? null
                            : () {
                                Navigator.of(ctx).pop();
                                _showOddyPreferencesDialog(subjects);
                              },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: _neoBox(
                            bg: subjects.isEmpty ? const Color(0xFFCCCCCC) : _kPurple,
                            radius: 8,
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.auto_awesome_rounded, size: 15,
                                  color: subjects.isEmpty ? _kBlack : _kWhite),
                              const SizedBox(width: 6),
                              Text(
                                'Lanjut',
                                style: TextStyle(
                                  fontFamily: 'BlackHanSans',
                                  fontSize: 14,
                                  color: subjects.isEmpty ? _kBlack : _kWhite,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Oddy Preferences Dialog ─────────────────────────────────────
  Future<void> _showOddyPreferencesDialog(List<String> subjects) async {
    final List<bool> selectedDays = List.filled(7, true); // Sen-Min
    final List<String> dayNames = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    String startHour = '08:00';
    String endHour = '22:00';
    int durationMinutes = 90;
    final durationOptions = [60, 90, 120];

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: _neoBox(bg: _kBg, radius: 16, shadowOffset: 4),
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 24,
                        decoration: BoxDecoration(
                          color: _kPurple,
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: _kBlack, width: 1.5),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Preferensi Belajar',
                        style: TextStyle(
                          fontFamily: 'BlackHanSans',
                          fontSize: 18,
                          color: _kBlack,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${subjects.length} mata pelajaran siap dijadwalkan oleh Oddy',
                    style: const TextStyle(fontFamily: 'Nunito', fontSize: 12, color: Color(0xFF666666)),
                  ),
                  const SizedBox(height: 18),

                  // Hari belajar
                  const Text(
                    'Hari yang tersedia',
                    style: TextStyle(fontFamily: 'BlackHanSans', fontSize: 13, color: _kBlack),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(7, (i) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: i < 6 ? 4 : 0),
                        child: GestureDetector(
                          onTap: () => setS(() => selectedDays[i] = !selectedDays[i]),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: selectedDays[i] ? _kBlack : _kWhite,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _kBlack, width: 1.5),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              dayNames[i],
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                                color: selectedDays[i] ? _kYellow : _kBlack,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )),
                  ),
                  const SizedBox(height: 16),

                  // Jam mulai belajar
                  const Text(
                    'Jam mulai paling awal',
                    style: TextStyle(fontFamily: 'BlackHanSans', fontSize: 13, color: _kBlack),
                  ),
                  const SizedBox(height: 8),
                  _NeoPickerButton(
                    label: startHour,
                    icon: Icons.access_time_rounded,
                    hasValue: true,
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: ctx,
                        initialTime: TimeOfDay(
                          hour: int.parse(startHour.split(':')[0]),
                          minute: int.parse(startHour.split(':')[1]),
                        ),
                      );
                      if (picked != null) {
                        setS(() => startHour = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Jam akhir belajar
                  const Text(
                    'Jam selesai paling akhir',
                    style: TextStyle(fontFamily: 'BlackHanSans', fontSize: 13, color: _kBlack),
                  ),
                  const SizedBox(height: 8),
                  _NeoPickerButton(
                    label: endHour,
                    icon: Icons.access_time_filled_rounded,
                    hasValue: true,
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: ctx,
                        initialTime: TimeOfDay(
                          hour: int.parse(endHour.split(':')[0]),
                          minute: int.parse(endHour.split(':')[1]),
                        ),
                      );
                      if (picked != null) {
                        setS(() => endHour = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Durasi per sesi
                  const Text(
                    'Durasi per sesi belajar',
                    style: TextStyle(fontFamily: 'BlackHanSans', fontSize: 13, color: _kBlack),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: durationOptions.map((d) {
                      final selected = durationMinutes == d;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: d != durationOptions.last ? 8 : 0),
                          child: GestureDetector(
                            onTap: () => setS(() => durationMinutes = d),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: selected ? _kYellow : _kWhite,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: selected ? _kBlack : _kBlack.withOpacity(0.3), width: 1.5),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${d}m',
                                style: const TextStyle(
                                  fontFamily: 'BlackHanSans',
                                  fontSize: 13,
                                  color: _kBlack,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.of(ctx).pop(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: _neoBox(bg: _kWhite, radius: 8),
                            alignment: Alignment.center,
                            child: const Text(
                              'Batal',
                              style: TextStyle(fontFamily: 'BlackHanSans', fontSize: 14, color: _kBlack),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
                          onTap: () {
                            final availDays = <String>[];
                            for (int i = 0; i < 7; i++) {
                              if (selectedDays[i]) availDays.add(dayNames[i]);
                            }
                            if (availDays.isEmpty) return;
                            Navigator.of(ctx).pop();
                            _runOddyGeneration(
                              subjects: subjects,
                              availableDays: availDays,
                              startHour: startHour,
                              endHour: endHour,
                              durationMinutes: durationMinutes,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: _neoBox(bg: _kPurple, radius: 8),
                            alignment: Alignment.center,
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.auto_awesome_rounded, size: 15, color: _kWhite),
                                SizedBox(width: 6),
                                Text(
                                  'Generate Jadwal',
                                  style: TextStyle(fontFamily: 'BlackHanSans', fontSize: 13, color: _kWhite),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Oddy AI Generation ─────────────────────────────────────────
  Future<void> _runOddyGeneration({
    required List<String> subjects,
    required List<String> availableDays,
    required String startHour,
    required String endHour,
    required int durationMinutes,
  }) async {
    // Show loading dialog
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: _neoBox(bg: _kBg, radius: 16, shadowOffset: 4),
          padding: const EdgeInsets.all(28),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: _kPurple, strokeWidth: 3),
              SizedBox(height: 16),
              Text(
                'Oddy lagi mikir...',
                style: TextStyle(fontFamily: 'BlackHanSans', fontSize: 16, color: _kBlack),
              ),
              SizedBox(height: 4),
              Text(
                'Lagi nyusun jadwal belajar terbaik buat kamu ✨',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Nunito', fontSize: 12, color: Color(0xFF666666)),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final dayMap = {
        'Sen': 'Senin', 'Sel': 'Selasa', 'Rab': 'Rabu',
        'Kam': 'Kamis', 'Jum': 'Jumat', 'Sab': 'Sabtu', 'Min': 'Minggu'
      };
      final daysFull = availableDays.map((d) => dayMap[d] ?? d).toList();

      final aiScheduleItems = (await ScheduleService.generateAutoSchedule(
        subjects: subjects,
        availableDays: daysFull,
        startHour: startHour,
        endHour: endHour,
        durationMinutes: durationMinutes,
        daysAhead: 7,
      ))
          .map((scheduleItem) => _AiScheduleItem(
                subject: scheduleItem.subject,
                studyDate: scheduleItem.studyDate,
                startTime: scheduleItem.startTime,
                endTime: scheduleItem.endTime,
                location: scheduleItem.location,
              ))
          .toList();

      if (!mounted) return;
      Navigator.of(context).pop(); // close loading

      if (aiScheduleItems.isEmpty) {
        _showErrorSnack('Oddy ga bisa buat jadwal. Coba lagi!');
        return;
      }

      _showOddyResultDialog(aiScheduleItems);
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        _showErrorSnack('Terjadi kesalahan: $e');
      }
    }
  }

  void _showErrorSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700)),
        backgroundColor: _kRed,
      ),
    );
  }

  // ── Oddy Result / Edit Dialog ──────────────────────────────────
  Future<void> _showOddyResultDialog(List<_AiScheduleItem> items) async {
    final editableItems = List<_AiScheduleItem>.from(items);

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: _neoBox(bg: _kBg, radius: 16, shadowOffset: 4),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 24,
                            decoration: BoxDecoration(
                              color: _kPurple,
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(color: _kBlack, width: 1.5),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Flexible(
                            child: Text(
                              'Jadwal dari Oddy',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'BlackHanSans',
                                fontSize: 18,
                                color: _kBlack,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _kPurpleLight,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _kPurple, width: 1.5),
                            ),
                            child: Text(
                              '${editableItems.length} sesi',
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                                color: _kPurple,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tap jadwal untuk edit sebelum disimpan',
                        style: TextStyle(fontFamily: 'Nunito', fontSize: 12, color: Color(0xFF666666)),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),

                // List
                Flexible(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: editableItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final item = editableItems[i];
                      return GestureDetector(
                        onTap: () async {
                          await _editAiScheduleItem(ctx, item);
                          setS(() {});
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _kWhite,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _kPurple.withOpacity(0.4), width: 1.5),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: _kPurpleLight,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: _kPurple, width: 1.5),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${i + 1}',
                                  style: const TextStyle(
                                    fontFamily: 'BlackHanSans',
                                    fontSize: 15,
                                    color: _kPurple,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.subject,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontFamily: 'BlackHanSans',
                                        fontSize: 14,
                                        color: _kBlack,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today_rounded, size: 11, color: Color(0xFF888888)),
                                        const SizedBox(width: 3),
                                        Expanded(
                                          child: Text(
                                            '${item.studyDate}  ·  ${item.startTime} – ${item.endTime}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontFamily: 'Nunito',
                                              fontSize: 11,
                                              color: Color(0xFF555555),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.edit_rounded, size: 14, color: Color(0xFFAAAAAA)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Bottom actions
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.of(ctx).pop(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: _neoBox(bg: _kWhite, radius: 8),
                            alignment: Alignment.center,
                            child: const Text(
                              'Batal',
                              style: TextStyle(fontFamily: 'BlackHanSans', fontSize: 14, color: _kBlack),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
                          onTap: () async {
                            Navigator.of(ctx).pop();
                            await _saveAllAiSchedules(editableItems);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: _neoBox(bg: _kPurple, radius: 8),
                            alignment: Alignment.center,
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.save_rounded, size: 15, color: _kWhite),
                                SizedBox(width: 6),
                                Text(
                                  'Simpan Semua',
                                  style: TextStyle(fontFamily: 'BlackHanSans', fontSize: 14, color: _kWhite),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Edit single AI schedule item inline ────────────────────────
  Future<void> _editAiScheduleItem(BuildContext ctx, _AiScheduleItem item) async {
    final subjectCtrl = TextEditingController(text: item.subject);
    final locationCtrl = TextEditingController(text: item.location ?? '');
    DateTime? date = _tryParseDate(item.studyDate);
    TimeOfDay? start = _tryParseTime(item.startTime);
    TimeOfDay? end = _tryParseTime(item.endTime);

    await showDialog<void>(
      context: ctx,
      builder: (innerCtx) => StatefulBuilder(
        builder: (innerCtx, setS) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: _neoBox(bg: _kBg, radius: 16, shadowOffset: 4),
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Edit Jadwal',
                    style: TextStyle(fontFamily: 'BlackHanSans', fontSize: 18, color: _kBlack),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: subjectCtrl,
                    style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, color: _kBlack),
                    decoration: _neoInput('Mata Pelajaran'),
                  ),
                  const SizedBox(height: 10),
                  _NeoPickerButton(
                    label: date == null ? 'Pilih Tanggal' : _formatDisplayDate(date!),
                    icon: Icons.calendar_today_rounded,
                    hasValue: date != null,
                    onTap: () async {
                      final p = await showDatePicker(
                        context: innerCtx,
                        initialDate: date ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (p != null) setS(() => date = p);
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _NeoPickerButton(
                          label: start == null ? 'Mulai' : _formatDisplayTime(start!),
                          icon: Icons.access_time_rounded,
                          hasValue: start != null,
                          onTap: () async {
                            final p = await showTimePicker(
                              context: innerCtx,
                              initialTime: start ?? const TimeOfDay(hour: 8, minute: 0),
                            );
                            if (p != null) setS(() => start = p);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _NeoPickerButton(
                          label: end == null ? 'Selesai' : _formatDisplayTime(end!),
                          icon: Icons.access_time_filled_rounded,
                          hasValue: end != null,
                          onTap: () async {
                            final p = await showTimePicker(
                              context: innerCtx,
                              initialTime: end ?? const TimeOfDay(hour: 9, minute: 0),
                            );
                            if (p != null) setS(() => end = p);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: locationCtrl,
                    style: const TextStyle(fontFamily: 'Nunito', color: _kBlack),
                    decoration: _neoInput('Lokasi (opsional)'),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {
                      if (subjectCtrl.text.trim().isNotEmpty) {
                        item.subject = subjectCtrl.text.trim();
                        if (date != null) item.studyDate = _formatIsoDate(date!);
                        if (start != null) item.startTime = _formatIsoTime(start!);
                        if (end != null) item.endTime = _formatIsoTime(end!);
                        item.location = locationCtrl.text.trim().isEmpty ? null : locationCtrl.text.trim();
                      }
                      Navigator.of(innerCtx).pop();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: _neoBox(bg: _kPurple, radius: 8),
                      alignment: Alignment.center,
                      child: const Text(
                        'Simpan Perubahan',
                        style: TextStyle(fontFamily: 'BlackHanSans', fontSize: 14, color: _kWhite),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Save all AI schedules ──────────────────────────────────────
  Future<void> _saveAllAiSchedules(List<_AiScheduleItem> items) async {
    int saved = 0;
    for (final item in items) {
      try {
        final created = await ScheduleService.createSchedule(
          subject: item.subject,
          studyDate: item.studyDate,
          startTime: item.startTime,
          endTime: item.endTime,
          location: item.location,
          mood: null,
        );
        await NotificationService.instance.scheduleStudyNotification(
          created.id,
          created.subject,
          _parseScheduleDateTime(created.studyDate, created.startTime),
          mood: created.mood ?? 'happy',
          location: created.location ?? 'home',
          durationMinutes: _calcDurationMinutes(created.startTime, created.endTime),
        );
    
        saved++;
      } catch (_) {}
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$saved jadwal berhasil disimpan! 🎉',
            style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700),
          ),
          backgroundColor: _kPurple,
        ),
      );
      _refreshSchedules();
    }
  }

  // ── Create Manual Dialog ───────────────────────────────────────
  Future<void> _showCreateScheduleDialog() async {
    final localizations = AppLocalizations.of(context, listen: false);
    final subjectController = TextEditingController();
    final locationController = TextEditingController();
    final moodController = TextEditingController();
    DateTime? studyDate;
    TimeOfDay? startTime;
    TimeOfDay? endTime;
    String? errorText;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                decoration: _neoBox(bg: _kBg, radius: 16, shadowOffset: 4),
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title bar
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 24,
                            decoration: BoxDecoration(
                              color: _kYellow,
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(color: _kBlack, width: 1.5),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            localizations.scheduleCreateNew,
                            style: const TextStyle(
                              fontFamily: 'BlackHanSans',
                              fontSize: 20,
                              color: _kBlack,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Subject
                      TextField(
                        controller: subjectController,
                        style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, color: _kBlack),
                        decoration: _neoInput(localizations.scheduleSubject),
                      ),
                      const SizedBox(height: 12),

                      // Date picker
                      _NeoPickerButton(
                        label: studyDate == null
                            ? localizations.scheduleStudyDate
                            : _formatDisplayDate(studyDate!),
                        icon: Icons.calendar_today_rounded,
                        hasValue: studyDate != null,
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: studyDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) setDialogState(() => studyDate = picked);
                        },
                      ),
                      const SizedBox(height: 12),

                      // Time row
                      Row(
                        children: [
                          Expanded(
                            child: _NeoPickerButton(
                              label: startTime == null
                                  ? localizations.scheduleStartTime
                                  : _formatDisplayTime(startTime!),
                              icon: Icons.access_time_rounded,
                              hasValue: startTime != null,
                              onTap: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: startTime ?? const TimeOfDay(hour: 8, minute: 0),
                                );
                                if (picked != null) setDialogState(() => startTime = picked);
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _NeoPickerButton(
                              label: endTime == null
                                  ? localizations.scheduleEndTime
                                  : _formatDisplayTime(endTime!),
                              icon: Icons.access_time_filled_rounded,
                              hasValue: endTime != null,
                              onTap: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: endTime ?? const TimeOfDay(hour: 9, minute: 0),
                                );
                                if (picked != null) setDialogState(() => endTime = picked);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Location
                      TextField(
                        controller: locationController,
                        style: const TextStyle(fontFamily: 'Nunito', color: _kBlack),
                        decoration: _neoInput(localizations.scheduleLocation),
                      ),
                      const SizedBox(height: 12),

                      // Mood
                      TextField(
                        controller: moodController,
                        style: const TextStyle(fontFamily: 'Nunito', color: _kBlack),
                        decoration: _neoInput(localizations.scheduleMood),
                      ),

                      // Error
                      if (errorText != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _kRed.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _kRed, width: 1.5),
                          ),
                          child: Text(
                            errorText!,
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              color: _kRed,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Actions
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: _neoBox(bg: _kWhite, radius: 8),
                                alignment: Alignment.center,
                                child: Text(
                                  localizations.cancel,
                                  style: const TextStyle(
                                    fontFamily: 'BlackHanSans',
                                    fontSize: 14,
                                    color: _kBlack,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                if (subjectController.text.trim().isEmpty) {
                                  setDialogState(() => errorText = '${localizations.scheduleSubject} is required');
                                  return;
                                }
                                if (studyDate == null || startTime == null || endTime == null) {
                                  setDialogState(() => errorText = localizations.error);
                                  return;
                                }
                                if (!_isTimeRangeValid(startTime!, endTime!)) {
                                  setDialogState(() => errorText = localizations.scheduleTimeRangeError);
                                  return;
                                }
                                try {
                                  final created = await ScheduleService.createSchedule(
                                    subject: subjectController.text.trim(),
                                    studyDate: _formatIsoDate(studyDate!),
                                    startTime: _formatIsoTime(startTime!),
                                    endTime: _formatIsoTime(endTime!),
                                    location: locationController.text.trim().isEmpty ? null : locationController.text.trim(),
                                    mood: moodController.text.trim().isEmpty ? null : moodController.text.trim(),
                                  );
                                  await NotificationService.instance.scheduleStudyNotification(
                                    created.id,
                                    created.subject,
                                    _parseScheduleDateTime(created.studyDate, created.startTime),
                                    mood: created.mood ?? 'happy',
                                    location: created.location ?? 'home',
                                    durationMinutes: _calcDurationMinutes(created.startTime, created.endTime),
                                  );
                                  if (!mounted) return;
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        localizations.scheduleCreated,
                                        style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700),
                                      ),
                                      backgroundColor: _kYellow,
                                    ),
                                  );
                                  _refreshSchedules();
                                } catch (e) {
                                  setDialogState(() => errorText = e.toString());
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: _neoBox(bg: _kYellow, radius: 8),
                                alignment: Alignment.center,
                                child: Text(
                                  localizations.save,
                                  style: const TextStyle(
                                    fontFamily: 'BlackHanSans',
                                    fontSize: 14,
                                    color: _kBlack,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Delete confirm ─────────────────────────────────────────────
  Future<void> _confirmDelete(ScheduleItem item) async {
    final localizations = AppLocalizations.of(context, listen: false);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: _neoBox(bg: _kBg, radius: 16, shadowOffset: 4),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.delete_rounded, size: 40, color: _kRed),
              const SizedBox(height: 12),
              Text(
                localizations.delete,
                style: const TextStyle(
                  fontFamily: 'BlackHanSans',
                  fontSize: 20,
                  color: _kBlack,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${localizations.scheduleDelete} "${item.subject}"?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  color: _kBlack,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: _neoBox(bg: _kWhite, radius: 8),
                        alignment: Alignment.center,
                        child: Text(
                          localizations.cancel,
                          style: const TextStyle(fontFamily: 'BlackHanSans', fontSize: 14, color: _kBlack),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: _neoBox(bg: _kRed, radius: 8),
                        alignment: Alignment.center,
                        child: Text(
                          localizations.delete,
                          style: const TextStyle(fontFamily: 'BlackHanSans', fontSize: 14, color: _kWhite),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed == true) {
      await NotificationService.instance.cancelNotification(item.id);
      await ScheduleService.deleteSchedule(item.id);
      _refreshSchedules();
    }
  }

  // ── Helpers ────────────────────────────────────────────────────
  String _formatIsoDate(DateTime v) =>
      '${v.year.toString().padLeft(4, '0')}-${v.month.toString().padLeft(2, '0')}-${v.day.toString().padLeft(2, '0')}';

  String _formatDisplayDate(DateTime v) =>
      '${v.day.toString().padLeft(2, '0')}/${v.month.toString().padLeft(2, '0')}/${v.year.toString().padLeft(4, '0')}';

  String _formatIsoTime(TimeOfDay v) =>
      '${v.hour.toString().padLeft(2, '0')}:${v.minute.toString().padLeft(2, '0')}';

  String _formatDisplayTime(TimeOfDay v) =>
      '${v.hour.toString().padLeft(2, '0')}:${v.minute.toString().padLeft(2, '0')}';

  bool _isTimeRangeValid(TimeOfDay start, TimeOfDay end) =>
      (end.hour * 60 + end.minute) > (start.hour * 60 + start.minute);

  DateTime _parseScheduleDateTime(String isoDate, String time) {
    final date = DateTime.parse(isoDate);
    final parts = time.split(':');
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  int _calcDurationMinutes(String startTime, String endTime) {
    try {
      final sParts = startTime.split(':');
      final eParts = endTime.split(':');
      final start = int.parse(sParts[0]) * 60 + int.parse(sParts[1]);
      final end   = int.parse(eParts[0]) * 60 + int.parse(eParts[1]);
      final diff  = end - start;
      return diff > 0 ? diff : 60;
    } catch (_) {
      return 60;
    }
  }

  DateTime? _tryParseDate(String s) {
    try {
      return DateTime.parse(s);
    } catch (_) {
      return null;
    }
  }

  TimeOfDay? _tryParseTime(String s) {
    try {
      final parts = s.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (_) {
      return null;
    }
  }

  // ── Build ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kYellow,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const Icon(Icons.arrow_back_rounded, color: _kBlack),
        ),
        title: Text(
          l.scheduleTitle,
          style: const TextStyle(
            fontFamily: 'BlackHanSans',
            color: _kBlack,
            letterSpacing: 0.5,
            fontSize: 20,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(height: 2, color: _kBlack),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    l.scheduleSubtitle,
                    style: const TextStyle(
                      fontFamily: 'BlackHanSans',
                      fontSize: 16,
                      color: _kBlack,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                // Add button → opens mode selector
                GestureDetector(
                  onTap: _showModeSelector,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: _neoBox(bg: _kYellow, radius: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_rounded, size: 18, color: _kBlack),
                        const SizedBox(width: 6),
                        Text(
                          l.scheduleAddButton,
                          style: const TextStyle(
                            fontFamily: 'BlackHanSans',
                            fontSize: 13,
                            color: _kBlack,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Schedule list
            Expanded(
              child: FutureBuilder<List<ScheduleItem>>(
                future: _schedulesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: _kBlack, strokeWidth: 2.5),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('😵', style: TextStyle(fontSize: 40)),
                          const SizedBox(height: 12),
                          Text(
                            l.error,
                            style: const TextStyle(
                              fontFamily: 'BlackHanSans',
                              fontSize: 16,
                              color: _kBlack,
                            ),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: _refreshSchedules,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: _neoBox(bg: _kYellow, radius: 8),
                              child: Text(
                                l.retry,
                                style: const TextStyle(fontFamily: 'BlackHanSans', fontSize: 14, color: _kBlack),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final schedules = snapshot.data ?? [];

                  if (schedules.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_month_rounded, size: 64, color: _kBlack),
                          const SizedBox(height: 16),
                          Text(
                            l.scheduleNoSchedules,
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF666666),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: schedules.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final schedule = schedules[index];
                      return _ScheduleCard(
                        schedule: schedule,
                        l: l,
                        onComplete: () async {
                          await ScheduleService.completeSchedule(schedule.id);
                          await NotificationService.instance.cancelNotification(schedule.id);
                          _refreshSchedules();
                        },
                        onDelete: () => _confirmDelete(schedule),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── AI Badge ───────────────────────────────────────────────────────
class _AiBadge extends StatelessWidget {
  const _AiBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _kPurple,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _kBlack, width: 1),
      ),
      child: const Text(
        'AI',
        style: TextStyle(
          fontFamily: 'BlackHanSans',
          fontSize: 9,
          color: _kWhite,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ── Schedule Card ──────────────────────────────────────────────────
class _ScheduleCard extends StatelessWidget {
  final ScheduleItem schedule;
  final AppLocalizations l;
  final VoidCallback onComplete;
  final VoidCallback onDelete;

  const _ScheduleCard({
    required this.schedule,
    required this.l,
    required this.onComplete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bool done = schedule.isCompleted;
    return Container(
      decoration: _neoBox(
        bg: done ? const Color(0xFFF0FFF4) : _kWhite,
        radius: 14,
        shadowOffset: 4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Yellow/Green top accent bar
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: done ? _kDoneGreen : _kYellow,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Subject + done badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        schedule.subject,
                        style: const TextStyle(
                          fontFamily: 'BlackHanSans',
                          fontSize: 18,
                          color: _kBlack,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    if (done)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _kDoneGreen,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _kBlack, width: 1.5),
                        ),
                        child: const Text(
                          'Done ✓',
                          style: TextStyle(
                            fontFamily: 'BlackHanSans',
                            color: _kWhite,
                            fontSize: 11,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Date & time chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _kBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _kBlack.withOpacity(0.2), width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 13, color: _kBlack),
                      const SizedBox(width: 5),
                      Text(
                        '${schedule.studyDate}  ·  ${schedule.startTime} – ${schedule.endTime}',
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: _kBlack,
                        ),
                      ),
                    ],
                  ),
                ),

                // Location
                if ((schedule.location ?? '').isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF888888)),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          schedule.location!,
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 13,
                            color: Color(0xFF555555),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                // Mood
                if ((schedule.mood ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.mood_rounded, size: 14, color: Color(0xFF888888)),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          schedule.mood!,
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 13,
                            color: Color(0xFF555555),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 12),

                // Action row
                Row(
                  children: [
                    if (!done)
                      GestureDetector(
                        onTap: onComplete,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: _neoBox(bg: _kBlack, radius: 8, shadowOffset: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_rounded, size: 15, color: _kYellow),
                              const SizedBox(width: 6),
                              Text(
                                l.scheduleComplete,
                                style: const TextStyle(
                                  fontFamily: 'BlackHanSans',
                                  fontSize: 13,
                                  color: _kYellow,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const Spacer(),
                    GestureDetector(
                      onTap: onDelete,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _kWhite,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _kRed.withOpacity(0.5), width: 1.5),
                        ),
                        child: const Icon(Icons.delete_outline_rounded, size: 18, color: _kRed),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Neo Picker Button ──────────────────────────────────────────────
class _NeoPickerButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool hasValue;
  final VoidCallback onTap;

  const _NeoPickerButton({
    required this.label,
    required this.icon,
    required this.hasValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: hasValue ? _kYellow.withOpacity(0.3) : _kWhite,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: hasValue ? _kYellow : _kBlack.withOpacity(0.4), width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: _kBlack),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: _kBlack,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Mode Tab Button ────────────────────────────────────────────────
class _ModeTabButton extends StatelessWidget {
  final String label;
  final bool isLeft;
  final bool isRight;
  final bool active;
  final VoidCallback onTap;

  const _ModeTabButton({
    required this.label,
    required this.isLeft,
    required this.isRight,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: active ? _kBlack : _kWhite,
            borderRadius: BorderRadius.horizontal(
              left: isLeft ? const Radius.circular(8) : Radius.zero,
              right: isRight ? const Radius.circular(8) : Radius.zero,
            ),
            border: Border.all(color: _kBlack, width: 2),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w700,
              fontSize: 11,
              color: active ? _kYellow : _kBlack,
            ),
          ),
        ),
      ),
    );
  }
}