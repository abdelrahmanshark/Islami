import 'package:flutter/material.dart';
import 'package:islami/utils/app_assets.dart';

/// Decorative side wheel that slides in from the screen edge.
class SplashWheel extends StatelessWidget {
  const SplashWheel({
    super.key,
    required this.isLeft,
  });

  final bool isLeft;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      isLeft ? AppAssets.splashWheelLeft : AppAssets.splashWheelRight,
      fit: BoxFit.contain,
    );
  }
}
