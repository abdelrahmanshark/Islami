import 'package:flutter/material.dart';
import 'package:islami/utils/app_colors.dart';

/// Solid rectangular Mushaf frame around a Quran page image.
///
/// Uses a single thick primary-color border so the frame reads as one piece,
/// with only a tiny gap between the frame and the Quran text.
class MoshafPageFrame extends StatelessWidget {
  final Widget child;
  final bool isDarkTheme;

  const MoshafPageFrame({
    super.key,
    required this.child,
    this.isDarkTheme = false,
  });

  @override
  Widget build(BuildContext context) {
    final fillColor =
        isDarkTheme ? AppColors.blackColor : AppColors.offWhite;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      child: Container(
        // Outer primary fill creates a solid single-piece frame.
        color: AppColors.primaryColor,
        // Frame thickness (wider than the old thin double outline).
        padding: const EdgeInsets.all(10),
        child: Container(
          color: fillColor,
          // Very small gap so the text almost touches the frame.
          padding: const EdgeInsets.only(left: 10, right: 10, top: 4, bottom: 10),
          child: child,
        ),
      ),
    );
  }
}
