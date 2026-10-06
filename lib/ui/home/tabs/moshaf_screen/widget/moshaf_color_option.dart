import 'package:flutter/material.dart';
import 'package:islami/utils/app_colors.dart';

/// Round color swatch; shows a gold ring and check mark when selected.
class MoshafColorOption extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const MoshafColorOption({
    super.key,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : AppColors.grayColor,
            width: isSelected ? 3 : 1,
          ),
        ),
        child: isSelected
            ? const Icon(Icons.check, color: AppColors.primaryColor, size: 20)
            : null,
      ),
    );
  }
}
