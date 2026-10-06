import 'package:flutter/material.dart';
import 'package:islami/utils/app_assets.dart';

/// Hanging lantern that drops in from the top.
class SplashLamp extends StatelessWidget {
  const SplashLamp({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppAssets.splashLamp,
      fit: BoxFit.contain,
      alignment: Alignment.topCenter,
    );
  }
}
