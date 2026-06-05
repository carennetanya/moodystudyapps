import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Enum bahasa yang didukung
enum AppLanguage { id, en }

/// ChangeNotifier untuk bahasa aktif.
/// Daftarkan di main.dart dengan ChangeNotifierProvider.
class LanguageProvider extends ChangeNotifier {
  AppLanguage _language = AppLanguage.id;

  AppLanguage get language => _language;
  bool get isEnglish => _language == AppLanguage.en;

  void toggle() {
    _language = _language == AppLanguage.id ? AppLanguage.en : AppLanguage.id;
    notifyListeners();
  }

  void setLanguage(AppLanguage lang) {
    if (_language != lang) {
      _language = lang;
      notifyListeners();
    }
  }
}

/// Semua string UI yang bisa ditranslate.
/// Akses via: AppLocalizations.of(context).someKey
class AppLocalizations {
  final AppLanguage language;
  const AppLocalizations(this.language);

  bool get isId => language == AppLanguage.id;

  /// Akses via Provider — otomatis rebuild saat bahasa berubah.
  /// Gunakan listen: false di dalam async method / event handler.
  static AppLocalizations of(BuildContext context, {bool listen = true}) {
    final lang = listen
        ? context.watch<LanguageProvider>().language
        : context.read<LanguageProvider>().language;
    return AppLocalizations(lang);
  }

  // ─── Login Screen ─────────────────────────────────────────────────
  String get loginTitle => isId ? 'Masuk ke Moody Study' : 'Login to Moody Study';
  String get loginSignIn => isId ? 'MASUK SEKARANG' : 'SIGN IN NOW';
  String get loginButton => isId ? 'Masuk' : 'Login';
  String get loginWelcomeBack => isId ? 'Selamat datang kembali' : 'Welcome back';
  String get loginEmail => isId ? 'Email' : 'Email';
  String get loginPassword => isId ? 'Kata Sandi' : 'Password';
  String get loginNoAccount => isId ? 'Belum punya akun? Daftar' : "Don't have an account? Sign up";
  String get loginEmailRequired => isId ? 'Email wajib diisi!' : 'Email is required!';
  String get loginInvalidEmail => isId ? 'Email tidak valid!' : 'Invalid email!';
  String get loginPasswordShort => isId ? 'Password minimal 6 karakter!' : 'Password must be at least 6 characters!';
  String get loginEmailHint => 'email@example.com';
  String get loginPasswordHint => isId ? 'min. 6 karakter' : 'min. 6 characters';

  // ─── Register Screen ──────────────────────────────────────────────
  String get registerTitle => isId ? 'Buat Akun' : 'Create Account';
  String get registerButton => isId ? 'Daftar' : 'Register';
  String get registerName => isId ? 'Nama' : 'Name';
  String get registerUsername => isId ? 'Username' : 'Username';
  String get registerFullName => isId ? 'Nama Lengkap' : 'Full Name';
  String get registerNameHint => isId ? 'Nama kamu' : 'Your name';
  String get registerPasswordHint => isId ? 'min. 6 karakter' : 'min. 6 characters';
  String get registerConfirmHint => isId ? 'ulangi password' : 'repeat password';
  String get registerConfirmPassword => isId ? 'Konfirmasi Password' : 'Confirm Password';
  String get registerHaveAccount => isId ? 'Sudah punya akun? Masuk' : 'Already have an account? Login';
  String get registerSuccess => isId ? 'Pendaftaran berhasil!' : 'Registration successful!';
  String get registerSignUp => isId ? 'DAFTAR SEKARANG' : 'SIGN UP NOW';
  String get registerSubtitle => isId ? 'ke Moody Study' : 'to Moody Study';
  String get registerNameRequired => isId ? 'Nama wajib diisi!' : 'Name is required!';
  String get registerUsernameRequired => isId ? 'Username wajib diisi!' : 'Username is required!';
  String get registerUsernameInvalid => isId ? 'Username minimal 3 karakter tanpa spasi!' : 'Username must be at least 3 characters without spaces!';
  String get registerPasswordMismatch => isId ? 'Password tidak cocok!' : 'Passwords do not match!';

