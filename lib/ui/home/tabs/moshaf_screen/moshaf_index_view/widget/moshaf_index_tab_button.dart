import 'package:flutter/material.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';

/// One selectable tab chip for the Mushaf index categories.
class MoshafIndexTabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const MoshafIndexTabButton({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: isSelected ? AppColors.primaryColor : AppColors.blackColor,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primaryColor),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: isSelected
                    ? AppStyles.blackBold14
                    : AppStyles.primaryBold14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
