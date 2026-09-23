import 'dart:async';
import 'dart:io';

/// Helpers for detecting offline state and mapping network failures.
class NetworkUtils {
  static const String noInternetMessage = 'تحقق من الاتصال بالانترنت';
  static const String genericFailureMessage = 'حدث خطأ ما';

  /// Returns true when the device can resolve a public host.
  static Future<bool> hasInternetConnection() async {
    try {
      final List<InternetAddress> result = await InternetAddress.lookup(
        'one.one.one.one',
      ).timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    } on TimeoutException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// True when [error] looks like a connectivity / DNS failure.
  static bool isNetworkError(Object error) {
    if (error is SocketException || error is TimeoutException) {
      return true;
    }
    final String message = error.toString().toLowerCase();
    return message.contains('socketexception') ||
        message.contains('failed host lookup') ||
        message.contains('network is unreachable') ||
        message.contains('connection refused') ||
        message.contains('connection reset') ||
        message.contains('clientexception') ||
        message.contains('connection timed out') ||
        message.contains('network error');
  }

  /// Picks the user-facing message for a failed online fetch.
  static Future<String> failureMessageFor(Object error) async {
    if (isNetworkError(error) || !await hasInternetConnection()) {
      return noInternetMessage;
    }
    return genericFailureMessage;
  }
}
