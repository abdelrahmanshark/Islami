import 'package:flutter/material.dart';
import 'package:islami/utils/app_assets.dart';

/// Center Islami crescent + title logo from Figma.
class SplashLogo extends StatelessWidget {
  const SplashLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppAssets.splashLogo,
      fit: BoxFit.contain,
    );
  }
}
