import 'package:flutter/material.dart';
import 'package:islami/ui/home/widgets/animated_icon_switcher.dart';
import 'package:islami/utils/app_colors.dart';

/// Compact icon button used by the mini player controls.
/// The icon scales and fades when it changes (e.g. play ↔ pause).
class MiniPlayerIconButton extends StatelessWidget {
  const MiniPlayerIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 28,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      icon: AnimatedIconSwitcher(
        child: Icon(
          icon,
          key: ValueKey(icon),
          color: AppColors.blackColor,
          size: size,
        ),
      ),
    );
  }
}
