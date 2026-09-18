import 'package:flutter/material.dart';

import '../../../../../utils/app_colors.dart';

/// Mode toggle button with a slash overlay when inactive.
class ReciterModeIconButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onPressed;

  const ReciterModeIconButton({
    super.key,
    required this.icon,
    required this.isActive,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final Color iconColor =
        isActive ? AppColors.blackColor : AppColors.grayColor;

    return IconButton(
      onPressed: onPressed,
      icon: SizedBox(
        width: 32,
        height: 32,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, color: iconColor, size: 28),
            if (!isActive)
              Transform.rotate(
                angle: -0.8,
                child: Container(
                  width: 28,
                  height: 2,
                  color: AppColors.blackColor,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