  // ─── Home / Character Intro ───────────────────────────────────────
  String get homeTagline => isId ? 'belajar kapan saja dan di mana saja' : 'study anytime anywhere';
  String get homeSubtitle => isId ? 'mood bagus atau tidak,\ntetap belajar bareng Oddy!' : "good mood or not,\nlet's keep studying with oddy!";
  String get homeStartNow => isId ? 'mulai sekarang' : 'start now';
  String get homeSchedule => isId ? 'atur jadwal' : 'schedule';
  String get homeStreak => isId ? 'Streak' : 'Streak';

  // ─── Bottom Nav ───────────────────────────────────────────────────
  String get navHome => isId ? 'Beranda' : 'Home';
  String get navQuest => isId ? 'Quest' : 'Quest';
  String get navFiles => isId ? 'File' : 'Files';
  String get navQuiz => isId ? 'Kuis' : 'Quiz';
  String get navStats => isId ? 'Statistik' : 'Stats';
  String get navSettings => isId ? 'Setelan' : 'Settings';
  String get navProfile => isId ? 'Profil' : 'Profile';

  // ─── Mood Screen ──────────────────────────────────────────────────
  String get moodQuestion => isId ? 'Bagaimana mood kamu\nhari ini?' : "How's your mood today?";
  String get moodSo => isId ? 'Jadi...' : 'So...';
  String get moodHappy => isId ? 'Senang' : 'Happy';
  String get moodOkay => isId ? 'Biasa saja' : 'Okay';
  String get moodSad => isId ? 'Sedih' : 'Sad';
  String get moodTired => isId ? 'Lelah' : 'Tired';

  // ─── Location Screen ──────────────────────────────────────────────
  String get locationQuestion => isId ? 'Di mana kamu\nbelajar sekarang?' : 'Where are you\nstudying now?';
  String get locationHome => isId ? 'Rumah / Luar' : 'Home / Outside';
  String get locationLibrary => isId ? 'Perpustakaan' : 'Library';
  String get locationSilent => isId ? 'Mode senyap & notifikasi visual saja' : 'Silent mode & visual alerts only';
  String get locationSound => isId ? 'Notifikasi suara & alarm aktif' : 'Sound alerts & notifications active';

  // ─── Study Session (timer screen) ────────────────────────────────
  String get sessionTitle => isId ? 'SESI BELAJAR HARI INI' : "TODAY'S STUDY SESSION";
  String get sessionRecommended => isId ? 'DIREKOMENDASIKAN UNTUK MOOD KAMU' : 'RECOMMENDED FOR YOUR MOOD';
  String get sessionReady => isId ? 'SIAP' : 'READY';
  String get sessionStartStudying => isId ? 'Mulai Belajar' : 'Start Studying';
  String get sessionAddMore => isId ? 'Tambah file' : 'Add more';
  String get sessionClose => isId ? 'Tutup' : 'Close';
  String get sessionMin => isId ? 'mnt' : 'min';

