import 'package:flutter/material.dart';
import 'package:islami/utils/app_colors.dart';

/// Decorative Mushaf frame around a Quran page image.
///
/// Dark mode: primary-color frame on every page.
/// Light mode: taupe frame only on pages 1 and 2; other pages have no frame.
class MoshafPageFrame extends StatelessWidget {
  final Widget child;
  final bool isDarkTheme;
  final int pageNumber;

  const MoshafPageFrame({
    super.key,
    required this.child,
    this.isDarkTheme = false,
    required this.pageNumber,
  });

  @override
  Widget build(BuildContext context) {
    // Light mode: frame only on pages 1 and 2.
    if (!isDarkTheme && pageNumber != 1 && pageNumber != 2) {
      return child;
    }

    final frameColor =
        isDarkTheme ? AppColors.primaryColor : AppColors.taupe;
    final gapColor =
        isDarkTheme ? AppColors.blackColor : AppColors.offWhite;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      child: Container(
        // Outer fill creates a solid single-piece frame.
        color: frameColor,
        // Frame thickness (wider than the old thin double outline).
        padding: const EdgeInsets.all(10),
        child: Container(
          color: gapColor,
          // Very small gap so the text almost touches the frame.
          padding: const EdgeInsets.only(
            left: 10,
            right: 12,
            top: 4,
            bottom: 10,
          ),
          child: child,
        ),
      ),
    );
  }
}
