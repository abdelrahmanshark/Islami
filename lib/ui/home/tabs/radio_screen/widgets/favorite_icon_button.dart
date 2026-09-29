import 'package:flutter/material.dart';
import 'package:islami/ui/home/widgets/animated_icon_switcher.dart';
import 'package:islami/utils/app_colors.dart';

/// Heart button that adds a card to favorites or removes it.
class FavoriteIconButton extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback onPressed;

  const FavoriteIconButton({
    super.key,
    required this.isFavorite,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      tooltip: isFavorite ? 'إزالة من المفضلة' : 'إضافة إلى المفضلة',
      icon: AnimatedIconSwitcher(
        child: Icon(
          isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          key: ValueKey(isFavorite),
          color: AppColors.blackColor,
          size: 26,
        ),
      ),
    );
  }
}