  // ─── Active Study Session ─────────────────────────────────────────
  String get activeKeepGoing => isId ? 'Terus semangat' : 'Keep going';
  String get activeRemaining => isId ? 'TERSISA' : 'REMAINING';
  String get activePause => isId ? 'Jeda' : 'Pause';
  String get activeResume => isId ? 'Lanjut' : 'Resume';
  String get activeDoneEarly => isId ? 'Selesai Awal' : 'Done Early';
  String get activeMaterialSummary => isId ? 'Ringkasan Materi' : 'Material Summary';
  String get activeSummaryReady => isId ? 'Siap' : 'Ready';
  String get activeSummaryError => isId ? 'Error' : 'Error';
  String get activeSaveAsPdf => isId ? 'Simpan sebagai PDF' : 'Save as PDF';
  String get activeSavingPdf => isId ? 'Menyimpan PDF...' : 'Saving PDF...';
  String get activeYourFiles => isId ? 'File Kamu' : 'Your Files';
  String get activeTestKnowledge => isId ? 'Uji Pengetahuanmu' : 'Test Your Knowledge';
  String get activeAlarmBanner => isId ? 'Alarm aktif karena kamu meninggalkan app lebih dari 30 detik.' : 'Alarm is active because you left the app for more than 30 seconds.';
  String get activeHeyBack => isId ? 'Hei, kembali!' : 'Hey, come back!';
  String get activeImBack => isId ? 'Aku sudah kembali!' : "I'm back!";
  String get activeSaveSummary => isId ? 'Simpan Ringkasan' : 'Save Summary';
  String get activeContinueStudying => isId ? 'Lanjut Belajar' : 'Continue Studying';
  String get activeExit => isId ? 'Keluar' : 'Exit';
  String get activeDidIt => isId ? 'Kamu berhasil' : 'You did it';
  String get activeStudiedFor => isId ? 'Kamu belajar selama' : 'You studied for';
  String get activeSummaryNotSaved => isId ? 'Ringkasan belum disimpan!' : "Your summary hasn't been saved!";
  String get activeSummaryWarning => isId ? 'Yakin tidak mau menyimpannya? Kamu mungkin butuh nanti.' : "Are you sure you don't want to save it? You might need it to study later.";

  // ─── Upload Screen ────────────────────────────────────────────────
  String get uploadHello => isId ? 'Halo' : 'Hello';
  String uploadGreeting(String name) => isId ? 'Halo, $name!' : 'Hello, $name!';
  String get uploadSubtitle => isId
      ? 'Upload atau seret materimu di sini dan kita rangkum bersama!'
      : "Upload or drag your materials here and let's summarize them together!";
  String get uploadClickFiles => isId ? 'Klik file di sini' : 'Click files here';
  String get uploadFormats => 'PDF · DOCX · TXT';
  String get uploadMaxSize => isId ? 'Maks 150 MB per file' : 'Max 150 MB per file';
  String get uploadOfflineMode => isId ? 'mode offline aktif secara otomatis.' : 'offline mode activates automatically.';
  String get uploadDone => isId ? 'Selesai' : 'Done';
  String uploadDoneCount(int n) => isId ? '${uploadDone} ($n file)' : '${uploadDone} ($n files)';
  String get upload20AI => isId
      ? '20 ringkasan AI tersedia per hari. Jika melebihi, '
      : '20 AI summaries available per day. If exceeded, ';

  // ─── Your Files Screen ────────────────────────────────────────────
  String get filesTitle => isId ? 'File Kamu' : 'Your Files';
  String get filesEmpty => isId ? 'Belum ada file yang disimpan. Simpan PDF terlebih dahulu.' : 'No files saved yet. Save a PDF first.';
  String get filesLoadError => isId ? 'Gagal memuat file' : 'Failed to load files';
  String get filesDeleteConfirm => isId ? 'Hapus file ini?' : 'Delete this file?';
  String get filesDeleteSuccess => isId ? 'File berhasil dihapus.' : 'File deleted successfully.';
  String get filesOpenError => isId ? 'Gagal membuka file.' : 'Failed to open file.';

  // ─── Daily Quest ──────────────────────────────────────────────────
  String get questTitle => isId ? 'Quest Harian' : 'Daily Quest';
  String get questSubtitle => isId ? 'Selesaikan quest hari ini' : 'Complete today\'s quests';
  String get questCompleted => isId ? 'Selesai!' : 'Completed!';
  String get questAllDone => isId ? '🎉 Semua quest selesai! Keren banget!' : '🎉 All quests done! Amazing!';
  String questProgress(int done, int total) =>
      isId ? '$done dari $total quest selesai' : '$done of $total quests completed';
  String get questInfo => isId
      ? 'Quest baru hadir setiap hari. Selesaikan sesi belajar untuk mengecek progresmu!'
      : 'New quests arrive every day. Complete a study session to check your progress!';
  String get questError => isId ? 'Terjadi kesalahan.' : 'Something went wrong.';
  String get questRetry => isId ? 'Coba Lagi' : 'Try Again';

