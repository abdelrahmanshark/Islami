import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:islami/utils/app_animations.dart';
import 'package:islami/utils/app_colors.dart';

/// Bottom bar icon; the selected one gets a pill background that
/// animates in and out when the tab changes.
class BottomNavIcon extends StatelessWidget {
  const BottomNavIcon({
    super.key,
    required this.icon,
    required this.isSelected,
  });

  final String icon;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppAnimations.fast,
      curve: AppAnimations.curve,
      padding: EdgeInsets.symmetric(
        horizontal: isSelected ? 20 : 0,
        vertical: isSelected ? 6 : 0,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(66),
        color: isSelected ? AppColors.grayColor : AppColors.transparentColor,
      ),
      child: SvgPicture.asset(
        icon,
        colorFilter: isSelected
            ? const ColorFilter.mode(AppColors.whiteColor, BlendMode.srcIn)
            : null,
      ),
    );
  }
}
