import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'package:spotify_sdk/spotify_sdk.dart';
import 'package:spotify_sdk/models/player_state.dart' as sp;
import 'package:dartz/dartz.dart' hide State;
import 'package:moody_study/core/failure.dart';
import 'package:moody_study/core/exception_handler.dart';
import 'package:moody_study/services/spotify_service.dart';

class HeadphoneScreen extends StatefulWidget {
  final AudioPlayer audioPlayer;

  const HeadphoneScreen({super.key, required this.audioPlayer});

  @override
  State<HeadphoneScreen> createState() => _HeadphoneScreenState();
}

class _HeadphoneScreenState extends State<HeadphoneScreen> {
  // ── Local audio (fallback) ──────────────────────────────────────────────
  static const String _localTrackTitle = 'Good Days - SZA';
  static const String _audioFile = 'audio/SZA - Good Days (Audio).mp3';

  bool _localPlaying = false;
  double _volume = 0.8;
  StreamSubscription<PlayerState>? _localStateSubscription;

  // ── Spotify ─────────────────────────────────────────────────────────────
  bool _spotifyConnected = false;
  String _spotifyStatus = 'Not connected';
  bool _spotifyPlaying = false;
  String _spotifyTrackName = '';
  String _spotifyArtistName = '';
  StreamSubscription<sp.PlayerState>? _spotifyStateSubscription;

