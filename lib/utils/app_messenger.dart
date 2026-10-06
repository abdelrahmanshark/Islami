import 'package:flutter/material.dart';

/// Global [ScaffoldMessenger] access for service-layer snackbars.
class AppMessenger {
  AppMessenger._();

  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  /// Shows a floating snackbar if a messenger is attached.
  static void showSnackBar(String message) {
    final ScaffoldMessengerState? messenger =
        scaffoldMessengerKey.currentState;
    if (messenger == null) {
      return;
    }

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}
