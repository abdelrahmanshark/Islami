import 'package:flutter/material.dart';
import 'package:islami/utils/network_utils.dart';

/// Shows the shared offline message as a SnackBar.
void showNoInternetSnackBar(BuildContext context) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      const SnackBar(
        content: Text(NetworkUtils.noInternetMessage),
        behavior: SnackBarBehavior.floating,
      ),
    );
}
