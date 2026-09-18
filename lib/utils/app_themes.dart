import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';

class AppTheme {
  /// Transparent status bar so app content draws behind it.
  static const SystemUiOverlayStyle systemUiOverlayStyle = SystemUiOverlayStyle(
    statusBarColor: AppColors.transparentColor,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: AppColors.primaryColor,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarDividerColor: AppColors.transparentColor,
  );

  static final ThemeData lightTheme = ThemeData(
    scaffoldBackgroundColor: AppColors.transparentColor,
    appBarTheme: const AppBarTheme(
      systemOverlayStyle: systemUiOverlayStyle,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.primaryColor,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.whiteColor,
      unselectedItemColor: AppColors.blackColor,
      showSelectedLabels: true,
      showUnselectedLabels: false,
      selectedLabelStyle: AppStyles.whiteBold12,
    ),
    textSelectionTheme: const TextSelectionThemeData(
      selectionHandleColor: AppColors.primaryColor,
      cursorColor: AppColors.primaryColor,
      selectionColor: AppColors.blackColor,
    ),
  );
}
