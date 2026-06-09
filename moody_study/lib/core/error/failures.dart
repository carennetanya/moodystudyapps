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

// ─── Validation inline ────────────────────────────────────────────────────────

final class NameEmptyFailure extends AppFailure {
  const NameEmptyFailure();
  @override
  String get messageKey => 'errors.validation.name.empty';
}

final class NameTooLongFailure extends AppFailure {
  const NameTooLongFailure();
  @override
  String get messageKey => 'errors.validation.name.tooLong';
}

final class UsernameTooShortFailure extends AppFailure {
  const UsernameTooShortFailure();
  @override
  String get messageKey => 'errors.validation.username.tooShort';
}

final class UsernameTooLongFailure extends AppFailure {
  const UsernameTooLongFailure();
  @override
  String get messageKey => 'errors.validation.username.tooLong';
}

final class UsernameFormatInvalidFailure extends AppFailure {
  const UsernameFormatInvalidFailure();
  @override
  String get messageKey => 'errors.validation.username.format';
}

final class UsernameContainsSpaceFailure extends AppFailure {
  const UsernameContainsSpaceFailure();
  @override
  String get messageKey => 'errors.validation.username.containsSpace';
}

final class UsernameAlreadyTakenFailure extends AppFailure {
  const UsernameAlreadyTakenFailure();
  @override
  String get messageKey => 'errors.validation.username.taken';
}

final class EmailEmptyFailure extends AppFailure {
  const EmailEmptyFailure();
  @override
  String get messageKey => 'errors.validation.email.empty';
}

final class EmailFormatInvalidFailure extends AppFailure {
  const EmailFormatInvalidFailure();
  @override
  String get messageKey => 'errors.validation.email.format';
}

final class EmailContainsSpaceFailure extends AppFailure {
  const EmailContainsSpaceFailure();
  @override
  String get messageKey => 'errors.validation.email.containsSpace';
}

final class EmailAlreadyRegisteredFailure extends AppFailure {
  const EmailAlreadyRegisteredFailure();
  @override
  String get messageKey => 'errors.validation.email.taken';
}

final class PasswordTooShortFailure extends AppFailure {
  const PasswordTooShortFailure();
  @override
  String get messageKey => 'errors.validation.password.tooShort';
}

final class OfflineCheckFailure extends AppFailure {
  const OfflineCheckFailure();
  @override
  String get messageKey => 'errors.validation.offline';
}

// ─── Fallback ─────────────────────────────────────────────────────────────────

final class UnknownFailure extends AppFailure {
  /// Hanya untuk logging — JANGAN tampilkan langsung ke user.
  final String debugMessage;
  const UnknownFailure(this.debugMessage);
  @override
  String get messageKey => 'errors.unknown';
}

// ─── API (backend response) ───────────────────────────────────────────────────

/// Failure untuk semua error dari backend yang sudah dinormalisasi lewat
/// [ApiException]. Carry key i18n (`"validation.xxx"` atau `"errors.xxx"`)
/// dan resolve via [AppLocalizations.errorByKey] — bukan [errorForKey].
final class ApiFailure extends AppFailure {
  final String _key;
  final int? statusCode;

  const ApiFailure({required String messageKey, this.statusCode})
      : _key = messageKey;

  @override
  String get messageKey => _key;

  @override
  String localizedMessage(BuildContext context) =>
      AppLocalizations.of(context, listen: false).errorByKey(_key);
}
