import 'package:intl/intl.dart';

/// KLE HOMECARE — Shared Utility Helpers
class AppHelpers {
  AppHelpers._();

  static String formatDate(DateTime date) =>
      DateFormat('dd MMM yyyy').format(date);

  static String formatDateTime(DateTime dt) =>
      DateFormat('dd MMM yyyy, hh:mm a').format(dt);

  static String formatDateApi(DateTime date) =>
      DateFormat('yyyy-MM-dd').format(date);

  static String capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  static String serviceTypeLabel(String type) =>
      type.replaceAll('_', ' ').split(' ').map(capitalize).join(' ');

  static String statusLabel(String status) =>
      status.replaceAll('_', ' ').split(' ').map(capitalize).join(' ');

  static String urgencyLabel(String urgency) => capitalize(urgency);

  /// Returns a user-friendly error message from an exception.
  ///
  /// [identifierLabel] lets callers say whether the login/register form used
  /// a mobile number or an email address, so messages like "incorrect
  /// mobile number or password" read correctly for the admin (email) portal
  /// too. Defaults to 'mobile number' since most of the app logs in that way.
  static String friendlyError(Object error, {String identifierLabel = 'mobile number'}) {
    final msg = error.toString();
    if (msg.contains('NetworkException')) {
      return 'No internet connection. Please check your network and try again.';
    }
    if (msg.contains('UnauthorizedException')) {
      return 'Your session has expired. Please login again.';
    }
    if (msg.contains('ServerException')) {
      // Extract the message part
      final match = RegExp(r'ServerException\(\d*\): (.+)').firstMatch(msg);
      final serverMsg = match?.group(1) ?? 'Server error. Please try again.';
      return _friendlyServerMessage(serverMsg, identifierLabel);
    }
    return 'Something went wrong. Please try again.';
  }

  /// Rewrites common raw backend error strings into clearer, user-facing copy
  /// (e.g. wrong password, unregistered account, duplicate account).
  static String _friendlyServerMessage(String serverMsg, String identifierLabel) {
    final lower = serverMsg.toLowerCase();

    final notFound = lower.contains('not found') ||
        lower.contains('no account') ||
        lower.contains("doesn't exist") ||
        lower.contains('does not exist') ||
        lower.contains('not registered');
    if (notFound) {
      return 'No account found with this $identifierLabel. Please check and '
          'try again, or register if you\'re new here.';
    }

    final badCredentials = (lower.contains('invalid') || lower.contains('incorrect')) &&
        (lower.contains('credential') || lower.contains('password') ||
            lower.contains('mobile') || lower.contains('phone') ||
            lower.contains('email') || lower.contains('login'));
    if (badCredentials) {
      return 'Incorrect $identifierLabel or password. Please try again.';
    }

    // Account-specific duplicate (registration / login flow)
    final accountDuplicate = (lower.contains('already') &&
            (lower.contains('exist') || lower.contains('registered'))) &&
        (lower.contains('account') || lower.contains('mobile') ||
            lower.contains('email') || lower.contains('phone')) ||
        lower.contains('duplicate key');
    if (accountDuplicate) {
      return 'An account with this mobile number or email already exists. '
          'Please login instead.';
    }

    // Non-account conflict (service, shift, resource name etc.) —
    // return the server message directly, it's already user-readable.
    if (lower.contains('already exists') || lower.contains('already exist')) {
      return serverMsg;
    }

    return serverMsg;
  }
}