  // ─── Stats Screen ─────────────────────────────────────────────────
  String get statsTitle => isId ? 'Statistik' : 'Statistics';
  String get statsComingSoon => isId ? '📊 Halaman statistik\nakan segera hadir!' : '📊 Statistics page\ncoming soon!';

  // ─── Schedule Screen ───────────────────────────────────────────────
  String get scheduleTitle => isId ? 'Jadwal Belajar' : 'Study Schedule';
  String get scheduleSubtitle => isId ? 'Atur jadwal belajarmu di sini.' : 'Set your study schedule here.';
  String get scheduleAddButton => isId ? 'Buat Jadwal' : 'Create';
  String get scheduleCreateNew => isId ? 'Buat Jadwal Baru' : 'Create New';
  String get scheduleSubject => isId ? 'Mata Pelajaran' : 'Subject';
  String get scheduleStudyDate => isId ? 'Tanggal Belajar' : 'Study Date';
  String get scheduleStartTime => isId ? 'Jam Mulai' : 'Start Time';
  String get scheduleEndTime => isId ? 'Jam Selesai' : 'End Time';
  String get scheduleLocation => isId ? 'Lokasi (opsional)' : 'Location (optional)';
  String get scheduleMood => isId ? 'Mood (opsional)' : 'Mood (optional)';
  String get scheduleNoSchedules => isId ? 'Belum ada jadwal. Tambah jadwal baru dulu.' : 'No schedules yet. Add a new schedule.';
  String get scheduleCreated => isId ? 'Jadwal berhasil dibuat!' : 'Schedule created successfully!';
  String get scheduleComplete => isId ? 'Tandai Selesai' : 'Mark Complete';
  String get delete => isId ? 'Hapus' : 'Delete';
  String get scheduleDelete => isId ? 'Hapus jadwal' : 'Delete schedule';
  String get scheduleTimeRangeError => isId ? 'Waktu akhir harus setelah waktu mulai.' : 'End time must be after start time.';

  // ─── Quiz ─────────────────────────────────────────────────────────
  String get quizTitle => isId ? 'Kuis' : 'Quiz';
  String get quizPickMaterial => isId ? '🧠 Pilih materi dulu\nuntuk mulai kuis!' : '🧠 Pick a material first\nto start the quiz!';

  // ─── General ─────────────────────────────────────────────────────
  String get cancel => isId ? 'Batal' : 'Cancel';
  String get save => isId ? 'Simpan' : 'Save';
  String get ok => 'OK';
  String get loading => isId ? 'Memuat...' : 'Loading...';
  String get error => isId ? 'Terjadi kesalahan' : 'Something went wrong';
  String get retry => isId ? 'Coba Lagi' : 'Retry';
  String get back => isId ? 'Kembali' : 'Back';
  String get langButtonLabel => isId ? 'EN' : 'ID';
  String get langTooltip => isId ? 'Ganti ke English' : 'Switch to Indonesian';

  // ─── Error messages (dipakai oleh AppFailure.localizedMessage) ────────────

  String get errorSpotifySdkNotInitialized => isId
      ? 'Aplikasi Spotify tidak terdeteksi. Pastikan Spotify sudah terpasang.'
      : 'Spotify app not found. Please make sure Spotify is installed.';

  String get errorSpotifyConnectionFailed => isId
      ? 'Gagal terhubung ke Spotify. Silakan coba lagi.'
      : 'Failed to connect to Spotify. Please try again.';

  String get errorSpotifyCancelled =>
      isId ? 'Koneksi Spotify dibatalkan.' : 'Spotify connection was cancelled.';

  String get errorSpotifyTokenExpired => isId
      ? 'Sesi Spotify habis. Silakan hubungkan ulang.'
      : 'Spotify session expired. Please reconnect.';

