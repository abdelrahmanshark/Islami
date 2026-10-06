import 'package:flutter/material.dart';
import 'package:islami/models/azkar_response.dart';
import 'package:islami/ui/home/tabs/radio_screen/widget/favorite_icon_button.dart';
import 'package:islami/ui/widget/pressable_scale.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';

/// Azkar category card with its title, items count, and a favorite heart.
class AzkarCategoryCard extends StatelessWidget {
  final AzkarCategory category;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoritePressed;

  const AzkarCategoryCard({
    super.key,
    required this.category,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoritePressed,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      category.title,
                      style: AppStyles.blackBold16,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'عدد الأذكار: ${category.items.length}',
                      style: AppStyles.blackBold14,
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ),
              ),
              FavoriteIconButton(
                isFavorite: isFavorite,
                onPressed: onFavoritePressed,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
