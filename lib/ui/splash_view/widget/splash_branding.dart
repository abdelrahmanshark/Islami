import 'package:flutter/material.dart';
import 'package:islami/utils/app_assets.dart';

/// Route branding + supervised text that rises from the bottom.
class SplashBranding extends StatelessWidget {
  const SplashBranding({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppAssets.splashBranding,
      fit: BoxFit.contain,
    );
  }
}
