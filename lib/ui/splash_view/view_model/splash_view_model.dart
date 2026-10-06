import 'package:flutter/material.dart';
import 'package:islami/utils/app_routes.dart';

/// Handles splash timing and navigation to the home screen.
class SplashViewModel {
  /// Length of the entrance motion for all splash layers.
  final Duration animationDuration = const Duration(milliseconds: 2400);

  /// Pause after entrance finishes, before navigating home.
  final Duration holdDuration = const Duration(milliseconds: 900);

  /// Replaces the splash route with the existing home screen.
  void goToHome(BuildContext context) {
    Navigator.of(context).pushReplacementNamed(AppRoutes.homeRouteName);
  }
}