  @override
  void initState() {
    super.initState();

    // Local player setup
    widget.audioPlayer.setReleaseMode(ReleaseMode.loop);
    _localStateSubscription =
        widget.audioPlayer.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() => _localPlaying = state == PlayerState.playing);
    });
    widget.audioPlayer.setVolume(_volume);

    // Read current system volume
    FlutterVolumeController.getVolume().then((v) {
      if (!mounted) return;
      if (v != null) setState(() => _volume = v);
    });
  }

  // ── Spotify connect ──────────────────────────────────────────────────────
  Future<void> _connectSpotify() async {
    setState(() => _spotifyStatus = 'Connecting...');

    final result = await SpotifyService.connect();
    if (!mounted) return;

    setState(() {
      _spotifyConnected = result.success;
      _spotifyStatus = result.message;
    });

    if (result.success) {
      _subscribeSpotifyPlayerState();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor:
            result.success ? const Color(0xFF1DB954) : const Color(0xFFCC3333),
      ),
    );
  }

  void _subscribeSpotifyPlayerState() {
    _spotifyStateSubscription?.cancel();
    _spotifyStateSubscription =
        SpotifySdk.subscribePlayerState().listen((sp.PlayerState state) {
      if (!mounted) return;
      setState(() {
        _spotifyPlaying = !state.isPaused;
        _spotifyTrackName = state.track?.name ?? '';
        _spotifyArtistName = state.track?.artist.name ?? '';
      });
    });
  }

  // ── Spotify controls ─────────────────────────────────────────────────────
  Future<Either<Failure, void>> _doToggleSpotify() async {
    try {
      if (_spotifyPlaying) {
        await SpotifyService.pause();
      } else if (_spotifyTrackName.isNotEmpty) {
        await SpotifyService.resume();
      } else {
        await SpotifyService.play(
          spotifyUri: 'spotify:playlist:37i9dQZF1DWZeKCadgRdKQ',
        );
      }
      return const Right(null);
    } catch (e) {
      return Left(ServiceFailure(sanitizeException(e)));
    }
  }

  Future<void> _toggleSpotify() async {
    final wasPlaying = _spotifyPlaying;
    final result = await _doToggleSpotify();
    if (!mounted) return;
    result.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengontrol Spotify. Pastikan aplikasi Spotify terbuka.'),
          backgroundColor: const Color(0xFFCC3333),
        ),
      ),
      (_) => setState(() => _spotifyPlaying = wasPlaying
          ? false
          : true),
    );
  }

  Future<Either<Failure, void>> _doSkipNext() async {
    try {
      await SpotifyService.skipNext().timeout(const Duration(seconds: 3));
      return const Right(null);
    } catch (e) {
      return Left(ServiceFailure(sanitizeException(e)));
    }
  }

  Future<void> _skipNext() async {
    (await _doSkipNext()).fold(
      (f) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not skip. Make sure Spotify is open.')),
        );
      },
      (_) {},
    );
  }

  Future<Either<Failure, void>> _doSkipPrev() async {
    try {
      await SpotifyService.skipPrevious().timeout(const Duration(seconds: 3));
      return const Right(null);
    } catch (e) {
      return Left(ServiceFailure(sanitizeException(e)));
    }
  }

  Future<void> _skipPrev() async {
    (await _doSkipPrev()).fold(
      (f) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not skip. Make sure Spotify is open.')),
        );
      },
      (_) {},
    );
  }

  Future<void> _setSpotifyVolume(double value) async {
    if (!mounted) return;
    setState(() => _volume = value);
    await FlutterVolumeController.setVolume(value);
  }

  // ── Local audio controls ─────────────────────────────────────────────────
  Future<Either<Failure, void>> _doToggleLocal() async {
    try {
      if (_localPlaying) {
        await widget.audioPlayer.pause();
      } else {
        await widget.audioPlayer.play(AssetSource(_audioFile));
      }
      return const Right(null);
    } catch (e) {
      return Left(AudioFailure(sanitizeException(e)));
    }
  }

  Future<void> _toggleLocal() async {
    (await _doToggleLocal()).fold(
      (f) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to start music. Please try again.')),
        );
      },
      (_) {},
    );
  }

  Future<void> _setLocalVolume(double value) async {
    setState(() => _volume = value);
    await widget.audioPlayer.setVolume(value);
  }

  @override
  void dispose() {
    _localStateSubscription?.cancel();
    _spotifyStateSubscription?.cancel();
    super.dispose();
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1EE86F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1EE86F),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF111111)),
        title: const Text(
          'Headphone Player',
          style: TextStyle(
              color: Color(0xFF111111), fontFamily: 'BlackHanSans'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Hero card ──────────────────────────────────────────────
              _card(
                child: Column(
                  children: const [
                    Icon(Icons.headphones, size: 72, color: Color(0xFF111111)),
                    SizedBox(height: 16),
                    Text(
                      'Listen while you study',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontFamily: 'BlackHanSans',
                          fontSize: 20,
                          color: Color(0xFF111111)),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Control your study soundtrack without leaving the app.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 14,
                          color: Color(0xFF444444),
                          height: 1.5),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // ── Spotify section ───────────────────────────────────────
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.music_note,
                            color: Color(0xFF1DB954), size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Spotify',
                          style: TextStyle(
                              fontFamily: 'BlackHanSans',
                              fontSize: 16,
                              color: Color(0xFF111111)),
                        ),
                        const Spacer(),
                        if (_spotifyConnected)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1DB954),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Connected',
                              style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    if (!_spotifyConnected) ...[
                      Text(
                        _spotifyStatus,
                        style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 13,
                            color: Color(0xFF666666)),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1DB954),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: const Icon(Icons.link_rounded),
                          onPressed: _connectSpotify,
                          label: const Text(
                            'Connect Spotify',
                            style: TextStyle(
                                fontFamily: 'BlackHanSans', fontSize: 16),
                          ),
                        ),
                      ),
                    ] else ...[
                      // Now playing info
                      if (_spotifyTrackName.isNotEmpty) ...[
                        Text(
                          _spotifyTrackName,
                          style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111111)),
                        ),
                        Text(
                          _spotifyArtistName,
                          style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 13,
                              color: Color(0xFF666666)),
                        ),
                        const SizedBox(height: 16),
                      ] else ...[
                        const Text(
                          'Open Spotify and play something!',
                          style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 13,
                              color: Color(0xFF666666)),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Playback controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: _skipPrev,
                            icon: const Icon(Icons.skip_previous_rounded,
                                size: 36, color: Color(0xFF111111)),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _toggleSpotify,
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1DB954),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: const Color(0xFF111111), width: 2),
                              ),
                              child: Icon(
                                _spotifyPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                size: 34,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _skipNext,
                            icon: const Icon(Icons.skip_next_rounded,
                                size: 36, color: Color(0xFF111111)),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Volume
                      const Text(
                        'Volume',
                        style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 14,
                            color: Color(0xFF111111)),
                      ),
                      Slider(
                        value: _volume,
                        min: 0.0,
                        max: 1.0,
                        activeColor: const Color(0xFF1DB954),
                        inactiveColor: const Color(0xFFCCCCCC),
                        onChanged: _setSpotifyVolume,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Low',
                              style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 12,
                                  color: Color(0xFF666666))),
                          Text('${(_volume * 100).round()}%',
                              style: const TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 12,
                                  color: Color(0xFF666666))),
                          const Text('High',
                              style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 12,
                                  color: Color(0xFF666666))),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ── Local audio (fallback) ────────────────────────────────
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Local Music (Fallback)',
                      style: TextStyle(
                          fontFamily: 'BlackHanSans',
                          fontSize: 14,
                          color: Color(0xFF111111)),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Play without Spotify',
                      style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 12,
                          color: Color(0xFF888888)),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _localTrackTitle,
                      style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111111)),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _localPlaying ? 'Playing now' : 'Paused',
                          style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 14,
                              color: Color(0xFF666666)),
                        ),
                        IconButton(
                          onPressed: _toggleLocal,
                          icon: Icon(
                            _localPlaying
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_filled,
                            size: 38,
                            color: const Color(0xFF111111),
                          ),
                        ),
                      ],
                    ),
                    const Text(
                      'Volume',
                      style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 14,
                          color: Color(0xFF111111)),
                    ),
                    Slider(
                      value: _volume,
                      min: 0.0,
                      max: 1.0,
                      activeColor: const Color(0xFF1EE86F),
                      inactiveColor: const Color(0xFFCCCCCC),
                      onChanged: _setLocalVolume,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ── Note ─────────────────────────────────────────────────
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Note',
                      style: TextStyle(
                          fontFamily: 'BlackHanSans',
                          fontSize: 14,
                          color: Color(0xFF111111)),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Spotify integration requires the Spotify app to be installed and running on your device. Connect once and control playback directly from here while you study!',
                      style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 14,
                          color: Color(0xFF444444),
                          height: 1.5),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF111111), width: 2),
      ),
      child: child,
    );
  }
}