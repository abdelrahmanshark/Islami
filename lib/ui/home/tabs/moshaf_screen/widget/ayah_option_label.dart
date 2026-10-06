import 'package:flutter/material.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';

/// Small chip shown near a selected ayah (e.g. "التفسير", "سبب النزول").
class AyahOptionLabel extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const AyahOptionLabel({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparentColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.blackColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primaryColor),
          ),
          child: Text(
            label,
            style: AppStyles.primaryBold14,
            textDirection: TextDirection.rtl,
          ),
        ),
      ),
    );
  }
}
