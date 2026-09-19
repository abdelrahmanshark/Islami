import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppStyles {
  static final TextStyle whiteBold12 = TextStyle(
    color: AppColors.whiteColor,
    fontSize: 12,
    fontWeight: FontWeight.bold,
  );
  static final TextStyle whiteBold16 = TextStyle(
    color: AppColors.whiteColor,
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );
  static final TextStyle whiteBold14 = TextStyle(
    color: AppColors.whiteColor,
    fontSize: 14,
    fontWeight: FontWeight.bold,
  );
  static final TextStyle blackBold24 = TextStyle(
    color: AppColors.blackColor,
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );
  static final TextStyle blackBold14 = TextStyle(
    color: AppColors.blackColor,
    fontSize: 14,
    fontWeight: FontWeight.bold,
  );
  static final TextStyle blackBold16 = TextStyle(
    color: AppColors.blackColor,
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );
  static final TextStyle blackBold18 = TextStyle(
    color: AppColors.blackColor,
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );
  static final TextStyle whiteBold20 = TextStyle(
    color: AppColors.whiteColor,
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );
  static final TextStyle primaryBold14 = TextStyle(
    color: AppColors.primaryColor,
    fontSize: 14,
    fontWeight: FontWeight.bold,
  );
  static final TextStyle primaryBold16 = TextStyle(
    color: AppColors.primaryColor,
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );
  static final TextStyle primaryBold20 = TextStyle(
    color: AppColors.primaryColor,
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );
  static final TextStyle primaryBold24 = TextStyle(
    color: AppColors.primaryColor,
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  /// Quran ayah body text with Amiri Quran font and comfortable line height.
  static final TextStyle quranAyah = TextStyle(
    color: AppColors.primaryColor,
    fontSize: 24,
    height: 2.0,
    fontFamily: 'AmiriQuran',
  );

  /// Bismillah and Surah title style for the reading screen.
  static final TextStyle quranBismillah = TextStyle(
    color: AppColors.primaryColor,
    fontSize: 26,
    height: 1.8,
    fontFamily: 'AmiriQuran',
  );
}
