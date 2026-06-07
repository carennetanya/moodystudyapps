import 'package:flutter/material.dart';
import '../../utils/app_localizations.dart';

/// Typed failure hierarchy untuk seluruh app.
///
/// Setiap subclass punya [messageKey] → key yang dilookup di AppLocalizations.
/// Gunakan [localizedMessage] di UI, bukan [debugMessage].
sealed class AppFailure {
  const AppFailure();

  String get messageKey;

  String localizedMessage(BuildContext context) =>
      AppLocalizations.of(context, listen: false).errorForKey(messageKey);
}

// ─── Spotify ──────────────────────────────────────────────────────────────────

final class SpotifySdkNotInitializedFailure extends AppFailure {
  const SpotifySdkNotInitializedFailure();
  @override
  String get messageKey => 'errors.spotify.sdkNotInitialized';
}

final class SpotifyConnectionFailure extends AppFailure {
  const SpotifyConnectionFailure();
  @override
  String get messageKey => 'errors.spotify.connectionFailed';
}

final class SpotifyAuthCancelledFailure extends AppFailure {
  const SpotifyAuthCancelledFailure();
  @override
  String get messageKey => 'errors.spotify.cancelled';
}

final class SpotifyTokenExpiredFailure extends AppFailure {
  const SpotifyTokenExpiredFailure();
  @override
  String get messageKey => 'errors.spotify.tokenExpired';
}

// ─── Auth ─────────────────────────────────────────────────────────────────────

final class InvalidCredentialsFailure extends AppFailure {
  const InvalidCredentialsFailure();
  @override
  String get messageKey => 'errors.auth.invalidCredentials';
}

final class UserNotFoundFailure extends AppFailure {
  const UserNotFoundFailure();
  @override
  String get messageKey => 'errors.auth.userNotFound';
}

final class EmailAlreadyUsedFailure extends AppFailure {
  const EmailAlreadyUsedFailure();
  @override
  String get messageKey => 'errors.auth.emailAlreadyUsed';
}

final class WeakPasswordFailure extends AppFailure {
  const WeakPasswordFailure();
  @override
  String get messageKey => 'errors.auth.weakPassword';
}

final class TooManyRequestsFailure extends AppFailure {
  const TooManyRequestsFailure();
  @override
  String get messageKey => 'errors.auth.tooManyRequests';
}

final class SessionExpiredFailure extends AppFailure {
  const SessionExpiredFailure();
  @override
  String get messageKey => 'errors.auth.sessionExpired';
}

// ─── Network ──────────────────────────────────────────────────────────────────

final class NetworkOfflineFailure extends AppFailure {
  const NetworkOfflineFailure();
  @override
  String get messageKey => 'errors.network.offline';
}

final class NetworkTimeoutFailure extends AppFailure {
  const NetworkTimeoutFailure();
  @override
  String get messageKey => 'errors.network.timeout';
}

final class ServerFailure extends AppFailure {
  final int statusCode;
  const ServerFailure(this.statusCode);
  @override
  String get messageKey => 'errors.network.serverError';
}

// ─── Validation ───────────────────────────────────────────────────────────────

final class ValidationFailure extends AppFailure {
  final String field;
  const ValidationFailure(this.field);
  @override
  String get messageKey => 'errors.validation.required';
}

// ─── PDF ──────────────────────────────────────────────────────────────────────

final class PdfTooLargeFailure extends AppFailure {
  const PdfTooLargeFailure();
  @override
  String get messageKey => 'errors.pdf.tooLarge';
}

final class PdfCorruptedFailure extends AppFailure {
  const PdfCorruptedFailure();
  @override
  String get messageKey => 'errors.pdf.corrupted';
}

final class PdfScannedNotSupportedFailure extends AppFailure {
  const PdfScannedNotSupportedFailure();
  @override
  String get messageKey => 'errors.pdf.scannedNotSupported';
}

final class PdfPasswordProtectedFailure extends AppFailure {
  const PdfPasswordProtectedFailure();
  @override
  String get messageKey => 'errors.pdf.passwordProtected';
}

// ─── Fallback ─────────────────────────────────────────────────────────────────

final class UnknownFailure extends AppFailure {
  /// Hanya untuk logging — JANGAN tampilkan langsung ke user.
  final String debugMessage;
  const UnknownFailure(this.debugMessage);
  @override
  String get messageKey => 'errors.unknown';
}
