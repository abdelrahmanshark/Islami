import 'package:flutter/material.dart';
import 'package:islami/utils/app_assets.dart';

/// Top mosque outline watermark from the Figma splash.
class SplashMosque extends StatelessWidget {
  const SplashMosque({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppAssets.splashMosque,
      fit: BoxFit.contain,
    );
  }
}
