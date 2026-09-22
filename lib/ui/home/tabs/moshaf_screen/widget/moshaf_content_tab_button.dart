import 'package:flutter/material.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';

/// Tab button for switching between Mushaf and Tafsir inside Moshaf.
class MoshafContentTabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const MoshafContentTabButton({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryColor.withValues(alpha: 0.2)
                : AppColors.transparentColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryColor
                  : AppColors.primaryColor.withValues(alpha: 0.3),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: isSelected
                ? AppStyles.primaryBold16
                : AppStyles.primaryBold14.copyWith(
                    color: AppColors.primaryColor.withValues(alpha: 0.7),
                  ),
            textDirection: TextDirection.rtl,
          ),
        ),
      ),
    );
  }
}
