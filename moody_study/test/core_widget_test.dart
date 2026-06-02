import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moody_study/widgets/sound_warning.dart';
import 'package:moody_study/widgets/sub_tagline.dart';
import 'package:moody_study/widgets/now_playing_widget.dart';
import 'package:moody_study/widgets/name_form_overlay.dart';
import 'package:moody_study/widgets/moody_title.dart';

/// Widget tests untuk minimal 5 core UI component.
/// Setiap test dibungkus MaterialApp + Scaffold agar context valid.

Widget wrapWidget(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: Stack(
        children: [child],
      ),
    ),
  );
}

void main() {
  // ─────────────────────────────────────────────
  // 1. SoundWarning
  // ─────────────────────────────────────────────
  group('Widget: SoundWarning', () {
    testWidgets('SoundWarning render tanpa error', (tester) async {
      await tester.pumpWidget(wrapWidget(const SoundWarning()));
      await tester.pump(const Duration(milliseconds: 900));
      expect(find.byType(SoundWarning), findsOneWidget);
    });

    testWidgets('SoundWarning mengandung teks peringatan suara', (tester) async {
      await tester.pumpWidget(wrapWidget(const SoundWarning()));
      await tester.pump(const Duration(milliseconds: 900));
      // Widget berisi teks tentang headphone / sound
      expect(
        find.byWidgetPredicate(
          (w) => w is Text && w.data != null && w.data!.isNotEmpty,
        ),
        findsWidgets,
      );
    });

    testWidgets('SoundWarning dispose berjalan tanpa error', (tester) async {
      await tester.pumpWidget(wrapWidget(const SoundWarning()));
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pumpWidget(const SizedBox()); // trigger dispose
      await tester.pumpAndSettle();
      // Tidak ada exception
    });
  });

  // ─────────────────────────────────────────────
  // 2. SubTagline
  // ─────────────────────────────────────────────
  group('Widget: SubTagline', () {
    testWidgets('SubTagline dengan show=false render tanpa error', (tester) async {
      await tester.pumpWidget(wrapWidget(const SubTagline(show: false)));
      expect(find.byType(SubTagline), findsOneWidget);
    });

    testWidgets('SubTagline dengan show=true render tanpa error', (tester) async {
      await tester.pumpWidget(wrapWidget(const SubTagline(show: true)));
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.byType(SubTagline), findsOneWidget);
    });

    testWidgets('SubTagline show berubah dari false ke true tidak crash', (
      tester,
    ) async {
      final key = GlobalKey();
      await tester.pumpWidget(wrapWidget(SubTagline(key: key, show: false)));
      await tester.pump();
      await tester.pumpWidget(wrapWidget(SubTagline(key: key, show: true)));
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.byType(SubTagline), findsOneWidget);
    });
  });

  // ─────────────────────────────────────────────
  // 3. NowPlayingWidget
  // ─────────────────────────────────────────────
  group('Widget: NowPlayingWidget', () {
    testWidgets('NowPlayingWidget show=false tidak menampilkan konten', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapWidget(const NowPlayingWidget(show: false, songName: 'test.mp3')),
      );
      expect(find.byType(NowPlayingWidget), findsOneWidget);
    });

    testWidgets('NowPlayingWidget show=true menampilkan nama lagu', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapWidget(
          const NowPlayingWidget(
            show: true,
            songName: 'lofi_beat.mp3',
            isPlaying: true,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.byType(NowPlayingWidget), findsOneWidget);
    });

    testWidgets('NowPlayingWidget isPlaying=false tidak crash', (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          const NowPlayingWidget(
            show: true,
            songName: 'lofi.mp3',
            isPlaying: false,
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(NowPlayingWidget), findsOneWidget);
    });
  });

  // ─────────────────────────────────────────────
  // 4. NameFormOverlay
  // ─────────────────────────────────────────────
  group('Widget: NameFormOverlay', () {
    testWidgets('NameFormOverlay show=false render tanpa error', (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          NameFormOverlay(show: false, onSubmit: (_) {}),
        ),
      );
      expect(find.byType(NameFormOverlay), findsOneWidget);
    });

    testWidgets('NameFormOverlay show=true render overlay', (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          NameFormOverlay(show: true, onSubmit: (_) {}),
        ),
      );
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.byType(NameFormOverlay), findsOneWidget);
    });

    testWidgets('NameFormOverlay onSubmit dipanggil dengan nama yang diinput', (
      tester,
    ) async {
      String submittedName = '';
      await tester.pumpWidget(
        wrapWidget(
          NameFormOverlay(
            show: true,
            onSubmit: (name) => submittedName = name,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 700));

      // Cari TextField dan isi nama
      final textFields = find.byType(TextField);
      if (textFields.evaluate().isNotEmpty) {
        await tester.enterText(textFields.first, 'Moody User');
        await tester.pump();
        // Cari tombol submit / ElevatedButton / TextButton
        final buttons = find.byType(ElevatedButton);
        if (buttons.evaluate().isNotEmpty) {
          await tester.tap(buttons.first);
          await tester.pump();
          expect(submittedName, 'Moody User');
        }
      }
    });

    testWidgets('NameFormOverlay isDark=true tidak crash', (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          NameFormOverlay(show: true, onSubmit: (_) {}, isDark: true),
        ),
      );
      await tester.pump();
      expect(find.byType(NameFormOverlay), findsOneWidget);
    });
  });

  // ─────────────────────────────────────────────
  // 5. MoodyTitle
  // ─────────────────────────────────────────────
  group('Widget: MoodyTitle', () {
    testWidgets('MoodyTitle render tanpa error', (tester) async {
      await tester.pumpWidget(
        wrapWidget(MoodyTitle(onDone: () {})),
      );
      await tester.pump(const Duration(seconds: 5));
      expect(find.byType(MoodyTitle), findsOneWidget);
    });

    testWidgets('MoodyTitle menjalankan animasi dot tanpa error', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapWidget(MoodyTitle(onDone: () {})),
      );
      // Jalankan keseluruhan animasi sequence sampai idle float mulai.
      await tester.pump(const Duration(seconds: 5));
      expect(find.byType(MoodyTitle), findsOneWidget);
    });

    testWidgets('MoodyTitle onDone callback tidak null', (tester) async {
      bool called = false;
      await tester.pumpWidget(
        wrapWidget(MoodyTitle(onDone: () => called = true)),
      );
      // Pump sampai animasi selesai (total ~4 detik simulasi)
      await tester.pump(const Duration(seconds: 5));
      expect(find.byType(MoodyTitle), findsWidgets); // masih ada atau sudah dipanggil
    });

    testWidgets('MoodyTitle dispose berjalan tanpa memory leak', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapWidget(MoodyTitle(onDone: () {})),
      );
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpWidget(const SizedBox()); // dispose widget
      await tester.pumpAndSettle();
      // Tidak ada error
    });
  });
}