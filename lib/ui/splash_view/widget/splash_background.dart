import 'package:flutter/material.dart';
import 'package:islami/utils/app_assets.dart';

/// Full-screen splash background from the Figma design.
class SplashBackground extends StatelessWidget {
  const SplashBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppAssets.splashBg,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
  }
}