  String get errorAuthInvalidCredentials => isId
      ? 'Email atau kata sandi tidak sesuai.'
      : 'Incorrect email or password.';

  String get errorAuthUserNotFound =>
      isId ? 'Akun tidak ditemukan.' : 'Account not found.';

  String get errorAuthEmailAlreadyUsed => isId
      ? 'Email ini sudah digunakan oleh akun lain.'
      : 'This email is already in use.';

  String get errorAuthWeakPassword => isId
      ? 'Kata sandi terlalu lemah. Gunakan minimal 6 karakter.'
      : 'Password is too weak. Use at least 6 characters.';

  String get errorAuthTooManyRequests => isId
      ? 'Terlalu banyak percobaan. Tunggu beberapa saat.'
      : 'Too many attempts. Please wait a moment.';

  String get errorAuthSessionExpired => isId
      ? 'Sesi kamu telah habis. Silakan masuk kembali.'
      : 'Your session has expired. Please log in again.';

  String get errorNetworkOffline => isId
      ? 'Tidak ada koneksi internet. Periksa jaringan kamu.'
      : 'No internet connection. Check your network.';

  String get errorNetworkTimeout => isId
      ? 'Koneksi lambat atau timeout. Silakan coba lagi.'
      : 'Connection timed out. Please try again.';

  String get errorNetworkServerError => isId
      ? 'Server sedang bermasalah. Coba lagi nanti.'
      : 'Server error. Please try again later.';

  String get errorValidationRequired =>
      isId ? 'Field ini wajib diisi.' : 'This field is required.';

  String get errorValidationInvalidEmail =>
      isId ? 'Format email tidak valid.' : 'Invalid email format.';

  String get errorValidationPasswordTooShort => isId
      ? 'Kata sandi minimal 6 karakter.'
      : 'Password must be at least 6 characters.';

  String get errorUnknown =>
      isId ? 'Terjadi kesalahan. Silakan coba lagi.' : 'Something went wrong. Please try again.';

  /// Lookup by i18n key — dipakai oleh AppFailure.localizedMessage().
  String errorForKey(String key) => switch (key) {
        'errors.spotify.sdkNotInitialized' => errorSpotifySdkNotInitialized,
        'errors.spotify.connectionFailed' => errorSpotifyConnectionFailed,
        'errors.spotify.cancelled' => errorSpotifyCancelled,
        'errors.spotify.tokenExpired' => errorSpotifyTokenExpired,
        'errors.auth.invalidCredentials' => errorAuthInvalidCredentials,
        'errors.auth.userNotFound' => errorAuthUserNotFound,
        'errors.auth.emailAlreadyUsed' => errorAuthEmailAlreadyUsed,
        'errors.auth.weakPassword' => errorAuthWeakPassword,
        'errors.auth.tooManyRequests' => errorAuthTooManyRequests,
        'errors.auth.sessionExpired' => errorAuthSessionExpired,
        'errors.network.offline' => errorNetworkOffline,
        'errors.network.timeout' => errorNetworkTimeout,
        'errors.network.serverError' => errorNetworkServerError,
        'errors.validation.required' => errorValidationRequired,
        'errors.validation.invalidEmail' => errorValidationInvalidEmail,
        'errors.validation.passwordTooShort' => errorValidationPasswordTooShort,
        _ => errorUnknown,
      };
}

/// Widget tombol globe untuk ganti bahasa — taruh di top bar.
/// Sekarang pakai Provider, tidak butuh parameter callback manual.
class LanguageToggleButton extends StatelessWidget {
  const LanguageToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final langProvider = context.watch<LanguageProvider>();
    final isId = !langProvider.isEnglish;
    return GestureDetector(
      onTap: langProvider.toggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF111111), width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFF111111),
              offset: Offset(2, 2),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language, size: 14, color: Color(0xFF111111)),
            const SizedBox(width: 4),
            Text(
              isId ? 'EN' : 'ID',
              style: const TextStyle(
                fontFamily: 'BlackHanSans',
                fontSize: 12,
                color: Color(0xFF111111),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}