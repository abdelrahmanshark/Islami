import 'package:flutter/material.dart';
import 'package:islami/utils/app_animations.dart';
import 'package:islami/utils/app_colors.dart';

/// Row of dots showing which zikr the user is on; the active one stretches.
class ZikrProgressDots extends StatelessWidget {
  const ZikrProgressDots({
    super.key,
    required this.count,
    required this.activeIndex,
  });

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    List<Widget> dots = [];
    for (int i = 0; i < count; i++) {
      final bool isActive = i == activeIndex;
      dots.add(
        AnimatedContainer(
          duration: AppAnimations.fast,
          curve: AppAnimations.curve,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primaryColor
                : AppColors.whiteColor.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: dots,
    );
  }
}
