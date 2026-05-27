import 'package:spotify_sdk/spotify_sdk.dart';

class SpotifyConnectionResult {
  final bool success;
  final String message;

  SpotifyConnectionResult({required this.success, required this.message});
}

class SpotifyService {
  SpotifyService._();

  static const String clientId = 'ac573efe03e747eaa73920529961a33f';
  static const String redirectUri = 'moodystudy://callback';

  static Future<SpotifyConnectionResult> connect() async {
    try {
      final token = await SpotifySdk.getAccessToken(
        clientId: clientId,
        redirectUrl: redirectUri,
        scope:
            'app-remote-control,streaming,playlist-read-private,user-read-playback-state,user-modify-playback-state',
      );

      if (token.isEmpty) {
        return SpotifyConnectionResult(
          success: false,
          message: 'Failed to get Spotify token.',
        );
      }

      // ✅ Establish App Remote connection (wajib untuk play/pause/getPlayerState)
      final connected = await SpotifySdk.connectToSpotifyRemote(
        clientId: clientId,
        redirectUrl: redirectUri,
      );

      if (!connected) {
        return SpotifyConnectionResult(
          success: false,
          message: 'Got token but could not connect to Spotify Remote. Make sure Spotify app is open.',
        );
      }

      return SpotifyConnectionResult(
        success: true,
        message: 'Connected to Spotify!',
      );
    } catch (e) {
      final errMsg = e.toString();
      if (errMsg.contains('CouldNotFindSpotifyApp') ||
          errMsg.contains('not installed')) {
        return SpotifyConnectionResult(
          success: false,
          message: 'Spotify app is not installed. Please install Spotify first.',
        );
      }
      return SpotifyConnectionResult(
        success: false,
        message: 'Could not connect to Spotify: $errMsg',
      );
    }
  }

  static const _timeout = Duration(seconds: 4);

  static Future<void> play({String? spotifyUri}) async {
    if (spotifyUri != null) {
      await SpotifySdk.play(spotifyUri: spotifyUri).timeout(_timeout);
    } else {
      await SpotifySdk.resume().timeout(_timeout);
    }
  }

  static Future<void> pause() async {
    await SpotifySdk.pause().timeout(_timeout);
  }

  static Future<void> resume() async {
    await SpotifySdk.resume().timeout(_timeout);
  }

  static Future<void> skipNext() async {
    await SpotifySdk.skipNext().timeout(_timeout);
  }

  static Future<void> skipPrevious() async {
    await SpotifySdk.skipPrevious().timeout(_timeout);
  }
}